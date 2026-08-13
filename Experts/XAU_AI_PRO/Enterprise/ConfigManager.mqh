//+------------------------------------------------------------------+
//|                                                 ConfigManager.mqh |
//|                                  Configuration Profile Manager   |
//|                                            XAU_AI_PRO v1.0       |
//+------------------------------------------------------------------+

#ifndef CONFIG_MANAGER_MQH
#define CONFIG_MANAGER_MQH

//==================================================
// CONFIG PROFILES
//==================================================

enum ConfigProfile
{
   PROFILE_SCALPING = 0,
   PROFILE_SWING,
   PROFILE_CONSERVATIVE,
   PROFILE_AGGRESSIVE,
   PROFILE_FTMO,
   PROFILE_PROP,
   PROFILE_REAL
};


//==================================================
// CONFIG STRUCTURE
//==================================================

struct ConfigSet
{
   string name;

   double lot_size;
   double stop_loss;
   double take_profit;
   double trailing_stop;

   double max_daily_loss;
   double max_daily_dd;

   int    max_trades_per_day;

   double risk_per_trade;

   double ai_weight;
   double min_confidence;

   bool   use_break_even;
   bool   use_trailing;
   bool   use_dynamic_lot;
};


//==================================================
// CONFIG MANAGER
//==================================================

class CConfigManager
{
private:

   static ConfigSet      m_profiles[];
   static int            m_profile_count;
   static bool           m_initialized;
   static ConfigProfile  m_current_profile;
   static string         m_config_dir;

public:

   static void Init();
   static void LoadProfiles();

   static bool SetProfile(
      ConfigProfile profile
   );

   static ConfigProfile GetCurrentProfile();

   static string GetCurrentProfileName();

   static ConfigSet GetProfile(
      ConfigProfile profile
   );

   static bool SaveProfile(
      ConfigProfile profile
   );

   static bool LoadProfile(
      ConfigProfile profile
   );

   static bool ExportProfile(
      const string filename
   );

   static bool ImportProfile(
      const string filename,
      ConfigProfile profile
   );

   static string GetStatus();

   static void LogStatus();
};


//==================================================
// STATIC MEMBERS
//==================================================

ConfigSet CConfigManager::m_profiles[];

int CConfigManager::m_profile_count = 0;

bool CConfigManager::m_initialized = false;

ConfigProfile CConfigManager::m_current_profile =
   PROFILE_CONSERVATIVE;

string CConfigManager::m_config_dir = "";


//==================================================
// PROFILE BUILDER
//==================================================

void SetConfigProfile(
   ConfigSet &profile,
   string name,
   double lot_size,
   double stop_loss,
   double take_profit,
   double trailing_stop,
   double max_daily_loss,
   double max_daily_dd,
   int max_trades_per_day,
   double risk_per_trade,
   double ai_weight,
   double min_confidence,
   bool use_break_even,
   bool use_trailing,
   bool use_dynamic_lot
)
{
   profile.name              = name;

   profile.lot_size          = lot_size;
   profile.stop_loss         = stop_loss;
   profile.take_profit       = take_profit;
   profile.trailing_stop     = trailing_stop;

   profile.max_daily_loss    = max_daily_loss;
   profile.max_daily_dd      = max_daily_dd;

   profile.max_trades_per_day = max_trades_per_day;

   profile.risk_per_trade    = risk_per_trade;

   profile.ai_weight         = ai_weight;
   profile.min_confidence    = min_confidence;

   profile.use_break_even    = use_break_even;
   profile.use_trailing      = use_trailing;
   profile.use_dynamic_lot   = use_dynamic_lot;
}


//==================================================
// INIT
//==================================================

void CConfigManager::Init()
{
   if(m_initialized)
      return;


   //------------------------------------------------
   // DIRECTORY
   //------------------------------------------------

   m_config_dir =
      TerminalInfoString(
         TERMINAL_DATA_PATH
      )
      +
      "\\MQL5\\Files\\XAU_AI_PRO\\Profiles\\";


   //------------------------------------------------
   // ARRAY
   //------------------------------------------------

   ArrayResize(
      m_profiles,
      7
   );

   m_profile_count = 7;


   //------------------------------------------------
   // SCALPING
   //------------------------------------------------

   SetConfigProfile(
      m_profiles[PROFILE_SCALPING],
      "Scalping",
      0.01,
      50,
      100,
      25,
      200,
      3.0,
      20,
      0.5,
      0.7,
      75,
      true,
      true,
      true
   );


   //------------------------------------------------
   // SWING
   //------------------------------------------------

   SetConfigProfile(
      m_profiles[PROFILE_SWING],
      "Swing",
      0.02,
      100,
      200,
      50,
      500,
      5.0,
      10,
      1.0,
      0.6,
      65,
      true,
      true,
      true
   );


   //------------------------------------------------
   // CONSERVATIVE
   //------------------------------------------------

   SetConfigProfile(
      m_profiles[PROFILE_CONSERVATIVE],
      "Conservative",
      0.01,
      80,
      160,
      40,
      300,
      3.0,
      5,
      0.5,
      0.5,
      80,
      true,
      false,
      true
   );


   //------------------------------------------------
   // AGGRESSIVE
   //------------------------------------------------

   SetConfigProfile(
      m_profiles[PROFILE_AGGRESSIVE],
      "Aggressive",
      0.05,
      30,
      90,
      15,
      1000,
      10.0,
      50,
      2.0,
      0.8,
      50,
      false,
      true,
      true
   );


   //------------------------------------------------
   // FTMO
   //------------------------------------------------

   SetConfigProfile(
      m_profiles[PROFILE_FTMO],
      "FTMO",
      0.01,
      100,
      200,
      50,
      1000,
      10.0,
      10,
      1.0,
      0.6,
      70,
      true,
      true,
      false
   );


   //------------------------------------------------
   // PROP FIRM
   //------------------------------------------------

   SetConfigProfile(
      m_profiles[PROFILE_PROP],
      "Prop Firm",
      0.01,
      80,
      160,
      40,
      500,
      5.0,
      10,
      0.5,
      0.6,
      75,
      true,
      true,
      false
   );


   //------------------------------------------------
   // REAL ACCOUNT
   //------------------------------------------------

   SetConfigProfile(
      m_profiles[PROFILE_REAL],
      "Real Account",
      0.02,
      100,
      200,
      50,
      500,
      5.0,
      10,
      1.0,
      0.6,
      70,
      true,
      true,
      true
   );


   //------------------------------------------------
   // READY
   //------------------------------------------------

   m_initialized = true;


   Print(
      "[CONFIG] ConfigManager initialized | Profiles=",
      m_profile_count
   );
}


//==================================================
// LOAD PROFILES
//==================================================

void CConfigManager::LoadProfiles()
{
   if(!m_initialized)
      Init();

   // Persistência será implementada posteriormente.
}


//==================================================
// SET PROFILE
//==================================================

bool CConfigManager::SetProfile(
   ConfigProfile profile
)
{
   if(!m_initialized)
      Init();


   if(
      profile < 0 ||
      profile >= m_profile_count
   )
   {
      Print(
         "[CONFIG] Invalid profile"
      );

      return false;
   }


   m_current_profile = profile;


   Print(
      "[CONFIG] Profile changed: ",
      GetCurrentProfileName()
   );


   return true;
}


//==================================================
// CURRENT PROFILE
//==================================================

ConfigProfile CConfigManager::GetCurrentProfile()
{
   return m_current_profile;
}


//==================================================
// CURRENT PROFILE NAME
//==================================================

string CConfigManager::GetCurrentProfileName()
{
   if(!m_initialized)
      Init();


   return m_profiles[
      m_current_profile
   ].name;
}


//==================================================
// GET PROFILE
//==================================================

ConfigSet CConfigManager::GetProfile(
   ConfigProfile profile
)
{
   if(!m_initialized)
      Init();


   if(
      profile >= 0 &&
      profile < m_profile_count
   )
   {
      return m_profiles[profile];
   }


   return m_profiles[
      PROFILE_CONSERVATIVE
   ];
}


//==================================================
// SAVE PROFILE
//==================================================

bool CConfigManager::SaveProfile(
   ConfigProfile profile
)
{
   if(!m_initialized)
      Init();


   if(
      profile < 0 ||
      profile >= m_profile_count
   )
      return false;


   return true;
}


//==================================================
// LOAD PROFILE
//==================================================

bool CConfigManager::LoadProfile(
   ConfigProfile profile
)
{
   if(!m_initialized)
      Init();


   if(
      profile < 0 ||
      profile >= m_profile_count
   )
      return false;


   return true;
}


//==================================================
// EXPORT PROFILE
//==================================================

bool CConfigManager::ExportProfile(
   const string filename
)
{
   if(!m_initialized)
      Init();


   if(filename == "")
      return false;


   return true;
}


//==================================================
// IMPORT PROFILE
//==================================================

bool CConfigManager::ImportProfile(
   const string filename,
   ConfigProfile profile
)
{
   if(!m_initialized)
      Init();


   if(filename == "")
      return false;


   if(
      profile < 0 ||
      profile >= m_profile_count
   )
      return false;


   return true;
}


//==================================================
// STATUS
//==================================================

string CConfigManager::GetStatus()
{
   if(!m_initialized)
      Init();


   ConfigSet current =
      m_profiles[
         m_current_profile
      ];


   return StringFormat(
      "Current: %s | Lot: %.2f | SL: %.0f | TP: %.0f | Max DD: %.1f%% | Max Trades: %d",
      current.name,
      current.lot_size,
      current.stop_loss,
      current.take_profit,
      current.max_daily_dd,
      current.max_trades_per_day
   );
}


//==================================================
// LOG STATUS
//==================================================

void CConfigManager::LogStatus()
{
   Print(
      "[CONFIG] ",
      GetStatus()
   );
}


//==================================================
// END
//==================================================

#endif // CONFIG_MANAGER_MQH