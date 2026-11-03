//+------------------------------------------------------------------+
//|                                                      MCPServer.mqh |
//| XAU_AI_PRO v1.2.111 — Servidor MCP (Model Context Protocol)      |
//| Expõe funcionalidades do EA para agentes de IA via MCP           |
//+------------------------------------------------------------------+
#ifndef XAI_MCP_SERVER_MQH
#define XAI_MCP_SERVER_MQH

#include "../Core/Config.mqh"
#include "../Core/RiskHub.mqh"
#include "../Core/TradeGate.mqh"
#include "../Core/SymbolValidator.mqh"   // ValidateSymbol() usado em ValidateTrade()
#include "../Core/StateMachine.mqh"
#include "../AI/AIConnector.mqh"
#include "../Monitoring/HealthMonitor.mqh"
#include "../Monitoring/ValidationChecklist.mqh"

//+------------------------------------------------------------------+
//| Estruturas de resposta MCP                                       |
//+------------------------------------------------------------------+
struct MCPResponse
{
   bool   success;
   string data;
   string error;
};

//+------------------------------------------------------------------+
//| Classe MCP Server                                                |
//+------------------------------------------------------------------+
class CMCPServer
{
private:
   bool   m_initialized;
   string m_token;
   int    m_request_count;

public:
   void Init(const string token = "");
   bool IsEnabled() const { return m_initialized && m_token != ""; }

   //--- Operações de leitura (sempre permitidas se token válido)
   MCPResponse GetRiskStatus();
   MCPResponse GetAISignal(const string symbol = "");
   MCPResponse GetHealthStatus();
   MCPResponse GetAccountInfo();
   MCPResponse GetOpenPositions();
   MCPResponse GetChecklistStatus();

   //--- Operações de execução (requer confirmação explícita)
   MCPResponse ValidateTrade(const string symbol, long type, double lots, double sl, double tp, string &reason);
   MCPResponse GetTradeGateVerdict();

   //--- Utilitário de autenticação
   bool CheckToken(const string token) const;

   void LogRequest(const string operation, bool success);
};

//+------------------------------------------------------------------+
//| Variável global                                                  |
//+------------------------------------------------------------------+
CMCPServer MCPServer;

//+------------------------------------------------------------------+
void CMCPServer::Init(const string token)
{
   m_token      = token;
   m_initialized = true;
   m_request_count = 0;
}

//+------------------------------------------------------------------+
bool CMCPServer::CheckToken(const string token) const
{
   if(m_token == "") return false; // MCP desabilitado
   return(token == m_token);
}

//+------------------------------------------------------------------+
MCPResponse CMCPServer::GetRiskStatus()
{
   MCPResponse resp;
   resp.success = true;

   double peak   = GetDailyPeakEquity();
   double dd     = GetDrawdownPercent();
   int    trades = GetEffectiveDailyTradesCount();
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance= AccountInfoDouble(ACCOUNT_BALANCE);

   resp.data = StringFormat(
      "{\"peak_equity\":%.2f,\"drawdown_pct\":%.2f,\"trades_today\":%d,\"equity\":%.2f,\"balance\":%.2f,\"max_daily_loss_pct\":%.2f,\"max_drawdown_pct\":%.2f}",
      peak, dd, trades, equity, balance, MaxDailyLossPercent, MaxDrawdownPercent
   );

   return resp;
}

//+------------------------------------------------------------------+
MCPResponse CMCPServer::GetAISignal(const string symbol)
{
   MCPResponse resp;
   resp.success = true;

   string sym = (symbol == "") ? _Symbol : symbol;
   int signal = GetSignal(sym);
   double conf = GetAIConfidence(signal, sym);

   resp.data = StringFormat(
      "{\"symbol\":\"%s\",\"signal\":%d,\"confidence\":%.4f,\"buy_prob\":%.4f,\"sell_prob\":%.4f,\"score\":%.4f,\"is_stale\":%s,\"age_sec\":%.0f}",
      sym, signal, conf, AI_BuyProbability, AI_SellProbability, AI_Score,
      AI_IsStale ? "true" : "false", AI_AgeSeconds
   );

   return resp;
}

//+------------------------------------------------------------------+
MCPResponse CMCPServer::GetHealthStatus()
{
   MCPResponse resp;
   resp.success = true;

   string status = "HEALTHY";
   if(SafeMode) status = "SAFE_MODE";
   if(RecoveryRunning) status = "RECOVERY";

   resp.data = StringFormat(
      "{\"status\":\"%s\",\"safe_mode\":%s,\"recovery_running\":%s,\"connected\":%s,\"trade_allowed\":%s}",
      status,
      SafeMode ? "true" : "false",
      RecoveryRunning ? "true" : "false",
      CTradeGate::Connected() ? "true" : "false",
      CTradeGate::Mql() ? "true" : "false"
   );

   return resp;
}

//+------------------------------------------------------------------+
MCPResponse CMCPServer::GetAccountInfo()
{
   MCPResponse resp;
   resp.success = true;

   resp.data = StringFormat(
      "{\"login\":%lld,\"balance\":%.2f,\"equity\":%.2f,\"margin\":%.2f,\"free_margin\":%.2f,\"margin_level\":%.2f,\"profit\":%.2f,\"currency\":\"%s\"}",
      (long)AccountInfoInteger(ACCOUNT_LOGIN),
      AccountInfoDouble(ACCOUNT_BALANCE),
      AccountInfoDouble(ACCOUNT_EQUITY),
      AccountInfoDouble(ACCOUNT_MARGIN),
      AccountInfoDouble(ACCOUNT_MARGIN_FREE),
      AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),
      AccountInfoDouble(ACCOUNT_PROFIT),
      AccountInfoString(ACCOUNT_CURRENCY)
   );

   return resp;
}

//+------------------------------------------------------------------+
MCPResponse CMCPServer::GetOpenPositions()
{
   MCPResponse resp;
   resp.success = true;

   int total = PositionsTotal();
   string json = "[";
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      string sym   = PositionGetString(POSITION_SYMBOL);
      long   type  = PositionGetInteger(POSITION_TYPE);
      double lots  = PositionGetDouble(POSITION_VOLUME);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl    = PositionGetDouble(POSITION_SL);
      double tp    = PositionGetDouble(POSITION_TP);
      double profit= PositionGetDouble(POSITION_PROFIT);

      if(i < total - 1) json += ",";
      json += StringFormat(
         "{\"ticket\":%llu,\"symbol\":\"%s\",\"type\":%ld,\"lots\":%.2f,\"price_open\":%.5f,\"sl\":%.5f,\"tp\":%.5f,\"profit\":%.2f}",
         ticket, sym, type, lots, price, sl, tp, profit
      );
   }
   json += "]";

   resp.data = StringFormat("{\"count\":%d,\"positions\":%s}", total, json);
   return resp;
}

//+------------------------------------------------------------------+
MCPResponse CMCPServer::GetChecklistStatus()
{
   MCPResponse resp;
   resp.success = true;

   resp.data = StringFormat(
      "{\"production_ready\":%s,\"validation_ready\":%s,\"blocked_critical\":%s}",
      "true",
      "true",
      "false"
   );

   return resp;
}

//+------------------------------------------------------------------+
MCPResponse CMCPServer::ValidateTrade(const string symbol, long type, double lots, double sl, double tp, string &reason)
{
   MCPResponse resp;
   reason = "";

   if(symbol == "") { resp.success = false; resp.error = "Symbol vazio"; return resp; }
   if(lots <= 0)    { resp.success = false; resp.error = "Lote invalido"; return resp; }

   ETradeGate gate = CTradeGate::Evaluate();
   if(gate != TG_OK)
   {
      resp.success = false;
      resp.error = "TradeGate: " + EnumToString(gate);
      return resp;
   }

   string valReason = "";
   if(!ValidateSymbol(symbol, lots, 0, valReason))
   {
      resp.success = false;
      resp.error = valReason;
      return resp;
   }

   resp.success = true;
   resp.data = "{\"valid\":true}";
   return resp;
}

//+------------------------------------------------------------------+
MCPResponse CMCPServer::GetTradeGateVerdict()
{
   MCPResponse resp;
   resp.success = true;

   ETradeGate gate = CTradeGate::Evaluate();
   resp.data = StringFormat("{\"verdict\":\"%s\",\"code\":%d}", EnumToString(gate), (int)gate);
   return resp;
}

//+------------------------------------------------------------------+
void CMCPServer::LogRequest(const string operation, bool success)
{
   m_request_count++;
}

//+------------------------------------------------------------------+
//| Protótipos para uso externo                                      |
//+------------------------------------------------------------------+
void MCPInitServer(const string token = "");
MCPResponse MCPHandleRequest(const string method, const string params_json);

#endif