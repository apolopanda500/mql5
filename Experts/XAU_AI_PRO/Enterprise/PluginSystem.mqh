//+------------------------------------------------------------------+
//|                                                 PluginSystem.mqh |
//|                                  Plugin System for Modularity    |
//|                                            XAU_AI_PRO v1.2.0       |
//+------------------------------------------------------------------+

#ifndef PLUGIN_SYSTEM_MQH
#define PLUGIN_SYSTEM_MQH

enum PluginType { PLUGIN_AI, PLUGIN_ORDERFLOW, PLUGIN_SMARTMONEY, PLUGIN_NEWS, PLUGIN_ML, PLUGIN_RISK, PLUGIN_DASHBOARD };
typedef void (*PluginCallback)();
typedef bool (*PluginBoolCallback)();


struct Plugin
{
   string      name;
   PluginType  type;
   bool        enabled;
   int         priority;
   string      version;
   string      author;
   PluginCallback       onInit;
   PluginCallback       onTick;
   PluginCallback       onDeinit;
   PluginBoolCallback   isEnabled;
};

class CPluginSystem
{
private:
   static Plugin m_plugins[];
   static int    m_plugin_count;
   static bool   m_initialized;
public:
   static void Init();
   static void RegisterPlugin(string name, PluginType type, int priority, string version, string author, PluginCallback init, PluginCallback tick, PluginCallback deinit);
   static void EnablePlugin(string name);
   static void DisablePlugin(string name);
   static bool IsPluginEnabled(string name);
   static void RunInit();
   static void RunTick();
   static void RunDeinit();
   static int GetPluginCount();
   static string GetStatus();
   static void LogStatus();
};

Plugin CPluginSystem::m_plugins[];
int CPluginSystem::m_plugin_count = 0;
bool CPluginSystem::m_initialized = false;

void CPluginSystem::Init()
{
   if(m_initialized) return;
   ArrayResize(m_plugins, 10);
   m_plugin_count = 0;
   m_initialized = true;
   Print("[PLUGIN] PluginSystem initialized");
}

void CPluginSystem::RegisterPlugin(string name, PluginType type, int priority, string version, string author, PluginCallback init, PluginCallback tick, PluginCallback deinit)
{
   if(!m_initialized) Init();
   if(m_plugin_count >= ArraySize(m_plugins)) return;
   
   Plugin p;
   p.name = name;
   p.type = type;
   p.priority = priority;
   p.version = version;
   p.author = author;
   p.onInit = init;
   p.onTick = tick;
   p.onDeinit = deinit;
   p.enabled = true;
   p.isEnabled = NULL;
   
   m_plugins[m_plugin_count++] = p;
   PrintFormat("[PLUGIN] Registered: %s v%s by %s", name, version, author);
}

void CPluginSystem::EnablePlugin(string name)
{
   for(int i = 0; i < m_plugin_count; i++)
   {
      if(m_plugins[i].name == name) { m_plugins[i].enabled = true; break; }
   }
}

void CPluginSystem::DisablePlugin(string name)
{
   for(int i = 0; i < m_plugin_count; i++)
   {
      if(m_plugins[i].name == name) { m_plugins[i].enabled = false; break; }
   }
}

bool CPluginSystem::IsPluginEnabled(string name)
{
   for(int i = 0; i < m_plugin_count; i++)
   {
      if(m_plugins[i].name == name) return m_plugins[i].enabled;
   }
   return false;
}

void CPluginSystem::RunInit()
{
   if(!m_initialized) return;
   // Sort by priority
   for(int i = 0; i < m_plugin_count; i++)
   {
      if(!m_plugins[i].enabled) continue;
      if(m_plugins[i].onInit != NULL) m_plugins[i].onInit();
   }
}

void CPluginSystem::RunTick()
{
   if(!m_initialized) return;
   for(int i = 0; i < m_plugin_count; i++)
   {
      if(!m_plugins[i].enabled) continue;
      if(m_plugins[i].onTick != NULL) m_plugins[i].onTick();
   }
}

void CPluginSystem::RunDeinit()
{
   if(!m_initialized) return;
   for(int i = 0; i < m_plugin_count; i++)
   {
      if(!m_plugins[i].enabled) continue;
      if(m_plugins[i].onDeinit != NULL) m_plugins[i].onDeinit();
   }
}

int CPluginSystem::GetPluginCount() { return m_plugin_count; }

string CPluginSystem::GetStatus()
{
   string s = StringFormat("Plugins: %d | ", m_plugin_count);
   for(int i = 0; i < m_plugin_count; i++)
   {
      s += StringFormat("%s(%s) ", m_plugins[i].name, m_plugins[i].enabled ? "ON" : "OFF");
   }
   return s;
}

void CPluginSystem::LogStatus() { Print("[PLUGIN] " + GetStatus()); }

#endif // PLUGIN_SYSTEM_MQH
