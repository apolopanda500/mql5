// XAU_AI_PRO v1.2.9
#ifndef SIGNALCORE_MQH
#define SIGNALCORE_MQH

#include "../Core/Config.mqh"

//==================================================
// SIGNAL CORE (baseline v1.2.0 restaurado)
// Revertido do backup v1.2.0 (24/08 17:36 -> cache de
// handles causou 'Falha ao copiar RSI' e travou sinais).
// Comportamento restaurado: handles criados, copiados e
// liberados a CADA chamada (como na versao que operava).
// Stubs SignalCoreInit/ReleaseSignalHandles mantidos
// apenas para compatibilidade com OnInit/OnDeinit.
//==================================================

// Stub por compatibilidade (chamado no OnInit).
void SignalCoreInit()
{
}

// Stub por compatibilidade (chamado no OnDeinit).
void ReleaseSignalHandles()
{
}

//==================================================
// v1.2.94 (02/11/2026) - P1.82: DESFECHO DO SINAL
//
// Ate aqui todos os caminhos de GetSignal devolviam o MESMO 0: handle
// invalido, copia falhada, historico vazio e "a regra nao pediu entrada".
// Medido no journal de 02/11: 13 293 varreduras NoSignal no dia, sem uma
// unica pista de qual dos quatro motivos era. Passa a haver dois
// contadores, publicados no [SCANNER] RESUMO:
//   g_sigNoRead  -> nao foi possivel LER (handle/copia/historico)
//   g_sigNeutral -> leu tudo e a REGRA nao pediu entrada
// Sem leitura e mercado sem setup sao doencas diferentes.
//==================================================
int g_sigNoRead  = 0;
int g_sigNeutral = 0;

int SignalNoReadCount()
{
   return g_sigNoRead;
}

int SignalNeutralCount()
{
   return g_sigNeutral;
}

int GetSignal()
{
   return GetSignal(_Symbol);
}

//==================================================
// MULTI SYMBOL
//==================================================

int GetSignal(string symbol)
{
   // v1.2.93 (02/11/2026) - P1.80: MEDIDO no journal de 02/11 as 20:23 - as
   // duas unicas linhas SEM TAG que restavam eram as do sinal ('USDBRL SIGNAL
   // BUY | RSI[1]=37.31'), e o throttle era um static UNICO partilhado por
   // todos os simbolos: o primeiro simbolo que passava gastava a vez do
   // minuto e os outros ficavam invisiveis no journal. Passa a throttle POR
   // SIMBOLO e a tag [SIGNAL], para o journal fechar em 0 linhas anonimas e
   // cada simbolo poder dizer se gerou sinal. Diagnostico apenas: nenhum
   // return, limite, lote, alvo ou regra de entrada muda.
   static string   sigLogSymbols[];
   static datetime sigLogTimes[];
   datetime logNow = TimeCurrent();
   bool logOnce = false;
   int sigIdx = -1;

   for(int si = 0; si < ArraySize(sigLogSymbols); si++)
     {
      if(sigLogSymbols[si] == symbol)
        {
         sigIdx = si;
         break;
        }
     }

   if(sigIdx < 0)
     {
      sigIdx = ArraySize(sigLogSymbols);
      ArrayResize(sigLogSymbols, sigIdx + 1);
      ArrayResize(sigLogTimes, sigIdx + 1);
      sigLogSymbols[sigIdx] = symbol;
      sigLogTimes[sigIdx] = 0;
     }

   if(logNow - sigLogTimes[sigIdx] >= 60)
     {
      sigLogTimes[sigIdx] = logNow;
      logOnce = true;
     }

   if(symbol=="")
      return 0;

   // Indicadores
   int emaFastHandle=iMA(
      symbol,
      PERIOD_CURRENT,
      FastEMA,
      0,
      MODE_EMA,
      PRICE_CLOSE
   );

   int emaSlowHandle=iMA(
      symbol,
      PERIOD_CURRENT,
      SlowEMA,
      0,
      MODE_EMA,
      PRICE_CLOSE
   );

   int signalRSIHandle=iRSI(
      symbol,
      PERIOD_CURRENT,
      RSIPeriod,
      PRICE_CLOSE
   );

   // Valida handles
   if(emaFastHandle==INVALID_HANDLE)
   {
      g_sigNoRead++;
      if(logOnce)
         Print("[SIGNAL] SEM LEITURA | ", symbol, " | handle EMA Fast invalido");
      return 0;
   }

   if(emaSlowHandle==INVALID_HANDLE)
   {
      g_sigNoRead++;
      if(logOnce)
         Print("[SIGNAL] SEM LEITURA | ", symbol, " | handle EMA Slow invalido");
      IndicatorRelease(emaFastHandle);
      return 0;
   }

   if(signalRSIHandle==INVALID_HANDLE)
   {
      g_sigNoRead++;
      if(logOnce)
         Print("[SIGNAL] SEM LEITURA | ", symbol, " | handle RSI invalido");
      IndicatorRelease(emaFastHandle);
      IndicatorRelease(emaSlowHandle);
      return 0;
   }

   double fast[];
   double slow[];
   double rsi[];

   ArrayResize(fast,3);
   ArrayResize(slow,3);
   ArrayResize(rsi,3);

   ArraySetAsSeries(fast,true);
   ArraySetAsSeries(slow,true);
   ArraySetAsSeries(rsi,true);

   // Copiar buffers
   bool copyOK=true;

   if(CopyBuffer(emaFastHandle,0,0,3,fast)<=0)
   {
      if(logOnce)
         Print("[SIGNAL] SEM LEITURA | ", symbol, " | falha ao copiar EMA Fast | Error=", GetLastError());
      copyOK=false;
   }

   if(CopyBuffer(emaSlowHandle,0,0,3,slow)<=0)
   {
      if(logOnce)
         Print("[SIGNAL] SEM LEITURA | ", symbol, " | falha ao copiar EMA Slow | Error=", GetLastError());
      copyOK=false;
   }

   if(CopyBuffer(signalRSIHandle,0,0,3,rsi)<=0)
   {
      if(logOnce)
         Print("[SIGNAL] SEM LEITURA | ", symbol, " | falha ao copiar RSI | Error=", GetLastError());
      copyOK=false;
   }

   // Liberar handles em todos os casos
   IndicatorRelease(emaFastHandle);
   IndicatorRelease(emaSlowHandle);
   IndicatorRelease(signalRSIHandle);

   if(!copyOK)
   {
      g_sigNoRead++;
      return 0;
   }

   // Logica de sinal v1.21 - vela FECHADA (indice 1) + pullback com reversao
   // BUY: tendencia de alta M15 (EMA50>EMA200) + RSI fechou <45 (pullback) + RSI virando p/ cima
   // SELL: tendencia de baixa M15 (EMA50<EMA200) + RSI fechou >55 (rally) + RSI virando p/ baixo
   // P2.01 (03/11/2026): a MESMA linha era escrita a cada minuto enquanto o
   // sinal persistia - o USDCNH escreveu "[SIGNAL] SELL | RSI[1]=74.26" as
   // 07:03, 07:04, 07:05 e 07:06. O sinal nao mudou, o RSI nao mudou. A
   // classificacao fica identica (o return e o mesmo 1/-1); muda apenas
   // QUANDO a linha vai para o journal: na mudanca de direcao e, no maximo,
   // 1x/hora por CONTA e por simbolo.
   int sinalLocal = 0;

   if(fast[1]>slow[1] && rsi[1]<RSIPullbackBuy && rsi[1]>rsi[2])
      sinalLocal = 1;
   else if(fast[1]<slow[1] && rsi[1]>RSIPullbackSell && rsi[1]<rsi[2])
      sinalLocal = -1;

   if(sinalLocal != 0)
   {
      static string   dirSim[64];
      static int      dirVal[64];
      static datetime dirTs[64];
      static int      dirN = 0;

      int idxDir = -1;

      for(int di = 0; di < dirN; di++)
         if(dirSim[di] == symbol)
           {
            idxDir = di;
            break;
           }

      if(idxDir < 0 && dirN < 64)
        {
         idxDir = dirN;
         dirSim[idxDir] = symbol;
         dirVal[idxDir] = 0;
         dirN++;
        }

      bool imprimirSinal = false;

      if(idxDir >= 0)
        {
         datetime agoraSinal = TimeCurrent();

         if(dirVal[idxDir] != sinalLocal)
            imprimirSinal = true;
         else if((agoraSinal - dirTs[idxDir]) >= 3600 &&
                 AccountLogGatePodeImprimir("sig_dir_" + symbol, 3600))
            imprimirSinal = true;

         if(imprimirSinal)
           {
            dirVal[idxDir] = sinalLocal;
            dirTs[idxDir]  = agoraSinal;
           }
        }

      if(logOnce && imprimirSinal)
         Print(sinalLocal > 0 ? "[SIGNAL] BUY | " : "[SIGNAL] SELL | ",
               symbol, " | RSI[1]=", DoubleToString(rsi[1], 2));

      return sinalLocal;
   }

   //--------------------------------------------------
   // v1.2.94 (02/11/2026) - P1.82: chegou aqui, o simbolo FOI lido e a
   // regra e que nao pediu entrada. 1 linha/15 min por simbolo (11
   // simbolos = 44/hora) para provar leitura viva sem encher o journal.
   //--------------------------------------------------
   g_sigNeutral++;

   static string   neuSim[];
   static datetime neuHora[];

   int nIdx = -1;

   for(int ni = 0; ni < ArraySize(neuSim); ni++)
      if(neuSim[ni] == symbol)
        {
         nIdx = ni;
         break;
        }

   if(nIdx < 0)
     {
      nIdx = ArraySize(neuSim);
      ArrayResize(neuSim, nIdx + 1);
      ArrayResize(neuHora, nIdx + 1);
      neuSim[nIdx]  = symbol;
      neuHora[nIdx] = 0;
     }

   // P2.02: o NEUTRO saia 1x/15 min em CADA grafico, com tendencia, EMA50,
   // EMA200 e RSI iguais nos 15 graficos. Passa a 1x/hora por simbolo e por
   // CONTA (sig_neu_): e estado, nao evento, e o mesmo mercado para todos.
   if(neuHora[nIdx] == 0 || (logNow - neuHora[nIdx]) >= 3600)
     {
      if(!AccountLogGatePodeImprimir("sig_neu_" + symbol, 3600))
         return 0;

      neuHora[nIdx] = logNow;

      int dg = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

      if(dg <= 0)
         dg = 5;

      Print("[SIGNAL] NEUTRO | ", symbol,
            " | tendencia=", (fast[1] > slow[1] ? "ALTA" : "BAIXA"),
            " | EMA50=", DoubleToString(fast[1], dg),
            " EMA200=", DoubleToString(slow[1], dg),
            " | RSI[1]=", DoubleToString(rsi[1], 2),
            " RSI[2]=", DoubleToString(rsi[2], 2),
            " | pede: BUY RSI<", DoubleToString(RSIPullbackBuy, 1), " e a subir",
            " | SELL RSI>", DoubleToString(RSIPullbackSell, 1), " e a descer");
     }

   return 0;
}

#endif