# PEDIDOS DE AJUDA - fila R-nnn

Registo unico dos pedidos entre agentes (ALFA, DELTA, CMD, DONO).
Escrito por tools\equipe-sync.ps1. Nao editar a mao: uma linha por pedido.

Estados: PEDIDO | ACEITE | FEITO | FECHADO | DEVOLVIDO | BLOQUEADO.

| ID | De -> Para | Assunto | Precisa | Prazo | Estado | Hora |
|---|---|---|---|---|---|---|
| R-001 | DELTA -> ALFA | corrigir Show-Check: acusar qualquer CR (2 linhas) :: PROVADO as 23:24 - sync-agent.ps1 linha 711 = if (crlfN -gt 0) { ; o comentario 708-710 regista o defeito antigo. De caminho o ValidateSet da linha 48 ja tem os 8 estados (PEDIDO/ACEITE/FEITO/DEVOLVIDO/BLOQUEADO) - o defeito do CONFIG_AGENTES.md 5 tambem caiu. Obrigado ALFA. | trocar a condicao EOL misturado por crlfN -gt 0 | 06/11 12:00 | FECHADO | 05/11 23:24 |
| R-002 | DELTA -> CMD | caminho do equipe-audit.ps1 e do FERRAMENTAS.md :: RESPONDIDO pelo proprio DELTA por medicao directa: Tools\equipe-audit.ps1 EXISTE em MQL5\Tools\ (16625 B, mtime 01:53:16Z, not under git control) e corre: all devolveu canal integro, 110 fontes 1 divergente, fila do dono 19 abertas. FERRAMENTAS.md existe em EQUIPE\ (4719 B) - foi o ALFA que o mediu no D-024. A confusao era de caminho: EQUIPE\tools\ = canal; MQL5\Tools\ = repo. R-002 nao precisa de CMD. | dir /s /b dos dois, ou dizer que nao existem | 06/11 12:00 | FECHADO | 05/11 23:24 |
| R-003 | DELTA -> DONO | decidir MaxDailyLoss 10->5 e MaxDrawdown 15->10 antes de conta real | sim/nao por escrito no INBOX_DONO | sem prazo - decisao do dono | PEDIDO | 05/11 23:04 |
| R-004 | CMD -> ALFA | validar canal em tempo real 10/10 :: CMD validou: ping registado, watcher detectou mudanca em tempo real, equipe-sync check OK. | confirmar rececao do ping/watcher | 06/11 18:00 | FEITO | 06/11 15:49 |
| R-005 | CMD -> DELTA | teste watcher tempo real :: CMD validou: watcher detectou mudanca em PEDIDOS.md em tempo real (timestamp 14:35:56). | confirmar deteccao | - | FEITO | 06/11 15:49 |
