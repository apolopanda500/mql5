//+------------------------------------------------------------------+
//| XAI_PRO_GV_HYGIENE.mq5                                        |
//| Higienizacao SOLO del entorno Strategy Tester (auditoria T4-V1). |
//| Elimina unicamente estado tester del XAU_AI_PRO:                 |
//|   1) XAI_PRO_T_RH_*   (RiskHub namespace tester)                 |
//|   2) XAI_PRO_LATCH_*  solo entradas con barTime antiguo (>7 dias)|
//| No toca: XAI_PRO_RH_* (live), XAI_PRO_SENT_*, CB_SAFE_UNTIL,     |
//|          XAI_PRO_EXEC_LOCK, latches recientes de instancias live.|
//+------------------------------------------------------------------+
void OnStart()
{
   int total = GlobalVariablesTotal();
   Print("[GVH] START total=", total);

   int i;

   //--- PASO 1: LISTADO (evidencia BEFORE) ---
   for(i = 0; i < total; i++)
   {
      string name = GlobalVariableName(i);
      double val  = GlobalVariableGet(name);
      if(StringFind(name, "XAI_PRO", 0) == 0)
         Print("[GVH] BEFORE ", name, "=", DoubleToString(val, 8));
   }

   //--- PASO 2: BORRADO ACOTADO ---
   long cutoff = (long)TimeLocal() - (7 * 86400);

   for(i = GlobalVariablesTotal() - 1; i >= 0; i--)
   {
      string name = GlobalVariableName(i);

      // 1) RiskHub tester
      if(StringFind(name, "XAI_PRO_T_RH_", 0) == 0)
      {
         Print("[GVH] DEL-RH ", name, "=", DoubleToString(GlobalVariableGet(name), 8));
         GlobalVariableDel(name);
         continue;
      }

      // 2) Latch: solo stale (>7 dias); los de instancias live son recientes
      if(StringFind(name, "XAI_PRO_LATCH_", 0) == 0)
      {
         string tsStr = "";
         int p;
         for(p = StringLen(name) - 1; p >= 0; p--)
         {
            if(StringGetCharacter(name, p) == '_')
            {
               tsStr = StringSubstr(name, p + 1);
               break;
            }
         }

         if(tsStr != "")
         {
            long barTime = (long)StringToInteger(tsStr);
            if(barTime > 0 && barTime < cutoff)
            {
               Print("[GVH] DEL-STALE ", name, "=", DoubleToString(GlobalVariableGet(name), 8));
               GlobalVariableDel(name);
            }
            else
               Print("[GVH] KEEP-LIVE ", name);
         }
         else
            Print("[GVH] KEEP-NOPARSE ", name);

         continue;
      }

      // 3) Otros namespaces XAI_PRO: solo reporte (sin borrar)
      Print("[GVH] REPORT(no-del) ", name, "=", DoubleToString(GlobalVariableGet(name), 8));
   }

   //--- PASO 3: VERIFICACION AFTER ---
   int after = GlobalVariablesTotal();
   Print("[GVH] AFTER total=", after);

   for(i = 0; i < after; i++)
   {
      string name = GlobalVariableName(i);
      if(StringFind(name, "XAI_PRO", 0) == 0)
         Print("[GVH] AFTER ", name, "=", DoubleToString(GlobalVariableGet(name), 8));
   }

   Print("[GVH] DONE");
}