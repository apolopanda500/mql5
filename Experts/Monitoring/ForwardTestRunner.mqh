//+------------------------------------------------------------------+
//|                                         ForwardTestRunner.mqh   |
//|                                 XAU_AI_PRO - Forward Test E13   |
//|             Coletor de dados de sesion para reconciliacion       |
//+------------------------------------------------------------------+
// ETAPA 13 (1/13) - FORWARD TEST PROFISSIONAL
//
// Coletor centralizado de observabilidade para a fase A (Demo),
// B (Stress) e C (Reconciliacion) do forward test:
//
//   FILE: Data\forward_test_session.csv  (FILE_COMMON)
//
// Columnas (heartbeat, 1x por segundo):
//   timestamp,balance,equity,drawdown_pct,free_margin,spread_points,
//   latency_ms,connection,symbol_valid,failure_mode,news_state,
//   ai_ready,ai_confidence,market_score,positions_open,ea_version
//
// Columnas (trade):
//   timestamp,symbol,event,signal,score,ai_confidence,side,volume,price,
//   sl,tp,ticket,profit,exec_result,retcode,block_reason
//
// PRINCIPIO: nunca bloqueia o interrompe a execucao; apenas registra.
// O CSV e reescrito por sessao ( OnInit ). O reconcilador (Fase C)
// compara este CSV contra AuditLog x TradeLogger x historico broker.
//+------------------------------------------------------------------+

#ifndef FORWARD_TEST_RUNNER_MQH
#define FORWARD_TEST_RUNNER_MQH

#include "../Core/Config.mqh"

input bool EnableForwardLog      = true;   // ETAPA 13: coletor de sesion live
input string ForwardLogSeparator = ",";    // separator CSV (por region)
input int    ForwardHeartbeatSec = 1;      // intervalo minimo do heartbeat (seg)

string const FORWARD_FILE        = "Data\\forward_test_session.csv";
string const FORWARD_FILE_TRADE  = "Data\\forward_test_trades.csv";

// Handle + estado do heartbeat
int       g_fwdHFile  = INVALID_HANDLE;
datetime  g_fwdLastHb = 0;

//==================================================
// HEADER CSV
//==================================================
bool ForwardFileInit()
{
   if(!EnableForwardLog)
      return true;

   ResetLastError();

   g_fwdHFile = FileOpen(
      FORWARD_FILE,
      FILE_COMMON | FILE_WRITE | FILE_CSV | FILE_ANSI |
      FILE_SHARE_READ | FILE_SHARE_WRITE
   );

   if(g_fwdHFile == INVALID_HANDLE)
   {
      Print("[FORWARD] falha ao abrir log: ", GetLastError());
      return false;
   }

   FileSeek(g_fwdHFile, 0, SEEK_END);

   if(FileSize(g_fwdHFile) == 0)
   {
            FileWrite(g_fwdHFile,
         "timestamp","balance","equity","drawdown_pct","free_margin",
         "spread_points","latency_ms","connection_state",
         "failure_mode","news_state","ai_ready","ai_confidence",
         "market_score","positions_open","ea_version");
      FileFlush(g_fwdHFile);
   }

   // Header do CSV de trades (se nao existir)
   int hTr = FileOpen(FORWARD_FILE_TRADE,
      FILE_COMMON | FILE_WRITE | FILE_CSV | FILE_ANSI |
      FILE_SHARE_READ | FILE_SHARE_WRITE);
   if(hTr != INVALID_HANDLE)
   {
      FileSeek(hTr, 0, SEEK_END);
      if(FileSize(hTr) == 0)
      {
         FileWrite(hTr,
            "timestamp","symbol","event","signal","score","ai_confidence",
            "side","volume","price","sl","tp","ticket","profit",
            "exec_result","retcode","block_reason");
         FileFlush(hTr);
      }
      FileClose(hTr);
   }
   else
   {
      Print("[FORWARD] falha ao abrir trades log: ", GetLastError());
   }

   return true;
}

//==================================================
// CERRAR
//==================================================
void ForwardLogClose()
{
   if(g_fwdHFile != INVALID_HANDLE)
   {
      FileFlush(g_fwdHFile);
      FileClose(g_fwdHFile);
      g_fwdHFile = INVALID_HANDLE;
   }
}

//==================================================
// DRAWOWN % (equidad respecto al peak)
//==================================================
double ForwardGetDrawdownPercent()
{
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   double peak = balance;
   // Usa RiskHub si existir; fallback al balance del dia.
   // Simple: drawdown = max(0, (peak - equity)/peak)
   double dd = 0.0;
   if(peak > 0.0)
      dd = MathMax(0.0, (peak - equity) / peak) * 100.0;
   return dd;
}

//==================================================
// HEARTBEAT (1x por segundo)
// Registra: balance, equity, dd, free margin, spread,
// latencia, estado conexion, failure mode, news, IA.
//==================================================
void ForwardHeartbeat()
{
   if(g_fwdHFile == INVALID_HANDLE)
      return;

   datetime now = TimeCurrent();
   if(g_fwdLastHb > 0 && (now - g_fwdLastHb) < ForwardHeartbeatSec)
      return;
   g_fwdLastHb = now;

   // Spread simbolo en puntos
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double spread = (point > 0.0) ? (ask - bid) / point : 0.0;

   // Latencia: diferencia entre TimeCurrent y TimeLocal del tick
   // (aproximacion: tick recibido vs reloj local)
   int latency = (int)(TimeLocal() - TimeCurrent());

   string connState = ConnectionGuardSummary();      // ETAPA 12
   string fmState   = GetFailureStateString();       // ETAPA 12

   string newsState = "CLEAR";
   if(EnableNewsFilter)
      newsState = EnumToString(GetNewsState());

   bool aiReady = AIClientConnected();

   double aiConf = 0.0;
   // Confidence global expuesta por AIEngine (si existe)
   // Fallback 0.0 quando nao disponivel.

   string version = "1.2.0";

      FileWrite(g_fwdHFile,
      TimeToString(now, TIME_DATE | TIME_SECONDS),
      DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
      DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2),
      DoubleToString(ForwardGetDrawdownPercent(), 2),
      DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2),
      DoubleToString(spread, 2),
      latency,
      connState,
      newsState,
      (aiReady ? "ON" : "OFF"),
      DoubleToString(aiConf, 2),
      DoubleToString(MarketScore, 2),
      (string)PositionsTotal(),
      version);

   FileFlush(g_fwdHFile);
}

//==================================================
// LOG TRADE - sesion de decisao / entrada / bloqueo
//==================================================
void ForwardLogTrade(const string symbol,
                     const string evt,          // "SIGNAL"|"BLOCK"|"OPEN"
                     const int signal,
                     const double score,
                     const string aiConf,
                     const string side,
                     const double volume,
                     const double price,
                     const double sl,
                     const double tp,
                     const string execResult,
                     const string blockReason)
{
   if(!EnableForwardLog)
      return;

   int h = FileOpen(FORWARD_FILE_TRADE,
      FILE_COMMON | FILE_WRITE | FILE_CSV | FILE_ANSI |
      FILE_SHARE_READ | FILE_SHARE_WRITE);
   if(h == INVALID_HANDLE)
      return;

   FileSeek(h, 0, SEEK_END);
   FileWrite(h,
      TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
      symbol,
      evt,
      (string)signal,
      DoubleToString(score, 2),
      aiConf,
      side,
      DoubleToString(volume, 2),
      DoubleToString(price, _Digits),
      DoubleToString(sl, _Digits),
      DoubleToString(tp, _Digits),
      (string)0,
      (string)0.0,
      execResult,
      (string)0,
      blockReason);
   FileFlush(h);
   FileClose(h);
}

//==================================================
// LOG DEAL - cierre/resultado de una operacion
//==================================================
void ForwardLogDeal(const string symbol,
                    const ulong ticket,
                    const int signal,
                    const double score,
                    const string aiConf,
                    const string side,
                    const double volume,
                    const double price,
                    const double profit,
                    const string execResult,
                    const int retcode)
{
   if(!EnableForwardLog)
      return;

   int h = FileOpen(FORWARD_FILE_TRADE,
      FILE_COMMON | FILE_WRITE | FILE_CSV | FILE_ANSI |
      FILE_SHARE_READ | FILE_SHARE_WRITE);
   if(h == INVALID_HANDLE)
      return;

   FileSeek(h, 0, SEEK_END);
   FileWrite(h,
      TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
      symbol,
      "CLOSE",
      (string)signal,
      DoubleToString(score, 2),
      aiConf,
      side,
      DoubleToString(volume, 2),
      DoubleToString(price, _Digits),
      (string)0.0,
      (string)0.0,
      (string)ticket,
      DoubleToString(profit, 2),
      execResult,
      (string)retcode,
      "");
   FileFlush(h);
   FileClose(h);
}

//==================================================
// FLUSH
//==================================================
void ForwardFlush()
{
   if(g_fwdHFile != INVALID_HANDLE)
      FileFlush(g_fwdHFile);
}

//==================================================
// SUMMARY
//==================================================
string ForwardSummary()
{
   return StringFormat("ForwardTest | Log=%s | HB=%s | HFile=%s",
      (EnableForwardLog ? "ON" : "OFF"),
      (g_fwdLastHb > 0 ? TimeToString(g_fwdLastHb, TIME_MINUTES) : "None"),
      (g_fwdHFile != INVALID_HANDLE ? "open" : "closed"));
}

#endif // FORWARD_TEST_RUNNER_MQH

