//+------------------------------------------------------------------+
//|                                      T7_BackupRecoveryTest.mq5   |
//|              Teste de recuperacao - ETAPA 7 (BackupManager v2)  |
//|                                            XAU_AI_PRO v1.2.0     |
//+------------------------------------------------------------------+
// Ciclo completo:
//  0. Purge de snapshots antigos + ResetItems
//  1. Cria dados de teste em FILE_COMMON (Config\*.set, Data\*.json,
//     Data\*.db, Data\*.csv, Logs\*.log)
//  2. CBackupManager::RunBackup() -> valida copia REAL (wildcards)
//  3. Corrompe/remove os originais
//  4. CBackupManager::RestoreAll() -> restaura o ultimo snapshot
//  5. Verifica integridade (existencia + tamanho byte a byte)
//
// O resultado detalhado e gravado em Common\Files\T7_diag.txt
// (o journal do Strategy Tester nem sempre fica acessivel).
//+------------------------------------------------------------------+

#property strict
#property version "1.01"

#include "Enterprise/BackupManager.mqh"

//==================================================
// ESTRUTURA DE VERIFICACAO
//==================================================

struct T7File
{
   string path;
   long   size;
};

T7File g_files[];

int g_pass = 0;
int g_fail = 0;

//==================================================
// DIARIO (arquivo de diagnostico)
//==================================================

void T7Diag(string msg)
{
   int h = FileOpen(
      "T7_diag.txt",
      FILE_READ |
      FILE_WRITE |
      FILE_TXT |
      FILE_ANSI |
      FILE_COMMON
   );

   if(h == INVALID_HANDLE)
      return;

   FileSeek(h, 0, SEEK_END);
   FileWrite(h, msg);
   FileClose(h);

   Print("[T7] ", msg);
}

//==================================================
// HELPERS
//==================================================

long T7FileSize(string path)
{
   ResetLastError();

   int h = FileOpen(path, FILE_READ | FILE_BIN | FILE_COMMON);

   if(h == INVALID_HANDLE)
      return -1;

   long sz = (long)FileSize(h);
   FileClose(h);

   return sz;
}

bool T7Check(bool cond, string label)
{
   if(cond)
   {
      g_pass++;
      T7Diag("PASS | " + label);
      return true;
   }

   g_fail++;
   T7Diag("FAIL | " + label);
   return false;
}

bool T7WriteText(string path, string content)
{
   ResetLastError();

   int h = FileOpen(path, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);

   if(h == INVALID_HANDLE)
   {
      T7Diag("Falha ao criar: " + path + " | Erro=" + IntegerToString(GetLastError()));
      return false;
   }

   FileWrite(h, content);
   FileClose(h);

   return true;
}

// Cria os dados de teste e guarda o tamanho original.
bool T7CreateData()
{
   ArrayResize(g_files, 5);

   g_files[0].path = "Config\\T7_config.set";
   g_files[1].path = "Data\\T7_pred.json";
   g_files[2].path = "Data\\T7_signals.db";
   g_files[3].path = "Data\\T7_dataset.csv";
   g_files[4].path = "Logs\\T7_backup.log";

   if(!T7WriteText(g_files[0].path, "MagicNumber=2026001"))
      return false;
   if(!T7WriteText(g_files[0].path, "RiskPercent=1.0"))
      return false;

   if(!T7WriteText(g_files[1].path, "{\"symbol\":\"XAUUSD\",\"signal\":1,\"conf\":75.5}"))
      return false;

   if(!T7WriteText(g_files[2].path, "T7_SQLITE_TEST_DATA_1234567890"))
      return false;

   if(!T7WriteText(g_files[3].path, "Time,Symbol,Signal"))
      return false;
   if(!T7WriteText(g_files[3].path, "2026.08.14 10:00,XAUUSD,1"))
      return false;
   if(!T7WriteText(g_files[3].path, "2026.08.14 10:15,XAUUSD,-1"))
      return false;

   if(!T7WriteText(g_files[4].path, "2026.08.22 18:00:00 INFO T7 test log line"))
      return false;

   // Tamanhos originais
   for(int i = 0; i < ArraySize(g_files); i++)
   {
      g_files[i].size = T7FileSize(g_files[i].path);

      if(g_files[i].size <= 0)
      {
         T7Diag("Falha ao medir: " + g_files[i].path);
         return false;
      }

      T7Diag("Criado: " + g_files[i].path + " | size=" + IntegerToString(g_files[i].size));
   }

   return true;
}

// Corrompe/remove os originais.
bool T7CorruptData()
{
   bool ok = true;

   // Remove
   if(!T7Check(
      FileDelete(g_files[0].path, FILE_COMMON),
      "remove " + g_files[0].path
   ))
      ok = false;

   // Corrompe (sobrescreve)
   if(!T7WriteText(g_files[1].path, "CORRUPTED"))
      ok = false;
   if(!T7Check(
      T7FileSize(g_files[1].path) != g_files[1].size,
      "corrompido " + g_files[1].path
   ))
      ok = false;

   // Remove
   if(!T7Check(
      FileDelete(g_files[2].path, FILE_COMMON),
      "remove " + g_files[2].path
   ))
      ok = false;

   // Corrompe
   if(!T7WriteText(g_files[3].path, "CORRUPTED"))
      ok = false;
   if(!T7Check(
      T7FileSize(g_files[3].path) != g_files[3].size,
      "corrompido " + g_files[3].path
   ))
      ok = false;

   // Remove
   if(!T7Check(
      FileDelete(g_files[4].path, FILE_COMMON),
      "remove " + g_files[4].path
   ))
      ok = false;

   return ok;
}

// Verifica integridade apos o restore (existencia + tamanho).
bool T7VerifyIntegrity()
{
   bool ok = true;

   for(int i = 0; i < ArraySize(g_files); i++)
   {
      bool exists = FileIsExist(g_files[i].path, FILE_COMMON);
      long sz     = T7FileSize(g_files[i].path);

      if(!T7Check(
         exists,
         "existe " + g_files[i].path
      ))
         ok = false;

      if(!T7Check(
         sz == g_files[i].size,
         "tamanho " + g_files[i].path + " (" + IntegerToString(sz) + "/" + IntegerToString(g_files[i].size) + ")"
      ))
         ok = false;
   }

   return ok;
}

//==================================================
// CICLO DO TESTE
//==================================================

bool RunRecoveryTest()
{
   T7Diag("================================================");
   T7Diag(" T7 - BACKUP & RECOVERY TEST (BackupManager v2)");
   T7Diag("================================================");

   //----------------------------------------------
   // 0. PURGE + RESET (snapshot unico, itens limpos)
   //----------------------------------------------

   CBackupManager::PurgeBackups();
   CBackupManager::ResetItems();

   T7Diag("PurgeBackups + ResetItems OK");

   //----------------------------------------------
   // 1. CRIAR DADOS
   //----------------------------------------------

   if(!T7Check(T7CreateData(), "criar dados de teste"))
      return false;

   //----------------------------------------------
   // 2. BACKUP (itens com wildcard + exatos)
   //----------------------------------------------

   CBackupManager::AddItem("T7Set",  "Config\\T7_config.set");
   CBackupManager::AddItem("T7JSON", "Data\\T7_*.json");
   CBackupManager::AddItem("T7DB",   "Data\\T7_*.db");
   CBackupManager::AddItem("T7CSV",  "Data\\T7_dataset.csv");
   CBackupManager::AddItem("T7Log",  "Logs\\T7_*.log");

   bool bk = CBackupManager::RunBackup();

   T7Check(bk, "RunBackup retornou true (copia real validada)");
   T7Check(
      CBackupManager::GetLastFilesCopied() == 5,
      "GetLastFilesCopied == 5 (wildcards expandidos) | copiados=" + IntegerToString(CBackupManager::GetLastFilesCopied())
   );
   T7Check(
      CBackupManager::GetLastFilesFailed() == 0,
      "GetLastFilesFailed == 0 | falhas=" + IntegerToString(CBackupManager::GetLastFilesFailed())
   );
   T7Check(
      CBackupManager::GetLastSnapshot() != "",
      "GetLastSnapshot identificado | " + CBackupManager::GetLastSnapshot()
   );

   //----------------------------------------------
   // 3. CORROMPER / REMOVER
   //----------------------------------------------

   T7CorruptData();

   //----------------------------------------------
   // 4. RESTORE ALL
   //----------------------------------------------

   ResetLastError();
   bool rs = CBackupManager::RestoreAll();

   T7Check(rs, "RestoreAll retornou true");
   T7Diag("RestoreAll GetLastError=" + IntegerToString(GetLastError()));

   //----------------------------------------------
   // 5. VERIFICAR INTEGRIDADE
   //----------------------------------------------

   T7VerifyIntegrity();

   //----------------------------------------------
   // RESUMO
   //----------------------------------------------

   T7Diag("----------------------------------------------");
   T7Diag("[T7] PASS=" + IntegerToString(g_pass) + " | FAIL=" + IntegerToString(g_fail));
   T7Diag("Snapshot: " + CBackupManager::GetLatestBackupPath());
   T7Diag(CBackupManager::GetStatus());
   T7Diag("----------------------------------------------");

   return (g_fail == 0);
}

//==================================================
// ON INIT
//==================================================

int OnInit()
{
   Print("================================================");
   Print(" T7_BackupRecoveryTest iniciando...");
   Print("================================================");

   bool ok = RunRecoveryTest();

   T7Diag(ok ? "[T7] RESULTADO FINAL: PASS" : "[T7] RESULTADO FINAL: FAIL");

   ExpertRemove();

   return INIT_SUCCEEDED;
}

//==================================================
// ON DEINIT
//==================================================

void OnDeinit(const int reason)
{
   Print("[T7] Teste finalizado | Reason=", reason);
}

//==================================================
// ON TICK (nao usado - teste roda no OnInit)
//==================================================

void OnTick()
{
}
