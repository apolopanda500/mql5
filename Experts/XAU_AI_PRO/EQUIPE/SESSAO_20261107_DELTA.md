# Sessao 07/11/2026 - DELTA (medicao, diagnostico, fecho)

Registo escrito no fim da sessao, a pedido do DONO: "agora so salvar e anotar
conversas e documentos". Complementa o `SESSAO_20261107_CMD.md` (escrito pelo CMD
as 05:59). Este documento nao assina gate nenhum.

## 1. O que o DONO pediu nesta sessao

1. Explicar as linhas `[TRADE BLOCK] COTACAO VELHA (timer)` com `idade=10063s` e
   depois `13114s` - "e um problema?".
2. Corrigir o `AIGatewayToken` vazio nos graficos.
3. Habilitar WebRequest para `http://127.0.0.1:9011` na GUI do MT5.
4. Aplicar hoje, sem esperar segunda-feira, as pendencias que estavam marcadas para
   o mercado abrir (Q-068/D-068, Q-071, Q-025).
5. Reorganizar a equipa e escrever como se chega a 10/10 sem falsificar nada.
6. Verificar o relatorio do CMD sobre os dois repositorios.
7. Encerrar o dia salvando e anotando conversas e documentos.

## 2. O que ficou feito

| Item | Estado | Prova |
|---|---|---|
| D-068 parser do gateway | aplicado e provado | `[AI] PYTHON \\| XAUUSD \\| SELL \\| BUY=27.65% \\| SELL=72.35% \\| SCORE=72.40 \\| CONF=72.40%` as 00:08:09.947 |
| D-068 caso negativo | provado | USDCLP, USDCZK, AUDUSD, USDJPY, NZDUSD, GBPUSD: 357 bytes, `disponivel=false`, `[AI] INDISPONIVEL ... edge ... abaixo do minimo +0.0500` |
| Q-071 MaxDrawdownPercent 15.0 -> 50.0 | no codigo e nos perfis | `Core/Config.mqh:136` = 50.0; 30 ficheiros `.chr` = 50.0 |
| Q-025 kill switch com chamador | em codigo, sem prova em execucao | `Management/EquityProtection.mqh`, ramo DRAWDOWN ALTO -> `CKillSwitch::ArmarAutomatico` |
| P1.137 ATR (ALFA) | no codigo, sem prova | `Indicators/VolatilityFilter.mqh` mtime 00:08:23 |
| Compile | 1 compile, 0 erros 0 avisos | publicacao v1.2.182 as 00:07:38-39 e v1.2.183 as 00:10:05-07 |

## 3. As linhas COTACAO VELHA - resposta ao DONO

Nao e problema, e o EA a recusar operar com preco parado. O mercado fechou as
2026-11-06T23:59:58 (hora do servidor) e nao reabriu. Sem tick, o `OnTick` nao corre,
por isso o guarda de idade (`Core/StalenessGuard.mqh`, limite `MaxSymbolTickAgeSec=900`)
imprime pelo `OnTimer` - e por isso a linha diz "(timer)". Idades observadas as
05:12-05:13: XAUUSD 40338s, USDBRL 40437s, USDRUB 62044s, USDCLP 53072s, USDCOP
51243s, restantes ~36832-36860s, sempre contra `limite=900s`. Fail-closed: o EA
prefere nao operar a operar com preco velho. A linha `[TRADE BLOCK] COTACAO VOLTOU`
so pode aparecer quando houver tick.

## 4. Correcoes que eu proprio tive de fazer no canal

1. `23:57` - escrevi "nao existe IA hoje, 9011 nao escuta e os dois portos devolvem
   401". Errado: 401 e o que um GET **sem** token devolve; o EA usa
   `AIGatewayTokenEfetivo()`, que le `XAU_GATEWAY_TOKEN` do `.env` (v1.2.133), e
   autentica. O que faltava era o parser, nao o gateway.
2. `00:12` - publiquei `ex5 966446 B MD5 D5917AC6`. O artefacto em disco ja era
   965778 B / A5C9F8C3 e depois 968458 B / C4F85F8B. Os tres numeros sao leituras
   reais; a regra do canal e "ultima observacao as HH:MM", e `MD5` de `.ex5` nao e
   identidade de build.
3. `00:12` - escrevi "Q-071 NAO ESTA EM VIGOR NOS GRAFICOS" porque os `.chr` mediam
   15.0. As 00:14 os perfis foram reescritos: hoje 30 de 30 `.chr` guardam 50.0.
   A frase deixou de ser verdadeira. Efeito real: fecho de emergencia aos 6.318,16
   USD (era 1.895,45), escada do RiskEngine aos 33,5%/16,5% (era 10,05%/4,95%) e
   kill switch a armar aos 40,0% (era 12,0%). Nao fui eu que reescrevi os perfis;
   nao fiz reattach nenhum hoje.

## 5. O que continua aberto (bloqueia 10/10)

1. **HG-01**: `#property version "1.382"` (`XAU_AI_PRO.mq5:22`) contra
   `EA_VERSION_STRING "1.2.183"` (`Enterprise/VersionManager.mqh:14`). Pela formula
   `minor*100+patch` deveria ser `1.383`. Sem este alinhamento o proximo compile
   publica um EA que diz uma versao e e outra.
2. **Changelog v1.2.183 ausente** - a entrada de v1.2.182 continua na linha 63.
3. **Q-025 sem prova em execucao** - 0 posicoes, mercado fechado, nao existe
   drawdown para demonstrar o armamento.
4. **P1.137 sem prova** - exige uma linha `[ATR] IDENTIDADE` por simbolo e nenhuma
   `[ATR] LEITURA SUSPEITA` com `ATR%=2274.32` (hoje medidas em USDCLP e USDCOP:
   `doHandle=14.780000` contra `daSerie=73950.936209`).
5. **7 ficheiros de codigo por commitar** (tabela em `SESSAO_20261107_CMD.md` secao
   3). Compilar/commit e acao do CMD na fronteira do contrato.
6. **GATE_REAL 1 verde de 11**: G1 conta real, G3 saturacao do score, G4 ATR
   handle/versao, G5 9-60 trades, G6 DD 61,50%, G7 PF 0,6643, G8 0% shorts, G9
   limites 10.0/15.0/1.0, G10 15 graficos contra 11 simbolos, G11 0 dias forward.
7. **Janela forward de 30 dias** nao pode comecar a mercado fechado.
8. **Higiene do canal**: colisao do ID D-068 em `IDS.md`, Q-018/Q-019/Q-065 fechadas
   sem `RESPOSTA` escrita, `equipe-sync.ps1:493` (`aviso`) emite
   ABERTO/RESPONDIDO/FECHADO que `dono` nao consegue emparelhar. `AIGatewayUrl`:
   30 `.chr` dizem 9001, a omissao do fonte diz 9011.

## 6. Estado medido no fecho (07/11/2026 09:00Z)

- `XAU_AI_PRO.ex5` 968458 B, mtime 00:10:05, MD5 `C4F85F8B289E1AC0FC2A2AA704DD84F1`.
- 15x `[START] XAU_AI_PRO v1.2.183` de 00:10:05.676 a 00:10:07.229, mais reattach
  00:11:46 e 00:13:16.
- 30 `.chr` (duas arvores de perfil): `MaxDrawdownPercent=50.0`,
  `AIGatewayUrl=http://127.0.0.1:9001/api/ai/predict`.
- Conta demo 113568614, equity 12636.32 USD, margin 0.00, 0 posicoes, 0 ordens.
- Git: HEAD `2c683ab1` "chore(equipe): lock livre no fecho da sessao"; 7 ficheiros
  de codigo modificados e por commitar; documentos commitados em `04824ebf`.
- Canal: `CANAL INTEGRO :: 0 problemas`.

## 7. Como retomar

1. `equipe-sync.ps1 check` e depois `lock`.
2. Ler `INBOX_DONO.md` e fechar HG-01 antes de qualquer compile.
3. Um compile unico com `#property version "1.383"` e `EA_VERSION_STRING "1.2.183"`,
   entrada de changelog escrita, publicacao num so passo.
4. Depois do compile: provar o P1.137 pela ausencia de `[ATR] LEITURA SUSPEITA`.
5. CMD commita e empurra; DELTA mede e assina o F2.2; nada de "10/10" antes de
   11/11 do GATE_REAL e dos 30 dias forward.

Assinatura: DELTA, 07/11/2026 09:00Z - medido, nao assinado como fecho de gate.
