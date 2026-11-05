// XAU_AI_PRO v1.2.9
#ifndef VOLATILITYFILTER_MQH
#define VOLATILITYFILTER_MQH


//==================================================
// VOLATILITY FILTER PRO (ATR)
//==================================================


#define VOLATILITY_ATR_PERIOD 14


//==================================================
// HANDLE
//==================================================

int volatilityATRHandle = INVALID_HANDLE;

double volatilityATRBuffer[];

//==================================================
// v1.2.149 (05/11/2026) - P1.108: CACHE DE HANDLE ATR POR SIMBOLO
//
// MEDIDO no journal do expert as 22:39:42 de 04/11, build v1.2.148:
//   [DATA] SEM LEITURA | USDSEK | ATR=0.000000 | ADX=42.12 | RSI=42.99
//   [DATA] SEM LEITURA | USDCNH | ATR=0.000000 | ADX=23.78 | RSI=43.21
// ADX e RSI chegaram com valor real e o ATR chegou a zero no MESMO candle.
// A causa estava aqui: a versao multi-simbolo chamava iATR() e
// IndicatorRelease() na MESMA leitura. O MT5 calcula o indicador de forma
// assincrona, logo o primeiro CopyBuffer de um handle recem-criado pode
// devolver 0 barras - e a funcao deitava o handle fora antes de ele
// aquecer. E exactamente o defeito que o P1.85 corrigiu no ADX (v1.2.96)
// e que ficou por corrigir no ATR.
//
// Efeito medido do ATR a zero: (a) o candle NAO e gravado no dataset,
// porque o [DATA] SEM LEITURA regressa antes do FileWrite, portanto os
// simbolos que nao sao o do grafico nunca chegaram ao CSV; (b) em
// Core/ExecutionEngine.mqh:943 o armPts cai para StoplessArmMinPoints e a
// simulacao de RR corre com um R de 30 pontos em vez do R real do par, um
// fail-open no portao MinSimulationRR.
//
// O handle passa a ser criado UMA vez por simbolo e reutilizado. Sem isso
// nao ha como o indicador aquecer.
//==================================================
#define ATR_SYMBOL_CACHE 256

string g_atrCacheSymbol[ATR_SYMBOL_CACHE];
int    g_atrCacheHandle[ATR_SYMBOL_CACHE];
int    g_atrCacheCount = 0;

int ATRSymbolHandle(string symbol)
{
   for(int i = 0; i < g_atrCacheCount; i++)
      if(g_atrCacheSymbol[i] == symbol)
         return g_atrCacheHandle[i];

   if(g_atrCacheCount >= ATR_SYMBOL_CACHE)
      return INVALID_HANDLE;

   int handle = iATR(symbol, PERIOD_CURRENT, VOLATILITY_ATR_PERIOD);

   if(handle == INVALID_HANDLE)
      return INVALID_HANDLE;

   g_atrCacheSymbol[g_atrCacheCount] = symbol;
   g_atrCacheHandle[g_atrCacheCount] = handle;
   g_atrCacheCount++;

   return handle;
}

void ATRReleaseSymbolHandles()
{
   for(int i = 0; i < g_atrCacheCount; i++)
      if(g_atrCacheHandle[i] != INVALID_HANDLE)
         IndicatorRelease(g_atrCacheHandle[i]);

   g_atrCacheCount = 0;
}



//==================================================
// INIT
//==================================================

bool InitATR()
{

   // v1.2.149 - P1.108: a cache e indexada por simbolo mas o timeframe entra
   // na criacao do handle (PERIOD_CURRENT), logo os handles antigos
   // responderiam com o periodo errado numa mudanca de timeframe.
   ATRReleaseSymbolHandles();

   volatilityATRHandle =
      iATR(
         _Symbol,
         PERIOD_CURRENT,
         VOLATILITY_ATR_PERIOD
      );


   if(volatilityATRHandle == INVALID_HANDLE)
   {
      Print("Erro criando ATR");
      return false;
   }


   ArraySetAsSeries(
      volatilityATRBuffer,
      true
   );


   return true;

}



//==================================================
// GET ATR
//==================================================

double GetATRInstance()
{

   if(volatilityATRHandle == INVALID_HANDLE)
      return 0.0;



   if(
      CopyBuffer(
         volatilityATRHandle,
         0,
         0,
         3,
         volatilityATRBuffer
      ) <= 0
   )
      return 0.0;



   return NormalizeDouble(
      volatilityATRBuffer[0],
      _Digits
   );

}


double GetATR(string symbol)
{
   // v1.2.150 - P1.109: o simbolo do grafico deixa de usar o handle
   // criado em OnInit (ver a nota do wrapper GetATR() mais abaixo).
   if(symbol=="")
      symbol=_Symbol;

   // Normaliza com os digitos do proprio simbolo (nao do chart),
   // senao ATR de pares com mais casas (ex: EURUSD, 5 digitos)
   // e arredondado a zero (NormalizeDouble(x,_Digits) com _Digits=2).
   int symbolDigits=(int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(symbolDigits<=0)
      symbolDigits=_Digits;

   // v1.2.149 - P1.108: handle por simbolo, em CACHE, e nunca libertado
   // na leitura. Era a libertacao imediata que impedia o aquecimento.
   int handle=ATRSymbolHandle(symbol);
   if(handle==INVALID_HANDLE)
      return 0.0;

   double buf[];
   ArraySetAsSeries(buf, true);

   double result=0.0;
   if(CopyBuffer(handle, 0, 0, 1, buf) > 0)
      result=NormalizeDouble(buf[0], symbolDigits);

   // v1.2.149 - P1.108: handle NAO libertado aqui; fica na cache e e
   // libertado em ReleaseATR e em InitATR. Sem barras calculadas o
   // resultado e 0.0 e a leitura seguinte ja encontra o indicador quente.
   return result;
}



//==================================================
double GetATR()
{
   // v1.2.150 - P1.109: o simbolo do grafico passa a ler pela cache por
   // simbolo, tal como o GetADX e o GetRSI ja faziam. O handle unico criado
   // em OnInit sobrevivia ao reload do perfil e podia devolver a serie de
   // OUTRO par (medido a 22:46:55: [CENARIO] USDJPY | ADX=33.2 | ATR%=17.97,
   // que sao o ADX e o ATR do XAUUSD). A leitura antiga fica em
   // GetATRInstance() e so e usada se alguem a chamar de proposito.
   return GetATR(_Symbol);
}


// RELEASE
//==================================================

void ReleaseATR()
{

   ATRReleaseSymbolHandles();   // v1.2.149 - P1.108

   if(volatilityATRHandle != INVALID_HANDLE)
   {

      IndicatorRelease(
         volatilityATRHandle
      );


      volatilityATRHandle = INVALID_HANDLE;

   }

}



//==================================================
// ATR POINTS
//==================================================

double GetATRPoints()
{

   double atr =
      GetATR();


   if(atr <= 0)
      return 0;



   return(
      atr /
      _Point
   );

}



//==================================================
// VOLATILITY FILTER
//==================================================

bool GoodVolatility(
   double minATRPoints
)
{

   double points =
      GetATRPoints();


   if(points <= 0)
      return false;


   return(
      points >= minATRPoints
   );

}



//==================================================
// AI VOLATILITY SCORE
//==================================================

double GetVolatilityScore()
{

   double atrPoints =
      GetATRPoints();



   if(atrPoints >= 300)
      return 100;


   if(atrPoints >= 150)
      return 80;


   if(atrPoints >= 70)
      return 60;


   if(atrPoints >= 30)
      return 40;


   return 20;

}



//==================================================
// HIGH VOLATILITY
//==================================================

bool HighVolatility(
   double multiplier
)
{

   double atr =
      GetATR();


   if(atr <= 0)
      return false;



   double averageATR = 0;


   // v1.2.150 - P1.109: a media de 20 barras tem de vir do MESMO
   // handle que o valor comparado, senao compara dois simbolos.
   int hVol = ATRSymbolHandle(_Symbol);
   int copied = 0;

   if(hVol != INVALID_HANDLE)
      copied = CopyBuffer(
         hVol,
         0,
         1,
         20,
         volatilityATRBuffer
      );


   if(copied <= 0)
      return false;



   for(int i=0;i<copied;i++)
      averageATR += volatilityATRBuffer[i];


   averageATR /= copied;



   return(
      atr >=
      averageATR * multiplier
   );

}



//==================================================
// MARKET STATE
//==================================================

bool IsLowVolatility()
{

   return(
      GetATRPoints() < 30
   );

}



bool IsNormalVolatility()
{

   double p =
      GetATRPoints();


   return(
      p >= 30 &&
      p < 150
   );

}



bool IsExtremeVolatility()
{

   return(
      GetATRPoints() >= 300
   );

}



#endif