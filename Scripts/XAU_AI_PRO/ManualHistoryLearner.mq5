//+------------------------------------------------------------------+
//|                                        ManualHistoryLearner.mq5  |
//|                              XAU_AI_PRO - EXTRAÇÃO DE CONTEXTO     |
//+------------------------------------------------------------------+
// POR QUE ESTE SCRIPT EXISTE
// ==========================
// "Fazer o EA aprender como eu opero" só vira código se as operações
// manuais forem descritas como (contexto -> decisão -> resultado). O
// histórico do MT5 guarda PREÇO e VOLUME, mas não guarda RSI, ADX, ATR,
// distância da EMA, sessão. Sem essas colunas não existe dataset, e sem
// dataset não existe aprendizado — existe só opinião.
//
// Este script reconstrói o contexto de cada entrada MANUAL a partir das
// barras históricas, no instante do deal, e grava um CSV pronto para o
// pipeline Python treinar. Ele NÃO altera nenhuma operação e NÃO muda o
// EA: é um extrator, não um robô.
//
// DUAS HONESTIDADES QUE O RELATÓRIO IMPRIME
// =========================================
// 1. Amostra: com poucas dezenas de entradas não se treina modelo. O
//    script mede N e avisa quando N < InpMinSampleForLearning.
// 2. Viés direcional: se 100% das suas entradas foram SELL, o modelo
//    aprende "vender sempre", que é o viés do período, não uma regra.
//    O script mede a divisão compra/venda e avisa.
//+------------------------------------------------------------------+
#property script_show_inputs
#property version   "1.00"

input int             InpLookbackDays         = 180;             // Janela de historico (dias)
input ENUM_TIMEFRAMES InpFeatureTF            = PERIOD_M1;       // TF usado para reconstruir features
input int             InpRSIPeriod            = 14;              // Periodo RSI
input int             InpADXPeriod            = 14;              // Periodo ADX
input int             InpATRPeriod            = 14;              // Periodo ATR
input int             InpFastEMA              = 50;              // EMA rapida
input int             InpSlowEMA              = 200;             // EMA lenta
input long            InpEAMagic              = 2026001;         // Magic do EA (deals com este magic sao ignorados)
input string          InpOutputFile           = "Data\\manual_trades_features.csv"; // CSV de saida
input int             InpMinSampleForLearning = 100;             // Minimo de entradas para treinar

//--- operacoes manuais coletadas (arrays paralelos: struct com string
//--- nao e redimensionavel de forma confiavel em todas as builds)
ulong    g_posId[];
string   g_symbol[];
int      g_dir[];
datetime g_time[];
double   g_price[];
double   g_volume[];
double   g_sl[];
double   g_tp[];
double   g_profit[];
bool     g_win[];

//--- cache de handles por simbolo
string   g_ctxSymbol[];
int      g_ctxRSI[];
int      g_ctxADX[];
int      g_ctxATR[];
int      g_ctxFast[];
int      g_ctxSlow[];

//+------------------------------------------------------------------+
//| Cria (ou reutiliza) os handles de indicador de um simbolo.        |
//| Handles sao criados UMA vez por simbolo: criar por deal deixaria   |
//| dezenas de handles abertos no terminal.                            |
//+------------------------------------------------------------------+
int GetCtxIndex(const string symbol)
  {
   const int n = ArraySize(g_ctxSymbol);

   for(int i = 0; i < n; i++)
      if(g_ctxSymbol[i] == symbol)
         return i;

   ArrayResize(g_ctxSymbol, n + 1);
   ArrayResize(g_ctxRSI,    n + 1);
   ArrayResize(g_ctxADX,    n + 1);
   ArrayResize(g_ctxATR,    n + 1);
   ArrayResize(g_ctxFast,   n + 1);
   ArrayResize(g_ctxSlow,   n + 1);

   g_ctxSymbol[n] = symbol;
   g_ctxRSI[n]    = iRSI(symbol, InpFeatureTF, InpRSIPeriod, PRICE_CLOSE);
   g_ctxADX[n]    = iADX(symbol, InpFeatureTF, InpADXPeriod);
   g_ctxATR[n]    = iATR(symbol, InpFeatureTF, InpATRPeriod);
   g_ctxFast[n]   = iMA(symbol, InpFeatureTF, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_ctxSlow[n]   = iMA(symbol, InpFeatureTF, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);

   return n;
  }

//+------------------------------------------------------------------+
//| Valor de um handle no instante informado.                        |
//| false quando a barra nao existe ou o buffer nao esta pronto.     |
//+------------------------------------------------------------------+
bool FetchAt(const string symbol, const int handle, const datetime when, double &value)
  {
   value = 0.0;

   if(handle == INVALID_HANDLE)
      return false;

   const int shift = iBarShift(symbol, InpFeatureTF, when, false);
   if(shift < 0)
      return false;

   double buf[];
   if(CopyBuffer(handle, 0, shift, 1, buf) != 1)
      return false;

   value = buf[0];

   if(value == EMPTY_VALUE || value == 0.0)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Lucro realizado de uma posicao (soma das saidas).                |
//| 0.0 quando a posicao ainda esta aberta ou sem historico.         |
//+------------------------------------------------------------------+
double PositionRealizedProfit(const ulong positionId)
  {
   double profit = 0.0;
   const int total = HistoryDealsTotal();

   for(int i = 0; i < total; i++)
     {
      const ulong t = HistoryDealGetTicket(i);
      if(t == 0)
         continue;

      if((ulong)HistoryDealGetInteger(t, DEAL_POSITION_ID) != positionId)
         continue;

      const ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(t, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
         continue;

      profit += HistoryDealGetDouble(t, DEAL_PROFIT);
      profit += HistoryDealGetDouble(t, DEAL_SWAP);
      profit += HistoryDealGetDouble(t, DEAL_COMMISSION);
     }

   return profit;
  }

//+------------------------------------------------------------------+
//| Coleta as entradas manuais do periodo.                           |
//| Manual = deal de entrada sem o magic do EA.                      |
//+------------------------------------------------------------------+
bool CollectManualEntries(const datetime from, const datetime to)
  {
   ArrayResize(g_posId,  0);
   ArrayResize(g_symbol, 0);
   ArrayResize(g_dir,    0);
   ArrayResize(g_time,   0);
   ArrayResize(g_price,  0);
   ArrayResize(g_volume, 0);
   ArrayResize(g_sl,     0);
   ArrayResize(g_tp,     0);
   ArrayResize(g_profit, 0);
   ArrayResize(g_win,    0);

   if(!HistorySelect(from, to))
     {
      PrintFormat("HISTORY | HistorySelect falhou | Error=%d", GetLastError());
      return false;
     }

   const int total = HistoryDealsTotal();

   for(int i = 0; i < total; i++)
     {
      const ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0)
         continue;

      const long dealType = HistoryDealGetInteger(ticket, DEAL_TYPE);
      if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL)
         continue;   // ignora balance, credit, charging, etc.

      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_IN)
         continue;

      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == InpEAMagic)
         continue;   // operacao do EA: fora do estudo manual

      const string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
      if(symbol == "")
         continue;

      const ulong posId  = (ulong)HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
      const int   dir    = (dealType == DEAL_TYPE_BUY) ? 1 : -1;
      const double profit = PositionRealizedProfit(posId);

      const int n = ArraySize(g_posId);

      ArrayResize(g_posId,   n + 1);
      ArrayResize(g_symbol,  n + 1);
      ArrayResize(g_dir,     n + 1);
      ArrayResize(g_time,    n + 1);
      ArrayResize(g_price,   n + 1);
      ArrayResize(g_volume,  n + 1);
      ArrayResize(g_sl,      n + 1);
      ArrayResize(g_tp,      n + 1);
      ArrayResize(g_profit,  n + 1);
      ArrayResize(g_win,     n + 1);

      g_posId[n]  = posId;
      g_symbol[n] = symbol;
      g_dir[n]    = dir;
      g_time[n]   = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      g_price[n]  = HistoryDealGetDouble(ticket, DEAL_PRICE);
      g_volume[n] = HistoryDealGetDouble(ticket, DEAL_VOLUME);
      g_sl[n]     = HistoryDealGetDouble(ticket, DEAL_SL);
      g_tp[n]     = HistoryDealGetDouble(ticket, DEAL_TP);
      g_profit[n] = profit;
      g_win[n]    = (profit > 0.0);
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Grava o CSV de features e imprime o relatorio de viabilidade.    |
//+------------------------------------------------------------------+
void WriteDatasetAndReport(const datetime from, const datetime to)
  {
   const int n = ArraySize(g_posId);

   if(n == 0)
     {
      PrintFormat("DATASET | Nenhuma operacao MANUAL no periodo %s .. %s",
                  TimeToString(from, TIME_DATE), TimeToString(to, TIME_DATE));
      return;
     }

   const int fh = FileOpen(InpOutputFile, FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(fh == INVALID_HANDLE)
     {
      PrintFormat("DATASET | FileOpen falhou | %s | Error=%d", InpOutputFile, GetLastError());
      return;
     }

   FileWriteString(fh,
      "time,symbol,direction,entry_price,volume,sl,tp,"
      "sl_points,tp_points,rr,close,ema_fast,ema_slow,atr_points,"
      "rsi,adx,close_vs_slow_pts,fast_vs_slow_pts,hour,weekday,profit,win\r\n");

   int    buys      = 0;
   int    sells     = 0;
   int    wins      = 0;
   int    withSL    = 0;
   int    complete  = 0;
   double sumProfit = 0.0;

   string symbolsSeen = "";

   for(int i = 0; i < n; i++)
     {
      const string symbol = g_symbol[i];
      const datetime when = g_time[i];

      if(g_dir[i] > 0)
         buys++;
      else
         sells++;

      if(g_win[i])
         wins++;

      if(g_sl[i] > 0.0)
         withSL++;

      sumProfit += g_profit[i];

      if(StringFind(symbolsSeen, "|" + symbol + "|") < 0)
         symbolsSeen += "|" + symbol + "|";

      //---------------------------------------------------------------
      // Contexto: reconstruido nas barras do TF escolhido.
      //---------------------------------------------------------------
      const double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

      const int ctx = GetCtxIndex(symbol);

      double rsi = 0.0, adx = 0.0, atr = 0.0, fast = 0.0, slow = 0.0;
      const bool okRSI  = FetchAt(symbol, g_ctxRSI[ctx],  when, rsi);
      const bool okADX  = FetchAt(symbol, g_ctxADX[ctx],  when, adx);
      const bool okATR  = FetchAt(symbol, g_ctxATR[ctx],  when, atr);
      const bool okFast = FetchAt(symbol, g_ctxFast[ctx], when, fast);
      const bool okSlow = FetchAt(symbol, g_ctxSlow[ctx], when, slow);

      const int shift = iBarShift(symbol, InpFeatureTF, when, false);
      const double closePx = (shift >= 0) ? iClose(symbol, InpFeatureTF, shift) : 0.0;

      if(okRSI && okADX && okATR && okFast && okSlow && closePx > 0.0 && point > 0.0)
         complete++;

      const double atrPts  = (okATR && point > 0.0)  ? atr / point : 0.0;
      const double slPts   = (g_sl[i] > 0.0 && point > 0.0) ? MathAbs(g_price[i] - g_sl[i]) / point : 0.0;
      const double tpPts   = (g_tp[i] > 0.0 && point > 0.0) ? MathAbs(g_tp[i] - g_price[i]) / point : 0.0;
      const double rr      = (slPts > 0.0) ? tpPts / slPts : 0.0;
      const double vsSlow  = (okSlow && closePx > 0.0 && point > 0.0) ? (closePx - slow) / point : 0.0;
      const double fastSlow= (okFast && okSlow && point > 0.0)        ? (fast - slow) / point   : 0.0;

      MqlDateTime dt;
      TimeToStruct(when, dt);

      FileWriteString(fh, StringFormat(
         "%s,%s,%d,%.5f,%.2f,%.5f,%.5f,%.1f,%.1f,%.2f,%.5f,%.5f,%.5f,%.1f,%.2f,%.2f,%.1f,%.1f,%d,%d,%.2f,%d\r\n",
         TimeToString(when, TIME_DATE|TIME_MINUTES),
         symbol,
         g_dir[i],
         g_price[i],
         g_volume[i],
         g_sl[i],
         g_tp[i],
         slPts,
         tpPts,
         rr,
         closePx,
         fast,
         slow,
         atrPts,
         rsi,
         adx,
         vsSlow,
         fastSlow,
         dt.hour,
         dt.day_of_week,
         g_profit[i],
         g_win[i] ? 1 : 0));
     }

   FileClose(fh);

   //------------------------------------------------------------------
   // RELATORIO DE VIABILIDADE
   //------------------------------------------------------------------
   const double winRate = (n > 0) ? (100.0 * wins / n) : 0.0;

   Print("==================================================");
   Print("   XAU_AI_PRO | CONTEXTO DAS OPERACOES MANUAIS");
   Print("==================================================");
   PrintFormat("Periodo.........: %s .. %s",
               TimeToString(from, TIME_DATE), TimeToString(to, TIME_DATE));
   PrintFormat("Entradas manuais: %d", n);
   PrintFormat("Com contexto ok.: %d de %d", complete, n);
   PrintFormat("Compra / Venda..: %d / %d", buys, sells);
   PrintFormat("Acerto..........: %.1f%%", winRate);
   PrintFormat("Com stop loss...: %d de %d", withSL, n);
   PrintFormat("Resultado total.: %.2f", sumProfit);
   PrintFormat("Simbolos........: %s", symbolsSeen);
   PrintFormat("Arquivo.........: MQL5\\Files\\%s", InpOutputFile);
   Print("--------------------------------------------------");

   //------------------------------------------------------------------
   // AVISOS - o que impede (ou não) aprender deste histórico
   //------------------------------------------------------------------
   if(n < InpMinSampleForLearning)
     {
      PrintFormat("[AVISO] Amostra insuficiente: %d entradas < %d. "
                  "Com menos que isso o modelo decora o passado, nao aprende a regra.",
                  n, InpMinSampleForLearning);
     }

   if(n >= 10 && (buys == 0 || sells == 0))
     {
      Print("[AVISO] Vies direcional total: todas as entradas manuais foram para o MESMO lado.");
      Print("[AVISO] Operar isso automaticamente = apostar na continuacao do ciclo atual.");
     }
   else
     if(n >= 10 && (100.0 * MathMax(buys, sells) / n) >= 90.0)
        Print("[AVISO] Vies direcional >= 90% para um lado: o modelo vai herdar esse vies.");

   if(withSL < n)
     {
      PrintFormat("[AVISO] %d de %d entradas manuais SEM stop loss no deal de entrada.",
                  n - withSL, n);
      Print("[AVISO] Reproduzir risco sem stop em EA e proibido por politica de seguranca.");
     }

   if(complete < n)
      PrintFormat("[AVISO] %d linha(s) sem contexto completo (historico curto no TF %s).",
                  n - complete, EnumToString(InpFeatureTF));

   Print("==================================================");
  }

//+------------------------------------------------------------------+
void OnStart()
  {
   const datetime to   = TimeCurrent();
   const datetime from = to - (datetime)(InpLookbackDays * 86400);

   PrintFormat("LEARNER | janela=%d dias | TF=%s | magic EA ignorado=%I64d",
               InpLookbackDays, EnumToString(InpFeatureTF), InpEAMagic);

   if(!CollectManualEntries(from, to))
      return;

   WriteDatasetAndReport(from, to);

   //------------------------------------------------------------------
   // Libera handles: um EA/script nao pode deixar indicador preso.
   //------------------------------------------------------------------
   for(int i = 0; i < ArraySize(g_ctxSymbol); i++)
     {
      if(g_ctxRSI[i]  != INVALID_HANDLE) IndicatorRelease(g_ctxRSI[i]);
      if(g_ctxADX[i]  != INVALID_HANDLE) IndicatorRelease(g_ctxADX[i]);
      if(g_ctxATR[i]  != INVALID_HANDLE) IndicatorRelease(g_ctxATR[i]);
      if(g_ctxFast[i] != INVALID_HANDLE) IndicatorRelease(g_ctxFast[i]);
      if(g_ctxSlow[i] != INVALID_HANDLE) IndicatorRelease(g_ctxSlow[i]);
     }
  }
//+------------------------------------------------------------------+
