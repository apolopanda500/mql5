//+------------------------------------------------------------------+
//|                                 TradeLoggerSQLite.mqh            |
//| XAU_AI_PRO v1.2.111 — TradeLogger com SQLite nativo (MQL5)       |
//| Substitui CSV por banco de dados estruturado — elimina erros de  |
//| colagem de linhas, vírgulas desalinhadas e ano 22026.            |
//+------------------------------------------------------------------+
#ifndef TRADE_LOGGER_SQLITE_MQH
#define TRADE_LOGGER_SQLITE_MQH

#include <Database.mqh>   // SQLite nativo do MQL5

//+------------------------------------------------------------------+
//| Estrutura de registro de trade (13 colunas)                      |
//+------------------------------------------------------------------+
struct STradeRecord
{
   ulong   ticket;
   long    magic;
   string  origin;          // "EA", "MANUAL", "COPY", "MCP"
   datetime time;
   string  symbol;
   long    type;            // POSITION_TYPE_BUY/SELL
   double  volume;
   double  price_open;
   double  sl;
   double  tp;
   double  price_close;
   double  profit;
   string  details;
};

//+------------------------------------------------------------------+
//| Classe TradeLoggerSQLite                                         |
//+------------------------------------------------------------------+
bool CTradeLoggerSQLite::Connect(const string db_name)
{
   m_db_path = db_name;

   // Abre ou cria o banco SQLite
   m_db_handle = DatabaseOpen(m_db_path, OPEN_READWRITE | OPEN_CREATE);
   if(m_db_handle == INVALID_HANDLE)
   {
      Print("[SQLITE] Falha ao abrir banco: ", GetLastError());
      return false;
   }

   m_connected = true;

   // Cria tabela se não existir
   if(!CreateTableIfNotExists())
   {
      Print("[SQLITE] Falha ao criar tabela");
      return false;
   }

   Print("[SQLITE] Banco conectado: ", m_db_path);
   return true;
}

//+------------------------------------------------------------------+
void CTradeLoggerSQLite::Disconnect()
{
   if(m_db_handle != INVALID_HANDLE)
   {
      DatabaseClose(m_db_handle);
      m_db_handle = INVALID_HANDLE;
   }
   m_connected = false;
}

//+------------------------------------------------------------------+
bool CTradeLoggerSQLite::CreateTableIfNotExists()
{
   if(!m_connected) return false;

   CDatabase db;
   if(!db.Attach(m_db_handle)) return false;

   string sql =
      "CREATE TABLE IF NOT EXISTS trades ("
      "  ticket      INTEGER PRIMARY KEY,"
      "  magic       INTEGER NOT NULL,"
      "  origin      TEXT NOT NULL,"
      "  time        INTEGER NOT NULL,"
      "  symbol      TEXT NOT NULL,"
      "  type        INTEGER NOT NULL,"
      "  volume      REAL NOT NULL,"
      "  price_open  REAL NOT NULL,"
      "  sl          REAL NOT NULL,"
//+------------------------------------------------------------------+
bool CTradeLoggerSQLite::InsertTrade(const STradeRecord &rec)
{
   if(!m_connected) return false;

   CDatabase db;
   if(!db.Attach(m_db_handle)) return false;

   // Usa INSERT OR REPLACE para evitar duplicatas por ticket
   string sql =
      "INSERT OR REPLACE INTO trades ("
      "  ticket, magic, origin, time, symbol, type, volume, "
      "  price_open, sl, tp, price_close, profit, details"
      ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";

   if(!db.Prepare(sql))
   {
      Print("[SQLITE] Erro PREPARE: ", db.LastError());
      return false;
   }

   // Bind dos parâmetros (evita SQL injection e problemas de formatação)
   db.BindInteger(0, (long)rec.ticket);
   db.BindInteger(1, rec.magic);
   db.BindText(2, rec.origin);
   db.BindInteger(3, (long)rec.time);
   db.BindText(4, rec.symbol);
   db.BindInteger(5, rec.type);
   db.BindDouble(6, rec.volume);
   db.BindDouble(7, rec.price_open);
   db.BindDouble(8, rec.sl);
   db.BindDouble(9, rec.tp);
   db.BindDouble(10, rec.price_close);
   db.BindDouble(11, rec.profit);
   db.BindText(12, rec.details);

   if(!db.Step())
   {
      Print("[SQLITE] Erro STEP INSERT: ", db.LastError());
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
bool CTradeLoggerSQLite::GetTradeByTicket(ulong ticket, STradeRecord &rec)
{
   if(!m_connected) return false;

   CDatabase db;
   if(!db.Attach(m_db_handle)) return false;

   string sql = "SELECT * FROM trades WHERE ticket = ?;";
   if(!db.Prepare(sql)) return false;

   db.BindInteger(0, (long)ticket);

   if(!db.Step()) return false;

   rec.ticket    = (ulong)db.ColumnInteger(0);
   rec.magic     = db.ColumnInteger(1);
   rec.origin    = db.ColumnText(2);
   rec.time      = (datetime)db.ColumnInteger(3);
   rec.symbol    = db.ColumnText(4);
   rec.type      = db.ColumnInteger(5);
   rec.volume    = db.ColumnDouble(6);
   rec.price_open= db.ColumnDouble(7);
   rec.sl        = db.ColumnDouble(8);
   rec.tp        = db.ColumnDouble(9);
   rec.price_close=db.ColumnDouble(10);
   rec.profit    = db.ColumnDouble(11);
   rec.details   = db.ColumnText(12);

   return true;
}

//+------------------------------------------------------------------+
int CTradeLoggerSQLite::GetTotalTrades()
{
   if(!m_connected) return 0;

   CDatabase db;
   if(!db.Attach(m_db_handle)) return 0;

   string sql = "SELECT COUNT(*) FROM trades;";
   if(!db.Prepare(sql)) return 0;

   if(!db.Step()) return 0;
   return (int)db.ColumnInteger(0);
}

//+------------------------------------------------------------------+
double CTradeLoggerSQLite::GetTotalProfit()
{
   if(!m_connected) return 0.0;

   CDatabase db;
   if(!db.Attach(m_db_handle)) return 0.0;

   string sql = "SELECT SUM(profit) FROM trades;";
   if(!db.Prepare(sql)) return 0.0;

   if(!db.Step()) return 0.0;
   return db.ColumnDouble(0);
}

//+------------------------------------------------------------------+
//| Instância global                                                 |
//+------------------------------------------------------------------+
CTradeLoggerSQLite g_trade_logger_sqlite;

//+------------------------------------------------------------------+
//| Funções de conveniência                                          |
//+------------------------------------------------------------------+
bool TradeLoggerSQLiteInit(const string db_name = "trade_history.db")
{
   return g_trade_logger_sqlite.Connect(db_name);
}

void TradeLoggerSQLiteShutdown()
{
   g_trade_logger_sqlite.Disconnect();
}

bool TradeLoggerSQLiteLog(const STradeRecord &rec)
{
   return g_trade_logger_sqlite.InsertTrade(rec);
}

#endif
      "  tp          REAL NOT NULL,"
      "  price_close REAL DEFAULT 0,"
      "  profit      REAL DEFAULT 0,"
      "  details     TEXT"
      ");";

   if(!db.Execute(sql))
   {
      Print("[SQLITE] Erro CREATE TABLE: ", db.LastError());
      return false;
   }

   // Índice para consultas rápidas por símbolo
   db.Execute("CREATE INDEX IF NOT EXISTS idx_trades_symbol ON trades(symbol);");
   db.Execute("CREATE INDEX IF NOT EXISTS idx_trades_time ON trades(time);");

   return true;
}
//+------------------------------------------------------------------+
class CTradeLoggerSQLite
{
private:
   int     m_db_handle;
   bool    m_connected;
   string  m_db_path;

public:
   CTradeLoggerSQLite();
   ~CTradeLoggerSQLite();

   bool  Connect(const string db_name = "trade_history.db");
   void  Disconnect();

   bool  InsertTrade(const STradeRecord &rec);
   bool  CreateTableIfNotExists();

   //--- Consulta por ticket
   bool  GetTradeByTicket(ulong ticket, STradeRecord &rec);

   //--- Estatísticas
   int   GetTotalTrades();
   double GetTotalProfit();

private:
   bool  BindInsert(CDatabase &db, const STradeRecord &rec);
};

//+------------------------------------------------------------------+
//| Construtor                                                       |
//+------------------------------------------------------------------+
CTradeLoggerSQLite::CTradeLoggerSQLite()
{
   m_db_handle = INVALID_HANDLE;
   m_connected = false;
   m_db_path   = "";
}

//+------------------------------------------------------------------+
//| Destrutor                                                        |
//+------------------------------------------------------------------+
CTradeLoggerSQLite::~CTradeLoggerSQLite()
{
   Disconnect();
}