//+------------------------------------------------------------------+
//| PermState.mqh                                                    |
//| XAU_AI_PRO - P1.3590 (v1.2.194)                                  |
//| O bit POR GRAFICO (MQL_TRADE_ALLOWED) deixa de ser legivel so'   |
//| quando o EA reinicia: passa a haver um ficheiro de estado por    |
//| simbolo, escrito pela INSTANCIA que pode responde-lo.            |
//+------------------------------------------------------------------+
#ifndef XAI_PERM_STATE_MQH
#define XAI_PERM_STATE_MQH

// P1.3590 (v1.2.194) - MEDIDO em 10/11/2026, no mesmo grafico, com dois
// programas e dois minutos de diferenca:
//   12:53:20.473  XAU_AI_PRO (USDCZK,H1)  [DIAGSCAN] portao do grafico=FECHADO | codigo=3
//   12:56:25.652  XAI_PermProbe (USDCZK,H1) [PERMPROBE] MQL_TRADE_ALLOWED=1 ... | codigo=0
//   12:58:20.222  XAU_AI_PRO (USDBRL,M5)  [DIAGSCAN] portao do grafico=FECHADO | codigo=3
//   12:56:25.651  XAI_PermProbe (USDBRL,M5) [PERMPROBE] MQL_TRADE_ALLOWED=1 ... | codigo=0
// O script e o EA leem o MESMO simbolo com respostas OPOSTAS. Nao houve
// reinicio entre as leituras e o script nao altera nada, portanto a diferenca
// nao e' de tempo so': e' de QUEM le ou de QUANDO le. HIPOTESE (nao isolada): num script
// devolve a permissao do TERMINAL (que estava ligada: system_status.json com
// algo_trading_enabled=true); num EA devolve a permissao daquele grafico, que
// era 0. Logo:
//   (a) SE a hipotese for verdadeira, uma sonda de script NAO ve o bit do grafico
//       grafico - e por isso uma varredura feita com ela certificaria "15/15
//       LIGADO" com a frota toda fechada;
//   (b) o unico programa que responde a pergunta certa e' o proprio EA naquele
//       grafico - e ate' aqui so' o fazia no [PERM] do OnInit (1 linha por
//       reinicio) e no [DIAGSCAN] (uma instancia de cada vez, cada 5 min).
// Este ficheiro fecha a lacuna (b): cada instancia reescreve uma linha com o
// seu estado, no arranque e sempre que o codigo muda, com idade legivel. Nao
// decide nada, nao altera nada e falha em silencio (fail-open): se nao puder
// escrever, a negociacao continua exactamente como estava.

#define XAI_PERMSTATE_PASTA "Data"
#define XAI_PERMSTATE_REFRESH_SEC 60

// Estado da instancia (RAM, por grafico). Reinicia com o EA - e o arranque
// escreve sempre, portanto nao ha leitura herdada de sessao anterior.
datetime XAI_PermState_Ultimo  = 0;
int      XAI_PermState_Codigo  = -1;

class CPermState
  {
public:
   static string Caminho(const string symbol);
   static void   Publish(const string symbol, const int codigo, const string etapa, const bool forcar);
   static int    UltimoCodigo(void) { return(XAI_PermState_Codigo); }
  };

//| permission_state_<SIMBOLO>.csv - um ficheiro por grafico, reescrito.
string CPermState::Caminho(const string symbol)
  {
   return(XAI_PERMSTATE_PASTA + "\\permission_state_" + symbol + ".csv");
  }

//| Publish: uma linha por instancia com os cinco bits, o codigo do portao
//| e a etapa ("init" no arranque, "tick" em rotina).
void CPermState::Publish(const string symbol, const int codigo, const string etapa, const bool forcar)
  {
   datetime agora = TimeLocal();

   // Em rotina so' escreve quando o veredicto MUDA, ou a cada
   // XAI_PERMSTATE_REFRESH_SEC para a idade do ficheiro nao mentir.
   if(!forcar && codigo == XAI_PermState_Codigo &&
      (agora - XAI_PermState_Ultimo) < XAI_PERMSTATE_REFRESH_SEC)
      return;

   int h = FileOpen(Caminho(symbol),
                    FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_SHARE_READ | FILE_SHARE_WRITE);
   if(h == INVALID_HANDLE)
      return;                       // fail-open: telemetria nunca trava nada

   FileWriteString(h, "server_time;local_time;symbol;login;mql;terminal;account;expert;connected;code;stage\r\n");
   FileWriteString(h, StringFormat("%s;%s;%s;%s;%d;%d;%d;%d;%d;%d;%s\r\n",
                                   TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
                                   TimeToString(TimeLocal(),   TIME_DATE | TIME_SECONDS),
                                   symbol,
                                   IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)),
                                   (int)CTradeGate::Mql(),
                                   (int)CTradeGate::Terminal(),
                                   (int)CTradeGate::Account(),
                                   (int)CTradeGate::Expert(),
                                   (int)CTradeGate::Connected(),
                                   codigo,
                                   etapa));
   FileFlush(h);
   FileClose(h);

   XAI_PermState_Ultimo = agora;
   XAI_PermState_Codigo = codigo;
  }

#endif // XAI_PERM_STATE_MQH
//+------------------------------------------------------------------+
