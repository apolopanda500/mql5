// XAU_AI_PRO v1.2.9
#ifndef AICONNECTOR_MQH
#define AICONNECTOR_MQH

#include "../Core/Config.mqh"            // self-contained: inputs (MaxPredictionAgeSec etc.)
#include "../Monitoring/EventEmitter.mqh" // self-contained: EventAIBlock (guard idempotente)

//==================================================
// AI CONNECTOR
// XAU_AI_PRO v1.2.9
// MULTI SYMBOL
//
// RESPONSABILIDADE:
// - Ler prediction_<SYMBOL>.json
// - Validar o sÃƒÂ­mbolo
// - Armazenar os dados da IA
// - Disponibilizar getters
//
// OBS:
// A funÃƒÂ§ÃƒÂ£o AITradeAllowed() NÃƒÆ’O fica aqui.
// Ela pertence ao AIEngine.mqh.
//==================================================


//==================================================
// GLOBAL AI STATE
//==================================================

string AI_Symbol="";
string AI_Signal="";

double AI_Price=0.0;
double AI_BuyProbability=0.0;
double AI_SellProbability=0.0;
double AI_Score=0.0;
double AI_Confidence=0.0;

// Metadados do modelo (Contrato A v2 - ETAPA 15.3)
string AI_ModelVersion="";
string AI_ModelID="";
string AI_FeatureHash="";
double AI_InferenceMs=0.0;
string AI_TimestampUTC="";

// ETAPA 15.3: governanca completa (publicados pelo pipeline Python)
string AI_Algorithm="";
string AI_TrainDate="";
string AI_DatasetVersion="";
string AI_Metrics="";

// Staleness (ETAPA 15.3): idade da previsao em segundos.
// AI_IsStale=true quando a previsao excedeu MaxPredictionAgeSec
// e foi descartada (fail-safe -> fallback local / veto).
bool   AI_IsStale=false;
double AI_AgeSeconds=-1.0;


//==================================================
// RESET AI STATE
//==================================================

void ResetAIState()
{
   AI_Symbol="";
   AI_Signal="";

   AI_Price=0.0;
   AI_BuyProbability=0.0;
   AI_SellProbability=0.0;
   AI_Score=0.0;
   AI_Confidence=0.0;

   AI_ModelVersion="";
   AI_ModelID="";
   AI_FeatureHash="";
   AI_InferenceMs=0.0;
   AI_TimestampUTC="";

   AI_Algorithm="";
   AI_TrainDate="";
   AI_DatasetVersion="";
   AI_Metrics="";

   AI_IsStale=false;
   AI_AgeSeconds=-1.0;
}


//==================================================
// NORMALIZE AI SYMBOL
// Converte o sÃƒÂ­mbolo do broker no nome base usado
// pelo pipeline Python. Ex: GOLD# -> XAUUSD,
// BTCUSD# -> BTCUSD, XAUUSDc -> XAUUSD.
//==================================================

string NormalizeAISymbol(string symbol)
{
   if(symbol=="")
      return "";

   StringTrimLeft(symbol);
   StringTrimRight(symbol);

   string up=symbol;
   StringToUpper(up);

   // Remove sufixos de classe: #, c, m, . , _i, .pro
   //
   // v1.2.95 (02/11/2026) - P1.83b: StringFind removia o sufixo em QUALQUER
   // posicao. MEDIDO no journal desta sessao: USDCHF, USDCAD, USDCNH, USDCZK,
   // USDCLP e USDCOP viravam "USD" porque o "C" do prefixo USD era o primeiro
   // encontrado. O gateway pedia symbol=USD e o parser recusava o arquivo
   // correto com "SIMBOLO DIFERENTE" - 6 dos 15 graficos ficavam sem IA mesmo
   // com Data\prediction_<SIMBOLO>.json valido. Agora so remove quando o
   // sufixo esta no FIM do nome.
   string suffixes[] = {"#", "C", "M", ".PRO", "_I", "."};
   for(int i=0; i<ArraySize(suffixes); i++)
   {
      int lenSuf=StringLen(suffixes[i]);
      int lenUp=StringLen(up);
      if(lenUp>lenSuf && StringSubstr(up, lenUp-lenSuf)==suffixes[i])
      {
         up=StringSubstr(up, 0, lenUp-lenSuf);
         break;
      }
   }

   // Mapeamento de aliases -> nome base do Python
   if(up=="GOLD" || up=="XAU")
      return "XAUUSD";

   if(up=="BTC")
      return "BTCUSD";

   if(up=="ETH")
      return "ETHUSD";

   return up;
}


//==================================================
// PARSE PREDICTION JSON
//==================================================
// Um parser para as DUAS fontes. O gateway devolve JSON e o arquivo tambem;
// se cada um tivesse o seu corpo, a divergencia entre os dois apareceria
// como "o gateway funciona, o arquivo nao" — sem nenhuma pista do porque.
//
// `json` e o corpo ja lido; `esperado` e o simbolo normalizado, para recusar
// previsao de outro ativo.
bool ParsePredictionJSON(string json, string esperado, bool logOnce)
{
   //================================================
   // EXTRACT VALUES
   //================================================

   // v1.2.95 (02/11/2026) - P1.83: o parser lia a chave "esperado", que
   // NAO existe em nenhum prediction_*.json. Resultado medido no journal de
   // 02/11: 55 linhas "[AI] JSON INVALIDO | SYMBOL=..." para arquivos que
   // existiam e eram validos, e a IA ficava offline mesmo com o arquivo
   // presente. O contrato publicado pelo pipeline usa "symbol"; e essa a
   // chave que este parser passa a ler. Nenhuma decisao muda: antes a
   // funcao devolvia false SEMPRE que o arquivo era lido.
   string jsonSymbol=
      ExtractJSON(
         json,
         "symbol"
      );


   string jsonSignal=
      ExtractJSON(
         json,
         "signal"
      );


   string jsonPrice=
      ExtractJSON(
         json,
         "price"
      );


   string jsonBuy=
      ExtractJSON(
         json,
         "buy"
      );


   string jsonSell=
      ExtractJSON(
         json,
         "sell"
      );


   string jsonScore=
      ExtractJSON(
         json,
         "score"
      );


   string jsonConfidence=
      ExtractJSON(
         json,
         "confidence"
      );

   string jsonModelVersion=
      ExtractJSON(
         json,
         "model_version"
      );

   string jsonModelID=
      ExtractJSON(
         json,
         "model_id"
      );

   string jsonFeatureHash=
      ExtractJSON(
         json,
         "feature_hash"
      );

   string jsonInferenceMs=
      ExtractJSON(
         json,
         "inference_ms"
      );

   string jsonTimestampUTC=
      ExtractJSON(
         json,
         "timestamp_utc"
      );

   // ETAPA 15.3: campos de governanca (publicados pelo pipeline)
   string jsonAlgorithm=
      ExtractJSON(
         json,
         "algorithm"
      );

   string jsonTrainDate=
      ExtractJSON(
         json,
         "train_date"
      );

   string jsonDatasetVersion=
      ExtractJSON(
         json,
         "dataset_version"
      );

   string jsonMetrics=
      ExtractJSON(
         json,
         "metrics"
      );


   //================================================
   // VALIDATE SYMBOL
   //================================================

   if(jsonSymbol=="")
   {
      if(logOnce)
         Print(
            "[AI] JSON INVALIDO | SYMBOL=",
            esperado
         );

      return false;
   }


   //================================================
   // VALIDATE SIGNAL
   //================================================

   if(jsonSignal=="")
   {
      if(logOnce)
         Print(
            "[AI] JSON INVALIDO | SIGNAL=",
            esperado
         );

      return false;
   }


   //================================================
   // SYMBOL MATCH
   // Aceita o sÃƒÂ­mbolo exato ou o normalizado
   // (ex: arquivo prediction_XAUUSD.json com esperado=XAUUSD
   //  ÃƒÂ© aceito para o sÃƒÂ­mbolo do broker GOLD#).
   //================================================

   bool esperadoOk =
      StringCompare(jsonSymbol, esperado, false)==0;

   if(!esperadoOk)
   {
      if(logOnce)
         Print(
            "[AI] SIMBOLO DIFERENTE | REQUEST=",
            esperado,
            " | JSON=",
            jsonSymbol
         );

      return false;
   }


   //================================================
   // UPDATE GLOBAL STATE
   //================================================

   AI_Symbol=
      esperado;


   AI_Signal=
      jsonSignal;


   AI_Price=
      StringToDouble(
         jsonPrice
      );


   AI_BuyProbability=
      StringToDouble(
         jsonBuy
      );


   AI_SellProbability=
      StringToDouble(
         jsonSell
      );


   AI_Score=
      StringToDouble(
         jsonScore
      );


   AI_Confidence=
      StringToDouble(
         jsonConfidence
      );


   //================================================
   // FALLBACK CONFIDENCE
   //================================================

   if(AI_Confidence<=0.0)
      AI_Confidence=
         AI_Score;

   //=================================
   // ATUALIZAR METADADOS (Contrato A v2)
   //=================================

   AI_ModelVersion=
      jsonModelVersion;

   AI_ModelID=
      jsonModelID;

   AI_FeatureHash=
      jsonFeatureHash;

   AI_InferenceMs=
      StringToDouble(
         jsonInferenceMs
      );

   // v1.2.95 (02/11/2026) - P1.83: o pipeline publica "timestamp" (ISO) e
   // este parser procurava apenas "timestamp_utc". Sem o fallback, um JSON
   // real ficava sem data e a verja de frescura nao tinha como reprovar.
   if(jsonTimestampUTC=="")
      jsonTimestampUTC=ExtractJSON(json,"timestamp");

   AI_TimestampUTC=
      jsonTimestampUTC;

   // ETAPA 15.3: governanca completa
   AI_Algorithm      = jsonAlgorithm;
   AI_TrainDate      = jsonTrainDate;
   AI_DatasetVersion = jsonDatasetVersion;
   AI_Metrics        = jsonMetrics;


   //================================================
   // STALENESS CHECK (ETAPA 15.3)
   // Idade da previsao = TimeGMT() - timestamp_utc.
   // Previsao mais antiga que MaxPredictionAgeSec (>0)
   // e descartada como indisponivel (fail-safe):
   // o AIEngine usa o fallback local e o RequireAIJSON=true
   // bloqueia novas entradas (fail-closed).
   //================================================

   AI_IsStale=false;
   AI_AgeSeconds=-1.0;

   if(jsonTimestampUTC!="")
   {
      string ts=jsonTimestampUTC;

      if(StringLen(ts)>=19)
      {
         // ISO "yyyy-mm-ddTHH:MM:SS[.ffffff][+HH:MM]"
         StringReplace(ts,"-",".");
         StringReplace(ts,"T"," ");
         ts=StringSubstr(ts,0,19);

         datetime predUtc=StringToTime(ts);

         if(predUtc>0)
         {
            long age=(long)TimeGMT()-(long)predUtc;

            if(age<0)
               age=0;

            AI_AgeSeconds=(double)age;

            if(MaxPredictionAgeSec>0 && age>(long)MaxPredictionAgeSec)
            {
               AI_IsStale=true;

               // P2.00: 129 linhas no dia a repetir "VENCIDA" com idades
               // diferentes; passa a 1x/h por CONTA e por simbolo.
               // P2.03: a chave levava o simbolo, logo os 15 graficos emitiam
               // ate 15 linhas por hora (15 simbolos x 1/h) para a MESMA
               // causa - a IA sem preco, que e uma so para a conta inteira.
               // A chave passa a ser da CONTA e a linha continua a nomear o
               // simbolo: nenhuma informacao de decisao se perde, so deixa de
               // ser repetida uma vez por simbolo.
               if(AccountLogGatePodeImprimir("ai_stale", 3600))
               Print(
                  "[AI] PREDICAO VENCIDA | ",
                  esperado,
                  " | AGE=",
                  (string)age,
                  "s > LIMIT=",
                  IntegerToString(MaxPredictionAgeSec),
                  "s"
               );

               ResetAIState();
               return false;
            }
         }
      }
   }


   //================================================
   // LOG
   //================================================

   if(logOnce)
      Print(
         "[AI] PYTHON | ",
         AI_Symbol,
         " | ",
         AI_Signal,
         " | PRICE=",
         DoubleToString(
            AI_Price,
            _Digits
         ),
         " | BUY=",
         DoubleToString(
            AI_BuyProbability,
            2
         ),
         "%",
         " | SELL=",
         DoubleToString(
            AI_SellProbability,
            2
         ),
         "%",
         " | SCORE=",
         DoubleToString(
            AI_Score,
            2
         ),
         " | CONF=",
         DoubleToString(
            AI_Confidence,
            2
         ),
         "%"
      );


   return true;
}


//==================================================
// PERIODO DO GRAFICO, NO NOME DO MODELO
//==================================================
// O MT5 entrega o periodo como `ENUM_TIMEFRAMES` (um numero: 16385 = H1), e o
// backend nomeia os artefatos por texto (`XAUUSD_H1`). Sem esta traducao, a
// consulta seria `?timeframe=16385` e o gateway nao acharia modelo nenhum —
// recusa correta, mas com o motivo errado: o operador culparia o modelo.
//
// Os nomes sao os do `TIMEFRAMES_VALIDOS` do backend (M5, M15, H1, H4). Um
// periodo que nao estiver nessa lista nao tem modelo e a resposta recusa com
// o motivo certo.
//
// `PERIOD_CURRENT` (0) NAO E TRADUZIDO: ele significa "o que esta no grafico",
// e inventar um nome seria exatamente o "nenhum valor pode ser presumido". O
// EA usa `Period()` ja resolvido, que o MT5 preenche com o valor concreto.

string PeriodLabel()
{
   ENUM_TIMEFRAMES p = (ENUM_TIMEFRAMES)Period();

   if(p == PERIOD_M5)
      return "M5";

   if(p == PERIOD_M15)
      return "M15";

   if(p == PERIOD_H1)
      return "H1";

   if(p == PERIOD_H4)
      return "H4";

   if(p == PERIOD_M1)
      return "M1";

   if(p == PERIOD_M30)
      return "M30";

   if(p == PERIOD_D1)
      return "D1";

   // Fora da lista de modelos: devolve o nome do enum, que o gateway recusa
   // com motivo. Vazio seria pior — a consulta sairia sem timeframe nenhum e o
   // backend escolheria um.
   return EnumToString(p);
}


//==================================================
// FETCH VIA GATEWAY (WebRequest)
//==================================================
// POR QUE ISTO EXISTE (medido em 05/10/2026)
// ==========================================
// O conector lia `Data\prediction_<SIMBOLO>.json`. Medido nesta maquina: essa
// pasta NAO EXISTE. O backend tem 25 modelos publicados e responde por HTTP, mas
// ninguem escreve o arquivo — entao o EA vivia sem sinal, e sem erro visivel
// porque "arquivo ausente" e um caminho previsto do codigo.
//
// Com `AIUseGateway`, o EA passa a ler do proprio backend: uma fonte de
// verdade so, com os 25 modelos que mediram inferencia real.
//
// SEMPRE VOLTA `false` QUANDO O GATEWAY NAO RESPONDE
// --------------------------------------------------
// A falha aqui cai no arquivo, nunca em sinal inventado. Um `WebRequest` que
// devolve corpo vazio e sucesso HTTP seria o pior caso: o EA receberia
// `signal=""` e `AIBuyAllowed` devolveria false — por sorte, e nao por
// desenho. A funcao verifica que veio JSON antes de aceitar.
//
// LIMITE DE TAXA
// --------------
// `AIPollSeconds` e o intervalo entre consultas. Sem ele, `AIBuyAllowed` seria
// chamado a cada tick e o gateway receberia centenas de requisicoes por
// segundo, com a inferencia real (que carrega o `.pkl` e monta 25 features)
// por baixo. A previsao antiga de 15 s e melhor do que perder o tick.

bool FetchPredictionFromGateway(
   string symbol,
   string timeframe,
   string &json
)
{
   string url = AIGatewayUrl;
   if(StringLen(url) == 0)
      return false;

   // v1.2.30 (30/10/2026) - P1.3/P-01: backoff de transporte. MEDIDO na
   // v1.2.29, janela 17:05:00-17:08:30: 51 linhas "AI GATEWAY | WebRequest
   // falhou | erro 4014" em 3,5 min (~900/hora nos 16 graficos), porque cada
   // grafico chama o gateway 1x/min e o WebRequest esta DESABILITADO no
   // terminal (P-01, decisao do dono). 4014/4060/5200/5202 sao erro de
   // CONFIGURACAO: nao se curam sozinhos durante a sessao, e insistir so gasta
   // requisicao e journal. Depois de 3 falhas duras seguidas o conector para de
   // tentar por AI_GW_COOLDOWN_SEC (o temporizador VOLTA a tentar, para o EA
   // retomar sozinho quando o dono habilitar o WebRequest). O arquivo local
   // Data\prediction_<SIMBOLO>.json continua a ser a fonte de fallback.
   static datetime s_gwCooldownUntil = 0;
   static int      s_gwHardFails     = 0;
   const int       AI_GW_COOLDOWN_SEC = 1800;

   // v1.2.130 (03/11/2026) - P2.21: 401/403 e erro de CREDENCIAL, nao de
   // rede. MEDIDO no journal do expert entre 23:37:09 e 23:46:19 de 03/11,
   // com a v1.2.128 nos 15 graficos: a linha "[AI] GATEWAY | HTTP 401"
   // saia 1x/min por GRAFICO (15/min, cerca de 900/h) porque a unica janela
   // era um static de 60 s POR INSTANCIA, e token recusado nao se cura
   // sozinho durante a sessao. O transporte ja tinha backoff (4014/4060);
   // a credencial nao tinha nenhum. Agora 3 recusas seguidas armam o MESMO
   // tipo de cooldown de 1800 s: o conector para de bater a porta e volta a
   // tentar 30 min depois, sozinho, quando o operador corrigir o token.
   // O fallback fica identico: FetchPredictionFromGateway devolve false e
   // LoadAIPrediction cai em Data\prediction_<SIMBOLO>.json, exactamente o
   // mesmo caminho de quando o 401 acontecia a cada 30 s.
   static datetime s_gwAuthCooldownUntil = 0;
   static int      s_gwAuthFails         = 0;
   const int       AI_GW_AUTH_COOLDOWN_SEC = 1800;

   if(TimeCurrent() < s_gwAuthCooldownUntil)
      return false;

   // Cooldowns: transporte (AI_GW_COOLDOWN_SEC, 4014/4060/5200/5202) e
   // credencial (AI_GW_AUTH_COOLDOWN_SEC, 401/403).

   if(TimeCurrent() < s_gwCooldownUntil)
      return false;

   // Simbolo e timeframe no endereco: o gateway le por query string
   // (`/api/ai/predict?symbol=&timeframe=`), e um simbolo vazio e recusa
   // com motivo la — o mesmo "nenhum simbolo pode ser presumido".
   StringReplace(url, "{symbol}", symbol);
   StringReplace(url, "{timeframe}", timeframe);
   if(StringFind(url, "symbol=") < 0)
      url = url + "?symbol=" + symbol + "&timeframe=" + timeframe;

   char post[], result[];

   // O MIDDLEWARE DO GATEWAY LE SO `Authorization: Bearer` (medido em
   // `fastapi_gateway.py`, linha 103: `auth != f"Bearer {API_TOKEN}"`).
   // Enviar `X-Gateway-Token` — como eu fiz na primeira versao — produz
   // "token invalido" com HTTP 401 mesmo com o token CORRETO no input. E a
   // quarta vez que os dois lados falam cabecalhos diferentes pelo mesmo nome.
   string headers = "Content-Type: application/json\r\n";
   if(StringLen(AIGatewayToken) > 0)
      headers = headers + "Authorization: Bearer " + AIGatewayToken + "\r\n";

   string payload = "{}";
   StringToCharArray(payload, post, 0, StringLen(payload), CP_UTF8);

   ResetLastError();
   int status = WebRequest(
      "POST",
      url,
      headers,
      AIRequestTimeoutMs,
      post,
      result,
      headers
   );

   if(status == -1)
   {
      int err = GetLastError();
      // -401 e o caso que mais importa: URL nao autorizada em
      // Ferramentas > Opcoes > Expert Advisors. E erro de CONFIGURACAO do
      // operador, nao do codigo, entao a mensagem diz exatamente o que fazer.
      // v1.2.18 (29/10/2026): a falha do WebRequest era MUDA quando o erro
      // nao era 401/406 (ex.: 4014/4060 = WebRequest desabilitado nas opcoes
      // do terminal). O journal so mostrava "AI LOAD" e "AI INVALID JSON",
      // escondendo a causa real. Agora o codigo do erro aparece 1x por minuto.
      static datetime lastWrErrLog = 0;

      // v1.2.30: 4014/4060/5200/5202 = configuracao do terminal. Aviso 1x/30 min
      // (era 1x/min) e contador de falhas duras que arma o cooldown do topo.
      bool hardErr   = (err == 4014 || err == 4060 || err == 5200 || err == 5202);
      int  errLogSec = (hardErr ? 14400 : 300);

      if(hardErr)
        {
         s_gwHardFails++;
         if(s_gwHardFails >= 3)
            s_gwCooldownUntil = TimeCurrent() + AI_GW_COOLDOWN_SEC;
        }

      if(TimeCurrent() - lastWrErrLog >= errLogSec && AccountLogGatePodeImprimir("aigw_" + IntegerToString(err), 21600))   // P1.90: 1x/6h por CONTA e por codigo
        {
         lastWrErrLog = TimeCurrent();
         // v1.2.88 (02/11/2026) - P1.75: tag [AI] e texto curto. 4014/4060
         // continuam a ser WebRequest desabilitado em Opcoes > Expert Advisors;
         // 5200/5202 = URL nao autorizada.
         // v1.2.129 (03/11/2026) - P2.20: 4014 tem DUAS causas (URL fora da
         // lista OU checkbox "Allow WebRequest" desligado) e publicar so a
         // primeira mandava o operador ao lugar errado. E a mesma doenca que o
         // P2.19 corrigiu no script de diagnostico. 4060 e dominio ausente;
         // 5200/5202 sao rede/URL. O codigo continua a ser impresso.
         string motivoWr = "erro nao classificado";
         if(err == 4014)
            motivoWr = "NAO PERMITIDO (URL fora da lista, ou checkbox 'Allow WebRequest' desligado)";
         else if(err == 4060)
            motivoWr = "URL nao adicionada a lista (dominio ausente)";
         else if(err == 5200)
            motivoWr = "URL invalida para o WebRequest";
         else if(err == 5202)
            motivoWr = "URL nao permitida pela lista";
         Print("[AI] GATEWAY falhou | erro=", err, " | ", url, " | ", motivoWr);
        }

      if(err == 401)
         Print("[AI] GATEWAY | URL nao autorizada (-401) | ", url,
               " | Autorize em Ferramentas > Opcoes > Expert Advisors");
      else if(err == 406)
         Print("[AI] GATEWAY | URL nao permitida (-406) | ", url);
      return false;
   }

   // HTTP DE ERRO NAO E PREVISAO (29/10/2026)
   // MEDIDO NESTA MAQUINA: sem `AIGatewayToken` o gateway responde 401 com
   // corpo JSON de erro. Esse corpo tem mais de 10 bytes, entao passava no
   // teste de tamanho abaixo, o parser falhava, o conector caia no arquivo
   // antigo e o journal mostrava apenas "IA indisponivel" — nunca o 401. A
   // causa real (token vazio) ficava invisivel para o operador.
   if(status != 200)
   {
      // v1.2.30: o transporte respondeu (HTTP != 200), logo o WebRequest esta
      // habilitado: zera o backoff de transporte para nao punir token/rota.
      s_gwHardFails     = 0;
      s_gwCooldownUntil = 0;

      // P2.21: credencial recusada (401/403) nao se cura sozinha durante a
      // sessao. Tres recusas seguidas armam o cooldown de credencial; o
      // temporizador volta a tentar, como no backoff de transporte.
      if(status == 401 || status == 403)
        {
         s_gwAuthFails++;
         if(s_gwAuthFails >= 3)
            s_gwAuthCooldownUntil = TimeCurrent() + AI_GW_AUTH_COOLDOWN_SEC;
        }
      else
         s_gwAuthFails = 0;

      static datetime lastStatusLog = 0;
      datetime statusNow = TimeCurrent();

      // v1.2.130 (03/11/2026) - P2.21: o aviso de HTTP != 200 tinha janela de 60 s
// POR PROGRAMA. MEDIDO: 13 graficos x 1 linha/min = ~780 linhas/hora no journal
// com um unico 401 de configuracao, que nao muda de minuto para minuto. O gate
// agora e por CONTA (arquivo em Common, igual ao AccountLogGate dos outros
// avisos): a mesma combinacao tag+status imprime 1x/30 min, venha de quantos
// graficos vier. A janela local sobe para 300 s como segunda barreira.
      if(statusNow - lastStatusLog >= 300 &&
         AccountLogGatePodeImprimir("aigw_http_" + IntegerToString(status), 1800))
      {
         lastStatusLog = statusNow;
         // v1.2.129 (03/11/2026) - P2.20: o transporte respondeu, logo o
         // WebRequest esta LIGADO e a URL esta na lista. Culpar sempre o token
         // (texto fixo "401/403 = token ausente ou invalido") escondia duas
         // causas distintas: token VAZIO e token RECUSADO. Agora a mensagem
         // separa por EVIDENCIA - comprimento do token enviado, codigo HTTP e
         // tamanho do corpo. O VALOR do token nunca e impresso.
         int    nTok   = StringLen(AIGatewayToken);
         string corpoR = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
         int    nCorpo = StringLen(corpoR);
         string motivo = "erro nao classificado";
         if(status == 401 || status == 403)
           {
            if(nTok == 0)
               motivo = "token AUSENTE (input AIGatewayToken vazio)";
            else
               motivo = "token RECUSADO (" + IntegerToString(nTok) +
                        " caracteres enviados; o gateway espera o XAU_GATEWAY_TOKEN do .env)";
           }
         else if(status == 404)
            motivo = "rota inexistente nesse servidor - confira AIGatewayUrl e se algo serve /api/ai/predict nessa porta";
         else if(status == 422)
            motivo = "requisicao recusada pelo servidor (parametros de symbol/timeframe)";
         else if(status >= 500)
            motivo = "backend fora do ar";
         Print("[AI] GATEWAY | HTTP ", status, " | ", url, " | ", motivo,
               " | WebRequest=LIGADO (a chamada SAIU) | corpo=", nCorpo, "B");
         if(nCorpo > 0)
            Print("[AI] GATEWAY | resposta: ", StringSubstr(corpoR, 0, 200));
      }

      return false;
   }

   string corpo = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   s_gwAuthFails = 0;   // P2.21: credencial aceite - o contador de recusas zera

   // Corpo vazio com HTTP 200 e o pior resultado possivel: o EA receberia uma
   // string sem sinal e acharia que a IA foi consultada. Recusa aqui.
   if(StringLen(corpo) < 10)
      return false;

   json = corpo;
   return true;
}


//==================================================
// LOAD AI PREDICTION
//==================================================

bool LoadAIPrediction(string symbol="")
{
   // Log de diagnostico (evita spam a cada tick)
   //
   // v1.2.33 (30/10/2026) - P1.3 rodada 5: era 1x/minuto e, com o gateway
   // inalcancavel (erro 4014) e sem os arquivos Data\prediction_*.json, as
   // tres linhas de diagnostico ("AI LOAD", "AI FILE NOT FOUND",
   // "AI INVALID JSON") somavam ~700 linhas/hora nos 16 graficos - medido em
   // 17:42-17:46 da v1.2.32. O estado que elas descrevem nao muda de minuto
   // para minuto: o arquivo continua ausente ou o JSON continua invalido.
   // Agora 1x/30 min. `logOnce` aqui gateia SOMENTE impressao (as decisoes
   // usam o retorno de ParsePredictionJSON), entao o comportamento de sinal
   // nao muda: so a frequencia do aviso.
   static datetime lastLogTime = 0;
   datetime logNow = TimeCurrent();
   bool logOnce = (logNow - lastLogTime >= 1800);
   if(logOnce)
      lastLogTime = logNow;

   if(symbol=="")
      symbol=_Symbol;

   StringTrimLeft(symbol);
   StringTrimRight(symbol);

   if(symbol=="")
      return false;

   // SÃƒÂ­mbolo normalizado (nome base do pipeline Python)
   string normalized = NormalizeAISymbol(symbol);

   //==================================================
   // FONTE 1: GATEWAY (padrao)
   //==================================================
   // Um limite de taxa por simbolo: `AIBuyAllowed` e chamado a cada tick, e a
   // inferencia real carrega o `.pkl` e monta 25 features. Sem este cache, o
   // gateway receberia centenas de requisicoes por segundo.
   //
   // A previsao com 15 s e melhor do que perder tick perto de um nivel, que e
   // quando o tick importa.
   static string ultimoSimboloConsultado = "";
   static datetime ultimaConsulta = 0;

   if(AIUseGateway)
   {
      if(ultimoSimboloConsultado != normalized ||
         (TimeCurrent() - ultimaConsulta) >= AIPollSeconds)
      {
         string jsonGateway = "";
         if(FetchPredictionFromGateway(normalized, PeriodLabel(), jsonGateway))
         {
            ultimoSimboloConsultado = normalized;
            ultimaConsulta = TimeCurrent();

            if(logOnce)
               Print("[AI] GATEWAY | ", normalized, " | ", PeriodLabel(),
                     " | ", StringLen(jsonGateway), " bytes");

            // O JSON do gateway entra pelo MESMO parser do arquivo. Um
            // formato, um parser: se os dois divergirem, a divergencia aparece
            // num so lugar.
            return ParsePredictionJSON(jsonGateway, normalized, logOnce);
         }

         // Gateway fora do ar: o arquivo e o plano B, e a proxima tentativa
         // acontece no proximo ciclo. Nao ha loop de retentativa aqui — um
         // tick bloqueado esperando HTTP e o pior resultado para quem opera.
      }
      else if(AI_Symbol == normalized)
      {
         // Dentro da janela: a previsao do gateway ainda vale. Devolve sem
         // tocar a rede.
         return true;
      }
   }

   //==================================================
   // FONTE 2: ARQUIVO (fallback e modo legado)
   //==================================================
   string fileName=
      "Data\\prediction_" +
      symbol +
      ".json";

   // Fallback: se o arquivo exato nÃƒÂ£o existe, tenta o nome normalizado
   // (pipeline Python gera prediction_XAUUSD.json, nÃƒÂ£o prediction_GOLD#.json)
   if(!FileIsExist(fileName) && normalized!=symbol)
   {
      string altName=
         "Data\\prediction_" +
         normalized +
         ".json";

      if(FileIsExist(altName))
         fileName=altName;
   }


   // v1.2.111 (03/11/2026) - P1.99: MEDIDO no journal de 03/11 -
   // 250 linhas [AI] LOAD (15 instancias x 2/hora) a repetir o MESMO
   // caminho de ficheiro. A janela passa a ser por CONTA e por simbolo,
   // como ja acontece no [SCANNER]: o texto identico sai 1x/hora no total.
   // P2.00: o caminho do ficheiro nao muda entre leituras - 1x/dia por CONTA
   // e por simbolo em vez de 1x/hora.
   if(logOnce && AccountLogGatePodeImprimir("ai_load_" + symbol, 86400))
   if(logOnce)
      Print(
         "[AI] LOAD | SYMBOL=",
         symbol,
         " | FILE=",
         fileName
      );


   ResetLastError();


   //================================================
   // FILE EXISTS
   //================================================

   if(!FileIsExist(fileName))
   {
      if(logOnce)
         Print(
            "[AI] FILE EM FALTA | ",
            fileName
         );

      return false;
   }


   //================================================
   // OPEN FILE
   //================================================

   int file=
      FileOpen(
         fileName,
         FILE_READ |
         FILE_TXT |
         FILE_ANSI |
         FILE_SHARE_READ | FILE_SHARE_WRITE
      );


   if(file==INVALID_HANDLE)
   {
      if(logOnce)
         Print(
            "[AI] FILE ERRO | ",
            symbol,
            " | ERROR=",
            GetLastError()
         );

      return false;
   }


   //================================================
   // READ JSON
   //================================================

   string json="";


   while(!FileIsEnding(file))
   {
      string line=
         FileReadString(file);

      json+=line;
   }


   FileClose(file);


   //================================================
   // VALIDATE JSON
   //================================================

   if(json=="")
   {
      if(logOnce)
         Print(
            "[AI] JSON VAZIO | ",
            symbol
         );

      return false;
   }


   //================================================
   //================================================
   // PARSE (mesmo caminho do gateway)
   //================================================

   return ParsePredictionJSON(json, normalized, logOnce);
}


//==================================================
// EXTRACT JSON VALUE
//==================================================

string ExtractJSON(
   string json,
   string key
)
{
   string search=
      "\"" +
      key +
      "\"";


   int start=
      StringFind(
         json,
         search
      );


   if(start<0)
      return "";


   start=
      StringFind(
         json,
         ":",
         start
      );


   if(start<0)
      return "";


   start++;


   int length=
      StringLen(
         json
      );


   //================================================
   // SKIP SPACES
   //================================================

   while(start<length)
   {
      int ch=
         StringGetCharacter(
            json,
            start
         );


      if(
         ch==' ' ||
         ch=='\t' ||
         ch=='\r' ||
         ch=='\n'
      )
      {
         start++;
      }
      else
      {
         break;
      }
   }


   //================================================
   // CHECK QUOTED VALUE
   //================================================

   bool quoted=false;


   if(
      start<length &&
      StringGetCharacter(
         json,
         start
      )=='"'
   )
   {
      quoted=true;
      start++;
   }


   int end=start;


   //================================================
   // READ VALUE
   //================================================

   if(quoted)
   {
      while(
         end<length &&
         StringGetCharacter(
            json,
            end
         )!='"'
      )
      {
         end++;
      }
   }
   else
   {
      while(
         end<length &&
         StringGetCharacter(
            json,
            end
         )!=',' &&
         StringGetCharacter(
            json,
            end
         )!='}' &&
         StringGetCharacter(
            json,
            end
         )!='\r' &&
         StringGetCharacter(
            json,
            end
         )!='\n'
      )
      {
         end++;
      }
   }


   if(end<=start)
      return "";


   string value=
      StringSubstr(
         json,
         start,
         end-start
      );


   StringTrimLeft(
      value
   );


   StringTrimRight(
      value
   );


   StringReplace(
      value,
      "\"",
      ""
   );


   return value;
}


//==================================================
// BUY SIGNAL CHECK
//==================================================

bool AIBuyAllowed(
   string symbol=""
)
{
   if(symbol=="")
      symbol=_Symbol;


   if(
      AI_Symbol!=symbol
   )
   {
      if(
         !LoadAIPrediction(
            symbol
         )
      )
      {
         return false;
      }
   }


   if(
      AI_Signal=="UNAVAILABLE" ||
      AI_Signal=="ERROR" ||
      AI_Signal=="HOLD"
   )
   {
      Print(
         "[AI] BLOCK | Estado nao executa vel: ",
         AI_Signal,
         " | ",
         symbol
      );
      EventAIBlock(symbol, "AI_" + AI_Signal);  // ETAPA 15.6
      return false;
   }

   return(
      AI_Signal=="BUY" ||
      AI_Signal=="STRONG_BUY"
   );
}


//==================================================
// SELL SIGNAL CHECK
//==================================================

bool AISellAllowed(
   string symbol=""
)
{
   if(symbol=="")
      symbol=_Symbol;


   if(
      AI_Symbol!=symbol
   )
   {
      if(
         !LoadAIPrediction(
            symbol
         )
      )
      {
         return false;
      }
   }


   if(
      AI_Signal=="UNAVAILABLE" ||
      AI_Signal=="ERROR" ||
      AI_Signal=="HOLD"
   )
   {
      Print(
         "[AI] BLOCK | Estado nao executa vel: ",
         AI_Signal,
         " | ",
         symbol
      );
      EventAIBlock(symbol, "AI_" + AI_Signal);  // ETAPA 15.6
      return false;
   }

   return(
      AI_Signal=="SELL" ||
      AI_Signal=="STRONG_SELL"
   );
}


//==================================================
// GET AI CONNECTOR SIGNAL
//==================================================

string GetAIConnectorSignal()
{
   return AI_Signal;
}


//==================================================
// GET AI SCORE
//==================================================

double GetAIScore()
{
   return AI_Score;
}


//==================================================
// GET AI CONFIDENCE
//==================================================

double GetAIConfidence()
{
   return AI_Confidence;
}


//==================================================
// GET AI BUY PROBABILITY
//==================================================

double GetAIBuy()
{
   return AI_BuyProbability;
}


//==================================================
// GET AI SELL PROBABILITY
//==================================================

double GetAISell()
{
   return AI_SellProbability;
}


//==================================================
// GET AI PRICE
//==================================================

double GetAIPrice()
{
   return AI_Price;
}


//==================================================
// GET AI SYMBOL
//==================================================

string GetAISymbol()
{
   return AI_Symbol;
}


//==================================================
// CHECK DATA FOR SYMBOL
//==================================================

bool AIDataForSymbol(
   string symbol
)
{
   if(symbol=="")
      return false;


   return(
      AI_Symbol==
      symbol
   );
}


//==================================================
// END
//==================================================

//==================================================
// GET AI META STRING (ETAPA 15/16 - ModelGovernance)
// Retorna "" com seguranca quando o campo nao existe.
// O parse atual do JSON NAO expoe metadados de modelo;
// portanto retornamos "" (honesto) e o ModelGovernance
// fica NAO-governado (fail-open, comportamento v1.2.0).
// Quando o pipeline Python publicar estes campos no JSON,
// basta adicionar a leitura aqui.
//==================================================
string GetAIMetaString(string key)
{
   // STATUS_DO_MODELO: derivado (producao) - politica v1.2.0
   if(key == "MODEL_STATUS")
      return "production";

   // Campos publicados pelo pipeline Python (Contrato A v2 - ETAPA 15.2.3)
   if(key == "MODEL_VERSION")
      return AI_ModelVersion;

   if(key == "MODEL_ID")
      return AI_ModelID;

   if(key == "FEATURE_HASH")
      return AI_FeatureHash;

   if(key == "INFERENCE_MS")
      return DoubleToString(AI_InferenceMs, 2);

   if(key == "TIMESTAMP_UTC")
      return AI_TimestampUTC;

   // ETAPA 15.3: governanca completa (publicados pelo pipeline Python)
   if(key == "ALGORITHM")
      return AI_Algorithm;

   if(key == "MODEL_TRAIN_DATE")
      return AI_TrainDate;

   if(key == "DATASET_VERSION")
      return AI_DatasetVersion;

   if(key == "MODEL_METRICS")
      return AI_Metrics;

   // Campo desconhecido -> "" (honesto)
   return "";
}

#endif
