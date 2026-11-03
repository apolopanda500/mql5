//+------------------------------------------------------------------+
//| _probe_learn_import.mq5                                          |
//| TEMPORARIO - sonda de leitura do historico real da conta.         |
//| Nao opera nada: so conta deals por tipo/magic e mostra o ticket   |
//| mais novo de saida. Serve para explicar "importados=0" do LEARN.  |
//+------------------------------------------------------------------+
#property strict

void OnStart()
{
   datetime to   = TimeCurrent();
   datetime from = to - (datetime)(200 * 86400);

   bool ok = HistorySelect(from, to);

   Print("[PROBE] HistorySelect ok=", ok,
         " err=", GetLastError(),
         " from=", TimeToString(from),
         " to=", TimeToString(to));

   int total = HistoryDealsTotal();
   Print("[PROBE] deals total=", total);

   int   ins = 0, outs = 0, manuais = 0, doEA = 0, outros = 0, semSymbol = 0;
   ulong ultimoOut = 0;

   for(int i = 0; i < total; i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0)
         continue;

      long   entry = HistoryDealGetInteger(d, DEAL_ENTRY);
      long   type  = HistoryDealGetInteger(d, DEAL_TYPE);
      long   magic = HistoryDealGetInteger(d, DEAL_MAGIC);
      string sym   = HistoryDealGetString(d, DEAL_SYMBOL);

      if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
      {
         outs++;
         if(d > ultimoOut)
            ultimoOut = d;
      }
      else if(entry == DEAL_ENTRY_IN)
         ins++;

      if(magic == 0)
         manuais++;
      else if(magic == 2026001)
         doEA++;
      else
         outros++;

      if(sym == "")
         semSymbol++;

      if(i < 3 || i > total - 4)
         Print("[PROBE] i=", i,
               " deal=", d,
               " sym=", sym,
               " entry=", entry,
               " type=", type,
               " magic=", magic,
               " profit=", DoubleToString(HistoryDealGetDouble(d, DEAL_PROFIT), 2),
               " time=", TimeToString((datetime)HistoryDealGetInteger(d, DEAL_TIME)));
   }

   Print("[PROBE] resumo | in=", ins,
         " out=", outs,
         " manual=", manuais,
         " ea=", doEA,
         " outroMagic=", outros,
         " semSymbol=", semSymbol,
         " ultimoOut=", ultimoOut);
}
//+------------------------------------------------------------------+
