//+------------------------------------------------------------------+
//|                                              EventEmitter.mqh    |
//|                                  Event Stream - ETAPA 15.6       |
//|                                            XAU_AI_PRO v1.2.9     |
//+------------------------------------------------------------------+
// ETAPA 15.6.1 / 15.6.2 - EVENT EMITTER (canal oficial de eventos)
//
// Funcao: camada UNICA e centralizada de eventos da plataforma.
// Todos os modulos emitem eventos AQUI (nunca escrevem o CSV direto).
//
//   EA --> EventEmitter --> forward_test_events.csv --> Python/App
//
// Formato (15.6.2 - 10 colunas):
//   Time,Event,Symbol,TF,Ticket,Severity,Module,Message,Value,Status
//
// Arquivo: Data\forward_test_events.csv (UTF-16 LE, append-only, 1 linha,
// com FILE_SHARE para leitura simultanea pelo App/Python).
//
// F4 v1.2.2 - SERIALIZACAO DE ESCRITA:
//   * Lock global via EventLock.mqh (CAS atomico + TTL), compartilhado
//     com o AuditLog: 1 produtor ativo por vez no arquivo.
//   * Criacao de header sob lock (arranque concorrente das 11 instancias
//     NAO gera header duplicado).
//   * Escrita com ABRIR->SEEK(END)->WRITE->FLUSH->FECHAR dentro do lock.
//     (NAO manter handle persistente aberto entre eventos: com 11
//     instancias abrindo o mesmo arquivo, o FileSeek(SEEK_END) de um
//     handle antigo nao enxerga o tamanho atualizado pelos outros
//     handles -> overlay/interleave. Handle novo a cada escrita resolve.)
//   * Custodia de drops/timeouts com contadores observaveis (summary).
//
// PRINCIPIO: nunca bloqueia/interrompe a execucao; apenas registra.

#ifndef EVENT_EMITTER_MQH
#define EVENT_EMITTER_MQH

#include "EventLock.mqh"

//==================================================
// NOMES PADRAO DE EVENTOS (15.6.1)
//==================================================
#define EV_SYSTEM_START      "SYSTEM_START"
#define EV_SYSTEM_STOP       "SYSTEM_STOP"
#define EV_FWD_START         "FORWARD_TEST_START"
#define EV_HEALTH_UPDATE     "HEALTH_UPDATE"
#define EV_AI_PREDICTION     "AI_PREDICTION"
#define EV_AI_ERROR          "AI_ERROR"
#define EV_AI_BLOCK          "AI_BLOCK"
#define EV_SIGNAL_GENERATED  "SIGNAL_GENERATED"
#define EV_TRADE_APPROVED    "TRADE_APPROVED"
#define EV_TRADE_REJECTED    "TRADE_REJECTED"
#define EV_TRADE_OPEN        "TRADE_OPEN"
#define EV_TRADE_CLOSE       "TRADE_CLOSE"
#define EV_RISK_BLOCK        "RISK_BLOCK"
#define EV_NEWS_BLOCK        "NEWS_BLOCK"
#define EV_CIRCUIT_BREAKER   "CIRCUIT_BREAKER"
#define EV_SAFE_MODE         "SAFE_MODE"
#define EV_RECOVERY          "RECOVERY"
#define EV_BROKER_ERROR      "BROKER_ERROR"
#define EV_PYTHON_ERROR      "PYTHON_ERROR"
#define EV_DATABASE_ERROR    "DATABASE_ERROR"
#define EV_SYSTEM_ERROR      "SYSTEM_ERROR"
#define EV_HEALTH_WARNING    "HEALTH_WARNING"
#define EV_HEALTH_FAILURE    "HEALTH_FAILURE"

//==================================================
// SEVERIDADE
//==================================================
#define EV_SEV_INFO    "INFO"
#define EV_SEV_WARN    "WARN"
#define EV_SEV_ERROR   "ERROR"
#define EV_SEV_CRIT    "CRITICAL"

static string EV_FILE = "Data\\forward_test_events.csv";
static bool   evInitialized = false;

// Versao local (nao depende de VersionManager)
// v1.2.231 (24/11/2026) - P1.3662: alinhado com EA_VERSION_STRING.
// MEDIDO: o journal dizia "XAU_AI_PRO (ETHUSD,M5) ... v1.2.230" enquanto o
// CSV do forward escrevia "EA inicializado 1.2.229" na linha SYSTEM_START,
// porque este literal e local e ficou para tras no bump anterior. A linha
// SYSTEM_START e a que rotula o build no ficheiro que o Python agrega: com
// ela atrasada, a agregacao do dia atribui os eventos ao build antigo.
#define EV_VERSION_STRING "1.2.239"

// F4: estatisticas locais de escrita desta instancia
int g_ev_written = 0;      // total de eventos gravados (esta instancia)
int g_ev_dropped = 0;      // total de eventos nao gravados (lock/timeout)

//==================================================
// ABRE O CSV (handle novo a cada chamada)
//==================================================
int EventOpenWrite()
{
   ResetLastError();
   int h = FileOpen(
      EV_FILE,
      FILE_WRITE | FILE_READ | FILE_CSV | FILE_UNICODE |
      FILE_SHARE_READ | FILE_SHARE_WRITE,
      ','
   );
   return h;
}

//==================================================
// INIT - garante header (ABRIR->LOCK->HEADER->FECHAR)
//==================================================
bool EventInit()
{
   if(evInitialized)
      return true;

   int h = EventOpenWrite();
   if(h == INVALID_HANDLE)
     {
      Print("[EVENT] falha ao abrir: ", EV_FILE, " | Err=", GetLastError());
      return false;
     }

   //--------------------------------------------------
   // F4: criacao de header SERIALIZADA
   // (arranque simultaneo das 11 instancias: so 1 grava)
   //--------------------------------------------------
   if(FileSize(h) == 0)
     {
      bool headerWritten = false;
      if(EventLockAcquire())
        {
         FileSeek(h, 0, SEEK_END);   // reconfirma apos lock
         if(FileSize(h) == 0)
           {
            FileWrite(h,
               "Time","Event","Symbol","TF","Ticket","Severity",
               "Module","Message","Value","Status");
            FileFlush(h);
            headerWritten = true;
           }
         EventLockRelease();
        }
      else
         Print("[EVENT] WARN | header sem lock (concorrencia) | append-only continuara");
     }

   FileClose(h);

   evInitialized = true;
   return true;
}

//==================================================
// WRITE - nucleo de escrita (chamado APOS o lock)
// Abre handle novo -> seek END -> write -> flush -> fecha.
//==================================================
bool EventWriteLine(const string event,
                    const string severity,
                    const string sym,
                    const string tf,
                    const long   ticket,
                    const string module,
                    const string message,
                    const string value,
                    const string status)
{
   int h = EventOpenWrite();
   if(h == INVALID_HANDLE)
     {
      Print("[EVENT] falha ao abrir (write): ", EV_FILE, " | Err=", GetLastError());
      return false;
     }

   //==================================================
   // v1.2.231 (24/11/2026) - P1.3662: QUEM VAI ESCREVER CONFIRMA A POSSE
   //
   // MEDIDO no Files\Data\forward_test_events.csv: 1 192 linhas malformadas
   // em 65 688 (1,8%), com a assinatura de dois escritores no mesmo offset
   // ("NE" = cauda de "ONLINE", dois timestamp concatenados). O lock existe,
   // mas entre o EventLockAcquire() do EventEmit e este FileSeek passa o
   // FileOpen, e uma instancia que julgue o lock expirado (TTL) pode
   // substituir o token nesse intervalo: as duas escrevem depois no mesmo
   // fim-de-ficheiro, cada uma com o SEU ponteiro.
   // Aqui a posse e reconfirmada imediatamente antes da escrita. Se o token
   // ja nao for o desta instancia, a linha e abandonada (drop contabilizado)
   // em vez de sobrepor a linha de outra instancia.
   // Nenhum limite, lote, alvo, stop, spread, preco, RR, regra de entrada ou
   // de saida, ou parametro de risco e tocado: muda apenas se uma escrita
   // que perdeu o lock chega ou nao ao ficheiro.
   //==================================================
   if(!EventLockOwned())
     {
      FileClose(h);
      g_ev_dropped++;
      Print("[EVENT] DROP | lock perdido antes da escrita | ", event,
            " | ", sym,
            " | total_dropped=", g_ev_dropped,
            " | ", EventLockStats());
      return false;
     }

   FileSeek(h, 0, SEEK_END);

   FileWrite(h,
      TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
      event,
      sym,
      tf,
      (ticket > 0 ? IntegerToString((long)ticket) : "0"),
      severity,
      module,
      message,
      value,
      status);

   FileFlush(h);
   FileClose(h);

   return true;
}

//==================================================
// EMIT - funcao central (escrita serializada)
//==================================================
bool EventEmit(
   const string event,
   const string severity = EV_SEV_INFO,
   const string symbol   = "",
   const string module   = "",
   const string message  = "",
   const string value    = "",
   const string status   = "OK",
   const long   ticket   = 0
)
{
   if(!evInitialized)
      EventInit();

   string sym = (symbol == "" ? _Symbol : symbol);
   string tf  = EnumToString((ENUM_TIMEFRAMES)Period());

   //--------------------------------------------------
   // F4: serializa a escrita (1 produtor por vez no CSV).
   //--------------------------------------------------
   // v1.2.237 - P1.3668: PERDER A POSSE DEPOIS DE A ADQUIRIR NAO E
   // MOTIVO PARA PERDER O MARCADOR. MEDIDO no arranque simultaneo
   // dos 5 graficos as 22:07:23.861 (build v1.2.236): BTCUSD
   // adquiriu o lock e 60 ms depois ja nao era dono, e a linha
   // SYSTEM_START foi abandonada, exactamente a linha com que o
   // agregador Python segmenta o forward. O drop continua a existir
   // como ultimo recurso, mas deixa de ser a primeira resposta: se a
   // posse caiu antes da escrita, a linha NAO entrou no ficheiro e
   // volta a ser tentada com o lock readquirido (3 tentativas).
   // Nenhum limite, lote, alvo, stop, spread, preco, RR ou regra de
   // entrada e de saida e tocado: muda apenas quantas vezes INSISTE
   // uma escrita que ainda nao aconteceu.
   bool ok = false;
   for(int tentativa = 1; tentativa <= 3; tentativa++)
     {
      if(!EventLockAcquire())
        {
         g_ev_dropped++;
         Print("[EVENT] DROP | ", event, " | ", symbol,
               " | total_dropped=", g_ev_dropped,
               " | timeouts=", g_ev_lock_timeouts);
         return false;
        }

      ok = EventWriteLine(event, severity, sym, tf, ticket,
                          module, message, value, status);

      bool aindaDono = EventLockOwned();
      EventLockRelease();

      // Escrita aceite (ok) ou recusada por outra causa que nao a
      // posse: nao ha nada a repetir.
      if(ok || aindaDono)
         break;

      if(tentativa < 3)
         Sleep(0);
     }

   if(ok)
      g_ev_written++;

   return ok;
}

//==================================================
// METODOS PADRAO (wrappers convenientes)
//==================================================
bool EventSystemStart(string extra)
{
   return EventEmit(EV_SYSTEM_START, EV_SEV_INFO, "", "EA",
                    "EA inicializado " EV_VERSION_STRING, extra, "ONLINE");
}

bool EventSystemStop(string reason)
{
   return EventEmit(EV_SYSTEM_STOP, EV_SEV_INFO, "", "EA",
                    "EA finalizado", reason, "OFFLINE");
}

bool EventForwardStart(string mode)
{
   return EventEmit(EV_FWD_START, EV_SEV_INFO, "", "FT",
                    "Forward test iniciado", mode, "ONLINE");
}

bool EventHealthUpdate(string metric, string value, string status)
{
   return EventEmit(EV_HEALTH_UPDATE, EV_SEV_INFO, "", "HEALTH",
                    metric, value, status);
}

bool EventHealthWarning(string metric, string value)
{
   return EventEmit(EV_HEALTH_WARNING, EV_SEV_WARN, "", "HEALTH",
                    metric, value, "WARNING");
}

bool EventHealthFailure(string metric, string value)
{
   return EventEmit(EV_HEALTH_FAILURE, EV_SEV_ERROR, "", "HEALTH",
                    metric, value, "FAILURE");
}

bool EventAIPrediction(string symbol, string signal, string score)
{
   return EventEmit(EV_AI_PREDICTION, EV_SEV_INFO, symbol, "AI",
                    "Predicao IA", signal, score);
}

bool EventAIBlock(string symbol, string reason, string causa = "")
{
   string detalhe = (causa == "" ? "IA indisponivel/bloqueio"
                                 : "IA indisponivel/bloqueio: " + causa);
   return EventEmit(EV_AI_BLOCK, EV_SEV_WARN, symbol, "AI",
                    detalhe, reason, "UNAVAILABLE");
}

bool EventAIError(string symbol, string reason)
{
   return EventEmit(EV_AI_ERROR, EV_SEV_ERROR, symbol, "AI",
                    "Erro IA", reason, "ERROR");
}

bool EventSignalGenerated(string symbol, string direction, string score)
{
   return EventEmit(EV_SIGNAL_GENERATED, EV_SEV_INFO, symbol, "SCANNER",
                    "Sinal gerado", direction, score);
}

bool EventTradeApproved(string symbol, string side, string volume)
{
   return EventEmit(EV_TRADE_APPROVED, EV_SEV_INFO, symbol, "EXEC",
                    "Trade aprovado", side + " vol=" + volume, "APPROVED");
}

bool EventTradeRejected(string symbol, string reason, string retcode)
{
   return EventEmit(EV_TRADE_REJECTED, EV_SEV_WARN, symbol, "EXEC",
                    "Trade rejeitado", reason, retcode);
}

bool EventTradeOpen(string symbol, long ticket, string volume)
{
   return EventEmit(EV_TRADE_OPEN, EV_SEV_INFO, symbol, "EXEC",
                    "Posicao aberta", "vol=" + volume, "OPEN", ticket);
}

bool EventTradeClose(string symbol, long ticket, string profit)
{
   return EventEmit(EV_TRADE_CLOSE, EV_SEV_INFO, symbol, "EXEC",
                    "Posicao fechada", "profit=" + profit, "CLOSED", ticket);
}

bool EventRiskBlock(string symbol, string reason)
{
   return EventEmit(EV_RISK_BLOCK, EV_SEV_WARN, symbol, "RISK",
                    "Bloqueio de risco", reason, "BLOCKED");
}

bool EventNewsBlock(string symbol, string reason)
{
   return EventEmit(EV_NEWS_BLOCK, EV_SEV_WARN, symbol, "NEWS",
                    "Bloqueio de noticia", reason, "BLOCKED");
}

bool EventCircuitBreaker(string reason)
{
   return EventEmit(EV_CIRCUIT_BREAKER, EV_SEV_CRIT, "", "CIRCUIT",
                    "Circuit breaker", reason, "SAFE");
}

bool EventSafeMode(string reason)
{
   return EventEmit(EV_SAFE_MODE, EV_SEV_WARN, "", "SAFETY",
                    "Modo seguro", reason, "SAFE");
}

bool EventRecovery(string reason)
{
   return EventEmit(EV_RECOVERY, EV_SEV_INFO, "", "RECOVERY",
                    "Recuperacao", reason, "RECOVERED");
}

bool EventBrokerError(string reason)
{
   return EventEmit(EV_BROKER_ERROR, EV_SEV_ERROR, "", "BROKER",
                    "Erro de broker", reason, "ERROR");
}

bool EventPythonError(string reason)
{
   return EventEmit(EV_PYTHON_ERROR, EV_SEV_ERROR, "", "PYTHON",
                    "Erro de Python/IA", reason, "ERROR");
}

bool EventDatabaseError(string reason)
{
   return EventEmit(EV_DATABASE_ERROR, EV_SEV_ERROR, "", "DB",
                    "Erro de banco de dados", reason, "ERROR");
}

bool EventSystemError(string reason)
{
   return EventEmit(EV_SYSTEM_ERROR, EV_SEV_CRIT, "", "EA",
                    "Erro de sistema", reason, "ERROR");
}

//==================================================
// FLUSH / CLOSE
//==================================================
void EventFlush()
{
   // Sem handle persistente (F4): cada escrita ja faz flush+close.
   EventLockRelease();   // libera lock se esta instancia o deteve
}

void EventShutdown()
{
   // F4: nao mantemos handle aberto; apenas libera lock e reinicia flag.
   EventLockRelease();
   evInitialized = false;
}

//==================================================
// SUMMARY (F4: inclui estatisticas de serializacao)
//==================================================
string EventSummary()
{
   return StringFormat(
      "EventEmitter | File=%s | State=%s | Written=%d | Dropped=%d | %s",
      EV_FILE,
      (evInitialized ? "ON" : "OFF"),
      g_ev_written,
      g_ev_dropped,
      EventLockStats());
}

#endif // EVENT_EMITTER_MQH
