# REGISTRO DE IDs - EQUIPE

Ledger de reserva. Cada linha e um ID entregue a UM agente.
Formato: `USADO | <tipo> | <id> | <agente> | <data hora> | <assunto>`

USADO | D | D-016 | ALFA | 05/11/2026 22:29:15 | modulo de sincronizacao: sync-agent.ps1 canonico
USADO | D | D-017 | DELTA | 05/11/2026 22:32:58 | 
USADO | D | D-018 | CMD | 05/11/2026 22:39:03 | plano mestre 10/10 + auditor de pre-commit do CMD
USADO | D | D-019 | ALFA | 05/11/2026 22:39:21 | equipa de 4: plano mestre, autorizacoes e rotina
USADO | D | D-020 | ALFA | 05/11/2026 22:40:33 | pedido de ajuda entre agentes + catalogo de configuracoes
USADO | D | D-021 | DELTA | 05/11/2026 22:40:45 | 
USADO | D | D-022 | ALFA | 05/11/2026 22:49:46 | reconciliacao: plano canonico = D-018 (CMD); ALFA complementa
USADO | D | D-023 | DELTA | 05/11/2026 22:50:27 | 
USADO | D | D-024 | ALFA | 05/11/2026 22:55:44 | correccao do D-023: F0.4 e F1.3 existem medidos; GATE F0 abre com os dois checks
USADO | D | D-025 | ALFA | 05/11/2026 23:03:44 | configuracoes medidas nos 13 graficos, hash do risco e F2.8 do magic number
USADO | D | D-026 | DELTA | 05/11/2026 23:04:56 | 
USADO | D | D-027 | CMD | 05/11/2026 23:08:21 | instalacao e servico do gateway 9011 (Q-009/B-015)
USADO | D | D-028 | ALFA | 05/11/2026 23:09:08 | causa medida de trades=0: piso da simulacao contra teto da IA indisponivel
USADO | D | D-029 | DELTA | 05/11/2026 23:11:16 | 
USADO | D | D-030 | ALFA | 05/11/2026 23:12:36 | P1.132 implementado: identidade do ATR verificada e ATR da propria serie
USADO | D | D-031 | DELTA | 05/11/2026 23:20:46 | 
USADO | D | D-032 | CMD | 05/11/2026 23:25:29 | resposta DONO Q-018 (b) veto e Q-019 reattach P1.132
USADO | D | D-033 | CMD | 05/11/2026 23:31:15 | resposta DONO Q-020 (opcao 3, ordem de 22:56 mantida: trabalhos sem interrupcao)
USADO | D | D-034 | ALFA | 05/11/2026 23:31:38 | fail-open: ATR errado encolhe a armadura e fabrica o RR da simulacao
USADO | D | D-035 | ALFA | 05/11/2026 23:33:32 | o bloqueio real e o token do gateway: 401 em 9001 e em 9011
USADO | D | D-036 | DELTA | 05/11/2026 23:34:50 | 
USADO | D | D-037 | ALFA | 05/11/2026 23:39:39 | 
USADO | D | D-038 | DELTA | 05/11/2026 23:40:43 | 
USADO | D | D-039 | DELTA | 05/11/2026 23:41:39 | 
USADO | D | D-040 | DELTA | 05/11/2026 23:42:26 | 
USADO | D | D-041 | DELTA | 05/11/2026 23:47:42 | 
USADO | D | D-042 | ALFA | 05/11/2026 23:53:16 | 
USADO | D | D-043 | ALFA | 05/11/2026 23:53:46 | 
USADO | D | D-044 | ALFA | 05/11/2026 23:57:28 | 
USADO | D | D-045 | ALFA | 06/11/2026 00:01:05 | 
USADO | D | D-046 | DELTA | 06/11/2026 00:25:22 | 
USADO | D | D-047 | ALFA | 06/11/2026 00:34:10 | 
USADO | D | D-048 | ALFA | 06/11/2026 00:36:38 | 
USADO | D | D-049 | ALFA | 06/11/2026 00:58:00 | P1.135: 4807 curado (handle recriado) + B-032 ia medir zero com EnableVolatilityFilter=false

USADO | D | D-050 | ALFA | 06/11/2026 01:00:00 | linha de base por contagem (218214 SEM LEITURA / 4663 HANDLE MORTO / 0 SERIE OK) + bug do StreamReader nao enumeravel
USADO | D | D-051 | ALFA | 06/11/2026 01:24:00 | compilacao REAL 1.2.172 (0 errors/0 warnings/931194 B/hash 0A28EDFC5BDC) + B-032 run_id 7704908543756588672 com contagem por offset 180740040
USADO | D | D-052 | ALFA | 06/11/2026 02:12 | B-032 fechou com v1.2.172: SEM LEITURA 218214->0, HANDLE MORTO 4663->0, SERIE OK 0->1, HANDLE RECRIADO 0->1 (offset 180740040; 22038506 B; Test passed 0:42:22.606; equity 10257.16)

USADO | D | D-053 | ALFA | 06/11/2026 05:52:26 | B-033 (filtro OFF): APPROVED 98->96, equity 10257.16->10242.94, BLOCK 662->681; criterio nao cumprido -> manter EnableVolatilityFilter=true; ATR RECRIADO 1->190 sem publicacao sem leitura
USADO | D | D-054 | DELTA | 06/11/2026 14:15:32 | gate de score inerte com IA indisponivel: 50+20=70 > MinMarketScore 65
USADO | D | D-055 | DELTA | 06/11/2026 14:36:34 | GATE_REAL: quadro de 11 criterios numericos para passagem a conta real; nenhum item passa por opiniao
USADO | D | D-056 | DELTA | 06/11/2026 14:46:42 | Gateway de IA: porta 9011 fechada (servico ausente) e api-probe.ps1 mede a 9001, que e o bridge do MT5 - a premissa da Q-021 estava errada
USADO | D | D-058 | ALFA | 06/11/2026 15:56:58 | P6 observabilidade do perfil: catalogo vs EM VIGOR provado e publicado v1.2.174
USADO | D | D-059 | ALFA | 06/11/2026 15:57:11 | P2 ADX 4807 resolvido: handle stale recriado por tempo, publicado v1.2.175
USADO | D | D-060 | ALFA | 06/11/2026 16:22:23 | A/B v1.2.175 fechado: delta -6.54 vs B-032, sem regressao e sem melhoria (reproduz v1.2.173)
USADO | D | D-061 | ALFA | 06/11/2026 16:28:54 | P0 causa raiz medida: expertmode=0 nos 15 chart files; MT5 reescreve o ficheiro no profile switch logo patch de ficheiro nao cura
USADO | D | D-057 | DELTA | 06/11/2026 15:50:00 | gateway de IA no ar na 9011 e autenticado com o token do .env; G2 do GATE_REAL verde com ressalva de durabilidade (registado em atraso nesta sessao - faltava no ledger)
USADO | D | D-062 | DELTA | 06/11/2026 20:10:00 | P0 fechado por medicao: carregar um perfil cujos .chr trazem expertmode=5 devolve MQL_TRADE_ALLOWED=1 (master=SIM); 117 parametros diferentes, 3 funcionais; Q-024 ao DONO
USADO | Q | Q-026 | DELTA | 06/11/2026 20:13:00 | ratificar XAI_P215_LIVE_B como perfil de trabalho + decidir EnableAutonomousMode (IA consultora vs IA que veta) + universo de modelos; substitui na pratica a Q-023, que ficou sem efeito; renumerada Q-024 -> Q-025 -> Q-026 em 06/11 20:30 por colisao com a Q-025 do ALFA (reservada no ledger as 20:25)
USADO | D | D-063 | ALFA | 06/11/2026 20:20:43 | F2.1 kill switch TESTADO ao vivo em 4 fases nos 13 graficos; v1.2.177 publicada; via automatica ainda sem gatilho
USADO | Q | Q-025 | ALFA | 06/11/2026 20:25:00 | F2.1: qual condicao arma o kill switch AUTOMATICO (CKillSwitch::ArmarAutomatico sem consumidor); renumerada de Q-024 em 06/11 20:24 apos colisao com a Q-024 do DELTA, causada pelo contador de IDs do `ask`; defeito corrigido no sync-agent.ps1
USADO | D | D-064 | ALFA | 06/11/2026 20:48:55 | F2.9 fechado por medicao: o portao de cotacao velha existia mas era invisivel no OnTick; deteccao de transicao no OnTimer + fonte unica do limite + relogio do servidor no MarketScanner; v1.2.179 provada nos 13 graficos
USADO | Q | Q-065 | ALFA | 06/11/2026 21:18:17 | Teto de exposicao total somada na conta real (F2.2): qual o limite em % do capital?

USADO | D | D-065 | DELTA | 06/11/2026 21:20:41 | F2.9 ASSINADO com prova independente (carimbo de tick do Market Watch, 21 simbolos) e revisao do relogio do MarketScanner do D-064; NAO assina COTACAO VOLTOU nem GATE F2 verde
USADO | D | D-066 | ALFA | 06/11/2026 21:26:40 | 
USADO | Q | Q-068 | ALFA | 06/11/2026 21:56:07 | D-068 (parser de IA): autoriza um compile unico da correccao conservadora? O EA nao opera porque o parser procura buy/sell/score e o gateway publica prob_buy/prob_sell/edge - AI_Score fica 0.0 e AIEngine.mqh:289 (0<60) devolve 0 em todos os simbolos, sempre. Escopo: (1) buy->prob_buy e sell->prob_sell; (2) AI_Score<-AI_Confidence quando nao ha score. A escala 0..1->0..100 fica para um compile separado (voto do DELTA). Custo agora medido: 0 posicoes, 0 ordens, margem 0.00, trades=0 hoje, mercado fechado - zero proteccao perdida. O D-068 faz o EA PODER operar; nao prova que DEVE (GATE_REAL 1 de 11, F2.2 sem prova de recusa nem de fail-closed, F6 nao arrancado).
USADO | Q | Q-070 | ALFA | 06/11/2026 23:00:46 | tres itens que as palavras do DONO de 06/11 23:00 nao fechavam (Q-017, Q-025, Q-026). ITEM 1 (Q-017, risco): disse que quer correr bastante risco mas nao escreveu numeros. Hoje MaxDailyLossPercent=10.0 e MaxDrawdownPercent=15.0 nos 13 graficos, ou seja: perda diaria maxima 1.263 USD e drawdown maximo 1.895 USD sobre 12.636. ITEM 2 (Q-025, ordem das guardas): o kill switch aos 50% da banca dispara muito depois de o MaxDrawdownPercent aos 15% ja ter bloqueado entradas - quer (i) manter as duas como estao (15% bloqueia, 50% mata) ou (ii) alinhar as duas no mesmo numero? ITEM 3 (Q-026): (b) EnableAutonomousMode fica true (a IA aconselha e nao veta) ou false (a IA veta e exige gateway)? (c) universo: reduzir a XAUUSD, o unico com modelo publicado, ou manter os 21 e esperar modelos?
USADO | D | D-068 | ALFA | 06/11/2026 23:04:58 | decisoes de risco, universo e modelos aprovadas pelo DONO em 06/11 23:03
USADO | Q | Q-071 | ALFA | 06/11/2026 23:13:44 | O senhor respondeu "2 ii" = alinhar as duas guardas no mesmo numero, mas nao escreveu QUAL numero fica. Hoje as duas estao desalinhadas e e por isso que uma chega primeiro: o MaxDrawdownPercent (15%) bloqueia novas entradas e o kill switch (50% da banca, Q-025) mata a conta. Alinhar significa escolher um numero unico para as duas. Com o equity de hoje (12.636,32 USD): se o numero for 15, o EA para e mata aos 1.895,45 USD de drawdown - e isso contradiz a Q-017 ("quero correr bastante risco"); se o numero for 50, o EA so para e mata aos 6.318,16 USD - e o numero que o proprio senhor deu na Q-025 ("quando perder 50% da banca"). Sao 4.422,71 USD de diferenca entre as duas leituras. Nada foi alterado: o EA continua com MaxDailyLossPercent 10.0 e MaxDrawdownPercent 15.0 em vigor nos 15 graficos.
USADO | Q | Q-072 | ALFA | 06/11/2026 23:13:44 | O senhor pediu "o EA operando todos ativos globais nao so xauusd". Medido agora: o universo ja tem 21 ativos (journal 21:38:01: marketwatch=21, deSymbols=11, ativos=21) e o EA esta anexado em 15 graficos, com todos os simbolos do Market Watch na lista. O que nao existe e modelo de IA para eles: o gateway responde "disponivel=true" SO para XAUUSD (1122 bytes); os outros 12 graficos recebem "disponivel=false" (357 bytes). E os ficheiros existem - ha 21 simbolos x {H1,H4,M15,M5} com .pkl e .meta.json em Python\models - mas reprovam o criterio de publicacao: XAUUSD_H1 passa (edge +0.0363, 4/5 folds), EURUSD_H1 reprova (edge -0.0161, pior que o palpite). A pergunta: enquanto os modelos nao forem retreinados, o senhor quer que os 20 ativos sem modelo operem a sinal TECNICO (a IA fica calada neles, porque EnableAutonomousMode=true ja tira o veto), ou quer que fiquem de fora ate terem modelo aprovado? Nao ha terceira via: ou opera a tecnico, ou nao opera.
USADO | D | D-067 | ALFA | 06/11/2026 21:39 | F2.2b (v1.2.181): o teto de exposicao passa a medir ACCOUNT_MARGIN (leitura unica do servidor) em vez da soma das posicoes filtradas por MagicNumber; EnableExposureCap=true a 20% (banda 10-50 autorizada na Q-065); #property 1.381 coerente com EA_VERSION_STRING 1.2.181. Corpo em DECISOES.md. Linha reposta no ledger em 07/11 por CMD - faltava desde a publicacao
USADO | D | D-069 | ALFA (reserva do CLI sem -From) | 06/11/2026 23:36:58 | ciclo final: contrato da EQUIPE ate ao 10/10 - 10 provas em vez de nota, quem faz nao assina, fases C0 a C7 com assinador, forward de 30 dias congelado por hash dos inputs, criterio de corte por simbolo. Corpo do bloco escrito em DECISOES.md as 23:39:04 (esta linha ficou sem descricao porque o id foi chamado sem -From). Ratificado pelo DONO as 23:42 (D-071 item 5). Documento: EQUIPE/CICLO_FINAL.md
USADO | D | D-070 | DELTA | 06/11/2026 23:41:34 | PROTOCOLO do ciclo 10/10: reorganizacao da equipe (uma responsabilidade, uma mao), definicao operacional de 10/10 (11/11 do GATE_REAL + 30 dias forward em demo + autorizacao escrita do DONO), regras de evidencia, ritual diario de 6 linhas, Definition of Done de 6 condicoes, compile unico por janela, regra de deploy, 30 dias de forward com criterios de aprovacao, quadro de pendencias com dono e prazo, ack obrigatorio de ALFA e CMD ate 07/11 12:00. Documento: EQUIPE/PROTOCOLO_CICLO_10_10.md (216 linhas). O D-069 ficou reservado vazio as 23:36:58 por sistema | ADENDA 15 e 16 (23:42:17): registo/versionamento/arquivo (commit e push com autor declarado, commit nao e deploy, mensagem com ID, copia para Backup antes de escrever, commit de marco por fase) e protocolo de teste e simulacao (estatico obrigatorio, Strategy Tester com janela e modelo identicos para antes e depois, relatorio salvo, ajuste ao passado repete a janela, forward demo como unico endurecimento real). Mesma decisao D-070 - as duas linhas foram fundidas em 07/11 por CMD porque o check acusa ID repetido no ledger
USADO | D | D-071 | ALFA | 06/11/2026 23:47:20 | 
