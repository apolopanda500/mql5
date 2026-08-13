//+------------------------------------------------------------------+
//|                                               BackupManager.mqh  |
//|                                  Backup Manager System           |
//|                                            XAU_AI_PRO v1.0       |
//+------------------------------------------------------------------+

#ifndef BACKUP_MANAGER_MQH
#define BACKUP_MANAGER_MQH

//==================================================
// BACKUP ITEM
//==================================================

struct BackupItem
{
   string   name;
   string   path;
   datetime last_backup;
   bool     success;
};


//==================================================
// BACKUP MANAGER
//==================================================

class CBackupManager
{
private:

   static BackupItem m_items[];
   static int        m_item_count;
   static bool       m_initialized;
   static string     m_backup_dir;
   static int        m_max_backups;
   static bool       m_compress;

   static bool BackupFile(
      const string src,
      const string dst
   );

   static void CleanupOldBackups(
      const string pattern
   );

public:

   static void Init();

   static void AddItem(
      string name,
      string path
   );

   static bool RunBackup();

   static bool Restore(
      const string name,
      const string backup_file
   );

   static bool RestoreAll();

   static datetime GetLastBackup(
      const string name
   );

   static string GetStatus();

   static void LogStatus();
};


//==================================================
// STATIC MEMBERS
//==================================================

BackupItem CBackupManager::m_items[];

int CBackupManager::m_item_count = 0;

bool CBackupManager::m_initialized = false;

string CBackupManager::m_backup_dir = "";

int CBackupManager::m_max_backups = 10;

bool CBackupManager::m_compress = false;


//==================================================
// INIT
//==================================================

void CBackupManager::Init()
{
   if(m_initialized)
      return;

   //------------------------------------------------
   // Inicializa estado ANTES de AddItem()
   // evita recursao Init() -> AddItem() -> Init()
   //------------------------------------------------

   m_initialized = true;

   m_item_count = 0;

   m_backup_dir = "XAU_AI_PRO\\Backups\\";


   //------------------------------------------------
   // Array
   //------------------------------------------------

   ArrayResize(
      m_items,
      20
   );


   //------------------------------------------------
   // Itens padrao
   //------------------------------------------------

   AddItem(
      "Config",
      "*.set"
   );

   AddItem(
      "Dataset",
      "Data\\dataset.csv"
   );

   AddItem(
      "Predictions",
      "Data\\*.json"
   );

   AddItem(
      "Logs",
      "Logs\\*.log"
   );

   AddItem(
      "Database",
      "Data\\*.db"
   );


   //------------------------------------------------
   // Log
   //------------------------------------------------

   Print(
      "[BACKUP] BackupManager initialized | Items=",
      m_item_count
   );
}


//==================================================
// ADD ITEM
//==================================================

void CBackupManager::AddItem(
   string name,
   string path
)
{
   //------------------------------------------------
   // Se chamado antes do Init, inicializa somente
   // quando necessario.
   //------------------------------------------------

   if(!m_initialized)
   {
      m_initialized = true;

      m_item_count = 0;

      ArrayResize(
         m_items,
         20
      );

      m_backup_dir =
         "XAU_AI_PRO\\Backups\\";
   }


   //------------------------------------------------
   // Limite
   //------------------------------------------------

   if(
      m_item_count >=
      ArraySize(m_items)
   )
   {
      Print(
         "[BACKUP] Item limit reached"
      );

      return;
   }


   //------------------------------------------------
   // Criar item
   //------------------------------------------------

   m_items[m_item_count].name =
      name;

   m_items[m_item_count].path =
      path;

   m_items[m_item_count].last_backup =
      0;

   m_items[m_item_count].success =
      false;

   m_item_count++;
}


//==================================================
// BACKUP FILE
//==================================================

bool CBackupManager::BackupFile(
   const string src,
   const string dst
)
{
   //------------------------------------------------
   // Wildcards nao sao suportados diretamente por
   // FileCopy(). Portanto, este metodo trabalha
   // somente com arquivos individuais.
   //------------------------------------------------

   if(
      StringFind(src, "*") >= 0 ||
      StringFind(src, "?") >= 0
   )
   {
      Print(
         "[BACKUP] Wildcard skipped: ",
         src
      );

      return false;
   }


   //------------------------------------------------
   // Verifica existencia
   //------------------------------------------------

   if(
      !FileIsExist(
         src,
         FILE_COMMON
      )
   )
   {
      Print(
         "[BACKUP] Source not found: ",
         src
      );

      return false;
   }


   //------------------------------------------------
   // Copia
   //------------------------------------------------

   ResetLastError();

   bool result =
      FileCopy(
         src,
         FILE_COMMON,
         dst,
         FILE_COMMON
      );


   if(!result)
   {
      Print(
         "[BACKUP] Copy failed: ",
         src,
         " -> ",
         dst,
         " | Error=",
         GetLastError()
      );

      return false;
   }


   return true;
}


//==================================================
// RUN BACKUP
//==================================================

bool CBackupManager::RunBackup()
{
   if(!m_initialized)
      Init();


   //------------------------------------------------
   // Timestamp seguro para nome de pasta
   //------------------------------------------------

   MqlDateTime dt;

   TimeToStruct(
      TimeCurrent(),
      dt
   );


   string timestamp =
      StringFormat(
         "%04d%02d%02d_%02d%02d%02d",
         dt.year,
         dt.mon,
         dt.day,
         dt.hour,
         dt.min,
         dt.sec
      );


   //------------------------------------------------
   // Pasta
   //------------------------------------------------

   string backup_path =
      m_backup_dir +
      "backup_" +
      timestamp +
      "\\";


 //==================================================
// CRIAR PASTA DE BACKUP
//==================================================

ResetLastError();

// FolderCreate retorna true se a pasta foi criada
// OU se ela já existia; false em caso de erro real.
bool created = FolderCreate(
   backup_path,
   FILE_COMMON
);

if(!created)
{
   Print(
      "[BACKUP] Failed creating directory: ",
      backup_path,
      " | Error=",
      GetLastError()
   );

   return false;
}


   //------------------------------------------------
   // Processamento
   //------------------------------------------------

   bool all_ok = true;

   for(
      int i = 0;
      i < m_item_count;
      i++
   )
   {
      m_items[i].success = false;


      //------------------------------------------------
      // Wildcards ainda nao possuem expansao aqui.
      //------------------------------------------------

      if(
         StringFind(
            m_items[i].path,
            "*"
         ) >= 0
      )
      {
         Print(
            "[BACKUP] Wildcard item skipped: ",
            m_items[i].name,
            " | ",
            m_items[i].path
         );

         all_ok = false;

         continue;
      }


      string destination =
         backup_path +
         m_items[i].name +
         "_" +
         timestamp +
         ".bak";


      if(
         BackupFile(
            m_items[i].path,
            destination
         )
      )
      {
         m_items[i].last_backup =
            TimeCurrent();

         m_items[i].success =
            true;
      }
      else
      {
         all_ok = false;
      }
   }


   //------------------------------------------------
   // Limpeza
   //------------------------------------------------

   CleanupOldBackups(
      m_backup_dir +
      "backup_*"
   );


   //------------------------------------------------
   // Resultado
   //------------------------------------------------

   if(all_ok)
   {
      Print(
         "[BACKUP] Backup completed successfully"
      );
   }
   else
   {
      Print(
         "[BACKUP] Backup completed with failures"
      );
   }


   return all_ok;
}


//==================================================
// CLEANUP
//==================================================

void CBackupManager::CleanupOldBackups(
   const string pattern
)
{
   //------------------------------------------------
   // Limpeza automatica sera implementada quando
   // o gerenciamento de diretorios for expandido.
   //------------------------------------------------

   // Nao apagar arquivos automaticamente nesta
   // versao para evitar perda acidental de backups.
}


//==================================================
// RESTORE
//==================================================

bool CBackupManager::Restore(
   const string name,
   const string backup_file
)
{
   if(!m_initialized)
      Init();


   //------------------------------------------------
   // Localiza item
   //------------------------------------------------

   for(
      int i = 0;
      i < m_item_count;
      i++
   )
   {
      if(
         m_items[i].name != name
      )
         continue;


      //------------------------------------------------
      // Verifica backup
      //------------------------------------------------

      if(
         !FileIsExist(
            backup_file,
            FILE_COMMON
         )
      )
      {
         Print(
            "[BACKUP] Backup file not found: ",
            backup_file
         );

         return false;
      }


      //------------------------------------------------
      // Restaura
      //------------------------------------------------

      ResetLastError();

      bool result =
         FileCopy(
            backup_file,
            FILE_COMMON,
            m_items[i].path,
            FILE_COMMON
         );


      if(!result)
      {
         Print(
            "[BACKUP] Restore failed: ",
            name,
            " | Error=",
            GetLastError()
         );

         return false;
      }


      Print(
         "[BACKUP] Restored: ",
         name
      );

      return true;
   }


   return false;
}


//==================================================
// RESTORE ALL
//==================================================

bool CBackupManager::RestoreAll()
{
   //------------------------------------------------
   // Restauracao automatica do ultimo snapshot
   // sera implementada posteriormente.
   //------------------------------------------------

   Print(
      "[BACKUP] RestoreAll not configured"
   );

   return false;
}


//==================================================
// LAST BACKUP
//==================================================

datetime CBackupManager::GetLastBackup(
   const string name
)
{
   if(!m_initialized)
      Init();


   for(
      int i = 0;
      i < m_item_count;
      i++
   )
   {
      if(
         m_items[i].name ==
         name
      )
      {
         return
            m_items[i].last_backup;
      }
   }


   return 0;
}


//==================================================
// STATUS
//==================================================

string CBackupManager::GetStatus()
{
   if(!m_initialized)
      Init();


   string status =
      "=== BACKUP MANAGER ===\n";


   status +=
      "Items: " +
      IntegerToString(
         m_item_count
      ) +
      "\n";


   status +=
      "Directory: " +
      m_backup_dir +
      "\n";


   for(
      int i = 0;
      i < m_item_count;
      i++
   )
   {
      string last =
         "Never";


      if(
         m_items[i].last_backup >
         0
      )
      {
         last =
            TimeToString(
               m_items[i].last_backup,
               TIME_DATE |
               TIME_SECONDS
            );
      }


      status +=
         StringFormat(
            "%s: %s | Last: %s\n",
            m_items[i].name,
            m_items[i].success
               ? "OK"
               : "FAIL",
            last
         );
   }


   return status;
}


//==================================================
// LOG STATUS
//==================================================

void CBackupManager::LogStatus()
{
   Print(
      "[BACKUP] ",
      GetStatus()
   );
}


//==================================================
// END
//==================================================

#endif // BACKUP_MANAGER_MQH