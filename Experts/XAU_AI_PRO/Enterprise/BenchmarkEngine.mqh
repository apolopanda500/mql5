//+------------------------------------------------------------------+
//|                                               BenchmarkEngine.mqh |
//|                                  Strategy Benchmark System        |
//|                                            XAU_AI_PRO v1.2.0       |
//+------------------------------------------------------------------+

#ifndef BENCHMARK_ENGINE_MQH
#define BENCHMARK_ENGINE_MQH

enum StrategyType { STRATEGY_TECHNICAL, STRATEGY_AI, STRATEGY_HYBRID, STRATEGY_ENSEMBLE };

struct StrategyResult
{
   StrategyType type;
   int          trades;
   double       profit;
   double       win_rate;
   double       profit_factor;
   double       max_dd;
   double       sharpe;
   datetime     last_trade;
};

class CBenchmarkEngine
{
private:
   static StrategyResult m_strategies[];
   static int            m_strategy_count;
   static bool           m_initialized;
   static int            m_benchmark_period_days;
   static StrategyType   m_best_strategy;
   static void EvaluateStrategies();
public:
   static void Init();
   static void RecordTrade(StrategyType type, double profit, double sl, double tp);
   static StrategyType GetBestStrategy();
   static string GetBestStrategyName();
   static double GetStrategyWinRate(StrategyType type);
   static double GetStrategyProfit(StrategyType type);
   static string GetComparisonSummary();
   static void LogComparison();
};

StrategyResult CBenchmarkEngine::m_strategies[];
int CBenchmarkEngine::m_strategy_count = 0;
bool CBenchmarkEngine::m_initialized = false;
int CBenchmarkEngine::m_benchmark_period_days = 30;
StrategyType CBenchmarkEngine::m_best_strategy = STRATEGY_TECHNICAL;

void CBenchmarkEngine::Init()
{
   if(m_initialized) return;
   ArrayResize(m_strategies, 4);
   m_strategy_count = 4;
   
   m_strategies[STRATEGY_TECHNICAL].type = STRATEGY_TECHNICAL;
   m_strategies[STRATEGY_TECHNICAL].trades = 0;
   m_strategies[STRATEGY_TECHNICAL].profit = 0;
   m_strategies[STRATEGY_TECHNICAL].win_rate = 0;
   m_strategies[STRATEGY_TECHNICAL].profit_factor = 0;
   m_strategies[STRATEGY_TECHNICAL].max_dd = 0;
   m_strategies[STRATEGY_TECHNICAL].sharpe = 0;
   m_strategies[STRATEGY_TECHNICAL].last_trade = 0;

   m_strategies[STRATEGY_AI].type = STRATEGY_AI;
   m_strategies[STRATEGY_AI].trades = 0;
   m_strategies[STRATEGY_AI].profit = 0;
   m_strategies[STRATEGY_AI].win_rate = 0;
   m_strategies[STRATEGY_AI].profit_factor = 0;
   m_strategies[STRATEGY_AI].max_dd = 0;
   m_strategies[STRATEGY_AI].sharpe = 0;
   m_strategies[STRATEGY_AI].last_trade = 0;

   m_strategies[STRATEGY_HYBRID].type = STRATEGY_HYBRID;
   m_strategies[STRATEGY_HYBRID].trades = 0;
   m_strategies[STRATEGY_HYBRID].profit = 0;
   m_strategies[STRATEGY_HYBRID].win_rate = 0;
   m_strategies[STRATEGY_HYBRID].profit_factor = 0;
   m_strategies[STRATEGY_HYBRID].max_dd = 0;
   m_strategies[STRATEGY_HYBRID].sharpe = 0;
   m_strategies[STRATEGY_HYBRID].last_trade = 0;

   m_strategies[STRATEGY_ENSEMBLE].type = STRATEGY_ENSEMBLE;
   m_strategies[STRATEGY_ENSEMBLE].trades = 0;
   m_strategies[STRATEGY_ENSEMBLE].profit = 0;
   m_strategies[STRATEGY_ENSEMBLE].win_rate = 0;
   m_strategies[STRATEGY_ENSEMBLE].profit_factor = 0;
   m_strategies[STRATEGY_ENSEMBLE].max_dd = 0;
   m_strategies[STRATEGY_ENSEMBLE].sharpe = 0;
   m_strategies[STRATEGY_ENSEMBLE].last_trade = 0;
   
   m_initialized = true;
   Print("[BENCHMARK] BenchmarkEngine initialized");
}

void CBenchmarkEngine::RecordTrade(StrategyType type, double profit, double sl, double tp)
{
   if(!m_initialized) Init();
   if(type < 0 || type >= m_strategy_count) return;
   
   m_strategies[type].trades++;
   m_strategies[type].profit += profit;
   m_strategies[type].last_trade = TimeCurrent();
   
   if(profit > 0) m_strategies[type].win_rate = (m_strategies[type].win_rate * (m_strategies[type].trades - 1) + profit) / m_strategies[type].trades;
   
   EvaluateStrategies();
}

void CBenchmarkEngine::EvaluateStrategies()
{
   double best_profit = -999999;
   for(int i = 0; i < m_strategy_count; i++)
   {
      if(m_strategies[i].profit > best_profit)
      {
         best_profit = m_strategies[i].profit;
         m_best_strategy = (StrategyType)i;
      }
   }
}

StrategyType CBenchmarkEngine::GetBestStrategy() { return m_best_strategy; }

string CBenchmarkEngine::GetBestStrategyName()
{
   switch(m_best_strategy)
   {
      case STRATEGY_TECHNICAL: return "Technical";
      case STRATEGY_AI: return "AI";
      case STRATEGY_HYBRID: return "Hybrid";
      case STRATEGY_ENSEMBLE: return "Ensemble";
      default: return "Unknown";
   }
}

double CBenchmarkEngine::GetStrategyWinRate(StrategyType type)
{
   if(type >= 0 && type < m_strategy_count) return m_strategies[type].win_rate;
   return 0;
}

double CBenchmarkEngine::GetStrategyProfit(StrategyType type)
{
   if(type >= 0 && type < m_strategy_count) return m_strategies[type].profit;
   return 0;
}

string CBenchmarkEngine::GetComparisonSummary()
{
   string s = "=== STRATEGY COMPARISON ===\n";
   string names[] = {"Technical", "AI", "Hybrid", "Ensemble"};
   
   for(int i = 0; i < m_strategy_count; i++)
   {
      string best = (i == (int)m_best_strategy) ? " *BEST*" : "";
      s += StringFormat("  %s: Trades=%d Profit=%.2f WinRate=%.1f%%%s\n",
         names[i], m_strategies[i].trades, m_strategies[i].profit, m_strategies[i].win_rate, best);
   }
   
   s += StringFormat("\nBest Strategy: %s", GetBestStrategyName());
   return s;
}

void CBenchmarkEngine::LogComparison() { Print("[BENCHMARK] " + GetComparisonSummary()); }

#endif // BENCHMARK_ENGINE_MQH
