//+------------------------------------------------------------------+
//|  XAI_LogGateProbe.mq5 - sonda descartavel do AccountLogGate       |
//|  Nao negocia, nao altera nada: apenas abre ficheiros de gate e     |
//|  imprime o que conseguiu ler/escrever.                            |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

input string ProbeTag = "probe_p205";   // tag de teste (ficheiro novo)

void OnStart()
  {
   // ---------- 1) estado do ficheiro pipe_standby com os flags reais ----------
   string nome = "XAU_AI_PRO\\loggate_pipe_standby.bin";
   ResetLastError();
   int h = FileOpen(nome, FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
   Print("[PROBE] open_realfags handle=", h, " err=", GetLastError());
   if(h != INVALID_HANDLE)
     {
      long sz = (long)FileSize(h);
      long v = 0;
      bool okSeek = FileSeek(h, 0, SEEK_SET);
      if(okSeek)
         v = FileReadLong(h);
      Print("[PROBE] size=", sz, " seek=", okSeek, " valor=", v, " agora=", (long)TimeCurrent(),
            " diff=", ((long)TimeCurrent() - v));
      FileClose(h);
     }

   // ---------- 2) com FILE_SHARE_READ|FILE_SHARE_WRITE ----------
   ResetLastError();
   int h2 = FileOpen(nome, FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON|FILE_SHARE_READ|FILE_SHARE_WRITE);
   Print("[PROBE] open_share handle=", h2, " err=", GetLastError());
   if(h2 != INVALID_HANDLE)
     {
      long v2 = 0;
      if(FileSeek(h2, 0, SEEK_SET))
         v2 = FileReadLong(h2);
      Print("[PROBE] share size=", (long)FileSize(h2), " valor=", v2);
      FileClose(h2);
     }

   // ---------- 3) replica da funcao do gate, 3 chamadas na mesma tag nova ----------
   for(int i = 0; i < 3; i++)
     {
      ResetLastError();
      int hh = FileOpen("XAU_AI_PRO\\loggate_" + ProbeTag + ".bin",
                        FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON);
      bool pode = true;
      long lido = -1;
      int err = 0;
      if(hh == INVALID_HANDLE)
        {
         err = GetLastError();
        }
      else
        {
         long sz = (long)FileSize(hh);
         long ultimo = 0;
         if(sz >= (long)sizeof(long))
           {
            if(FileSeek(hh, 0, SEEK_SET))
               ultimo = FileReadLong(hh);
           }
         lido = ultimo;
         long agora = (long)TimeCurrent();
         pode = (ultimo == 0 || agora >= ultimo + 3600 || agora < ultimo);
         if(pode)
           {
            FileSeek(hh, 0, SEEK_SET);
            FileWriteLong(hh, agora);
           }
         FileClose(hh);
        }
      Print("[PROBE] chamada ", i, " pode=", pode, " lido=", lido, " err=", err);
     }

   // ---------- 4) agora com share flags ----------
   for(int i = 0; i < 2; i++)
     {
      ResetLastError();
      int hh = FileOpen("XAU_AI_PRO\\loggate_" + ProbeTag + "_share.bin",
                        FILE_READ|FILE_WRITE|FILE_BIN|FILE_COMMON|FILE_SHARE_READ|FILE_SHARE_WRITE);
      Print("[PROBE] share chamada ", i, " handle=", hh, " err=", GetLastError());
      if(hh != INVALID_HANDLE)
         FileClose(hh);
     }

   Print("[PROBE] fim");
  }
//+------------------------------------------------------------------+
