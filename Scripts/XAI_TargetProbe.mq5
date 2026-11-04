//+------------------------------------------------------------------+
//|                                             XAI_TargetProbe.mq5  |
//| Sonda de alvos e de politica de saida (diagnostico, NAO negocia). |
//|                                                                  |
//| Para cada posicao real do EA (magic):                            |
//|   R  = distancia do stop ORIGINAL (maior SL visto nas ordens da   |
//|        posicao, porque BreakEven so aperta o stop, nunca afasta)  |
//|   MFE/MAE em R dentro de uma janela de horas apos a entrada       |
//|                                                                  |
//| Duas leituras:                                                   |
//|  1) grid de alvos fixos em R (0,30 ... 2,00)                     |
//|  2) A/B da POLITICA DE SAIDA, nas mesmas operacoes:              |
//|     ANTIGA = resultado realmente realizado (R)                    |
//|     NOVA   = trava em LockR depois de TriggerR, alvo em TpR      |
//|                                                                  |
//| Filtro de contaminacao: posicao cujo unico SL registrado e o de   |
//| break even aparece com R minusculo; descarta R/preco < 0,02%.     |
//| Saida: Files\Data\XAI_targets_probe.csv                          |
//+------------------------------------------------------------------+
#property script_show_inputs

input long   InpMagic        = 2026001;   // magic do EA
input int    InpHorizonHours = 12;        // horas de preco a frente
input int    InpMaxPositions = 400;       // limite de posicoes
input bool   InpOnlyExpert   = true;      // apenas operacoes do EA
input double InpMinRelR      = 0.0002;    // descarta R/preco abaixo disso
input double InpNewTriggerR  = 0.60;      // NOVA politica: gatilho da trava (R)
input double InpNewLockR      = 0.30;     // NOVA politica: trava (R)
input double InpNewTpR        = 1.00;     // NOVA politica: alvo (R)
input string InpOutputFile   = "Data\\XAI_targets_probe.csv";

#define KCOUNT 9

//+------------------------------------------------------------------+
void OnStart()
  {
   double K[KCOUNT];
   K[0] = 0.30;
   K[1] = 0.40;
   K[2] = 0.50;
   K[3] = 0.60;
   K[4] = 0.80;
   K[5] = 1.00;
   K[6] = 1.25;
   K[7] = 1.50;
   K[8] = 2.00;

//--- 1) coleta as entradas (DEAL_ENTRY_IN) do magic alvo
   long     posIds[];
   string   vSymbol[];
   int      vDir[];
   datetime vTime[];
   double   vPrice[];

   ArrayResize(posIds, 0);
   ArrayResize(vSymbol, 0);
   ArrayResize(vDir, 0);
   ArrayResize(vTime, 0);
   ArrayResize(vPrice, 0);

   if(!HistorySelect(0, TimeCurrent()))
     {
      Print("[PROBE] HistorySelect falhou | err=", GetLastError());
      return;
     }

   int dealsTotal = HistoryDealsTotal();
   int collected  = 0;

   for(int i = 0; i < dealsTotal; i++)
     {
      ulong dt = HistoryDealGetTicket(i);
      if(dt == 0)
         continue;

      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(dt, DEAL_ENTRY) != DEAL_ENTRY_IN)
         continue;

      long magic = (long)HistoryDealGetInteger(dt, DEAL_MAGIC);
      if(InpOnlyExpert && magic != InpMagic)
         continue;

      long posId = (long)HistoryDealGetInteger(dt, DEAL_POSITION_ID);
      if(posId == 0)
         continue;

      bool seen = false;
      for(int j = 0; j < collected; j++)
        {
         if(posIds[j] == posId)
           {
            seen = true;
            break;
           }
        }
      if(seen)
         continue;

      int dir = ((ENUM_DEAL_TYPE)HistoryDealGetInteger(dt, DEAL_TYPE) == DEAL_TYPE_BUY) ? 1 : -1;

      ArrayResize(posIds, collected + 1);
      ArrayResize(vSymbol, collected + 1);
      ArrayResize(vDir, collected + 1);
      ArrayResize(vTime, collected + 1);
      ArrayResize(vPrice, collected + 1);

      posIds[collected]  = posId;
      vSymbol[collected] = HistoryDealGetString(dt, DEAL_SYMBOL);
      vDir[collected]    = dir;
      vTime[collected]   = (datetime)HistoryDealGetInteger(dt, DEAL_TIME);
      vPrice[collected]  = HistoryDealGetDouble(dt, DEAL_PRICE);

      collected++;

      if(collected >= InpMaxPositions)
         break;
     }

   Print("[PROBE] entradas coletadas=", collected, " de ", dealsTotal, " deals");

   if(collected == 0)
     {
      Print("[PROBE] nada para analisar");
      return;
     }

//--- 2) por posicao: SL original, TP, saida real
   double   vR[];
   double   vSL[];
   double   vTP[];
   double   vExit[];
   double   vProfit[];
   double   vRealR[];
   double   vMFE[];
   double   vMAE[];
   bool     vOk[];

   ArrayResize(vR, collected);
   ArrayResize(vSL, collected);
   ArrayResize(vTP, collected);
   ArrayResize(vExit, collected);
   ArrayResize(vProfit, collected);
   ArrayResize(vRealR, collected);
   ArrayResize(vMFE, collected);
   ArrayResize(vMAE, collected);
   ArrayResize(vOk, collected);

   int valid  = 0;
   int noStop = 0;
   int contam = 0;

   for(int i = 0; i < collected; i++)
     {
      vOk[i]     = false;
      vR[i]      = 0.0;
      vSL[i]     = 0.0;
      vTP[i]     = 0.0;
      vExit[i]   = 0.0;
      vProfit[i] = 0.0;
      vRealR[i]  = 0.0;
      vMFE[i]    = 0.0;
      vMAE[i]    = 0.0;

      if(!HistorySelectByPosition(posIds[i]))
         continue;

      double bestDist = 0.0;
      int ordersTotal = HistoryOrdersTotal();

      for(int o = 0; o < ordersTotal; o++)
        {
         ulong ot = HistoryOrderGetTicket(o);
         if(ot == 0)
            continue;

         double sl = HistoryOrderGetDouble(ot, ORDER_SL);
         double tp = HistoryOrderGetDouble(ot, ORDER_TP);

         if(sl > 0.0)
           {
            double dist = MathAbs(vPrice[i] - sl);
            if(dist > bestDist)
              {
               bestDist = dist;
               vSL[i]   = sl;
              }
           }

         if(tp > 0.0 && vTP[i] == 0.0)
            vTP[i] = tp;
        }

      int dealsPos = HistoryDealsTotal();

      for(int d = 0; d < dealsPos; d++)
        {
         ulong dt2 = HistoryDealGetTicket(d);
         if(dt2 == 0)
            continue;

         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dt2, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY && entry != DEAL_ENTRY_INOUT)
            continue;

         vExit[i]    = HistoryDealGetDouble(dt2, DEAL_PRICE);
         vProfit[i] += HistoryDealGetDouble(dt2, DEAL_PROFIT)
                       + HistoryDealGetDouble(dt2, DEAL_SWAP)
                       + HistoryDealGetDouble(dt2, DEAL_COMMISSION);
        }

      if(bestDist <= 0.0 || vPrice[i] <= 0.0)
        {
         noStop++;
         continue;
        }

      // v1.2.17: stop de break even (poucos pontos) nao e o stop do trade
      if(bestDist / vPrice[i] < InpMinRelR)
        {
         contam++;
         continue;
        }

      vR[i]  = bestDist;
      vOk[i] = true;
      valid++;
     }

   Print("[PROBE] validas=", valid, " | sem stop=", noStop, " | contaminadas=", contam);

   if(valid == 0)
     {
      Print("[PROBE] nenhuma posicao valida");
      return;
     }

//--- 3) simulacoes
   int    tpHits[KCOUNT];
   int    slHits[KCOUNT];
   int    openCnt[KCOUNT];
   double totalR[KCOUNT];

   for(int k = 0; k < KCOUNT; k++)
     {
      tpHits[k]  = 0;
      slHits[k]  = 0;
      openCnt[k] = 0;
      totalR[k]  = 0.0;
     }

   double sumOldR   = 0.0;   // realizado real (politica antiga)
   double sumNewR   = 0.0;   // politica nova simulada
   int    newTp     = 0;
   int    newSl     = 0;
   int    newLock   = 0;
   int    newOpen   = 0;

   int simulated = 0;
   int noData    = 0;

   for(int i = 0; i < collected; i++)
     {
      if(!vOk[i])
         continue;

      datetime tFrom = vTime[i];
      datetime tTo   = vTime[i] + (datetime)(InpHorizonHours * 3600);

      MqlRates rates[];
      int copied = CopyRates(vSymbol[i], PERIOD_M1, tFrom, tTo, rates);

      if(copied <= 0)
        {
         noData++;
         continue;
        }

      ArraySetAsSeries(rates, false);

      double R = vR[i];
      if(R <= 0.0)
         continue;

      double maxFav = 0.0;
      double maxAdv = 0.0;

      for(int b = 0; b < copied; b++)
        {
         double favP = (vDir[i] > 0) ? (rates[b].high - vPrice[i]) : (vPrice[i] - rates[b].low);
         double advP = (vDir[i] > 0) ? (vPrice[i] - rates[b].low) : (rates[b].high - vPrice[i]);

         if(favP / R > maxFav)
            maxFav = favP / R;
         if(advP / R > maxAdv)
            maxAdv = advP / R;
        }

      vMFE[i] = maxFav;
      vMAE[i] = maxAdv;

      if(vExit[i] > 0.0)
        {
         double realP = (vDir[i] > 0) ? (vExit[i] - vPrice[i]) : (vPrice[i] - vExit[i]);
         vRealR[i] = realP / R;
        }

      sumOldR += vRealR[i];

      //--- 3a) grid de alvos fixos
      for(int k = 0; k < KCOUNT; k++)
        {
         int    outcome = 0;
         double mtm     = 0.0;

         for(int b = 0; b < copied; b++)
           {
            double favP = (vDir[i] > 0) ? (rates[b].high - vPrice[i]) : (vPrice[i] - rates[b].low);
            double advP = (vDir[i] > 0) ? (vPrice[i] - rates[b].low) : (rates[b].high - vPrice[i]);

            double favR = favP / R;
            double advR = advP / R;

            if(advR >= 1.0)
              {
               outcome = -1;
               break;
              }

            if(favR >= K[k])
              {
               outcome = 1;
               break;
              }

            mtm = ((vDir[i] > 0) ? (rates[b].close - vPrice[i]) : (vPrice[i] - rates[b].close)) / R;
           }

         if(outcome == 1)
           {
            tpHits[k]++;
            totalR[k] += K[k];
           }
         else
            if(outcome == -1)
              {
               slHits[k]++;
               totalR[k] -= 1.0;
              }
            else
              {
               openCnt[k]++;
               totalR[k] += mtm;
              }
        }

      //--- 3b) politica NOVA: trava em LockR depois de TriggerR, alvo TpR
      bool armed = false;
      int  how   = 0;          // 1=alvo, -1=stop, 2=trava
      double res = 0.0;
      double mtmNew = 0.0;

      for(int b = 0; b < copied; b++)
        {
         double favP = (vDir[i] > 0) ? (rates[b].high - vPrice[i]) : (vPrice[i] - rates[b].low);
         double advP = (vDir[i] > 0) ? (vPrice[i] - rates[b].low) : (rates[b].high - vPrice[i]);

         double favR = favP / R;
         double advR = advP / R;

         // conservador: stop antes do alvo dentro da mesma vela
         if(armed)
           {
            if(advR >= InpNewLockR)
              {
               how = 2;
               res = InpNewLockR;
               break;
              }
           }
         else
           {
            if(advR >= 1.0)
              {
               how = -1;
               res = -1.0;
               break;
              }
           }

         if(favR >= InpNewTpR)
           {
            how = 1;
            res = InpNewTpR;
            break;
           }

         if(!armed && favR >= InpNewTriggerR)
            armed = true;

         mtmNew = ((vDir[i] > 0) ? (rates[b].close - vPrice[i]) : (vPrice[i] - rates[b].close)) / R;
        }

      if(how == 1)
         newTp++;
      else
         if(how == -1)
            newSl++;
         else
            if(how == 2)
               newLock++;
            else
               newOpen++;

      sumNewR += (how != 0) ? res : mtmNew;

      simulated++;
     }

   Print("[PROBE] simuladas=", simulated, " | sem dados M1=", noData);
   Print("[PROBE] ANTIGA realizado_R=", DoubleToString(sumOldR, 2),
         " | NOVA=", DoubleToString(sumNewR, 2),
         " | alvo=", newTp, " stop=", newSl, " trava=", newLock, " aberto=", newOpen);

//--- 4) grava CSV
   int h = FileOpen(InpOutputFile, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
     {
      Print("[PROBE] FileOpen falhou | ", InpOutputFile, " | err=", GetLastError());
      return;
     }

   FileWriteString(h, "# XAI_TargetProbe | magic=" + (string)InpMagic
                    + " | horizonte_h=" + (string)InpHorizonHours
                    + " | validas=" + (string)simulated
                    + " | descartadas_sem_stop=" + (string)noStop
                    + " | descartadas_contaminadas=" + (string)contam + "\r\n");

   FileWriteString(h, "# symbol;dir;entrada;sl;tp;R;realizado_R;mfe_R;mae_R;profit\r\n");

   for(int i = 0; i < collected; i++)
     {
      if(!vOk[i])
         continue;

      FileWriteString(h,
                      vSymbol[i] + ";" +
                      (string)vDir[i] + ";" +
                      DoubleToString(vPrice[i], 5) + ";" +
                      DoubleToString(vSL[i], 5) + ";" +
                      DoubleToString(vTP[i], 5) + ";" +
                      DoubleToString(vR[i], 5) + ";" +
                      DoubleToString(vRealR[i], 3) + ";" +
                      DoubleToString(vMFE[i], 3) + ";" +
                      DoubleToString(vMAE[i], 3) + ";" +
                      DoubleToString(vProfit[i], 2) + "\r\n");
     }

   FileWriteString(h, "\r\n# A/B DA POLITICA DE SAIDA (mesmas operacoes)\r\n");
   FileWriteString(h, "# politica;total_R;media_R\r\n");

   double avgOld = (simulated > 0) ? sumOldR / simulated : 0.0;
   double avgNew = (simulated > 0) ? sumNewR / simulated : 0.0;

   FileWriteString(h, "ANTIGA_realizado;" + DoubleToString(sumOldR, 2) + ";" + DoubleToString(avgOld, 3) + "\r\n");
   FileWriteString(h, "NOVA_trava_" + DoubleToString(InpNewLockR, 2) + "R_apos_"
                    + DoubleToString(InpNewTriggerR, 2) + "R_tp_"
                    + DoubleToString(InpNewTpR, 2) + "R;"
                    + DoubleToString(sumNewR, 2) + ";" + DoubleToString(avgNew, 3) + "\r\n");
   FileWriteString(h, "# desfecho_NOVA;alvo=" + (string)newTp
                    + ";stop=" + (string)newSl
                    + ";trava=" + (string)newLock
                    + ";aberto=" + (string)newOpen + "\r\n");

   FileWriteString(h, "\r\n# K;sl_hits;tp_hits;open;total_R;wr;payoff;avg_R\r\n");

   for(int k = 0; k < KCOUNT; k++)
     {
      int total = tpHits[k] + slHits[k] + openCnt[k];
      double wr = (total > 0) ? (100.0 * tpHits[k] / total) : 0.0;
      double avg = (total > 0) ? (totalR[k] / total) : 0.0;

      double grossWin  = tpHits[k] * K[k];
      double grossLoss = slHits[k] * 1.0;
      double payoff    = (grossLoss > 0.0) ? (grossWin / grossLoss) : 0.0;

      FileWriteString(h,
                      DoubleToString(K[k], 2) + ";" +
                      (string)slHits[k] + ";" +
                      (string)tpHits[k] + ";" +
                      (string)openCnt[k] + ";" +
                      DoubleToString(totalR[k], 2) + ";" +
                      DoubleToString(wr, 1) + ";" +
                      DoubleToString(payoff, 3) + ";" +
                      DoubleToString(avg, 3) + "\r\n");
     }

   FileClose(h);

   Print("[PROBE] CSV gravado em Files\\", InpOutputFile);
  }
//+------------------------------------------------------------------+
