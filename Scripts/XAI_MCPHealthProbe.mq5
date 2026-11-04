//+------------------------------------------------------------------+
//| XAI_MCPHealthProbe.mq5 — prova de vida do Core/MCPServer.mqh      |
//| Compila SÓ com o modulo (nao com o EA) e exercita a API em runtime.|
//| Nao envia ordens, nao altera risco: apenas leitura.               |
//+------------------------------------------------------------------+
#include "..\\Experts\\XAU_AI_PRO\\Core\\MCPServer.mqh"

void OnStart()
{
   Print("[MCPPROBE] inicio | token de teste com 8 caracteres");
   MCPInitServer("PROBE123");
   Print("[MCPPROBE] enabled=", MCPServer.IsEnabled());

   // 1) SelfTest corre os 7 metodos de leitura.
   Print("[MCPPROBE] selftest=", MCPServer.SelfTest());

   // 2) health.status pelo ponto de entrada autenticado.
   MCPResponse h = MCPHandleRequest("health.status", "", "PROBE123");
   Print("[MCPPROBE] health ok=", h.success, " data=", h.data);

   // 3) gate.verdict
   MCPResponse g = MCPHandleRequest("gate.verdict", "", "PROBE123");
   Print("[MCPPROBE] gate ok=", g.success, " data=", g.data);

   // 4) Token ERRADO tem de ser recusado (era o defeito P2.09).
   MCPResponse bad = MCPHandleRequest("account.info", "", "ERRADO12");
   Print("[MCPPROBE] token_errado ok=", bad.success, " erro=", bad.error);

   // 5) trade.validate SEM 'type' tem de ser recusado (StringToInteger("")=0=BUY).
   MCPResponse v1 = MCPHandleRequest("trade.validate", "symbol=XAUUSD;lots=0.01", "PROBE123");
   Print("[MCPPROBE] validate_sem_type ok=", v1.success, " erro=", v1.error);

   // 6) trade.validate com SL do lado errado numa compra tem de ser recusado.
   string sym = _Symbol;
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double slRuim = (ask > 0.0 ? ask + 100.0 * SymbolInfoDouble(sym, SYMBOL_POINT) : 0.0);
   MCPResponse v2 = MCPHandleRequest("trade.validate",
                                     "symbol=" + sym + ";type=0;lots=0.01;sl=" + DoubleToString(slRuim, _Digits),
                                     "PROBE123");
   Print("[MCPPROBE] validate_sl_errado ok=", v2.success, " erro=", v2.error);

   // 7) metodo desconhecido
   MCPResponse u = MCPHandleRequest("nao.existe", "", "PROBE123");
   Print("[MCPPROBE] desconhecido ok=", u.success, " erro=", u.error);

   Print("[MCPPROBE] contadores pedidos=", MCPServer.RequestCount(),
         " recusados=", MCPServer.RejectedCount());
   Print("[MCPPROBE] fim");
}
//+------------------------------------------------------------------+
