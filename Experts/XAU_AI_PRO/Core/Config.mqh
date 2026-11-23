// XAU_AI_PRO v1.2.9
#ifndef CONFIG_MQH
#define CONFIG_MQH

// P2.11 (03/11/2026): GetATR() vive em Indicators/VolatilityFilter.mqh e e
// chamada mais abaixo, em NoiseDistancePointsForRisk() e no envelope de risco
// stopless. Sem esta declaracao, compilar ESTE ficheiro isolado (Ctrl+F7)
// dava 4 erros "undeclared identifier 'GetATR'"; dentro do EA o pre-scan do
// TU encontrava a definicao e escondia o defeito. ATR.mqh traz so as
// assinaturas do ATR, portanto nao arrasta os globais do filtro.
#include "../Indicators/ATR.mqh"

//==================================================
// GERAL
//==================================================
input bool   AutoTrade          = true;
input long   MagicNumber        = 2026001;
input string TradeComment       = "XAU_AI_PRO";

//==================================================
// FONTE DA IA
//==================================================
// `AIConnector.mqh` Historically lia `Data\prediction_<SIMBOLO>.json`. Medido em
// 05/10/2026: essa pasta NAO EXISTE na maquina - o backend responde por HTTP e
// nunca escreve arquivo. Resultado: o EA rodava sem sinal nenhum, e nao havia
// log de erro porque a ausencia de arquivo e um caminho previsto.
//
// AIUseGateway=true passa a chamar o proprio backend, que e a FONTE DE VERDADE
// dos 25 modelos publicados. O arquivo continua disponivel como fallback: se o
// gateway estiver fora do ar, `AIUseGateway` volta a true sozinho no proximo
// ciclo, e o arquivo so e lido se a tentativa HTTP falhar.
//
// A URL tem que estar AUTORIZADA em
// Ferramentas > Opcoes > Expert Advisors > "Allow WebRequest for listed URL".
// Sem isso o MT5 devolve -401 e o EA registra "gateway recusou" uma vez por
// minuto no log - e segue operando pela leitura de arquivo.
input bool   AIUseGateway       = true;
// v1.2.133 (04/11/2026) - P-01c: a porta por omissao apontava para o servidor
// ERRADO. MEDIDO em 04/11/2026 com o gateway no ar: 127.0.0.1:9001 responde
// 401 a qualquer /api/ai/predict porque e o servidor MCP EMBUTIDO do MT5
// (config\assistant.ini), nao o gateway; o gateway escuta em 9011
// (XAU_GATEWAY_PORT) e responde 200 ao GET autenticado com o
// XAU_GATEWAY_TOKEN do .env. O 401 que o journal repetia desde 03/11 era o
// endereco errado lido como credencial recusada. A omissao passa a 9011, que e
// a porta que o backend usa quando XAU_GATEWAY_PORT nao esta definido.
input string AIGatewayUrl       = "http://127.0.0.1:9011/api/ai/predict";
input string AIGatewayToken     = "";

//==================================================
// MAPEIO DE SIMBOLO PARA O GATEWAY (v1.2.217 - 23/11/2026)
//==================================================
// DECISAO DO DONO (23/11/2026): "mapeio no EA".
//
// MEDIDO nesta corretora, 23/11/2026, com o gateway em 9027 e o token da
// sessao: GET /api/ai/predict?symbol=GOLD devolve
//   {"ok":true,"available":true,"signal":"BUY","confidence":46.1,
//    "model":"MULTI_METALS - GOLD 1H"}
// e o MESMO pedido com symbol=XAUUSD devolve
//   {"ok":false,"available":false,
//    "reason":"MT5 nao devolveu candles para XAUUSD H1 (no_candles_for_symbol)"}
// Ou seja: o gateway publica GOLD e NAO publica XAUUSD.
//
// O EA JA pede GOLD nesta corretora: NormalizeAISymbol (AI/AIConnector.mqh,
// D-218) so converte GOLD->XAUUSD quando o simbolo XAUUSD existe no terminal,
// e aqui nao existe (o metal chama-se GOLD). A prova do "available=false"
// registada antes vinha de um pedido XAUUSD feito por FORA do EA (sonda).
//
// Esta input e o mapeio explicito, para o dia em que o nome tiver de ser
// forcado sem recompilar: pares `DE=PARA` separados por `;`, aplicados DEPOIS
// de todas as regras acima. Vazio (omissao) nao altera nada.
//   exemplo: "XAUUSD=GOLD"  manda sempre GOLD quando o EA calculou XAUUSD.
input string AIGatewaySymbolAlias = "";
// Segundos entre uma consulta e outra. 15 s alinha com o ciclo do motor e com
// a leitura de latencia: mais rapido e consumo sem ganho, mais lento e o EA
// age sobre previsao velha.
input int    AIPollSeconds      = 15;
// Tempo maximo de espera da resposta HTTP.
//
// MEDIDO em 05/10/2026, nos 25 modelos validados pela rota real:
//   primeiro acesso ao par   2096 ms   (carrega o `.pkl` do disco)
//   acesso seguinte          144 ms   (o `_CACHE` do backend segura)
//   pior caso no lote        450 ms   (apos o cache aquecer)
//
// O limite e 15 s, e nao 5: em disco frio o carregamento do artefato passa de
// 2 s, e um timeout curto faria o EA cair no fallback de arquivo - que tambem
// nao existe - justamente na primeira consulta, que e a que importa.
//
// NINGUM TIMEOUT PODE SER MENOR QUE O CUSTO REAL. Cortar o tempo para "ir
// mais rapido" troca um sinal atrasado por um sinal ausente.
input int    AIRequestTimeoutMs = 15000;

//==================================================
// APP EXTERNO (ponte app -> EA)
//==================================================
// Canal por arquivo em FILE_COMMON (`Common\Files`), o MESMO caminho que o
// backend ja le para o heartbeat. Contrato completo em
// `Integration/ExternalBridge.mqh`.
//
// Fechada por padrao, e com DUAS condicoes para abrir: chave ligada E token
// com 8+ caracteres. Arquivo em Common nao identifica quem escreveu, entao
// sem token isto viraria um controle remoto aberto na maquina.
//
// Somente acoes de leitura (ping/status/heartbeat). Nenhuma acao daqui
// envia, modifica ou fecha ordem; nada aqui altera risco.
input bool   EnableExternalBridge = false;
input string ExternalBridgeToken  = "";

//==================================================
// MCP (Model Context Protocol) - MT5 Build 6060+
//==================================================
// Expõe funcionalidades do EA para agentes de IA externos (Claude Code, Codex, etc.)
// via MCP. Operações de leitura (risco, IA, saúde, conta, posições) são permitidas
// quando o token é válido. Operações de execução requerem confirmação explícita.
// Todas as ações via MCP são gravadas no AuditLog para rastreabilidade.
//
// Requer: Ferramentas > Opções > Expert Advisors > "Allow WebRequest for listed URL"
//         (apenas se o servidor MCP usar HTTP para receber comandos externos)
// v1.2.126 - P2.16 (03/11/2026): o token do servidor MCP embutido estava escrito
// aqui ("xau-mcp-local-2026"), portanto publico no GitHub, e o servidor arrancava
// com ele nos 15 graficos - medido em [MCP] servidor ativo ... as 21:44:59.
// Segredo nao se versiona: o default passa a vazio, o servidor passa a ser opt-in
// e o token define-se no input do grafico. O valor antigo e recusado em runtime
// por XAU_AI_PRO.mq5 (linha "token literal publico recusado").
input bool   EnableMCPServer      = false; // Ligar/desligar servidor MCP (opt-in: exige token privado)
input string MCPServerToken       = "";     // Token de autenticação (8+ caracteres)
//==================================================
// COPILOT HUB (Adaptador dentro do EA) - v1.2.192
//==================================================
// Ponte com o Cloud MCP Hub do Copilot Ultra: o hub faz GET /mt5/pull com
// este token e devolve ordens no contrato {"acao":...}. O EA executa via
// CExecutionEngine (RiskCenter unico gate de risco). Fechado por padrao.
input bool   EnableCopilotHub = false;
input string CopilotHubURL     = "https://copilot-ultra-3d-hub.onrender.com/mt5/pull";
input string CopilotHubToken  = "";

//==================================================
// RISCO
//==================================================
// LOTE FIXO REMOVIDO (29/10/2026). Nao existem mais `UseRiskManagement` nem
// `LotSize`: o lote e SEMPRE dinamico (ver CalculateDynamicLot em
// Core/ExecutionEngine.mqh). Os dois inputs antigos ficavam no .set e no
// perfil e davam a impressao de que lote fixo ainda existia.


input double RiskPercent        = 0.5;

// v1.2.191 (09/11/2026) - P1.3515: o default compilado passa a ser o valor
// APROVADO em operacao. Estava 10.0 enquanto os 15 graficos corriam 3.0: um
// reattach que omitisse esta input caia no default e o teto diario saltava de
// 379,67 (3,00% de 12 655,63) para 600,00, porque o teto efetivo e
// MIN(MaxDailyLossUsd, saldo * MaxDailyLossPercent/100). O default e rede de
// seguranca, nao sugestao: 10.0 -> 3.0 (aperta, nao afrouxa) e fica igual ao
// valor da DECISAO DO DONO de 09/11/2026 15:01 (opcao A: 600 USD + 3,0%).
// `0` desliga o teto percentual e deixa mandar so o teto em USD.
input double MaxDailyLossPercent= 3.0;

// v1.2.35 (30/10/2026) - P1.2b: teto da perda do dia em DINHEIRO.
// MEDIDO: com `MaxDailyLossPercent=10` e saldo 12 351,78 o limite diario era
// 1 235 USD, contra meta de lucro de 20-40 USD/dia - assimetria de ~30:1. Um
// dia ruim custava o equivalente a dezenas de dias bons. O numero em % nao
// segue a expectativa do dono: ele escala junto com o saldo.
// O limite efetivo passa a ser o MENOR entre o de % e o de USD - mesma regra
// ja usada em `MaxTotalRiskOpenUsd`. `0` desliga este teto e mantem so o de %.
// DECISAO DO DONO (09/11/2026 15:01, opcao A) - 60.0 -> 600.0.
// MEDIDO antes de tocar no numero (OrcamentoDiarioPerda, abaixo):
//   teto efetivo = MIN(MaxDailyLossUsd, saldo * MaxDailyLossPercent/100).
//   Com saldo 12 655,63 e MaxDailyLossPercent=3.0 o teto percentual e 379,67,
//   logo o teto efetivo sobe de 60,00 para 379,67 (3,00% da banca), NAO 600.
//   Para o teto ser literalmente 600 seria preciso MaxDailyLossPercent >= 4,75.
// O DONO escolheu A para manter o teto diario dentro do MANDATO (drawdown 6%).
// `0` continua a desligar este teto e a manter so o de %.
input double MaxDailyLossUsd    = 600.0;
// Q-071 (DONO, 06/11 23:42) - 15.0 -> 50.0. MEDIDO antes de tocar no numero:
// esta input governa DUAS guardas de capital e nao uma.
//   * Management/EquityProtection.mqh CheckEquityProtection(): DRAWDOWN
//     CRITICO aos MaxDrawdownPercent -> EmergencyCloseAll(), e DRAWDOWN ALTO
//     aos MaxDrawdownPercent*0.8.
//   * Core/RiskEngine.mqh:88-90 e :210-215: a escada de reducao de risco
//     (100% / 75% / 50% / 25%) e tambem derivada de MaxDrawdownPercent.
// Com 15.0 o fecho de emergencia da conta disparava aos 1.895,45 USD (15% de
// 12.636,32) e a escada aos 10,05% e 4,95%. Com 50.0 passa a disparar aos
// 6.318,16 USD e a escada aos 33,5% e 16,5% - o EA corre a risco cheio por
// 3,3x mais drawdown. Custo aceito por escrito pelo DONO em DEMO. Em conta
// REAL o criterio de aceitacao continua a ser o do CICLO_FINAL: drawdown
// realizado abaixo de 8% no forward de 30 dias, sem alterar criterio.
input double MaxDrawdownPercent = 6.0;
input double MinEquityPercent   = 10.0;  // Equity minima (% do balance) para operar

input double MinFreeMargin      = 2.0;   // Margem livre minima (moeda da conta). 23/11/2026: era 10.0 - a conta real tem margin_free 7.43 e o EA recusava toda entrada nova

input int    MaxTradesPerDay    = 100;
input int    MaxOpenPositions   = 20;   // 23/11/2026: autorizado pelo DONO (forward real, multi-simbolo) - teto de 20 posicoes simultaneas

//==================================================
// F2.2 (v1.2.180) - TETO DE EXPOSICAO EM MARGEM (D-066) - DESLIGADO
//==================================================
// `MaxOpenPositions` e um tecto de CONTAGEM. Estas duas inputs medem MARGEM:
// somam a margem exigida pelas posicoes do EA e comparam com o equity.
//
// CORRECCAO DE 06/11/2026 21:28 - a leitura inicial desta sessao ("nao existe
// limite de exposicao somada na conta") estava ERRADA. O CMD refutou-a com
// codigo executavel, e eu verifiquei linha a linha:
//   * `MaxTotalRiskPercent = 10.0`      -> Config.mqh:336
//   * `MaxTotalRiskOpenUsd = 60.0`      -> Config.mqh:353
//   * `RiscoAbertoUSD()` soma entrada->SL -> Config.mqh:1219
//   * envelope = min(saldo*10%, 60 USD)  -> Config.mqh:1318-1322
//   * recusa com `RISK_ENVELOPE_FULL`    -> ExecutionEngine.mqh:686-701
// Ou seja: o RISCO ABERTO SOMADO ja era limitado. O que nao existia era uma
// medida de MARGEM. Sao grandezas diferentes, mas o envelope existente e muito
// mais apertado (60 USD de risco contra 2527 USD de margem a 20%), portanto e
// ele que manda na pratica e esta guarda praticamente nunca seria a primeira a
// disparar.
//
// v1.2.181 (D-067): a guarda passa a medir a MARGEM DA CONTA, lida de
// ACCOUNT_MARGIN - valor que o servidor calcula e publica por conta - e nao a
// soma das posicoes do MagicNumber. Duas objecoes registadas no canal ficam
// fechadas por esta troca de fonte, e nenhuma delas era de estilo:
//   (1) o somatorio por posicao filtrava por MagicNumber, portanto no dia em que
//       o F2.8 der magic unico por grafico o teto FRAGMENTA-SE em 13 tetos de
//       20% do capital e o limite deixa de existir na pratica (ponto (b) do CMD);
//   (2) o somatorio por posicao chamava OrderCalcMargin por simbolo e devolvia
//       -1 se UM exotico nao fosse calculavel, recusando a CONTA inteira por um
//       simbolo (ponto (3b) do DELTA). ACCOUNT_MARGIN e uma leitura unica.
// Por isso fica LIGADA por omissao: compara dois numeros publicados pelo
// servidor (margem usada e equity) em vez de somar um calculo proprio.
//
// O RISCO ABERTO SOMADO (entrada -> SL) e limitado pelo envelope que JA existia
// - MaxTotalRiskPercent / MaxTotalRiskOpenUsd / RiscoAbertoUSD(), recusado com
// RISK_ENVELOPE_FULL - e esse NAO foi alterado por este patch: continua a
// filtrar por MagicNumber e a correccao do filtro depende de decisao do CMD.
input bool   EnableExposureCap  = true;
input double MaxExposurePercent = 20.0;

// v1.3.0 (Etapa 3): quando o risco configurado exige lote abaixo do
// minimo do broker. true = opera no minimo (comportamento antigo,
// risco real maior que o configurado). false = estrito, bloqueia.
input bool   AllowMinLotOverride = true;

//==================================================
// LIMITE DE SPREAD - EM PORCENTAGEM DO PRECO (08/10/2026)
//==================================================
// MEDIDO na conta 391773676 (XMGlobal-MT5 14), terminal aberto, com o EA
// operando BTCUSD H4:
//
//   simbolo   point    spread_preco   spread_pts   limite de 50 pts =   bloqueia?
//   BTCUSD    0.01        40,00000       4000,0           0,50000        SIM
//   ETHUSD    0.01         3,00000        300,0           0,50000        SIM
//   USDSEK    0.00001      0,01550       1579,0           0,00050        SIM
//   GOLD      0.01         0,57000         57,0           0,50000        SIM
//   USDCNH    0.0001       0,00430         43,0           0,00500        nao
//   EURUSD    0.00001      0,00019         19,0           0,00050        nao
//
// 4 de 12 simbolos BLOQUEADOS com spread NORMAL. E o OURO, por 57 contra 50:
// um limite em pontos crus e fragil ate no metal que da nome ao projeto.
//
// A CAUSA: `point` varia mil vezes entre um forex e o BTCUSD. "50 pontos"
// vale $5,00 no BTCUSD e $0,0005 no EURUSD. O mesmo numero nao pode servir
// as duas coisas.
//
// A CAUSA SEGUNDA: o mapa por simbolo nao ACERTAVA para nenhum dos tres que
// ele nomeava. Os nomes tinham `#` no fim (`GOLD#:350`) e a comparacao e
// `StringCompare(sym, symbol, false)` com `symbol = _Symbol`, que e `GOLD` -
// sem `#`. Entao o mapa caia sempre no fallback. (O `CircuitBreaker.mqh:153`
// ja tinha um comentario sobre isso; o comentario estava certo e o codigo
// continuou errado.)
//
// A CORRECAO: o limite passa a ser PORCENTAGEM DO PRECO, e o
// `GetMaxSpread` continua devolvendo PONTOS - derivados do preco e do `point`
// do proprio simbolo. Entao os SEIS lugares que comparam
// (`SymbolValidator:123`, `ValidationEngine:90`, `SpreadFilter:91` e `:145`,
// `SmartExecution:334` e `:341`) nao mudam uma linha, e a unidade do broker
// deixa de importar.
//
// FOLGA MEDIDA com 0,6% de fallback (spread real em % do preco):
//   USDSEK 0,158% -> 3,8x   ETHUSD 0,121% -> 5,0x   USDCNH 0,064% -> 9,4x
//   BTCUSD 0,049% -> 12,3x  NZDUSD 0,055% -> 10,8x  GOLD 0,014% -> 43,6x
// Todos passam, e o mais apertado ainda tem 3,8x antes de a trava fechar.
input double MaxSpreadPct       = 0.6;
// Limites POR SIMBOLO, tambem em porcentagem. Formato "SIMBOLO:pct".
// Sem `#`: o nome e o que o terminal escreve, e `_Symbol` nao tem sufixo.
// Simbolos nao listados usam MaxSpreadPct.
input string MaxSpreadPctBySymbol = "";

//==================================================
// GET MAX SPREAD PCT - a porcentagem do simbolo
//==================================================
double GetMaxSpreadPct(string symbol="")
{
   if(symbol == "")
      symbol = _Symbol;

   string list = MaxSpreadPctBySymbol;
   StringTrimLeft(list);
   StringTrimRight(list);
   if(list != "")
   {
      string entries[];
      int n = StringSplit(list, ',', entries);
      for(int i = 0; i < n; i++)
      {
         string kv[];
         int k = StringSplit(entries[i], ':', kv);
         if(k == 2)
         {
            string sym = kv[0];
            StringTrimLeft(sym);
            StringTrimRight(sym);
            string val = kv[1];
            StringTrimLeft(val);
            StringTrimRight(val);
            // Comparacao sem `#`: `_Symbol` nunca tem sufixo, e era exatamente
            // o sufixo que fazia o mapa nunca casar (medido acima).
            if(StringCompare(sym, symbol, false) == 0)
            {
               double pct = StringToDouble(val);
               if(pct > 0.0)
                  return pct;
            }
         }
      }
   }
   return(MaxSpreadPct > 0.0 ? MaxSpreadPct : 0.6);
}

//==================================================
// GET MAX SPREAD - em PONTOS, derivado do preco
//==================================================
// A UNIDADE CONTINUA SENDO PONTO, porque os seis leitores ja comparam com
// `spread = (ask-bid)/point`. O que muda e de onde o numero vem: em vez de
// "50 pontos" escrito a mao, e a porcentagem do preco convertida no `point`
// daquele simbolo.
double GetMaxSpread(string symbol="")
{
   if(symbol == "")
      symbol = _Symbol;

   double pct = GetMaxSpreadPct(symbol);
   if(pct <= 0.0)
      return(50.0);

   double ask  = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   // Sem ficha do simbolo nao ha preco nem point: nao se chora o limite, e
   // nao se inventa um numero. O fallback e a mesma 50 pontos de antes.
   if(point <= 0.0)
      return(50.0);
   if(ask <= 0.0)
      ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(ask <= 0.0)
      return(50.0);

   double limitePreco = ask * pct / 100.0;
   double limitePts   = limitePreco / point;
   if(limitePts <= 0.0)
      return(50.0);

   // Teto e piso em PONTOS, para o limite nao virar absurdo em nenhum dos
   // extremos: 1 ponto no minimo (nunca "spread 0"), e 100.000 no maximo.
   if(limitePts < 1.0)
      return(1.0);
   if(limitePts > 100000.0)
      return(100000.0);
   return(limitePts);
}
input int    Slippage           = 5;

//==================================================
// ORDER RETRY v1.2.0
// Parametros centralizados de retry de ordens.
//==================================================
input int    RetryMaxAttempts       = 5;
input int    RetryBaseDelayMs       = 100;
input double RetryDelayMultiplier   = 2.0;
input int    RetryMaxDelayMs        = 2000;
input int    RetryMaxSlippage       = 50;
input int    RetrySlippageIncrement = 2;


//==================================================
// STOP
//==================================================
input int StopLossPoints        = 300;
input int TakeProfitPoints      = 600;

//----------------------------------------------
// RISCO por operacao em DINHEIRO (decisao do dono, 08/10/2026)
//----------------------------------------------
// MEDIDO na conta 391773676: `StopLossPoints=300` e PONTOS CRUOS, e ponto nao
// e dinheiro. No GOLD (point 0,01) dava US$ 3,00; no EURUSD (point 0,00001)
// dava US$ 3,00 tambem; no USDJPY daria US$ 20 e no BTCUSD US$ 0,03. Um
// numero so, quatro riscos diferentes.
//
// E o pior: US$ 3,00 contra um orcamento diario de 5% de US$ 12,13 = US$ 0,61.
// Uma operacao estouraria o limite diario inteiro, que foi exatamente o que
// aconteceu: SELL 0,01 GOLD @ 4152,43 com stop em 4155,43 (+3,00), tocado.
//
// Aqui o risco e em DOLARES e vale para todos os simbolos. `RewardRatio = 1.0`
// deixa alvo e stop iguais (2 por 2, 3 por 3); 2.0 volta ao 1:2 antigo.
// Os inputs em PONTOS continuam existindo como caminho de fuga: se
// `RiskPerTradeUsd <= 0` eles voltam a valer, entao nenhum controle fica sem
// consumidor.
input double RiskPerTradeUsd     = 2.0;   // risco do STOP por operacao, em moeda da conta
input double RewardRatio         = 0.65;  // alvo: 0.65 = TP a 65% da distancia do SL (era 0.5)

//----------------------------------------------
// RISCO EM % DO SALDO + ENVELOPE (29/10/2026)
//----------------------------------------------
// "Lote grande, alvo curto" precisa de risco em DINHEIRO que acompanhe o
// saldo: `RiskPerTradeUsd` e absoluto e nao muda quando a conta muda.
// `RiskPerTradePercent > 0` tem prioridade sobre ele.
//
// `MaxTotalRiskPercent` e o teto do risco SOMADO das posicoes abertas do EA
// (faixa pedida: 5 a 10%). Quando o envelope enche, `RiscoPorTradeUsd()`
// devolve 0 e a execucao RECUSA a nova entrada em vez de passar do teto.
// ATENCAO: risco por trade alto multiplicado por 50 posicoes abertas estoura
// o envelope rapido. Com alvo curto o stop costuma ser atingido antes do
// alvo; o envelope existe para que isso nao vire conta zerada.
input double RiskPerTradePercent = 0.50;   // % do saldo por operacao (0 = usa RiskPerTradeUsd)
input double MaxTotalRiskPercent = 0.50;   // teto do risco aberto somado (% do saldo). 11/11/2026 P0: era 10.0; com 0.50 o envelope fica igual ao risco por trade (0,50% = 63,32 hoje) e escala com a banca - para N posicoes simultaneas use N*0.50

// TETO ABSOLUTO EM USD DO RISCO ABERTO (v1.2.32 - 30/10/2026) - P1.1
// O teto em % acompanha o saldo, e por isso ele CRESCE quando a conta cresce e
// NAO protege contra o que realmente assusta: o numero de posicoes simultaneas.
// Exemplo medido nesta conta (saldo ~12 348): 10% = ~1 235 USD de risco aberto
// somado, contra uma meta diaria de 10-20 USD. Um dia ruim com 10-15 posicoes
// abertas (o EA chega a varrer 11 simbolos por ciclo) pode devolver dezenas de
// vezes a meta.
//
// `MaxTotalRiskOpenUsd > 0` poe um limite em DINHEIRO, que nao depende do
// saldo: o envelope passa a ser o MENOR entre o valor em % e este. 60 USD = 3x
// o topo da meta diaria.
//
// IMPORTANTE (paridade de backtest): com deposito de 200 e 10% de envelope o
// teto em % da 20 USD, portanto ESTE limite nao interfere no backtest de 200
// USD - ele so morde onde o saldo e grande. `0` desliga e volta ao de antes.
input double MaxTotalRiskOpenUsd = 0.0;   // teto do risco aberto somado em USD (0 = so o de %). 11/11/2026 P0: era 60.0 e cortava o risco por trade de 63,32 para 60,00 sem escalar com a banca

//==================================================
// BREAK EVEN
//==================================================
input bool EnableBreakEven      = true;
input int  BreakEvenTrigger     = 50;
input int  BreakEvenOffset      = 10;
// v1.2.16 (29/10/2026): trava de break even medida em R
// MEDIDO com MQL5\Scripts\XAI_TargetProbe.mq5 sobre 30 posicoes reais do EA:
// o alvo ficava em ~1,0 R e o preco andava 0,5 a 1,2 R a favor (MFE), mas o
// resultado realizado saia entre 0,03 e 0,37 R. Causa: ao andar 1 ATR a
// favor, o stop ia para entrada + 10 PONTOS, e qualquer respiro fechava a
// operacao em ~0,1 R. Era o "alvo curto" visto na conta.
// Com a trava em fracao do R da posicao, o lucro travado acompanha a escala
// do stop do proprio trade em vez de um numero fixo de pontos.
input bool   BreakEvenInR       = true;   // gatilho e trava em R, nao em pontos
input double BreakEvenTriggerR  = 0.60;   // anda X R a favor -> trava o stop
input double BreakEvenLockR     = 0.30;   // trava fica X R alem da entrada

//==================================================
// ESCADA DE SAIDA EM DINHEIRO (29/10/2026)
//==================================================
// Regra do operador, em DOLARES:
//   1) entrada sem stop (EnableStoplessEntry);
//   2) lucro >= LadderArmPct (% do saldo) -> stop na ENTRADA (zero a zero);
//   3) lucro >= LadderLockTriggerPct  -> stop no nivel que trava LadderLockPct;
//   4) alvo = LadderTpPct (% do saldo), fecha a posicao inteira.
// Quando EnableMoneyLadder=true esta escada e a UNICA dona de SL/TP: o
// break-even em R, o trailing ATR, o alvo aproximado, a parcial e a saida
// rapida por regime de disparada ficam desligados para nao brigarem pelo
// mesmo stop.
// RISCO POR DESENHO: antes de (2) nao ha stop nenhum; o prejuizo corre ate o
// vigia CheckStoplessEmergency (StoplessEmergencyPoints).
// v1.2.69 (02/11/2026) - P1.55: padrao pedido pelo dono, degrau a degrau -> 5 USD arma o stop na ENTRADA; 7 USD trava 1 USD; 10 USD fecha a posicao inteira. O padrao anterior era 10/5/15/20 e pode ser reposto nas propriedades do EA (sao inputs).
input bool   EnableMoneyLadder    = true;    // escada de saida em dinheiro (USD)
input double LadderArmUsd         = 5.0;     // lucro (USD) que arma o stop na entrada
input double LadderLockUsd        = 1.0;     // lucro (USD) que fica travado
input double LadderLockTriggerUsd = 7.0;     // lucro (USD) que move o stop para LadderLockUsd
input double LadderTpUsd          = 10.0;    // legado: alvo em USD (usado so se LadderTpPct = 0)

// v1.2.214 (13/11/2026) - P1.3643: OS QUATRO DEGRAUS PASSAM A SER PERCENTAGEM
// DO SALDO, LIDA EM CADA PASSAGEM. Pedido do dono: acompanhar a banca atual,
// sempre atualizada, nada fixo, com percentagens certas.
//
// `pct` e por cento do SALDO LIDO AGORA (AccountInfoDouble(ACCOUNT_BALANCE)).
// Nao ha valor guardado em lado nenhum: se a banca subir, o degrau sobe com ela;
// se cair, desce. Ninguem tem de reconfigurar nada.
//
// PORQUE A PERCENTAGEM E A UNIDADE CERTA: o lote nasce de RiskPercent x saldo,
// logo volume e saldo crescem juntos. O que o mercado mede e a DISTANCIA EM
// PRECO do degrau, que vale USD / (volume x valor do ponto). Com o USD
// proporcional ao saldo, essa distancia fica CONSTANTE em qualquer banca - a
// escada vale o mesmo numa conta de 200 e numa de 100.000. Um valor fixo em USD
// faz o contrario: encolhe em pontos a medida que a banca cresce, e foi assim
// que a armadura disparou 9 vezes entre 5,01 e 6,93 USD no dia 13/11.
//
// Os valores por omissao (0,05 / 0,01 / 0,07 / 0,10 por cento) reproduzem
// exactamente o que a v1.2.213 valia numa conta de 10.000 USD: 5 / 1 / 7 / 10.
// `pct = 0` volta ao valor em USD correspondente (LadderArmUsd, LadderLockUsd,
// LadderLockTriggerUsd, LadderTpUsd) - e o rollback, sem recompilar.
input double LadderArmPct         = 0.05;    // % do saldo que arma o stop na entrada
input double LadderLockPct        = 0.01;    // % do saldo que fica travado
input double LadderLockTriggerPct = 0.07;    // % do saldo que move o stop para LadderLockPct
input double LadderTpPct          = 0.10;    // % do saldo que fecha a posicao inteira

// v1.2.213 (13/11/2026) - P1.3642: A ESCADA PASSA A ACOMPANHAR A BANCA.
// PEDIDO DO DONO (13/11): "armar stop na entrada quando passar de 5 USD mas
// dependendo da banca".
// MEDIDO em 13/11/2026 com a banca em 12.810,96 USD: a ARMADURA armou 9 vezes
// no dia, todas entre 5,01 e 6,93 USD de lucro. O gatilho e um numero FIXO em
// USD enquanto o lote cresce com o saldo (RiskPercent 0,5 por cento), logo o
// MESMO numero em USD e uma distancia de preco cada vez MENOR quando a banca
// cresce: 5 USD num lote 0,10 sao ~50 pontos, num lote 0,50 sao ~10 pontos -
// a armadura passa a disparar dentro do ruido e o stop vai para a entrada
// antes de o preco andar. E o mesmo defeito que o v1.2.16 mediu no GBPUSD 0,41
// ("USD sozinho nao serve como gatilho") e que o P1.55 mediu a 1R. A correcao
// agora e a ESCALA, nao o valor: o dono continua a configurar 5 / 1 / 7 / 10.
// Regra: os quatro degraus em USD valem o que esta configurado para uma conta
// de `LadderBalanceRefUsd` e escalam LINEARMENTE com o saldo (saldo/referencia),
// nunca abaixo de 1,0 (banca menor nao aperta a escada) e com tecto de 10x.
// A geometria em PRECO fica identica em qualquer banca - que e a unica coisa
// que o mercado ve e que o stop de emergencia mede. `LadderBalanceRefUsd <= 0`
// desliga a escala e devolve exactamente o comportamento anterior.
input double LadderBalanceRefUsd  = 10000.0; // legado: referencia (USD) do caminho sem percentagem

//==================================================
// RESUMO PARA O OPERADOR (29/10/2026)
//==================================================
// Pedido do dono: "quero entender o que o EA esta fazendo".
//
// O journal prova cada decisao, mas espalhado em dezenas de linhas tecnicas por
// minuto. Monitoring/OperatorBrief.mqh condensa o estado em poucas linhas
// `[RESUMO]`:
//   * quem esta no comando do pipeline (master/standby);
//   * quantas posicoes sao do EA e quantas sao manuais;
//   * quanto o dia rendeu contra a meta efetiva (DailyTargetEffectiveUsd);
//   * em que DEGRAU da escada cada posicao do EA esta, e quanto vale o alvo.
//
// O modulo e SOMENTE LEITURA: nao decide, nao envia ordem e nao altera SL/TP.
// `OperatorBriefSeconds` e o intervalo entre resumos, em segundos.
input bool EnableOperatorBrief    = true;   // imprime o resumo periodico
input int  OperatorBriefSeconds   = 300;    // intervalo do resumo (s)

//==================================================
// TRAILING
//==================================================
input bool   EnableTrailingATR  = true;
input double ATRMultiplier      = 1.2;

//==================================================
// PARCIAL
//==================================================
// `PartialTrigger` esta em PONTOS do input original. MEDIDO 05/10/2026: 150
// pontos e 0,17% no BTCUSD (86.439) e 1,5% no EURUSD (1,125) - a mesma
// configuracao e uma distancia- em um ativo e colada em outro. E a mesma
// armadilha do `XAUUSD`/`GOLD`: o numero e o mesmo, o significado nao.
//
// `PartialTriggerInATR=true` passa a medir em MULTIPLOS DE ATR, que e a
// unica escala que significa a mesma coisa em metais, forex e cripto.
// `false` mantem o comportamento antigo em pontos.
input bool   EnablePartialClose = true;
input int    PartialTrigger     = 150;
input double PartialPercent     = 30.0;
input bool   PartialTriggerInATR = true;
// Quando `PartialTriggerInATR`, este e o multiplicador de ATR que substitui
// `PartialTrigger`. 1,0 = fecha a parte quando o preco percorre 1 ATR a
// favor. Medido: em BTCUSD (ATR ~2.500) isso e 1 ATR; em EURUSD (ATR ~0,006)
// e 0,006 - a mesma leitura de volatilidade, nao a mesma distancia bruta.
input double PartialTriggerATRMult = 1.0;

//==================================================
// TP QUE SO APROXIMA (05/10/2026)
//==================================================
// MEDIDO: o SL se movia (`TrailingStopATR`), o parcial fechava
// (`PartialClose`), mas o TP NUNCA se mexia. O alvo ficava no numero original
// enquanto o preco ia e voltava - e o "quase la e voltou" que o operador
//relsse ao vivo na conta real.
//
// POR QUE SO APROXIMA, E NAO PERSEGUE
// ------------------------------------
// Se o TP perseguisse o preco como o SL, uma oscilacao contra moveria os DOIS
// para baixo, e o alvo que estava quase alcancado se afastaria junto. Com
// `ApproximatesOnly`, o TP so chega mais perto: um degrau que ja foi
// alcancado nunca recua. O preco pode ter recuperado, mas o alvo continua
// valendo - e um alvo que recua deixa de ser alvo.
input bool   EnableDynamicTP     = true;
// Multiplos de ATR que o TP avanca a cada vez. 0,5 = passos curtos e
// frequentes (mais modificacoes); 2,0 = passos largos e raros.
input double TPAproxStepATRMult  = 1.0;
// Fra-o do caminho ate o TP original que o TP pode ter andado. 1.0 = pode
// chegar no alvo original. Abaixo disso, para antes - util quando o alvo
// original era longe demais.
input double TPAproxMaxFraction  = 1.0;

//==================================================
// FILTROS
//==================================================
input bool EnableSpreadFilter      = true;
input bool EnableSessionFilter     = true;
input bool EnableTrendFilter       = true;
input bool EnableVolatilityFilter  = true;
input bool EnableADXFilter         = true;
input bool EnableMTFConfirmation   = true;
input bool EnableNewsFilter        = true;
input bool EnableAIFilter          = true;

//==================================================
// FRESCURA DE DADOS POR SIMBOLO (P1.82 / v1.2.94)
//
// MEDIDO no journal de 02/11: o USDBRL tinha o feed parado desde
// 30/10 20:00 (RSI[1]=37.31 identico as 05:05, 05:31, 20:13, 20:56 e
// 20:57) e produziu 1 771 dos 1 839 sinais do dia - 96,3 por cento de
// todo o ruido do pipeline - sem uma unica leitura que pudesse virar
// operacao. Um preco que nao se mexeu nao e um setup: e um dado morto.
//
// EnableStaleDataGuard: liga a verja de frescura por simbolo no
//   MarketScanner, antes do sinal. Nao altera nenhum outro filtro.
// MaxSymbolTickAgeSec: idade maxima, em segundos, do ultimo tick
//   aceito como preco vivo. 900 s (15 min) deixa passar com folga
//   qualquer sessao normal em H1 e barra feed congelado. 0 = sem
//   limite de idade (so exige que exista tick com hora).
//==================================================
input bool EnableStaleDataGuard    = true;
input int  MaxSymbolTickAgeSec     = 900;

//==================================================
// NEWS FILTER v1.3.0 (Etapa 6)
// Economic Calendar nativo MQL5 com estados
// NEWS_CLEAR/WARNING/BLOCK/ACTIVE, throttle de
// 60s e filtro por moeda.
// NewsCurrencies vazio = auto-derivacao pelo simbolo
// (XAUUSD->USD, EURUSD->EUR+USD). Lista manual tem
// prioridade sobre a auto-derivacao.
//==================================================
input string NewsCurrencies        = "";
input int    NewsImpactThreshold   = 2;        // 1=low, 2=medium, 3=high
input int    NewsMinutesBefore     = 30;
input int    NewsMinutesAfter      = 30;

//==================================================
// OPERAR NOTICIA (29/10/2026)
//==================================================
// Pedido do dono: "ensinar EA operar noticias". Ate aqui o NewsFilter.mqh so
// sabia BLOQUEAR: dentro da janela do evento CanTradeNews() devolvia false e
// o EA ficava fora do mercado.
//
// Agora a noticia e um MODO DE OPERACAO:
//   NEWS_TRADE_BLOCK  -> comportamento antigo (bloquear)
//   NEWS_TRADE_REDUCE -> opera com lote reduzido, referencia e alvo
//                        alargados (padrao): evento anda mais que o normal
//   NEWS_TRADE_FULL   -> opera normal, sem reducao
//
// EnableNewsTrading liga o modulo mesmo com EnableNewsFilter=false, porque o
// grafico atual esta com o filtro desligado - sem isso a noticia seria
// ignorada por completo.
enum ENUM_NEWS_TRADE_MODE
{
   NEWS_TRADE_BLOCK  = 0,   // BLOQUEIA (comportamento antigo)
   NEWS_TRADE_REDUCE = 1,   // OPERA com lote reduzido e alvo alargado
   NEWS_TRADE_FULL   = 2    // OPERA normal (sem reducao)
};

input bool                 EnableNewsTrading   = true;
input ENUM_NEWS_TRADE_MODE NewsTradeMode       = NEWS_TRADE_REDUCE;
input int                  NewsTradeMinImpact  = 3;      // 1=baixo 2=medio 3=alto
input double               NewsTradeLotFactor  = 0.35;   // lote x0,35 na noticia
input double               NewsTradeRiskMult   = 1.60;   // referencia x1,6
input double               NewsTradeTPMult     = 1.30;   // alvo x1,3
input double               NewsTradeMinConf    = 70.0;   // piso de confianca
input bool                 NewsTradeTrendOnly  = true;   // so com tendencia (ADX)
// v1.2.98 (03/11/2026) - P1.87: piso de ADX EXCLUSIVO da trava de noticia.
// MEDIDO 02/11 23:58 no journal (v1.2.93): XAUUSD rejeitado 1x/7 s com
// "noticia sem tendencia clara | ADX=21.9 < 35.0". O ADX usado era o
// DynADXClear, que e o piso de TENDENCIA CLARA do scoring (3h no historico) e
// nao um minimo de "nao esta morto". Ouro passa a maior parte da sessao entre
// ADX 18 e 30, logo o piso 35 bloqueava sempre. Este parametro existe para o
// filtro de noticia exigir apenas "existe direcao", sem reutilizar um limiar
// pensado para premiar tendencia. 0 = comportamento antigo (usa DynADXClear).
input double               NewsTrendMinADX     = 18.0;

//==================================================
// REGIME DE MERCADO: VOLUME + VELOCIDADE (29/10/2026)
//==================================================
// Pedido do dono: com volume alto e preco correndo, o EA tem que EXECUTAR
// RAPIDO e FECHAR no lucro; com volume normal, esperar andar e travar stop.
// "Disparada" = tick volume >= PulseVolumeSpikeMult x a media E deslocamento
// de preco >= PulseVelocityATRMult x ATR na janela de PulseVelocityBars velas.
input bool   EnableMarketPulse          = true;
input int    PulseVolumeLookback        = 20;    // velas da media de volume
input double PulseVolumeSpikeMult       = 1.80;  // volume "alto"
input int    PulseVelocityBars          = 3;     // janela da velocidade
input double PulseVelocityATRMult       = 0.60;  // velocidade minima em ATRs
input double PulseExtremeFactor         = 1.80;  // acima disso = EXTREMO
input double PulseFastArmFactor         = 0.50;  // arma o stop mais cedo
input double PulseFastLockFactor        = 0.80;  // trava mais perto
input double PulseFastLotFactor         = 0.80;  // lote no regime EXTREMO
input double PulseQuickProfitMinUsd     = 10.0;  // lucro minimo p/ sair (USD)
input double PulseQuickProfitBalancePct = 3.0;   // ou este % do saldo, se maior
input double PulseQuickLossUsd          = 12.0;  // 0 = desligado; >0 trava a perda (NUNCA em lucro)
input double PulseQuickProfitMaxUsd    = 50.0;  // teto absoluto da saida rapida (0 = sem teto)
input int    PulseFastLaneSec           = 5;     // cadencia da via rapida (s)

//==================================================
// SIMULACAO PRE-EXECUCAO (29/10/2026)
//==================================================
// MEDIDO: o piso fixo `risk_reward >= 1.0` reprovava todo alvo adaptativo
// menor que o stop (DynTPFactorMin=0,35): as entradas FRACA/BASE nunca
// executavam ("Poor risk/reward"). Os pisos agora sao inputs.
input double MinSimulationRR          = 0.30;   // piso de risco/recompensa
input double MinSimulationExpectancy  = 0.00;   // EP minimo em unidades de R
input double MinSimulationProbability = 0.50;   // probabilidade minima
input bool   SimulationUseConfidence  = true;   // confianca do sinal = probabilidade


//==================================================
// IA
//==================================================
input double MinAIConfidence    = 40.0;   // 11/11/2026 P0: era 60.0. Medido 34,1-48,3 em 16 simbolos -> 0/16 passavam e o EA nao abria nada. Piso 40,0 = teto da confianca de fallback (AIUnavailableConfidenceCap)

//----------------------------------------------
// IA AUSENTE x CONFIANCA (23/10/2026)
//----------------------------------------------
// MEDIDO: quando o gateway nao responde, `GetAIConfidence` caia no fallback
// local e devolvia ate 85 (50 de base + 15 tendencia + 10 RSI + 10 ADX). Com
// 85 o multiplicador de lote era 1,00 e o filtro de IA (piso 50) passava sem
// nenhuma IA existir. O painel dizia "IA", o numero vinha dos indicadores.
//
// `AllowTradeWithoutAI=false` (padrao) faz a ausencia de IA ser MOTIVO DE
// BLOQUEIO para novas entradas: a IA veta, e sem ela nao ha veto - logo nao
// ha entrada. Posicoes ja abertas continuam sendo geridas normalmente.
//
// `true` existe para o Strategy Tester, onde o pipeline Python nao roda.
// Nesse modo o fallback e CAPADO em `AIUnavailableConfidenceCap`, para que o
// numero nao volte a mentir sobre a existencia de uma IA.
input bool   AllowTradeWithoutAI           = false;    // v1.2.186: D-088 #6 (DONO 07/11/2026) OPERAR TODOS

//==================================================
// CONFLITO IA x TECNICO (v1.2.10 - 29/10/2026)
//==================================================
// Problema medido: `GetCombinedSignal` devolvia 0 sempre que o tecnico e a
// IA apontavam lados diferentes. Com um gateway que publica JSON vazio ou
// desatualizado, isso zerava TODA entrada - o EA varria os 11 simbolos,
// logava "No Signal" e nunca chegava ao AllowTrade (zero linhas DECISION
// em 3h de journal). Nao era falta de setup tecnico: era o conflito.
//
// Politica nova: a IA so cancela uma entrada tecnica quando ela e
// CONFIAVEL (score >= AIConflictMinScore) e esta fresca. Fora disso o
// tecnico prevalece e o evento vira log `[AI CONFLICT]`, nunca silencio.
//
// EnableAIConflictResolve=false restaura o comportamento antigo
// (empate = nao operar).
input bool   EnableAIConflictResolve        = true;
input double AIConflictMinScore             = 80.0;
input double AIUnavailableConfidenceCap    = 40.0;

//==================================================
// IA - AUTORIDADE DE SINAL (05/10/2026)
//==================================================
// MEDIDO em 05/10/2026: o `AIEngine` lia `AI_BuyProbability` e
// `AI_SellProbability`, que o backend NAO publica - a rota
// `/api/ai/predict` devolve `prob_buy`/`prob_sell` (0.0 no payload
// canonico) e, sobretudo, um `signal` TEXTUAL ("BUY", "SELL",
// "NEUTRAL", "STRONG_BUY"). O `AI_Signal` nunca era lido para decidir.
//
// Resultado: a IA era so veto e redutor de lote, e o sinal de compra e
// venda vinha do tecnico (EMA+RSI). Ligando isto, a IA passa a DECIDIR -
// que e o que o dono pediu ("a IA pode fazer tudo").
//
// false (padrao) = comportamento anterior: IA veta, tecnico decide. - a
// opcao segura e a que estava valendo antes desta mudanca.
input bool   AIHasSignalAuthority = true;

// Minimo de score para a IA ASSUMIR a decisao, separado do veto.
// `MinAIConfidence` e o piso do veto; este e o piso para mandar.
// 75 = o mesmo valor que `GetCombinedSignal` ja usava para dar autoridade
// a IA sobre o tecnico - o numero nao e novo, so passa a ter nome.
input double AIAuthorityMinScore  = 75.0;

//----------------------------------------------
// IA SEM MODELO PUBLICADO x TECNICO (11/11/2026)
//----------------------------------------------
// ORDEM DO DONO (11/11/2026): "o EA nao pode ser exclusivo para XAUUSD".
// D-088 #6 (07/11/2026) ja tinha decidido "OPERAR TODOS E TUDO".
//
// MEDIDO em 11/11/2026 no forward: o gateway so publica previsao para
// XAUUSD; os outros 15 pares respondem available=false (edge abaixo do
// minimo / folds instaveis). Com `AIHasSignalAuthority=true` e a IA calada,
// `GetCombinedSignal` devolvia 0 SEMPRE, e o scanner registava
// NoSignal=7146 contra sinais=553 - a exclusividade nao era do simbolo,
// era da recusa do gateway a ser lida como "nao operar".
//
// REGRA: "a IA nao tem previsao" e diferente de "a IA diz que nao".
//   * sem previsao publicada -> a IA nao opina: o tecnico decide e o portao
//     de IA nao fecha o simbolo (os outros filtros continuam valendo);
//   * com previsao (mesmo NEUTRAL ou abaixo do piso) -> a IA opina: a
//     autoridade e o veto valem exactamente como antes.
// XAUUSD, que tem modelo, nao muda de comportamento.
//
// false = comportamento antigo: sem previsao, o simbolo nao opera.
input bool   AIFallbackToTechNoPrediction = true;

//==================================================
// MARKET INTELLIGENCE - IQ do mercado (v1.3)
//==================================================
// `EnableMarketIntelligence` liga o sistema de inteligencia de mercado:
//   * Sessoes globais (Sydney, Tokio, Londres, Nova York, Sobreposicao)
//   * Calendario economico nativo do MT5 (CalendarValueLast)
//   * Detecção de fechamento de mercado (fim de semana, feriado, meio dia)
//   * Score de inteligencia 0-100 que ajusta o veto da IA
//   * Bloqueio antes de evento de alto impacto e proximo do fechamento
input bool   EnableMarketIntelligence  = true;

// Score minimo de inteligencia de mercado para operar.
// 0 = desligado (so usa o veto da IA normal).
// 40 = bloqueia quando inteligencia muito baixa (fora de sessao, feriado).
// 60 = bloqueia quando inteligencia baixa ou media-baixa.
input double MinIntelligenceScore    = 0.0;

// Bloquear entrada nos X minutos antes do fechamento da sessao atual.
// 0 = desligado.
input int    BlockPreCloseMinutes      = 15;

// Bloquear entrada nos X minutos antes de evento de alto impacto.
// 0 = desligado.
input int    BlockHighImpactNewsMin    = 15;

// Multiplicador de lote quando inteligencia de mercado e baixa mas nao bloqueia.
// 1.0 = sem mudanca. 0.5 = reduz lote pela metade em inteligencia baixa.
input double LowIntelLotFactor       = 0.5;
// RequireAIJSON=false (padrao): o arquivo
// prediction_<SYMBOL>.json e opcional. Quando ausente,
// o AIEngine usa o fallback local (indicadores/score).
// Necessario para backtest, pois o pipeline Python
// nao roda dentro do Strategy Tester.
// RequireAIJSON=true: exige o JSON do pipeline Python
// para liberar o simbolo (modo producao estrito).
//
// MEDIDO 05/10/2026: com `false`, o EA opera MESMO SEM IA - que e o
// oposto de "operar guiado por IA". Quem quer a IA no comando liga isto.
input bool   RequireAIJSON      = true;

//==================================================
// RISCO - STOP LOSS OBRIGATORIO (05/10/2026)
//==================================================
// MEDIDO na conta real 391773676: uma posicao aberta no MT5 com
// `sl = 0.0` e TP 86.584,30. Sem protecao, uma queda de 2% no BTCUSD
// levava o equity de 11,63 para -5,65 - STOP OUT.
//
// O backend ja recusava ("Stop Loss calculou zero", `auto_engine.py`),
// mas o EA nao: `ExecutionEngine.mqh` calculava o SL e, se o resultado
// fosse 0, seguia com a ordem. Este input fecha essa diferenca.
//
// true = recusa ordem sem SL. Nao existe caso em que desligar seja
// seguro com dinheiro real; existe para backtest, onde o SL as vezes e
// calculado depois.
input bool   RequireStopLoss     = true;

//==================================================
// IA - STALENESS (ETAPA 15.3)
// Idade maxima aceita para o timestamp_utc do
// prediction JSON, em segundos. 0 = verificacao
// desativada. Previsao mais antiga que o limite
// e tratada como INDISPONIVEL (o AIEngine cai no
// fallback local ou bloqueia, conforme politica).
// Padrao 900s = 15 min (~3 candles M5).
//==================================================
input int    MaxPredictionAgeSec = 900;

//==================================================
// KCI v1.2.0
// Parametros centralizados dos indicadores KCI.
//==================================================
input int    KCI_VD_Period        = 14;
input int    KCI_DX_BasePeriod    = 9;
input int    KCI_DX_ZScorePeriod  = 30;
input double KCI_DX_Sensitivity   = 1.5;
input double KCI_DX_MainThreshold = 30.0;


//==================================================
// SESSAO
//==================================================
input int TradeStartHour        = 0;
input int TradeEndHour          = 24;

//----------------------------------------------
// HORAS PROIBIDAS (29/10/2026)
//----------------------------------------------
// Lista de horas do SERVIDOR (TimeCurrent) em que NENHUMA entrada nova e
// aberta. Separadas por virgula. Vazio, "off" ou "none" desliga o veto.
//
// MEDIDO em ai_feedback.csv (402 trades de 24/08 a 29/10/2026):
//   * hora 00 -> 39 trades | WR 43,6% | -27,87
//   * hora 20 -> 19 trades | WR 21,1% | -31,88
//   * o resto   -> 303 trades | WR 78,2% | +79,15
// As duas primeiras horas concentram 59,75 de prejuizo em 14,4% dos trades.
//
// O veto e PROPRIO: vale mesmo com `EnableSessionFilter=false` (padrao), que
// so controla a janela TradeStartHour..TradeEndHour. Posicoes ja abertas
// continuam sendo geridas normalmente.
input string AvoidHoursList     = "0,20";

//----------------------------------------------
// HORAS PROIBIDAS EM GMT (v1.2.23 - 29/10/2026)
//----------------------------------------------
// A lista acima usa hora de SERVIDOR e tem dois defeitos medidos:
//
// 1) NAO DIZ O QUE PARECE DIZER. Este servidor esta em GMT+2 (medido nesta
//    sessao: TimeGMT=01:23 com servidor=03:23). Logo "hora 0" = GMT 22
//    (fecho de NY, fino) e "hora 20" = GMT 18, que e MEIO DA SESSAO DE NOVA
//    IORQUE. Banir GMT 18 em EURUSD/GBPUSD e herdar uma medicao de ouro para
//    o melhor horario desses pares.
// 2) ANDA COM O DST DO BROKER. GMT+2 no inverno e GMT+3 no verao: a MESMA
//    lista bane GMT 22/18 em janeiro e GMT 21/17 em julho. Ela descreve um
//    ponteiro de relogio, nao um horario de mercado.
//
// Abaixo a mesma regra escrita em GMT, que nao muda nunca. O padrao "18,22"
// e o EQUIVALENTE CONGELADO do que a lista antiga faz HOJE (com GMT+2), para
// nao alterar comportamento no dia da atualizacao - o ganho e ela parar de
// derivar em marco e em outubro.
//
// `AvoidHoursByClass` aceita regras por tipo de ativo, formato
// "CLASSE:h1,h2;CLASSE:h1,h2" (METAL, MAJOR, MINOR, EXOTICO, INDICE, CRIPTO).
// Padrao VAZIO de proposito: nenhuma regra nova e inventada sem evidencia.
//
// `EnableAvoidHoursGMT=false` volta ao comportamento antigo (hora de
// servidor) sem apagar nada.
input bool   EnableAvoidHoursGMT = true;
// v1.2.29 (30/10/2026): acrescentado 20 (GMT). MEDIDO em ai_feedback.csv
// (402 trades): a hora de servidor 22 (= GMT 20, com servidor em GMT+2 medido
// nesta sessao) deu 28 trades, WR 53,6% e -14,34. O prejuizo inteiro e o
// NZDUSD (14 trades, -20,28); os outros 6 simbolos naquele horario somam
// +5,94. Acrescentar o 20 tem saldo +14,34 e nao toca no XAUUSD (nenhum
// trade as 22h no registo). Remover o 20 da lista devolve o comportamento
// anterior sem tocar em codigo.
// v1.2.43 (31/10/2026) - P1.15: ACRESCENTADOS 9, 11 e 14 (GMT).
// MEDIDO sobre os 99 560 registos validos de Common\Files\trade_history.csv
// (leitura de 31/10, antes da correcao do TradeLogger no P1.16):
//   hora de servidor 16 (= GMT 11) : 7 449 trades, -11 123 USD
//   hora de servidor 19 (= GMT 14) : 2 083 trades,  -7 576 USD  (PF 0,455)
//   hora de servidor 14 (= GMT  9) : 7 090 trades,  -6 443 USD
//   soma das tres                  : 16 622 trades, -25 141 USD
// As tres melhores horas (GMT 10, 13 e 15) somam +9 765. A lista em vigor
// ("18,20,22" = servidor 23,1,3) protegia horas que quase nao operam: o
// servidor 23 tem 42 trades no registo inteiro. Remover qualquer uma destas
// tres horas devolve o comportamento anterior sem tocar em codigo.
input string AvoidHoursGMT       = "9,11,14,18,20,22";
input string AvoidHoursByClass   = "";

//==================================================
// TRAVA DE CUSTO: spread + comissao vs alvo em US$ (v1.2.25)
//==================================================
// A regra vive em Filters/CostGate.mqh. Aqui ficam apenas os limites para o
// dono enxergar e ajustar sem abrir o modulo.
//
// DIFERENCA PARA MaxSpreadPct
// --------------------------
// `MaxSpreadPct` limita o spread como % do PRECO (spread absurdo).
// `MaxCostPctOfTarget` limita o custo como % do ALVO daquela entrada - a
// pergunta economica: "quanto do lucro que eu espero o custo vai comer?".
//
// Custo = spread (ida e volta, ja embutido) + comissao por lote.
// Sem comissao na conta, deixe `CommissionPerLotUsd = 0` (padrao).
input bool   EnableCostGate      = true;
input double MaxCostPctOfTarget  = 20.0;   // custo maximo como % do alvo (0 = desliga)
input double MaxCostPctOfRisk    = 40.0;   // custo maximo como % do risco (0 = desliga)
input double CommissionPerLotUsd = 0.0;    // comissao ida e volta por lote, em US$
input int    CostGateLogSec      = 300;    // throttle do log [COST] por simbolo

//==================================================
// INDICADORES
//==================================================
input int FastEMA               = 50;
input int SlowEMA               = 200;

input int RSIPeriod             = 14;

//==================================================
// SINAL PULLBACK v1.2.0
// Niveis de RSI (vela fechada) para entrada por pullback:
//  - BUY  exige RSI fechado ABAIXO de RSIPullbackBuy  (dip na tendencia de alta)
//  - SELL exige RSI fechado ACIMA  de RSIPullbackSell (rally na tendencia de baixa)
// Valores 40/60 = mais seletivo (menos sinais, maior qualidade)
// Valores 45/55 = moderado (padrao)
// Valores 50/50 = comportamento antigo (muito permissivo)
//==================================================
input double RSIPullbackBuy     = 45.0;
input double RSIPullbackSell    = 55.0;

input int ATRPeriod             = 14;
input int ADXPeriod             = 14;

input double MinimumADX         = 18.0;

//==================================================
// SCHEDULER v1.2.0
// Agendador interno: intervalo de execucao + shutdown de fim de semana.
//==================================================
input bool   EnableScheduler       = true;
input int    SchedulerIntervalSec  = 60;
input bool   EnableWeekendShutdown = true;

//==================================================
// DATABASE / TELEMETRY v1.2.0
// Integracao com DatabaseManager,
// TradeLogger e Statistics.
//==================================================
input bool   EnableDatabase        = true;
input string DatabasePath          = "XAU_AI_PRO.db";
input bool   EnableTelemetry       = true;


//==================================================
// DATASET
//==================================================
input bool EnableDataset        = true;
input bool SaveDatasetCSV       = true;
input bool EnableBacktestLog    = true;

//==================================================
// DASHBOARD
//==================================================
input bool EnableDashboard      = true;
input bool EnableLogs           = true;
input bool DebugTradeDecision   = true;

//==================================================
// MONITORING & AUDITORIA (ETAPA 6)
// HealthMonitor absorveu o WatchDog (heartbeat dos
// modulos ATR/ADX/RSI/AI/PYTHON/CSV/JSON).
// AuditLog absorveu o FullAudit (registro estruturado
// de entrada/saida por ticket em Data\full_audit.csv).
//==================================================
input bool EnableHealthMonitor   = true;   // HealthMonitor + WatchDog integrado
input int  HealthCheckInterval   = 60;     // segundos entre health checks completos
input int  HealthWatchdogInterval= 120;    // segundos sem heartbeat para contar falha (liveness)
input int  HealthPipelineProgressTimeout= 0;  // 0 = auto (2x cadencia da vela, min WatchdogInterval)
input bool EnableAuditLog        = true;   // Auditoria (decisoes + full audit)
input int  AuditLogMaxSizeMb     = 8;      // v1.2.40 P1.13: rotacao de audit_log.csv (MB, 0 = nunca)
input bool EnableDiagnostics     = true;   // Diagnostico completo no OnInit

//==================================================
// REPLAY & BACKUP (ETAPA 7)
// ReplayEngine: reproduz decisoes/eventos historicos
// sem interferir na execucao real (REPLAY != LIVE).
// BackupManager: snapshots em FILE_COMMON + local,
// com wildcards, manifesto e restauracao validada.
//==================================================
input bool   EnableReplay          = false;  // REPLAY: reproduz historico, bloqueia trades reais
input string ReplayDatasetFile     = "Data\\trades_dataset.csv"; // decisoes (Dataset.mqh export)
input string ReplayOHLCFile        = "Data\\dataset.csv";        // OHLC/tick (DataLogger.mqh)
input string ReplayAuditFile       = "Data\\full_audit.csv";     // entradas/saidas (AuditLog.mqh)
input string ReplaySymbolFilter    = "";     // vazio = todos; ex: "XAUUSD" ou "GOLD#"
input bool   EnableBackupManager   = true;   // Backup automatico dos dados do EA
input int    BackupIntervalMinutes = 60;     // 0 = somente manual (OnInit)
input int    BackupMaxKeep         = 10;     // snapshots mantidos (limpeza automatica)

//==================================================
// BACKTEST ANALYZER & BENCHMARK (ETAPA 8)
// BacktestAnalyzer: registra cada trade do tester
// em BacktestReport.csv e calcula metricas (win rate,
// profit factor, drawdown, sharpe, expectativa).
// BenchmarkEngine: compara estrategias (Technical,
// AI, Hybrid, Ensemble) e elege a melhor.
//==================================================
input bool EnableBacktestAnalyzer = true;   // ANALISE: log + metricas de backtest
input bool EnableBenchmark        = true;   // BENCHMARK: comparacao de estrategias

//==================================================
// NOTIFICATION CENTER (ETAPA 9)
// Camada de observabilidade (Push nativo + Telegram).
// NUNCA bloqueia o trading: falha de notificacao apenas
// conta e registra, sem interferir no fluxo do EA.
//==================================================
input bool   EnableNotifications     = true;   // Central de notificacoes
input bool   NotifyPushEnabled       = true;   // Push nativo MT5 (SendNotification)
input string NotifyTelegramToken     = "";     // Token do bot Telegram (vazio = OFF)
input string NotifyTelegramChatID    = "";     // Chat ID do Telegram
input int    NotifyCooldownSec       = 30;     // cooldown entre mensagens (mesma categoria)
input int    NotifyMaxPerMinute      = 10;     // limite anti-spam global
input bool   NotifyTradeEvents       = true;   // notificar abertura/fechamento
input bool   NotifyErrors            = true;   // notificar erros
input bool   NotifyDrawdown          = true;   // notificar drawdown
input double NotifyDrawdownThreshold = 5.0;    // % minimo de drawdown para alertar
input bool   NotifyHealth            = true;   // notificar falha de HealthMonitor
input bool   NotifyCircuitBreaker    = true;   // notificar Circuit Breaker / SAFE
input bool   NotifyExecutionFailures = true;   // notificar rejeicoes de ordem

//==================================================
// MULTI SYMBOL
//==================================================
input bool EnableMultiSymbol    = true;

input string Symbols="XAUUSD,USDCLP,USDCOP,USDCZK,USDSGD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,USDCHF,USDBRL,USDSEK,USDCNH";   // v1.2.206: USDRUB saiu do default - a exclusao vive em SymbolsExclude

// v1.2.167 (05/11/2026) - P1.130: UNIVERSO DO EA.
// `Symbols` deixou de ser o universo inteiro: e a lista de BASE, por ordem de
// prioridade. MEDIDO em 05/11 as 21:30 na conta 113568614: o Market Watch tinha
// 21 simbolos e `Symbols` tinha 11 - nenhum dos 21 estava fora de `Symbols`, mas
// 10 estavam fora da lista (AMD, MSFT, INTC, NVDA, GOLD, USDCLP, USDCOP, USDCZK,
// USDRUB e USDSGD), e destes ultimos tres tinham grafico aberto no perfil sem
// nunca serem avaliados pela instancia mestre. A instancia mestre percorre
// ActiveSymbols, portanto o universo do EA era um retrato fixo que comecava em
// XAUUSD e nunca acompanhava o que o terminal realmente tem.
// true  = universo = Symbols + Market Watch + simbolo do grafico (universal).
// false = universo = Symbols + simbolo do grafico (comportamento anterior).
input bool   SymbolsFromMarketWatch = false;

// v1.2.206 (11/11/2026): EXCLUSAO DE SIMBOLOS DO UNIVERSO DO EA.
// MEDIDO em 11/11/2026: o USDRUB tem spread estrutural acima de 25% do ATR H1
// e o teto de custo (MaxSpreadPct=0,6% do preco) nunca o deixava passar - era
// um simbolo avaliado em todas as instancias e permanentemente recusado. A
// cura anterior era reanexar grafico a grafico e editar a lista Symbols de
// cada um; com esta input o simbolo sai de TODAS as instancias no arranque
// seguinte, sem tocar em nenhuma outra input e sem reanexar nada.
//
// Formato: lista separada por virgulas. A comparacao e sem distincao de
// maiusculas, sem o sufixo do broker, e aceita SIMBOLO ou SIMBOLO:motivo
// (o motivo e ignorado) - o mesmo criterio de MaxSpreadPctBySymbol.
// Exemplo: "USDRUB" ou "USDRUB,USDCLP".
// Vazio = nenhum simbolo excluido (comportamento anterior a v1.2.206).
input string SymbolsExclude = "USDRUB";

//--------------------------------------------------
// v1.2.206: true quando symbol esta em SymbolsExclude.
// Nao decide nada sobre negociacao: so responde a uma pergunta de
// configuracao, para o universo do EA (Core/SymbolManager.mqh) poder filtrar
// antes de avaliar o simbolo.
//--------------------------------------------------
bool SymbolExcluido(string symbol)
{
   if(symbol == "")
      return false;

   string lista = SymbolsExclude;
   StringTrimLeft(lista);
   StringTrimRight(lista);

   if(lista == "")
      return false;

   string entries[];
   int total = StringSplit(lista, ',', entries);

   for(int i = 0; i < total; i++)
   {
      string item = entries[i];
      StringTrimLeft(item);
      StringTrimRight(item);

      if(item == "")
         continue;

      // Aceita SIMBOLO e SIMBOLO:motivo - so o nome conta.
      string kv[];
      int k = StringSplit(item, ':', kv);
      string nome = kv[0];
      StringTrimLeft(nome);
      StringTrimRight(nome);

      if(nome != "" && StringCompare(nome, symbol, false) == 0)
         return true;
   }

   return false;
}

//==================================================
// RISCO EM DINHEIRO -> DISTANCIA EM PONTOS
//==================================================
// Definicao UNICA do "quanto de preco corresponde a N dolares de risco" para
// um simbolo e um lote. `ExecutionEngine` e `OrderManager` consomem ISTA funcao.
//
// Se cada um dividisse por conta propria, um deles acabaria com um numero e o
// outro com outro - e o sintoma seria o mesmo que ja-investigamos: o cliente
// lendo um nome e o servidor entregando outra medida.
//
// `SYMBOL_TRADE_CONTRACT_SIZE` e propriedade DOUBLE, nao enum inteiro: no MT5 o
// tamanho de contrato pode ser fracionario, e o compilador rejeita com
// "cannot convert enum" quando ele e pedido como `SymbolInfoInteger`. Medido
// em 08/10/2026: e o primeiro erro que aparece ao compilar este trecho.
//
// MEDIDO em 23/10/2026: a formula antiga era `risco / (contrato x volume x
// point)`, e ela so vale quando a moeda de COTACAO e a moeda da conta. Em
// USDJPY (point 0,001, contrato 100.000, 0,01 lote) ela devolvia 2 pontos para
// US$ 2,00 de risco - 0,2 pip, dentro do spread. O valor real de 1 ponto em
// USDJPY e ~US$ 0,66 por lote, nao US$ 100,00; a razao e o proprio cambio
// (100 / 0,66 = ~151x). USDJPY, USDSEK, USDCNH e USDBRL estao na lista padrao
// de simbolos, entao o defeito abria stop colado no preco em 4 dos 11.
//
// A fonte correta e a ficha do simbolo: `TICK_VALUE` ja vem na MOEDA DA CONTA.
// O fallback por contrato continua existindo, mas DEPOIS, e so quando a ficha
// nao responde - nunca como primeira escolha.
//==================================================
// VALOR DE UM PONTO EM MOEDA DA CONTA (11/11/2026 - P0)
//==================================================
// MEDIDO em 11/11/2026 na conta 113568614, simbolo XAUUSD (contract_size=100,
// tick_size=0.01000000, tick_value=0.10): a formula `(tickVal/tickSize)*point`
// devolve 0,10000000 por lote por ponto. A verdade e 1,00000000 - conferida
// com OrderCalcProfit, que e a MESMA funcao que calcula o lucro da posicao.
// FATOR 0,1000. Com StopLossPoints=300: o EA dimensionava a ordem como se o
// stop valesse 30,00 USD por lote, quando vale 300,00. O lote saia 10x maior
// que o risco autorizado (journal: "ValorPorLote=30.00" e "perda no stop com
// 2.000 lotes = 60.00 USD" - reais 300,00 e 600,00).
//
// Nao existe campo da ficha do simbolo para trocar: o servidor publica
// tick_value = tick_value_profit = tick_value_loss = 0,10 para um ouro cujo
// contract_size=100 com ponto 0,01 vale 1,00. E `contract_size * point`
// tambem nao serve: acerta o XAUUSD (100*0,01=1,00) mas da 100,00 no USDJPY,
// onde a verdade e 0,63. OrderCalcProfit acertou os seis simbolos medidos:
// XAUUSD 1,0000 | EURUSD 1,0000 | USDJPY 0,9944 | USDCHF 1,0014 |
// USDBRL 0,9992 | USDCLP 1,0143 (todos dentro de +-1,5%).
//
// Mede 1,0 lote com 1 ponto de distancia: devolve o lucro em moeda da conta
// por lote por ponto. Devolve 0,0 quando o simbolo nao responde - e quem
// chama trata 0,0 como "desconhecido" (bloqueia), nunca como valor valido.
double ValorPorPontoUSD(string symbol)
{
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   if(point <= 0.0)
      return(0.0);

   double preco = SymbolInfoDouble(symbol, SYMBOL_BID);

   if(preco <= 0.0)
      preco = SymbolInfoDouble(symbol, SYMBOL_ASK);

   if(preco <= 0.0)
      return(0.0);

   double lucro = 0.0;

   if(!OrderCalcProfit(ORDER_TYPE_BUY, symbol, 1.0, preco, preco + point, lucro))
      return(0.0);

   if(lucro <= 0.0)
      return(0.0);

   return(lucro);
}

double DistanciaPontosParaRiscoUSD(
   string symbol,
   double volume,
   double risco_usd
)
{
   if(risco_usd <= 0.0 || volume <= 0.0)
      return(0.0);

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   if(point <= 0.0)
      return(0.0);

   // 11/11/2026 (P0): fonte trocada para OrderCalcProfit (ValorPorPontoUSD).
   // A formula antiga `(tickVal/tickSize)*point` devolvia 0,10 no XAUUSD
   // contra 1,00 real, e a distancia saia 10x maior que a devida.
   // O fallback por `contract_size * point` foi REMOVIDO de proposito: ele
   // acerta o XAUUSD mas erra o USDJPY em ~150x. Sem fonte confiavel a
   // funcao devolve 0,0 e a entrada e bloqueada - erra para o lado seguro.
   double valorPorPonto = ValorPorPontoUSD(symbol);

   if(valorPorPonto <= 0.0)
      return(0.0);

   return(risco_usd / (valorPorPonto * volume));
}

//==================================================
// ORCAMENTO DIARIO x RISCO POR OPERACAO
//==================================================
// `RiskPerTradeUsd` e um valor ABSOLUTO: ele nao acompanha o tamanho da conta.
// Quando ele passa do orcamento do dia (`MaxDailyLossPercent` do saldo), UMA
// operacao estoura o limite que o `SafetyManager` usa para parar de operar.
//
// MEDIDO em 08/10/2026: risco de US$ 3,00 contra orcamento de US$ 0,61 numa
// conta de US$ 12,13. A correcao da epoca trocou o numero para US$ 2,00 e NAO
// criou a comparacao - o defeito de escala continuou, so que menor.
//
// A trava compara os DOIS numeros que o sistema ja possui. `MaxTradeRiskPctOfBudget`
// diz quanto do orcamento do dia uma unica entrada pode consumir (100 = o dia
// inteiro; 50 = metade). Para desligar a comparacao, use um valor <= 0.
input double MaxTradeRiskPctOfBudget = 100.0;

double OrcamentoDiarioPerda()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   double orcamento = (balance > 0.0 && MaxDailyLossPercent > 0.0 ? balance * MaxDailyLossPercent / 100.0 : 0.0);
   // v1.2.35 - P1.2b: o criterio em USD entra quando for menor (ou quando o de % estiver desligado).

   double teto = (MaxDailyLossUsd > 0.0 && (orcamento <= 0.0 || MaxDailyLossUsd < orcamento) ? MaxDailyLossUsd : orcamento);

   // v1.2.219 (23/11/2026): em conta micro o orcamento do dia nao pode ser
   // menor que UMA operacao autorizada. Sem isto, `RiscoCabeNoOrcamento`
   // recusava todas as entradas por aritmetica (risco 1,00 USD contra um
   // orcamento de 0,12 a 0,41 USD) e o EA nunca chegava a tentar.
   double pisoMicroOrcamento = MicroAccountRiskFloor();

   if(pisoMicroOrcamento > 0.0 && teto < pisoMicroOrcamento)
      teto = pisoMicroOrcamento;

   return(teto);
}

// Valor em dinheiro de uma distancia em PONTOS, para um lote. Mesma fonte da
// distancia (TICK_VALUE/TICK_SIZE), no sentido inverso: quem dimensiona a
// ordem e quem cobra o orcamento leem a MESMA unidade.
double RiscoEmDinheiroDaOrdem(
   string symbol,
   double volume,
   double pontos
)
{
   if(volume <= 0.0 || pontos <= 0.0)
      return(0.0);

   // 11/11/2026 (P0): mesma fonte da distancia (OrderCalcProfit), no sentido
   // inverso. Era `(tickVal/tickSize)*point`, que no XAUUSD devolvia 0,10 em
   // vez de 1,00 - o journal imprimia "ValorPorLote=30.00" onde o real era
   // 300,00, e o lote saia 10x maior que o risco autorizado.
   double valorPorPonto = ValorPorPontoUSD(symbol);

   if(valorPorPonto <= 0.0)
      return(0.0);

   return(pontos * valorPorPonto * volume);
}

bool RiscoCabeNoOrcamento(double risco_usd, string &motivo)
{
   motivo = "";

   if(risco_usd <= 0.0)
   {
      motivo = "risco por operacao invalido (0)";
      return(false);
   }

   if(MaxTradeRiskPctOfBudget <= 0.0)
      return(true);

   double orcamento = OrcamentoDiarioPerda();

   // Limite diario desligado (MaxDailyLossPercent <= 0): nao ha o que comparar.
   if(orcamento <= 0.0)
      return(true);

   double teto = orcamento * MaxTradeRiskPctOfBudget / 100.0;

   if(risco_usd > teto + 1e-8)
   {
      motivo = StringFormat(
         "risco US$ %.2f > teto US$ %.2f (%.0f%% do orcamento diario %.2f%% de saldo %.2f)",
         risco_usd,
         teto,
         MaxTradeRiskPctOfBudget,
         MaxDailyLossPercent,
         AccountInfoDouble(ACCOUNT_BALANCE));
      return(false);
   }

   return(true);
}

//==================================================
// MODO AUTONOMO (operar sem gateway de IA)
//==================================================
// MEDIDO em 29/10/2026 na conta 113568614: com `EnableAIFilter=true`,
// `AllowTradeWithoutAI=false` e o gateway Python (127.0.0.1:9001) fora do ar,
// o EA nao abria NENHUMA operacao. Dois gates independentes barravam tudo:
//   * ValidateTrade -> AITradeAllowed(): confianca de fallback (40, teto de
//     `AIUnavailableConfidenceCap`) < `MinAIConfidence` (50) -> sempre false;
//   * AllowTrade -> FinalAIAllow(): "IA indisponivel" -> sempre false.
//
// `EnableAutonomousMode=true` mantem a IA como CONSULTORA: continua
// calculando score, registrando feedback e alimentando o log, mas NAO veta e
// NAO exige disponibilidade. Toda a cadeia de risco continua valendo
// (spread, tendencia, ADX, volatilidade, SafetyManager, CircuitBreaker,
// EquityProtection, drawdown e limite diario).
input bool   EnableAutonomousMode = true;   // IA real: veta e exige gateway (era consultiva)

// Piso do MarketScore aplicado em AllowTrade (DecisionEngine). Era 60.0 fixo
// no codigo; agora e ajustavel sem recompilar.
input double MinMarketScore       = 65.0;

//==================================================
// PISO CONDICIONAL DO MARKETSCORE (v1.2.186 - P1.2341 / D-088 #5)
//==================================================
// O MarketScore e 100 x pontos / maxScorePoints (115). As parcelas TECNICAS
// somam no maximo 65 pontos:
//   20 EMA + 15 RSI + 15 ADX + 10 KCI_direcao + 5 KCI_volume = 65
// e a parcela da IA vale ate 50 (50 x confianca). Sem o modelo o teto e
// 65/115 = 56,52 de 100 - ABAIXO do piso de 65,0. Consequencia:
// `AllowTradeWithoutAI=true` sozinho NAO abre nenhuma entrada; quem decide
// e o piso. Por isso existe este segundo piso.
//
//   * com leitura de IA real (AILeituraReal() == true) -> vale MinMarketScore
//   * sem leitura de IA                               -> vale MinMarketScoreNoAI
//
// 45,0 = 79,6% do teto tecnico sem IA (56,52). Referencias: 50,0 = 88,5%
// (mais rigoroso) e 40,0 = 70,8% (mais permissivo). O numero e do DONO
// (D-088 #5 = REVER); muda por input, sem recompilar.
input double MinMarketScoreNoAI   = 45.0;

//----------------------------------------------
// VETO DE SCORE ZERO DA IA AVANCADA (29/10/2026)
//----------------------------------------------
// `FinalAIAllow()` devolve TRUE sem olhar o score quando `AIGateRequired()`
// e false - e ele e false com `EnableAutonomousMode=true` (padrao) e com
// `AllowTradeWithoutAI=true`. Nesse caminho, score 0 passava direto.
//
// MEDIDO em ai_feedback.csv (402 trades):
//   * score == 0 -> 67 trades | WR 34,3% | -56,77
//   * score  > 0 -> 335 trades | WR 75,8% | +46,26
// Score 0 nao e "sinal fraco": e AUSENCIA de leitura (nenhum componente
// somou). Este veto e proprio, independente do gate e do modo autonomo.
// `false` restaura o comportamento antigo (score 0 entra).
input bool   BlockZeroAIScore     = true;

//==================================================
// ENTRADA SEM STOP + STOP ARMADO NO LUCRO (29/10/2026)
//==================================================
// Pedido do dono: ENTRAR SEM STOP, deixar o preco andar a favor e SO ENTAO
// colocar o stop ACIMA da entrada, ja com lucro travado. Motivo declarado:
// parar de colecionar stops por ruido antes da tendencia aparecer.
//
// AVISO (dinheiro real): posicao aberta sem stop NAO tem limite individual de
// perda no servidor. A conta passa a depender de:
//   * MaxTotalRiskPercent  -> envelope que AGORA conta estas posicoes pela
//                             distancia de referencia StopLossPoints;
//   * MaxDailyLossPercent  -> bloqueia novas entradas quando o dia perde;
//   * StoplessEmergencyRMult -> fecha a mercado em StoplessEmergencyRMult x 1R.
input bool   EnableStoplessEntry     = false;   // true = entra sem SL e arma no lucro
input double StoplessArmATRMult      = 0.8;    // anda X ATR a favor -> arma o stop
input int    StoplessArmMinPoints    = 30;     // piso do gatilho, em pontos
input double StoplessLockATRMult     = 0.35;   // stop nasce X ATR ALEM da entrada
input int    StoplessLockMinPoints   = 10;     // piso do lucro travado, em pontos
input int    StoplessEmergencyPoints = 0;      // 0 = auto (R x StoplessEmergencyRMult); >0 fixo em pontos

//----------------------------------------------
// TETO DE PERDA EM R PARA A POSICAO SEM STOP (v1.2.29 - 30/10/2026)
//----------------------------------------------
// MEDIDO em ai_feedback.csv (402 trades, 24/08 a 29/10/2026):
//   * 277 ganhos  -> +153,64  (ganho medio 0,55)
//   * 125 perdas  -> -164,15  (perda media 1,31)  => R medio 0,42
//   * as 12 piores perdas somam -82,03, ou seja METADE do prejuizo bruto
//     vem de 3% dos trades (-15,00 XAGUSD; -11,94 USDCHF; -9,51 e -9,00 XAUUSD;
//     -6,30 NZDUSD; ...).
// Simulacao de corte por trade (limite SUPERIOR: nao conta trades que
// recuperariam nem os que nunca existiriam):
//   teto 1,0 USD -> +84,40 | 1,5 -> +61,75 | 2,0 -> +47,39 | 3,0 -> +31,53 |
//   6,0 -> +11,24 | sem teto -> -10,51.
// A conta nao perde por acertar pouco (WR 68,9%): perde porque a cauda e
// 2,4x maior que o ganho medio.
//
// CAUSA no codigo: o risco da entrada e dimensionado sobre 1R = ATR x
// StoplessArmATRMult (0,8) com piso em StoplessArmMinPoints, mas o vigia de
// emergencia cortava em 3xATR ~ 3,75R. Ou seja, a posicao podia perder quase
// QUATRO vezes o que foi orcado para ela.
//
// Agora o vigia corta em `StoplessEmergencyRMult` x 1R (mesma referencia do
// dimensionamento). 1,5 = tolera meia barra de ruido alem do risco e corta a
// cauda. 0 desliga o teto em R (volta ao 3xATR antigo via StoplessEmergencyPoints).
// StoplessEmergencyPoints > 0 continua mandando (valor fixo em pontos).
input double StoplessEmergencyRMult  = 1.5;    // teto de perda do stopless, em multiplos de 1R

//==================================================
// ALVOS VARIAVEIS POR CONVICCAO (29/10/2026)
//==================================================
// "varios tipos de lotes e alvos": o alvo deixa de ser um numero fixo e vira
// um multiplo da distancia de referencia (StopLossPoints), pela MESMA nota de
// conviccao que escolhe o lote. Alvo curto na duvida, alvo longo na certeza.
input bool   EnableAdaptiveTargets = true;
input double DynTPFactorMin        = 0.35;
input double DynTPFactorBase       = 0.50;
input double DynTPFactorClear      = 0.80;
input double DynTPFactorStrong     = 1.20;
input double DynTPFactorElite      = 2.00;
input int    MinTargetPoints       = 70;
input int    MaxTargetPoints       = 1500;

//==================================================
// RISCO ABERTO / RISCO EFETIVO POR TRADE
//==================================================
// Soma o risco (preco de entrada -> SL) das posicoes ABERTAS do EA, na moeda
// da conta, usando TICK_VALUE/TICK_SIZE (os mesmos campos da ficha do simbolo
// que `DistanciaPontosParaRiscoUSD` usa). Posicao sem SL nao entra na conta.
double RiscoAbertoUSD()
{
   double total = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);

      if(tk == 0 || !PositionSelectByTicket(tk))
         continue;

      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      string sym   = PositionGetString(POSITION_SYMBOL);
      double open  = PositionGetDouble(POSITION_PRICE_OPEN);
      double vol   = PositionGetDouble(POSITION_VOLUME);
      double point = SymbolInfoDouble(sym, SYMBOL_POINT);

      // 11/11/2026 (P0): o envelope de risco aberto usava a MESMA formula
      // 10x do dimensionamento. Efeito: o risco das posicoes abertas era
      // contado 10x MENOR do que e, o envelope nunca enchia e o EA aceitava
      // muito mais posicoes simultaneas do que o autorizado.
      double valorPorPonto = ValorPorPontoUSD(sym);

      if(point <= 0.0 || valorPorPonto <= 0.0 || vol <= 0.0)
         continue;

      double sl = PositionGetDouble(POSITION_SL);

      // 29/10/2026: posicao aberta SEM stop continua ocupando o envelope.
      // Sem isto, toda entrada sem SL somava ZERO de risco aberto e o
      // limitador nunca enchia: dava para abrir dezenas sem nenhum freio.
      if(sl <= 0.0)
      {
         if(!EnableStoplessEntry)
            continue;

         // v1.2.21: posicao SEM stop conta a distancia de ARMADURA
         // (ATR * StoplessArmATRMult, piso StoplessArmMinPoints), que e onde o
         // stop realmente vai ser colocado quando o trade ficar verde. Antes
         // contava StopLossPoints=300 pts fixos: com saldo de 185 USD duas
         // posicoes sem stop esgotavam o envelope de 10% e o EA travava em
         // "envelope de risco aberto cheio".
         double ref = 0.0;
         double atrArm = GetATR(sym);

         if(atrArm > 0.0)
            ref = atrArm * StoplessArmATRMult;

         double pisoArm = (double)StoplessArmMinPoints * point;

         if(ref < pisoArm)
            ref = pisoArm;

         // Piso CONSERVADOR (v1.2.22): nunca subestimar o risco de uma
         // posicao SEM stop. MEDIDO no backtest XAUUSD M15 20-29/10/2026:
         // contar apenas a distancia de armadura liberou demasiadas entradas
         // simultaneas e o resultado caiu de +21,23 USD (16 trades) para
         // -13,40 USD. O envelope usa o MAIOR dos dois: armadura vs
         // StopLossPoints. Assim continua conservador como antes e fica mais
         // rigoroso quando a volatilidade (ATR) for grande.
         double pisoConservador = (double)StopLossPoints * point;

         if(pisoConservador > ref)
            ref = pisoConservador;

         if(ref <= 0.0)
            continue;

         sl = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
              ? (open - ref) : (open + ref);
      }

      double pontos = MathAbs(open - sl) / point;
      total += valorPorPonto * pontos * vol;
   }

   return(total);
}

// Risco efetivo da PROXIMA entrada, em moeda da conta.
// 0 = envelope cheio (a execucao recusa a entrada).
double RiscoPorTradeUsd()
{
   double risco = RiskPerTradeUsd;

   if(RiskPerTradePercent > 0.0)
   {
      double b = AccountInfoDouble(ACCOUNT_BALANCE);

      if(b > 0.0)
         risco = b * RiskPerTradePercent / 100.0;
   }

   // v1.2.219 (23/11/2026): em conta micro o risco pedido por operacao nunca
   // fica abaixo do piso autorizado pelo dono (MicroAccountRiskCapUsd). Este
   // numero alimenta o dimensionamento do lote E o envelope de risco aberto.
   double pisoMicroRisco = MicroAccountRiskFloor();

   if(pisoMicroRisco > 0.0 && risco < pisoMicroRisco)
      risco = pisoMicroRisco;

   if(risco <= 0.0 || MaxTotalRiskPercent <= 0.0)
      return(risco);

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   if(balance <= 0.0)
      return(risco);

   double envelope = balance * MaxTotalRiskPercent / 100.0;

   // v1.2.219 (23/11/2026): o envelope aberto tambem nao pode valer menos que
   // UMA operacao autorizada, senao o bloco de envelope reduzia o lote abaixo
   // do minimo do broker e devolvia ENVELOPE_SEM_SOBRA_MIN_LOT.
   if(pisoMicroRisco > 0.0 && envelope < pisoMicroRisco)
      envelope = pisoMicroRisco;

   // v1.2.32 - P1.1: o teto em USD manda quando for menor que o de %.
   if(MaxTotalRiskOpenUsd > 0.0 && MaxTotalRiskOpenUsd < envelope)
      envelope = MaxTotalRiskOpenUsd;

   double sobra    = envelope - RiscoAbertoUSD();

   if(sobra <= 0.0)
      return(0.0);

   return(MathMin(risco, sobra));
}

//==================================================
// LOTE DINAMICO POR CONFIANCA + CLAREZA DA TENDENCIA
//==================================================
// "Nao faca lotes fixos": o EA escolhe a faixa de lote. O lote nao e um numero
// digitado; e o MENOR entre:
//   (a) a faixa pedida pela conviccao do sinal (confianca da IA) e pela
//       clareza da tendencia (ADX, via GetADXStrength/GetADX);
//   (b) o lote que faz ESTA distancia de stop valer o risco permitido
//       (RiskPerTradePercent, limitado pelo envelope MaxTotalRiskPercent);
// com teto extra de MaxRiskPerTradePercentCap por operacao.
// Fail-safe: sem leitura de ADX (warm-up) o EA NAO escala o lote para cima.
input bool   EnableDynamicLot          = true;
input double DynLotFactorMin           = 0.25;  // conviccao baixa
input double DynLotFactorBase          = 1.00;  // conviccao media
input double DynLotFactorClear         = 2.00;  // confianca alta + tendencia clara
input double DynLotFactorStrong        = 3.00;  // confianca muito alta + tendencia forte
input double DynLotFactorElite         = 4.00;  // conviccao maxima
input double DynConfBase               = 66.0;  // piso para lote "normal"
input double DynConfClear              = 74.0;  // piso para escala 2x
input double DynConfStrong             = 82.0;  // piso para escala 3x
input double DynConfElite              = 90.0;  // piso para escala 4x
// v1.2.43 (31/10/2026) - P1.14: 25,0 -> 35,0.
// MEDIDO no XAUUSD (80 065 registos de trade_history.csv), por banda de ADX:
//   ADX < 20   : n=35 514  net -14 102  WR 61,0%  PF 0,872
//   ADX 20-25  : n= 4 518  net -17 952  WR 69,5%  PF 0,526
//   ADX 25-35  : n=10 936  net -31 033  WR 70,2%  PF 0,592
//   ADX >= 35  : n=29 097  net +36 153  WR 82,6%  PF 1,295
// Todo o lucro vem de ADX >= 35 e as duas bandas que perdiam dinheiro eram
// exactamente as que recebiam lote 2x (ExecutionEngine.mqh:41). Com 35,0 o
// factor 2x passa a exigir a mesma tendencia que o 3x ja exigia; a escala
// por conviccao (DynConfClear) continua a decidir entre 2x e 3x, portanto
// nenhum nivel fica inalcancavel. Efeito lateral assumido: a trava de noticia
// `NewsTradeTrendOnly` (ExecutionEngine.mqh:554) passa a exigir ADX >= 35.
input double DynADXClear               = 35.0;  // ADX minimo para "tendencia clara"
input double DynADXStrong              = 35.0;  // ADX para "tendencia forte"
input double MaxRiskPerTradePercentCap = 1.0;   // teto de risco por operacao apos escalar

//==================================================
// TETO DE RISCO REAL POR OPERACAO (v1.2.26 - 29/10/2026)
//
// O PROBLEMA MEDIDO (conta demo 113568614, 29/10/2026 as 21:45):
//   NZDUSD SELL 0,60 lotes, entrada 0.56319, fecho 0.56354 -> -20,92 USD.
// O lote foi dimensionado por `StopLossPoints` (300 pts), mas a escada arma
// o stop a 1R, que nesse simbolo valia ~5 pts. Resultado: a perda real foi
// ~6x maior que o risco planejado - e um unico trade apagou o dia inteiro.
//
// A CORRECAO: depois de todo o escalonamento (conviccao, cenario, sessao,
// aprendizagem) o lote e capado para que a perda na distancia REAL do stop
// (a mesma que `LadderNoiseDistance` usa: ATR, piso de pontos, stops level e
// 2x spread) nunca passe de `MaxRiskPerTradeUsd`.
//
// `MaxRiskPerTradeUsd = 0` desliga a checagem e volta ao comportamento antigo.
//==================================================
input double MaxRiskPerTradeUsd = 0.0;   // perda maxima REAL por operacao (0 = desliga). 11/11/2026 P0: era 8.0; com o valor por ponto 10x menor capava em 80,00 reais. A regua passou a ser RiskPerTradePercent = 0,50% do saldo, que escala com a banca

// v1.2.27 (30/10/2026) - DECISAO em vez de aviso.
// Antes, quando o lote caia abaixo do minimo do simbolo, o EA imprimia
// "EXECUTION WARNING | FORCA LOTE MINIMO | ... | Risco real excede o
// configurado" e abria a ordem MESMO ASSIM. O aviso nao protegia nada: quem
// le o journal depois do prejuizo descobre que o risco tinha sido avisado.
// Com `true`, se o lote MINIMO do simbolo ja estourar `MaxRiskPerTradeUsd`
// na distancia real do stop (1R), a entrada e RECUSADA com o evento
// MIN_LOT_EXCEEDS_RISK_CAP. Fica em `false` por padrao para nao mudar
// comportamento de producao sem decisao explicita do dono.
input bool   BlockWhenMinLotExceedsRiskCap = true;   // v1.2.35 - P1.4: nao abrir quando o lote minimo ja estoura o teto

//==================================================
// TECTO DE RISCO EM CONTA MICRO (v1.2.219 - 23/11/2026)
//==================================================
// DECISAO DO DONO (23/11/2026): "4,13 USD so comporta 0,01 lote; o EA pode
// comecar a operar a partir de 1 USD por operacao."
//
// O QUE ESTAVA A BLOQUEAR (medido, nao suposto): com saldo 4,13 os QUATRO
// limites de risco por operacao apontavam para valores abaixo do que o lote
// minimo arrisca:
//   * RiskPerTradePercent 0,50% do saldo -> 0,02 USD de risco pedido
//   * MaxRiskPerTradePercentCap 10%      -> 0,41 USD de tecto
//   * MaxTotalRiskPercent (envelope)     -> 0,41 USD de envelope aberto
//   * OrcamentoDiarioPerda (3% a 10%)    -> 0,12 a 0,41 USD por entrada
// Com StopLossPoints=300 o lote minimo ja arrisca mais do que qualquer um
// deles, logo o lote caia abaixo do minimo do broker e a entrada morria em
// ENVELOPE_SEM_SOBRA_MIN_LOT, GROWTH_TARGET_BELOW_COST ou LOT MIN.
//
// A CORRECAO: numa banca ate `MicroAccountMaxBalanceUsd`, os QUATRO limites
// passam a ter como PISO `MicroAccountRiskCapUsd` (1,00 USD). O tecto continua
// a ser TECTO: se o lote minimo do simbolo arriscar MAIS que isso na distancia
// real do stop (1R), a entrada e RECUSADA com MIN_LOT_EXCEEDS_RISK_CAP -
// nunca arredondada para cima contra o dono. Acima de
// `MicroAccountMaxBalanceUsd` nada muda: os limites normais voltam a mandar.
//
// INPUTS NOVOS de proposito: estes nomes nao existem nos .chr dos graficos,
// portanto o MT5 aplica-lhes estes defaults no reload sem precisar de um
// reattach com a lista completa de inputs.
input bool   EnableMicroAccountRiskCap = true;   // piso de risco por operacao em conta micro
input double MicroAccountMaxBalanceUsd = 25.0;   // saldo ate onde o piso de 1 USD por operacao vale
input double MicroAccountRiskCapUsd    = 1.00;   // risco maximo por operacao nessa faixa (USD)

// Piso de risco por operacao em vigor (0 = fora da faixa micro ou desligado).
double MicroAccountRiskFloor()
{
   if(!EnableMicroAccountRiskCap || MicroAccountRiskCapUsd <= 0.0)
      return(0.0);

   double saldo = AccountInfoDouble(ACCOUNT_BALANCE);

   if(saldo <= 0.0 || saldo > MicroAccountMaxBalanceUsd)
      return(0.0);

   return(MicroAccountRiskCapUsd);
}

// Tecto REAL por operacao depois do escalonamento (0 = sem tecto).
// Substitui a leitura directa de MaxRiskPerTradeUsd nos dois sitios do
// ExecutionEngine: em conta micro o tecto absoluto passa a ser o piso acima.
double RiskCapPerTradeUsd()
{
   double pisoMicro = MicroAccountRiskFloor();

   if(pisoMicro > 0.0)
      return(pisoMicro);

   return(MaxRiskPerTradeUsd);
}

//==================================================
// REGIME DE RISCO EM VIGOR (11/11/2026 - P0)
//==================================================
// MEDIDO no journal vivo de 11/11/2026, tres vezes (03:15:03, 09:41:24,
// 10:00:03): a linha [RISK] CALC USD dizia "Risco=60.00 USD" com saldo
// 12.633,04. Com RiskPerTradePercent=0.50 esse saldo vale 63,17. O 60,00 nao
// vinha da formula: vinha de o chart estar anexado com
// RiskPerTradePercent=0.00 e RiskPerTradeUsd=60,0, caso em que
// RiscoPorTradeUsd() devolve o valor ABSOLUTO. O EA obedeceu ao que estava
// configurado; o que faltava era dizer QUEM manda. Valor absoluto nao escala
// com a banca, e o tamanho da posicao tem de escalar com a banca.
//
// Esta funcao NAO decide nada e NAO altera limite nenhum: publica no arranque
// qual das duas regras esta em vigor e quanto isso vale em USD e em % do
// saldo. Sem esta linha o journal pode ser lido como se a regra percentual
// estivesse a mandar quando nao esta.
void DeclararRegimeDeRisco()
{
   double saldo  = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double risco  = RiscoPorTradeUsd();
   string regra  = "";
   string aviso  = "";

   if(RiskPerTradePercent > 0.0)
      regra = "PERCENTUAL " + DoubleToString(RiskPerTradePercent, 2) + "% do saldo";
   else if(RiskPerTradeUsd > 0.0)
   {
      regra = "ABSOLUTO " + DoubleToString(RiskPerTradeUsd, 2) + " USD";
      aviso = " | ATENCAO: absoluto NAO escala com a banca - use RiskPerTradePercent > 0";
   }
   else
   {
      regra = "NENHUM";
      aviso = " | ATENCAO: risco por trade desligado (RiskPerTradePercent=0 e RiskPerTradeUsd=0)";
   }

   double pctSaldo = (saldo > 0.0 ? 100.0 * risco / saldo : 0.0);

   PrintFormat("[RISCO EM VIGOR] regra=%s | risco por trade=%.2f USD (%.3f%% do saldo) | saldo=%.2f | equity=%.2f | teto por operacao=%.2f%% do saldo | teto absoluto=%.2f%s",
               regra, risco, pctSaldo, saldo, equity, MaxRiskPerTradePercentCap, MaxRiskPerTradeUsd, aviso);
}

//==================================================
// DISTANCIA DE RUIDO EM PONTOS (mesma regra da MoneyLadder)
//==================================================
// Devolve a distancia, em pontos, que o preco precisa andar para armar o
// stop na entrada (1R). E a referencia de risco REAL da operacao. Devolve 0
// quando nao ha dados suficientes - quem chama trata 0 como "nao medivel".
double NoiseDistancePointsForRisk(string symbol)
{
   if(symbol == "")
      return(0.0);

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   if(point <= 0.0)
      return(0.0);

   double dist = 0.0;
   double atr  = GetATR(symbol);

   if(atr > 0.0)
      dist = atr * StoplessArmATRMult;

   double piso = (double)StoplessArmMinPoints * point;

   if(dist < piso)
      dist = piso;

   long stopsLevel = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double pisoStops = (double)stopsLevel * point;

   if(dist < pisoStops)
      dist = pisoStops;

   double spread = SymbolInfoDouble(symbol, SYMBOL_ASK) - SymbolInfoDouble(symbol, SYMBOL_BID);

   if(spread > 0.0 && dist < 2.0 * spread)
      dist = 2.0 * spread;

   if(dist <= 0.0)
      return(0.0);

   return(dist / point);
}
//==================================================
// CENARIO GLOBAL (v1.2.21 - 29/10/2026)
//==================================================
// Adapta o EA ao TIPO de mercado em vez de vetar por um unico criterio.
// A classificacao mora em Filters/MarketScenario.mqh e usa ADX (forca) +
// ATR em % do preco (volatilidade comparavel entre ouro, forex, indices e
// cripto - pontos crus nao sao).
//
// MEDIDO no journal em 29/10/2026 (21:55): as duas unicas entradas do dia
// foram vetadas por "VALIDATION: TREND SELL" (EURUSD) e "VALIDATION: TREND
// BUY" (USDCHF) - veto binario do TrendFilter num mercado sem tendencia.
// Com o gate adaptativo, contramao em cenario LATERAL passa a ser PERMITIDA
// com lote reduzido, e continua VETADA quando a tendencia ja esta formada.
//
// Nada aqui aumenta risco: os fatores de lote sao <= 1.0, o alvo continua
// limitado por MinTargetPoints/MaxTargetPoints e o envelope
// MaxTotalRiskPercent segue mandando.
input bool   EnableScenarioAdaptation    = true;   // liga a adaptacao por cenario
input bool   EnableAdaptiveTrendGate     = true;   // contramao permitida em lateral
input bool   EnableScenarioLog           = true;   // linha [CENARIO] no journal

input double ScenarioADXStrong           = 25.0;   // ADX >= isto = TENDENCIA_FORTE
input double ScenarioADXWeak             = 18.0;   // ADX >= isto = TENDENCIA_FRACA
input double ScenarioCounterTrendMaxADX  = 22.0;   // ADX >= isto VETA contramao

//==================================================
// Q-079 = B (07/11/2026, decisao do DONO): FOLGA DE 1 ATR
//
// MEDIDO em 05/11/2026 (D-079): 1576 sinais, 1576 entraram em AllowTradeEx
// e 0 passaram; 58,5% dos vetos amostrados eram TREND. O sinal exige
// EMA50>EMA200 + RSI<45 (pullback fundo) e o portao exigia bid>EMA200(H1).
// Num pullback fundo o bid fura a EMA200 H1 e o portao lia contramao - o EA
// vetava o sinal que a propria regra procura.
//
// A folga NAO apaga a guarda: um preco a mais de `ScenarioTrendAtrSlack` ATR
// da EMA200 continua a ser contramao e segue as regras de ADX/cenario. Sem
// leitura de EMA ou de ATR, o rigor antigo fica intacto. Nenhum limite de
// risco, lote, SL ou TP muda aqui: `ScenarioLotFactor` e o envelope
// (`MaxTotalRiskPercent`) continuam a mandar.
//==================================================
input double ScenarioTrendAtrSlack      = 1.0;   // Q-079/B: folga em ATR junto a EMA200
input double ScenarioVolPctMax           = 2.00;   // ATR% >= isto = VOLATILIDADE_ALTA

input double ScenarioLotStrong           = 1.00;   // lote em tendencia forte
input double ScenarioLotWeak             = 0.90;   // lote em tendencia fraca
input double ScenarioLotRanging          = 0.75;   // lote em lateral
input double ScenarioLotVolatile         = 0.60;   // lote em volatilidade alta

input double ScenarioTargetVolatile      = 1.15;   // alvo x em volatilidade alta
input double ScenarioTargetRanging       = 0.90;   // alvo x em lateral

//==================================================
// CENARIO GLOBAL MULTI-ATIVO (v1.2.22 - 29/10/2026)
//==================================================
// A v1.2.21 respondeu "que TIPO de mercado e este". Faltavam as duas
// perguntas que so existem quando o EA roda em MUITOS ativos ao mesmo tempo.
//
// 1) CORRELACAO. Dos 16 graficos, quase todos sao pares contra o dolar.
//    `MaxOpenPositions=50` e um teto de CONTAGEM: com 50 vagas o EA podia
//    comprar dolar em USDJPY, USDCHF, USDCAD, USDCNH e USDSEK ao mesmo tempo.
//    Isso nao sao 5 operacoes - e UMA aposta no dolar com 5x o tamanho, e
//    quando o dolar vira as cinco perdem juntas. Aqui a exposicao passa a ser
//    medida POR MOEDA e POR SENTIDO, em dinheiro.
//    O veto e de CORRELACAO, nao de direcao: "comprar EURUSD" e "comprar
//    GBPUSD" somam em USD curto; "comprar USDJPY" e o oposto e nao soma.
//
// 2) SESSAO. `TradeStartHour..TradeEndHour` e `AvoidHoursList` foram
//    calibrados em 402 trades de XAUUSD e usam hora de SERVIDOR, que muda com
//    o horario de verao do broker. A sessao aqui e lida em GMT (fonte:
//    Filters/GlobalScenario.mqh) e o efeito e no LOTE, nao no veto.
//
// Nenhum fator aqui aumenta risco: todos os multiplicadores sao <= 1.0.
input bool   EnableCurrencyExposureGuard = true;   // liga a guarda de correlacao
input int    MaxCorrelatedTrades         = 3;      // posicoes no MESMO sentido de UMA moeda (0 = off)
input double MaxCorrelatedRiskPercent    = 3.0;    // risco somado no mesmo sentido de uma moeda (% do balance, 0 = off)

input bool   EnableSessionLotAdaptation  = true;   // liga a reducao de lote por sessao
input double SessionLotAsia              = 0.85;   // lote na Asia (00-07 GMT)
input double SessionLotLondon            = 1.00;   // lote em Londres (07-12 GMT)
input double SessionLotNY                = 1.00;   // lote em Nova Iorque (12-21 GMT)
input double SessionLotLate              = 0.70;   // lote depois do fecho de NY (21-24 GMT)
input double SessionLotClosed            = 0.50;   // lote em fim de semana / sem sessao
input double SessionLotExoticOffHours    = 0.75;   // reducao EXTRA de exotico/minor fora das sessoes liquidas
input double SessionLotFloor             = 0.35;   // piso: a sessao nunca zera o lote sozinha

input bool   EnableGlobalScenarioLog     = true;   // linha [GLOBAL] no journal (5 min por simbolo)

//==================================================
// META DIARIA DE LUCRO (desacelerar depois de bater)
//==================================================
// Lucro REALIZADO do dia (deals fechados do EA, exclui posicoes abertas).
// Ao alcancar DailyProfitSlowPercent% da meta:
//   DailyProfitStopTrading = true  -> nao abre mais nada ate o proximo dia;
//   DailyProfitStopTrading = false -> segue operando com lote reduzido por
//                                     DailyProfitSlowLotFactor.
// Para subir a meta no futuro, basta alterar DailyProfitTargetUsd.
input bool   EnableDailyProfitTarget   = true;
input double DailyProfitTargetUsd      = 100.0;

// META PROPORCIONAL A BANCA (v1.2.14)
// 20 USD e a meta certa para banca pequena (<=200 USD). Quando a banca cresce,
// 20 USD deixa de pagar o risco assumido. Com EnableDailyTargetBalancePct=true
// a meta efetiva passa a ser o MAIOR entre DailyProfitTargetUsd e
// DailyProfitTargetBalancePct% do saldo - a meta nunca DIMINUI.
input bool   EnableDailyTargetBalancePct = true;
input double DailyProfitTargetBalancePct = 0.80;   // % do saldo (0 = desliga o piso por %)
// v1.2.28 (30/10/2026) - P1.2: era 100.0. Com saldo ~12 348 e
// DailyProfitTargetBalancePct=10 o piso por % da 1234 USD, logo o teto era
// quem mandava e a meta efetiva ficava em 100 USD - cinco vezes a meta pedida
// pelo dono (10-20 USD/dia). Com 40.0 o EA para de abrir quando o dia chega a
// 40 USD - SUBSTITUIDO em 11/11/2026 por decisao do DONO: meta minima 100
// USD/dia, 0,80% do saldo acima disso, teto 200 USD. O teto nao e limite de
// risco; o risco por trade segue em 0,50% do saldo (63,32 USD na banca atual).
input double DailyProfitTargetMaxUsd     = 200.0;   // teto absoluto da meta (0 = sem teto)
input double DailyProfitSlowPercent    = 100.0;
input bool   DailyProfitStopTrading    = true;
input double DailyProfitSlowLotFactor  = 0.25;

// Meta batida NAO desfaz o que esta aberto: a meta conta lucro FECHADO, e as
// posicoes abertas ainda podem virar prejuizo. Com `true`, ao alcancar a meta
// o EA coloca stop NA ENTRADA ou ACIMA dela (lucro travado) em toda posicao
// aberta do EA, sem esperar o gatilho normal do break-even.
input bool   DailyProfitProtectPositions = true;

// Lucro realizado hoje, em moeda da conta, somente deals do EA.
double LucroRealizadoHojeUSD()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;
   datetime inicio = StructToTime(dt);

   if(!HistorySelect(inicio, TimeCurrent() + 60))
      return(0.0);

   double total = 0.0;
   int deals = HistoryDealsTotal();

   for(int i = 0; i < deals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);

      if(ticket == 0)
         continue;

      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != MagicNumber)
         continue;

      long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);

      // So o que FECHOU posicao conta como lucro realizado.
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
         continue;

      total += HistoryDealGetDouble(ticket, DEAL_PROFIT)
             + HistoryDealGetDouble(ticket, DEAL_SWAP)
             + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
   }

   return(NormalizeDouble(total, 2));
}

//==================================================
// META DIARIA EFETIVA (v1.2.14)
//
// O maior entre a meta fixa em USD e o piso percentual do saldo. Uma unica
// fonte de verdade: ExecutionEngine (freio de entradas) e PositionManager
// (trava das posicoes abertas) leem daqui, para nunca divergirem.
//==================================================
double DailyTargetEffectiveUsd()
{
   double meta = DailyProfitTargetUsd;

   if(EnableDailyTargetBalancePct && DailyProfitTargetBalancePct > 0.0)
   {
      double saldo = AccountInfoDouble(ACCOUNT_BALANCE);

      if(saldo > 0.0)
      {
         double porPct = saldo * DailyProfitTargetBalancePct / 100.0;

         if(porPct > meta)
            meta = porPct;
      }
   }

   // Teto absoluto: 10% de uma conta grande nao e meta de scalp.
   if(DailyProfitTargetMaxUsd > 0.0 && meta > DailyProfitTargetMaxUsd)
      meta = DailyProfitTargetMaxUsd;

   return(NormalizeDouble(meta, 2));
}

//==================================================
// PIPELINE MASTER (uma instancia por conta)
//==================================================
// MEDIDO em 29/10/2026: 13 graficos com o EA anexado rodavam o pipeline
// completo (11 simbolos cada) = 143 varreduras por tick. Pior que o custo:
// o latch "1 operacao por vela" usa o timeframe do GRAFICO (PERIOD_CURRENT),
// logo o mesmo simbolo podia ser negociado uma vez por minuto pelo grafico M1
// e outra vez por hora pelo grafico H1 - a chave do latch muda com a vela e o
// latch global nao barrava nada.
//
// `true` elege UMA instancia como dona do pipeline e da gestao de posicoes,
// com heartbeat de 180s. Se o grafico mestre for fechado, outra instancia
// assume automaticamente. `false` = comportamento antigo (todas rodam).
input bool   EnablePipelineMasterGuard = true;

//==================================================
// FREIO DE SEQUENCIA PERDEDORA (v1.2.20)
//==================================================
// MEDIDO no backtest XAUUSD M15 20-29/10/2026: 12 perdas seguidas custaram
// 56,88 USD (28% da banca de 200). O contador ConsecutiveLosses ja existia
// em OnTradeTransaction, mas NENHUM freio o usava: o EA seguia abrindo
// entradas novas durante a serie ruim.
//
// A pausa EXPIRA sozinha (StreakBrakePauseMinutes): o EA volta a operar sem
// intervencao manual. A gestao das posicoes abertas NUNCA e bloqueada, so a
// abertura de novas entradas. Ultimo campo em 0 desliga a pausa.
input bool EnableStreakBrake        = true;   // freio apos N perdas seguidas
input int  StreakBrakeLosses        = 3;      // N perdas seguidas armam a pausa
input int  StreakBrakePauseMinutes  = 240;    // duracao da pausa em minutos (0 = desliga)

//==================================================
// DEGRAUS DE CRESCIMENTO DA BANCA (v1.2.215 - 23/11/2026)
//==================================================
// Regra do dono: o EA tem de saber SEMPRE se a banca e pequena, media ou
// grande, e ajustar sozinho o alvo em dinheiro e o tecto de lote - sem
// reconfigurar graficos quando o saldo muda de faixa.
//
//   saldo < GrowthSmallLimitUsd         -> alvo GrowthSmallTargetUsd, lote <= 0.01
//   saldo < GrowthMediumLimitUsd        -> alvo GrowthMediumTargetUsd, lote <= 0.02
//   saldo >= GrowthMediumLimitUsd       -> sem tecto (a escada volta a mandar)
//
// A camada SO reduz o lote e SO recusa a entrada quando o alvo do degrau nao
// cobre GrowthMaxCostPctOfTarget do custo do spread para aquele lote - ou seja,
// quando a operacao nao consegue "bater no minimo" pedido. O tecto de lote
// respeita sempre o minimo do simbolo (GOLD 0.001, ETHUSD 0.02, BTCUSD 0.01,
// SOLUSD 0.05): o degrau nunca forca um lote que o broker nao aceita.
input bool   EnableGrowthPolicy        = true;  // degraus de crescimento (banca pequena/media/grande)
input double GrowthSmallLimitUsd       = 50.0;  // limite (USD) entre banca pequena e media
input double GrowthMediumLimitUsd      = 200.0; // limite (USD) entre banca media e grande
input double GrowthSmallTargetUsd      = 0.70;  // alvo por operacao na banca pequena (USD)
input double GrowthMediumTargetUsd     = 1.50;  // alvo por operacao na banca media (USD)
input double GrowthSmallLotTarget      = 0.01;  // tecto de lote na banca pequena
input double GrowthMediumLotTarget     = 0.02;  // tecto de lote na banca media
input double GrowthMaxCostPctOfTarget  = 20.0;  // custo do spread maximo como % do alvo (0 = desliga)

//--------------------------------------------------
// STOP POR DEGRAU DE BANCA (v1.2.222 - 23/11/2026, D-224)
//--------------------------------------------------
// REGRA DO DONO (23/11/2026): "so poder ativar estrategia stop com banca
// media acima de 100 usd" e "sim sem stop [a subir] crescimento".
//   SALDO <  GrowthStopMinBancaUsd (100 USD) -> so CRESCIMENTO: a escada NAO
//        sobe o stop; fica o SL que a entrada trouxe e o alvo em dinheiro e
//        que fecha no lucro. Nenhum degrau de protecao e armado - a vencedora
//        pode devolver o lucro ate ao SL da entrada, e e a regra do dono.
//   SALDO >= GrowthStopMinBancaUsd (100 USD) -> crescimento + stop de
//        protecao: arma quando o lucro passa de GrowthStopArmUsd (5.00 USD) e
//        fica ACIMA da entrada, garantindo GrowthStopLockUsd (0.50 USD).
//   GRANDE  (>= GrowthMediumLimitUsd) -> alvos maiores (GrowthLargeTargetUsd)
//        com a mesma protecao da banca media.
// O limiar de 100 USD e SEPARADO do degrau de alvo (GrowthSmallLimitUsd=50):
// o degrau diz qual e o alvo em dinheiro, este limiar diz se ha protecao.
// A banca 50-99 USD continua a ter alvo de banca media e ZERO stop a subir.
// Tudo em USD de lucro da POSICAO (nao em pontos), como o resto da escada.
// GrowthStopLockUsd e a GARANTIA, nao a distancia da trava: a trava continua
// a nascer fora do ruido do simbolo (StoplessLockATRMult/StoplessLockMinPoints)
// e o piso acima da entrada e que passa a ser a garantia.
input bool   GrowthStopEnabled       = true;   // stop por degrau (abaixo de GrowthStopMinBancaUsd nao arma)
input double GrowthStopMinBancaUsd   = 100.0;  // banca minima (USD) para a protecao poder armar
input double GrowthStopArmUsd        = 5.00;   // lucro (USD) que arma o stop acima da banca minima
input double GrowthStopLockUsd       = 0.50;   // lucro (USD) que o stop ACIMA da entrada garante
input double GrowthLargeTargetUsd    = 3.00;   // alvo por operacao na banca grande (USD; 0 = escada decide)

//==================================================
// CRIPTO 24/7 - SEM FREIO DIARIO (v1.2.217 - 23/11/2026)
//==================================================
// DECISAO DO DONO (23/11/2026): "sem freio nenhum" em cripto. Cripto negoceia
// 24/7, sete dias por semana, e nao tem sessao que feche o dia - por isso os
// QUATRO freios que fecham o dia deixam de se aplicar aos simbolos de cripto:
//
//   1. limite de PERDA do dia        (CSafetyManager::CheckDailyLoss)
//   2. limite de DRAWDOWN do dia     (CSafetyManager::CheckDailyDrawdown)
//   3. limite de NUMERO de operacoes (CSafetyManager::CheckDailyTrades)
//   4. meta diaria de LUCRO que trava novas entradas
//                                    (ExecutionEngine, EnableDailyProfitTarget)
//
// O que NAO muda, porque nao e freio DIARIO: o risco POR OPERACAO
// (RiskPerTradeUsd / RiskPerTradePercent / MaxRiskPerTradeUsd), o envelope de
// risco aberto, o limite de spread, o custo minimo do alvo (GrowthPolicy), o
// SL obrigatorio e a pausa por perdas seguidas (EnableStreakBrake, que conta
// perdas e nao horas do dia). Esses continuam a valer em cripto: sem eles a
// conta nao tem limite nenhum por operacao e uma unica entrada mal parada
// consome a banca de 5,63 USD.
//
// A deteccao e pelo PREFIXO do nome do simbolo (BTCUSD, ETHUSD, SOLUSD,
// AAVEUSD...). Lista vazia desliga a regra e todos os simbolos voltam a ter
// freio diario.
input bool   EnableCryptoNoDailyBrake = true;  // cripto: sem freio diario (24/7)
input string CryptoSymbolsList        = "BTC,ETH,SOL,XRP,LTC,BCH,DOGE,ADA,AVAX,LINK,UNI,NEAR,ETC,DASH,ZEC,AAVE,DOT,TRX,SHIB,XLM,ATOM,FIL,APT,ARB,BNB";

bool SymbolIsCrypto(string symbol)
{
   if(StringLen(symbol) <= 0 || StringLen(CryptoSymbolsList) <= 0)
      return(false);

   string alvo = symbol;
   StringToUpper(alvo);

   string lista = CryptoSymbolsList;
   StringToUpper(lista);

   string tokens[];
   int n = StringSplit(lista, (ushort)',', tokens);

   for(int i = 0; i < n; i++)
   {
      string tok = tokens[i];
      StringTrimLeft(tok);
      StringTrimRight(tok);

      // Prefixo, e nao "contem": EURUSD nao e cripto e BTCUSD e.
      if(StringLen(tok) >= 3 && StringSubstr(alvo, 0, StringLen(tok)) == tok)
         return(true);
   }

   return(false);
}

bool CryptoDailyBrakeOff(string symbol)
{
   return(EnableCryptoNoDailyBrake && SymbolIsCrypto(symbol));
}

//==================================================
// MAPEIO EXPLICITO DO SIMBOLO DA IA (v1.2.217)
//==================================================
// Aplica a tabela AIGatewaySymbolAlias ("DE=PARA;DE2=PARA2") DEPOIS de todas
// as regras de NormalizeAISymbol. Lista vazia devolve o valor recebido tal e
// qual - ou seja, sem configuracao o comportamento anterior fica intacto.
string AIGatewayAliasResolve(string baseSymbol)
{
   if(StringLen(AIGatewaySymbolAlias) <= 0 || StringLen(baseSymbol) <= 0)
      return(baseSymbol);

   string alvo = baseSymbol;
   StringToUpper(alvo);

   string pares[];
   int np = StringSplit(AIGatewaySymbolAlias, (ushort)';', pares);

   for(int i = 0; i < np; i++)
   {
      string par = pares[i];
      StringTrimLeft(par);
      StringTrimRight(par);

      int pos = StringFind(par, "=");

      if(pos <= 0)
         continue;

      string de   = StringSubstr(par, 0, pos);
      string para = StringSubstr(par, pos + 1);
      StringTrimLeft(de);
      StringTrimRight(de);
      StringTrimLeft(para);
      StringTrimRight(para);
      StringToUpper(de);

      if(StringLen(para) > 0 && de == alvo)
         return(para);
   }

   return(baseSymbol);
}

//==================================================
// DEBUG - NAO ALTERE
//==================================================
input bool EnableVerboseDebug    = true;  // v1.2.36: ignorado no Strategy Tester

#endif
