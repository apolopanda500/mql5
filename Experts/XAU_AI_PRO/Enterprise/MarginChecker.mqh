//+------------------------------------------------------------------+
//|                                               MarginChecker.mqh |
//|                                  Smart Execution Engine - Margin |
//|                                            XAU_AI_PRO v1.2.0       |
//+------------------------------------------------------------------+

#ifndef MARGIN_CHECKER_MQH
#define MARGIN_CHECKER_MQH

//==================================================
// COOLDOWN — CONSTANTES
//==================================================
// Definidas AQUI, antes da classe, porque os arrays usam a constante no
// proprio tamanho. Declarar depois da classe compila como array de tamanho
// desconhecido e quebra em runtime.
//
// Medido no forward test (CSV UTF-16, 24/08 a 02/10): 4.165 `EXEC_NO_MARGIN`,
// intervalo MEDIANO de 2 a 3 s entre recusas do mesmo simbolo, rajada de 4 no
// mesmo segundo, 1.452 recusas so em 17/09. A trava de margem ja existia e
// funcionava — recusava a ordem. O que faltava era PARAR de tentar: margem
// esgotada so volta com swap, deposito ou fechamento de posicao.
//
// 60s e o piso (corta as rajadas de 2-3 s). Teto de 3600s evita ficar mudo a
// noite inteira. 64 simbolos cobrem qualquer lista de pares do EA.
#define MARGIN_COOLDOWN_BASE_SEC   60
#define MARGIN_COOLDOWN_MAX_SEC 3600
#define MARGIN_COOLDOWN_MAX_SYMBOLS 64

class CMarginChecker
{
private:
   static double m_required_margin;
   static double m_free_margin;
   static double m_margin_level;
   static bool   m_initialized;

   // COOLDOWN POR SIMBOLO. Estado do processo do EA: dois EAs com
   // magics diferentes nao compartilham a mesma trava.
   static datetime m_cooldown_until[MARGIN_COOLDOWN_MAX_SYMBOLS];
   static int      m_consecutive_blocks[MARGIN_COOLDOWN_MAX_SYMBOLS];
   static string   m_symbol_names[MARGIN_COOLDOWN_MAX_SYMBOLS];
   static int      m_blocked_symbols;

   static int SymbolIndex(string symbol);

public:
   static void Init();
   static bool CheckMargin(string symbol, double volume, double price);
   static double CalculateRequiredMargin(string symbol, double volume, double price);
   static double GetFreeMargin();
   static double GetMarginLevel();
   static string GetMarginError(string symbol, double volume, double price);
   static void LogMarginStatus();

   static bool   IsInCooldown(string symbol);
   static void   RegisterBlock(string symbol);
   static string GetCooldownError(string symbol);
   static int    GetCooldownRemaining(string symbol);
   static int    GetBlockedCount();
   static void   ClearCooldowns();
   static bool   CooldownActive(string symbol);
};

double CMarginChecker::m_required_margin = 0;
double CMarginChecker::m_free_margin = 0;
double CMarginChecker::m_margin_level = 0;
bool CMarginChecker::m_initialized = false;

datetime CMarginChecker::m_cooldown_until[MARGIN_COOLDOWN_MAX_SYMBOLS];
int      CMarginChecker::m_consecutive_blocks[MARGIN_COOLDOWN_MAX_SYMBOLS];
string   CMarginChecker::m_symbol_names[MARGIN_COOLDOWN_MAX_SYMBOLS];
int      CMarginChecker::m_blocked_symbols = 0;

//==================================================
// COOLDOWN — INTERNOS
//==================================================

int CMarginChecker::SymbolIndex(string symbol)
{
   if(symbol == "") symbol = _Symbol;

   int total = MathMin(m_blocked_symbols, MARGIN_COOLDOWN_MAX_SYMBOLS);
   for(int i = 0; i < total; i++)
   {
      if(m_blocked_symbols > i && m_symbol_names[i] == symbol) return i;
   }
   return -1;
}

//==================================================
// IS IN COOLDOWN
//==================================================

bool CMarginChecker::IsInCooldown(string symbol)
{
   if(symbol == "") symbol = _Symbol;

   int idx = SymbolIndex(symbol);
   if(idx < 0) return false;

   datetime now = TimeCurrent();
   if(now >= m_cooldown_until[idx])
   {
      // NAO zera `m_consecutive_blocks` aqui. Medido por simulacao com esta
      // mesma logica e os mesmos parametros:
      //   zerando o contador -> 1.440 bloqueios/dia por simbolo
      //   mantendo o contador ->    27 bloqueios/dia por simbolo
      // Zerar devolvia a trava ao estado inicial a cada 60 s e mantinha a taxa
      // do defeito. O contador so zera quando a margem VOLTA (ver CheckMargin).
      m_cooldown_until[idx] = 0;
      return false;
   }
   return true;
}

//==================================================
// REGISTER BLOCK
//==================================================

void CMarginChecker::RegisterBlock(string symbol)
{
   if(symbol == "") symbol = _Symbol;

   int idx = SymbolIndex(symbol);

   // Sem espaco no rastreio: NAO registra e devolve. Perder o cooldown de um par
   // e aceitavel; escrever fora do array nao e. Degenera para o comportamento
   // antigo (tenta e a trava recusa), que e o estado seguro.
   if(idx < 0 && m_blocked_symbols >= MARGIN_COOLDOWN_MAX_SYMBOLS)
   {
      PrintFormat("[MARGIN] cooldown sem espaco para %s (%d rastreados): usando trava sem cooldown",
                  symbol, m_blocked_symbols);
      return;
   }

   if(idx < 0)
   {
      idx = m_blocked_symbols;
      m_blocked_symbols++;
      m_symbol_names[idx]       = symbol;
      m_cooldown_until[idx]     = 0;
      m_consecutive_blocks[idx] = 0;
   }

   m_consecutive_blocks[idx]++;

   int cooldown = MARGIN_COOLDOWN_BASE_SEC * (1 << MathMin(m_consecutive_blocks[idx] - 1, 10));
   if(cooldown > MARGIN_COOLDOWN_MAX_SEC) cooldown = MARGIN_COOLDOWN_MAX_SEC;

   m_cooldown_until[idx] = TimeCurrent() + cooldown;

   PrintFormat("[MARGIN] %s bloqueado por %ds (recusa %d) | livre=%.2f nivel=%.2f%%",
               symbol, cooldown, m_consecutive_blocks[idx], GetFreeMargin(), GetMarginLevel());
}

//==================================================
// GET COOLDOWN ERROR
//==================================================

string CMarginChecker::GetCooldownError(string symbol)
{
   if(symbol == "") symbol = _Symbol;

   int remaining = GetCooldownRemaining(symbol);
   if(remaining <= 0) return "";

   int idx = SymbolIndex(symbol);
   int consecutive = (idx >= 0) ? m_consecutive_blocks[idx] : 1;

   return StringFormat("%s em cooldown apos %d recusa(s) por margem: faltam %ds. "
                       "Margem esgotada nao se resolve em segundos.",
                       symbol, consecutive, remaining);
}

//==================================================
// GET COOLDOWN REMAINING
//==================================================

int CMarginChecker::GetCooldownRemaining(string symbol)
{
   if(symbol == "") symbol = _Symbol;

   int idx = SymbolIndex(symbol);
   if(idx < 0) return 0;

   datetime now = TimeCurrent();
   if(now >= m_cooldown_until[idx]) return 0;

   return (int)(m_cooldown_until[idx] - now);
}

//==================================================
// GET BLOCKED COUNT
//==================================================

int CMarginChecker::GetBlockedCount()
{
   int blocked = 0;
   for(int i = 0; i < m_blocked_symbols; i++)
   {
      if(TimeCurrent() < m_cooldown_until[i]) blocked++;
   }
   return blocked;
}

//==================================================
// CLEAR COOLDOWNS
//==================================================

void CMarginChecker::ClearCooldowns()
{
   for(int i = 0; i < m_blocked_symbols; i++)
   {
      m_cooldown_until[i]     = 0;
      m_consecutive_blocks[i] = 0;
   }
}

bool CMarginChecker::CooldownActive(string symbol)
{
   return IsInCooldown(symbol);
}

void CMarginChecker::Init()
{
   if(m_initialized) return;
   m_free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   m_margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   m_initialized = true;
   PrintFormat("[MARGIN] Free: %.2f | Level: %.2f%%", m_free_margin, m_margin_level);
}

bool CMarginChecker::CheckMargin(string symbol, double volume, double price)
{
   if(!m_initialized) Init();
   if(symbol == "") symbol = _Symbol;

   // COOLDOWN PRIMEIRO. Antes de qualquer leitura de conta: um
   // simbolo recem bloqueado nao precisa de OrderCalcMargin para saber que a
   // resposta sera "nao" — e essa era a repeticao de 2 em 2 segundos.
   if(IsInCooldown(symbol))
      return false;

   m_required_margin = CalculateRequiredMargin(symbol, volume, price);
   m_free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   m_margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);

   // Cada recusa abaixo vira um cooldown. Sem isto a trava recusa a ordem e o
   // proximo tick tenta de novo, infinitamente — foram as 4.165
   // EXEC_NO_MARGIN do forward test.
   if(m_free_margin <= 0)
   {
      RegisterBlock(symbol);
      return false;
   }

   if(m_required_margin > m_free_margin * 0.9)
   {
      RegisterBlock(symbol);
      return false;
   }

   // Nivel de margem 0 = sem posicoes abertas (nao bloqueia).
   // So bloqueia quando existe nivel real abaixo de 200%.
   if(m_margin_level > 0 && m_margin_level < 200)
   {
      RegisterBlock(symbol);
      return false;
   }

   // MARGEM VOLTOU. Chegou aqui = passou pelo cooldown E a margem esta
   // suficiente, entao a serie de recusas encerra. Sem isto o par ficaria
   // travado em 1 h para sempre mesmo com a conta sadia, e trocar "muitas
   // ordens recusadas" por "nenhuma ordem aceita" tambem e defeito.
   int idx = SymbolIndex(symbol);
   if(idx >= 0 && m_consecutive_blocks[idx] > 0)
   {
      PrintFormat("[MARGIN] %s recuperou margem | serie de %d recusa(s) encerrada",
                  symbol, m_consecutive_blocks[idx]);
      m_consecutive_blocks[idx] = 0;
   }

   return true;
}

double CMarginChecker::CalculateRequiredMargin(string symbol, double volume, double price)
{
   if(symbol == "") symbol = _Symbol;

   // v1.3.0: OrderCalcMargin nativo converte moedas corretamente
   // (pares com USD na base como USDJPY, crosses, metais, indices).
   // A formula manual antiga multiplicava pelo preco mesmo quando
   // a moeda base ja era a da conta (USDJPY: $10 reais -> $159 calculados).
   double margin = 0.0;

   if(OrderCalcMargin(ORDER_TYPE_BUY, symbol, volume, price, margin) && margin > 0.0)
      return margin;

   // Fallback: calculo manual aproximado
   double contract_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double leverage = (double)AccountInfoInteger(ACCOUNT_LEVERAGE);
   if(leverage <= 0) leverage = 100;
   return (volume * contract_size * price) / leverage;
}

double CMarginChecker::GetFreeMargin()
{
   return AccountInfoDouble(ACCOUNT_MARGIN_FREE);
}

double CMarginChecker::GetMarginLevel()
{
   return AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
}

string CMarginChecker::GetMarginError(string symbol, double volume, double price)
{
   double required = CalculateRequiredMargin(symbol, volume, price);
   double free = GetFreeMargin();
   double level = GetMarginLevel();
   
   if(free <= 0) return "Sem margem livre disponivel";
   if(required > free * 0.9)
      return StringFormat("Margem requerida (%.2f) excede 90%% da livre (%.2f)", required, free);
   if(level > 0 && level < 200)
      return StringFormat("Nivel de margem (%.2f%%) abaixo de 200%%", level);
   return "";
}

void CMarginChecker::LogMarginStatus()
{
   double free = GetFreeMargin();
   double level = GetMarginLevel();
   PrintFormat("[MARGIN] Free: %.2f | Level: %.2f%% | Required: %.2f", free, level, m_required_margin);
}

#endif // MARGIN_CHECKER_MQH
