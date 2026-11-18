// XAU_AI_PRO v1.2.9
#ifndef HANDLEREGISTRY_MQH
#define HANDLEREGISTRY_MQH

//==================================================
// v1.2.207 (11/11/2026) - P1.3602: O NUMERO DO HANDLE NAO DIZ O QUE E
//
// MEDIDO no journal de 11/11/2026, build v1.2.206, grafico XAUUSD,H1:
//   15:13:07.851 [ATR] IDENTIDADE ERRADA | XAUUSD | doHandle=4053.760000 |
//        daSerie=13.828547 | falhas=1 | usaHandleAgora=SIM
//   15:42:44.302 [ATR] LEITURA SUSPEITA | XAUUSD | ATR=4053.660000 |
//        preco=3990.88 | ATR%=101.57 | handle=10 | barsCalc=60457 |
//        barrasSerie=60457 | devolvido=0.0
//   15:42:44.303 [ATR] SERIE ASSUME | XAUUSD | doHandle=4053.66 |
//        daSerie=13.89 | ATR%serie=0.35 | devolvido=daSerie
// O handle do ATR respondia 4053.76 e 4053.66 - e NAO era o preco: era a
// MEDIA MOVEL do ouro H1, a mesma familia que o proprio journal publica em
//   [SIGNAL] NEUTRO | XAUUSD | EMA50=4053.52 EMA200=4050.64  (16:00:06.353)
//   [SIGNAL] NEUTRO | XAUUSD | EMA50=4067.46 EMA200=4053.47  (09:00:00.248)
// barsCalc=60457 = barrasSerie=60457 prova que a serie e a H1 do PROPRIO
// ouro: o que mudou foi o INDICADOR que o numero passou a designar.
//
// A troca e simetrica e tem prova directa no mesmo ficheiro:
//   15:43:16.186 [TREND] LEITURA SUSPEITA | XAUUSD | EMA=22.07831 | bid=3990.99
//        (o handle da EMA a devolver um valor de escala de ATR)
//   15:45:15.206 [ATR]   LEITURA SUSPEITA | USDGEL | ATR=12808.552100
//   15:46:36.474 [TREND] LEITURA SUSPEITA | AAPL   | EMA=12808.55205
//        (o MESMO numero, igual ate a 5a casa, lido por duas caches que o
//         julgam dois indicadores diferentes)
//
// CAUSA: cada IndicatorRelease() devolve o numero ao espaco de handles do
// programa e o MT5 reutiliza-o no iATR/iADX/iRSI/iMA seguinte. As caches
// (ATR, ADX, RSI, TREND) guardam SO O NUMERO, portanto depois de uma
// reciclagem continuam a pedir CopyBuffer a um indicador que ja nao e o seu.
// Quem liberta handles neste EA, medido por leitura: ValidationChecklist
// (iATR+iADX+iRSI+iEMA criados e libertados de imediato), TrendFilter
// (liberta e recria a EMA), ATRCacheDrop, ADXCacheDrop, RSICacheDrop,
// TrendCacheDrop, SignalCore, ADX, RSI, MultiTimeframeFilter, TrendStrength,
// DecisionEngine e CircuitBreaker.
//
// CORRECCAO (esta versao): passa a existir um registo NUMERO -> DONO. Quem
// cria um handle registra-o com a chave que o identifica (tipo|simbolo|
// periodo|parametro) e quem o usa volta a perguntar de quem ele e. Se o
// numero foi reciclado por outro modulo, a chave deixa de bater e a cache
// deita fora a entrada SEM libertar nada (o numero ja nao lhe pertence) e
// cria um handle novo. Nenhum limite, lote, alvo, stop, spread, preco, RR,
// regra de entrada ou de saida, ou parametro de risco e alterado: muda
// apenas QUANDO uma cache aceita o numero que tem em maos.
//==================================================

#define XAI_HANDLE_REG 1024

int    g_xaiHRegNum[XAI_HANDLE_REG];
string g_xaiHRegKey[XAI_HANDLE_REG];
int    g_xaiHRegCount = 0;

// v1.2.211 (13/11/2026) - P1.3640: A COLISAO DE HANDLE DEIXA DE SER MUDA.
// Medido no journal de 13/11/2026, build v1.2.210, EM ROTINA e nao so no
// arranque (oito minutos depois do reload):
//   14:36:43.431 [ATR] HANDLE RECICLADO | USDCZK | numero=10 |
//        esperado=ATR|USDCZK|16385|14
//   14:36:43.537 [ATR] HANDLE RECICLADO | USDSEK | numero=10 | ...
// O registo fazia o seu trabalho (descartava em vez de servir valor alheio),
// mas nao dizia QUEM tinha ficado com o numero, por isso a causa continuava
// invisivel e o ciclo repetia-se. Passa a sair uma linha por colisao, com as
// duas chaves, limitada a XAI_HREG_COLISAO_MAX para nao inundar o journal.
// Isto e LOG: nao muda nenhuma decisao, nenhum limite, nenhum lote, alvo, stop,
// spread, preco ou regra de entrada/saida.
#define XAI_HREG_COLISAO_MAX 200
int    g_xaiHRegColisoes = 0;

// Toda a troca de dono de um numero passa por aqui: escreve as duas chaves no
// journal (limitado por XAI_HREG_COLISAO_MAX) e nao decide nada. Existe para a
// pergunta "quem ficou com o handle 10" deixar de ser hipotese.
void XAI_HandleCollision(const int handle, const string antigo, const string novo)
{
   if(antigo == novo)
      return;

   if(g_xaiHRegColisoes >= XAI_HREG_COLISAO_MAX)
      return;

   g_xaiHRegColisoes++;

   Print("[HANDLE] COLISAO DE NUMERO | numero=", handle,
         " | dono_anterior=", antigo,
         " | novo_dono=", novo,
         " | colisoes=", g_xaiHRegColisoes);
}

//==================================================
// Chave de identidade de um indicador neste programa.
//==================================================
string XAI_HandleKey(const string kind, const string symbol,
                     const ENUM_TIMEFRAMES tf, const int param)
{
   return kind + "|" + symbol + "|" + IntegerToString((int)tf) + "|" +
          IntegerToString(param);
}

int XAI_HandleIndex(const int handle)
{
   if(handle == INVALID_HANDLE)
      return -1;

   for(int i = 0; i < g_xaiHRegCount; i++)
      if(g_xaiHRegNum[i] == handle)
         return i;

   return -1;
}

// O ultimo que registra o numero e o dono. Uma reciclagem troca o dono sem
// que ninguem tenha de ser avisado - e e por isso que a pergunta "e meu?"
// se faz no momento do uso e nao no momento da criacao.
bool XAI_HandleRegister(const int handle, const string key)
{
   if(handle == INVALID_HANDLE)
      return false;

   int idx = XAI_HandleIndex(handle);

   if(idx >= 0)
   {
      XAI_HandleCollision(handle, g_xaiHRegKey[idx], key);
      g_xaiHRegKey[idx] = key;
      return true;
   }

   if(g_xaiHRegCount >= XAI_HANDLE_REG)
      return false;   // registo cheio: a cache cai para o comportamento antigo

   g_xaiHRegNum[g_xaiHRegCount] = handle;
   g_xaiHRegKey[g_xaiHRegCount] = key;
   g_xaiHRegCount++;

   return true;
}

bool XAI_HandleIsOurs(const int handle, const string key)
{
   int idx = XAI_HandleIndex(handle);

   // Numero desconhecido = nao se assume que seja nosso. A cache recria.
   if(idx < 0)
      return false;

   return (g_xaiHRegKey[idx] == key);
}

void XAI_HandleForget(const int handle)
{
   int idx = XAI_HandleIndex(handle);

   if(idx < 0)
      return;

   for(int j = idx; j < g_xaiHRegCount - 1; j++)
   {
      g_xaiHRegNum[j] = g_xaiHRegNum[j + 1];
      g_xaiHRegKey[j] = g_xaiHRegKey[j + 1];
   }

   g_xaiHRegCount--;
   g_xaiHRegNum[g_xaiHRegCount] = INVALID_HANDLE;
   g_xaiHRegKey[g_xaiHRegCount] = "";
}

// Toda a libertacao passa por aqui: o numero sai do registo no mesmo instante
// em que e devolvido ao terminal, para nenhuma cache o poder reclamar depois.
bool XAI_HandleRelease(const int handle)
{
   if(handle == INVALID_HANDLE)
      return false;

   XAI_HandleForget(handle);

   return IndicatorRelease(handle);
}

#endif
