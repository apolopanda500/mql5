//+------------------------------------------------------------------+
//|                                                 EventManager.mqh |
//|                                  Event Engine - Decoupled System |
//|                                            XAU_AI_PRO v1.2.0       |
//+------------------------------------------------------------------+

#ifndef EVENT_MANAGER_MQH
#define EVENT_MANAGER_MQH

enum EventType { EVENT_TICK, EVENT_TRADE, EVENT_NEWS, EVENT_AI, EVENT_RISK, EVENT_SYSTEM, EVENT_USER };

struct Event
{
   EventType type;
   datetime  time;
   string    symbol;
   string    data;
   double    value;
   int       priority;
};

typedef void (*EventHandler)(const Event&);

class CEventManager
{
private:
   static Event    m_queue[];
   static int      m_queue_size;
   static int      m_queue_count;
   static bool     m_initialized;
   static EventHandler m_handlers[];
public:
   static void Init();
   static void Push(EventType type, string symbol, string data, double value, int priority);
   static void Process();
   static void RegisterHandler(EventType type, EventHandler handler);
   static void UnregisterHandler(EventType type);
   static int GetQueueSize();
   static string GetStatus();
   static void LogStatus();
};

Event CEventManager::m_queue[];
int CEventManager::m_queue_size = 0;
int CEventManager::m_queue_count = 0;
bool CEventManager::m_initialized = false;
EventHandler CEventManager::m_handlers[];

void CEventManager::Init()
{
   if(m_initialized) return;
   ArrayResize(m_queue, 100);
   m_queue_size = 100;
   m_queue_count = 0;
   ArrayResize(m_handlers, 7);
   m_initialized = true;
   Print("[EVENT] EventManager initialized");
}

void CEventManager::Push(EventType type, string symbol, string data, double value, int priority)
{
   if(!m_initialized) Init();
   if(m_queue_count >= m_queue_size) Process(); // Process if full
   
   Event evt;
   evt.type = type;
   evt.time = TimeCurrent();
   evt.symbol = symbol;
   evt.data = data;
   evt.value = value;
   evt.priority = priority;
   
   m_queue[m_queue_count++] = evt;
}

void CEventManager::Process()
{
   if(!m_initialized) return;
   for(int i = 0; i < m_queue_count; i++)
   {
      int idx = (int)m_queue[i].type;
      if(idx >= 0 && idx < ArraySize(m_handlers) && m_handlers[idx] != NULL)
      {
         m_handlers[idx](m_queue[i]);
      }
   }
   m_queue_count = 0; // Clear queue
}

void CEventManager::RegisterHandler(EventType type, EventHandler handler)
{
   if(!m_initialized) Init();
   int idx = (int)type;
   if(idx >= 0 && idx < ArraySize(m_handlers)) m_handlers[idx] = handler;
}

void CEventManager::UnregisterHandler(EventType type)
{
   int idx = (int)type;
   if(idx >= 0 && idx < ArraySize(m_handlers)) m_handlers[idx] = NULL;
}

int CEventManager::GetQueueSize() { return m_queue_count; }

string CEventManager::GetStatus()
{
   return StringFormat("Events queued: %d/%d", m_queue_count, m_queue_size);
}

void CEventManager::LogStatus() { Print("[EVENT] " + GetStatus()); }

#endif // EVENT_MANAGER_MQH
