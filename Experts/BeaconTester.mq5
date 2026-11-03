//+------------------------------------------------------------------+
//| BeaconTester.mq5 - sonda minima para isolar falha do agente       |
//+------------------------------------------------------------------+
#property version   "1.00"
#property strict

int OnInit()
{
   Print("[BEACON] OnInit OK");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   Print("[BEACON] OnDeinit ", reason);
}

void OnTick()
{
   static int n = 0;
   n++;
   if(n % 500 == 0)
      Print("[BEACON] tick ", n);
}
