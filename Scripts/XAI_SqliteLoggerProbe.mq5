//+------------------------------------------------------------------+
//| XAI_SqliteLoggerProbe.mq5                                        |
//| Prova de vida do TradeLoggerSQLite: abre, grava, conta, le de     |
//| volta e fecha. Nao toca em ordens, posicoes nem risco.           |
//+------------------------------------------------------------------+
#include "..\\Experts\\XAU_AI_PRO\\Monitoring\\TradeLoggerSQLite.mqh"

void OnStart()
{
   Print("[PROBE] inicio");

   if(!TradeLoggerSQLiteInit())
   {
      Print("[PROBE] FALHOU Init | erro=", GetLastError());
      return;
   }
   Print("[PROBE] banco=", g_trade_logger_sqlite.DatabasePath());

   int antes = g_trade_logger_sqlite.GetTotalTrades();
   Print("[PROBE] trades_antes=", antes);

   STradeRecord r;
   r.ticket     = 5000000001;            // > 2^31: prova que o ticket nao trunca
   r.magic      = 2026001;
   r.origin     = "PROBE";
   r.time       = TimeCurrent();
   r.symbol     = "XAUUSD";
   r.type       = (long)POSITION_TYPE_BUY;
   r.volume     = 0.10;
   r.price_open = 2345.67;
   r.sl         = 2340.00;
   r.tp         = 2360.00;
   r.price_close= 2350.12;
   r.profit     = 4.45;
   r.details    = "probe \"aspas\" \\barra\\ \nlinha";   // testa o escape/JSON hostil

   bool ok = TradeLoggerSQLiteLog(r);
   Print("[PROBE] Log=", ok, " erro=", GetLastError());

   int depois = g_trade_logger_sqlite.GetTotalTrades();
   Print("[PROBE] trades_depois=", depois);

   STradeRecord back;
   bool got = g_trade_logger_sqlite.GetTradeByTicket(r.ticket, back);
   Print("[PROBE] GetByTicket=", got,
         " ticket=", back.ticket,
         " magic=", back.magic,
         " symbol=[", back.symbol, "]",
         " type=", back.type,
         " vol=", DoubleToString(back.volume, 2),
         " sl=", DoubleToString(back.sl, 2),
         " tp=", DoubleToString(back.tp, 2),
         " profit=", DoubleToString(back.profit, 2),
         " details=[", back.details, "]");

   Print("[PROBE] total_profit=", DoubleToString(g_trade_logger_sqlite.GetTotalProfit(), 2));

   // ticket inexistente tem de devolver false, nao lixo
   STradeRecord none;
   Print("[PROBE] inexistente=", g_trade_logger_sqlite.GetTradeByTicket(1, none));

   TradeLoggerSQLiteShutdown();
   Print("[PROBE] fim | ligado=", g_trade_logger_sqlite.IsConnected());
}
//+------------------------------------------------------------------+
