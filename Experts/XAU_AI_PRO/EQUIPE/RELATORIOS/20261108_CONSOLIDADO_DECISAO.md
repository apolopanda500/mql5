# CONSOLIDADO PARA DECISAO - 08/11/2026 11:55

- **Autor:** DELTA
- **Para:** DONO (decisoes) + CMD (execucao) + ALFA (medicao)
- **Objectivo:** juntar num so' sitio o que esta' medido, o que esta' aberto e o que
  se decide agora. Nao substitui `GATE_REAL.md` (scoreboard) nem `PENDENCIAS.md`
  (registo); e' o resumo que se le antes de decidir.
- **Estado medido as 11:51-11:55**, com `get_workspace_info` (MetaTrader +
  MetaEditor) feito nesta sessao antes de qualquer leitura.
- **LOCK:** livre desde 11:42:46 (CMD). Nada aqui exigiu reanexo, ordem ou risco.

---

## 0. Veredicto numa linha

**Faltam 18 h 10 min para a janela de forward (09/11 00:05). Nao ha nada de
codigo a fazer antes disso - e' exactamente essa a decisao.** O que sobra sao
5 decisoes do DONO e 3 factos novos que ninguem registou.

---

## 1. Fotografia do sistema (medida, nao citada)

| Item | Valor | Fonte |
|---|---|---|
| Conta | `MetaQuotes-Demo` 113568614, hedging, **demo** | `get_trading_account_info` 11:51Z |
| Saldo / equity | **12 636,32** / 12 636,32 USD, margem 0,00 | idem |
| Posicoes / ordens | **0 / 0** | `get_trading_open_positions` |
| Terminal | build **6308**, `synchronized`, ping 214 ms, reconexao as 14:07Z (11:07 local) | `get_trading_account_info` |
| Versao | `#property` 1.388 / EA **1.2.188** / EV **1.2.188** | 3 fontes |
| Binario **da frota** | 970 168 B, 05:59:42, MD5 **943DB7CB6955299C6A470141B942BC54** | journal + carga 09:34 |
| Binario **em disco hoje** | 969 944 B, 10:25:59, MD5 **5C99AF0CDCE1E2C74D39270C21047607** | `Get-FileHash` 11:52 |
| Graficos | **16** abertos (15 com EA + **1 sem EA**) | `list_open_charts` |
| EAs a correr | **15/15** v1.2.188 no perfil `XAU_AI_PRO_15CHARTS_Q071` | idem |
| USDBRL (chart13) | **M5** confirmado (regra do P1.3481 cumprida) | idem |
| Gateway 9011 | UP, `/api/health` 401 sem token (vivo) | sonda CMD D-109 |
| Mercado | **FECHADO** - `[TRADE BLOCK] COTACAO VELHA`, idade 146 104-171 307 s vs limite 900 s | `Logs\20261108.log` 11:34-11:35 |
| Tarefas | 4 `Ready`; **ForwardInicio = 11/09 00:05:00** (nunca correu) | `Get-ScheduledTask` 11:52 |
| GATE_REAL | **2 de 11** | `EQUIPE/GATE_REAL.md` |
| Forward | **0 de 30** dias | idem |
| Risco em uso | 1,0 / 10,0 / 50,0 / 2,0 / 8,0 / 10,0 / 65,0 (treino de demo) | inputs reais dos 15 graficos |
| Git | HEAD `46117fcc`; arvore com **1** untracked (o meu relatorio ao ALFA) | `git status` |

---

## 2. Factos novos (nao estao em nenhum relatorio ainda)

### F-A. Ha' um **16º grafico**, sem EA, criado as 10:57:16

`chart16.chr` (2 040 B) foi **criado** 08/11 **10:57:16** dentro do perfil
`XAU_AI_PRO_15CHARTS_Q071`, com `XAUUSD,H1` e **sem expert advisor**
(`list_open_charts`: o bloco `expert` nao existe nesse grafico). No mesmo
segundo, os `chart01..chart15.chr` foram **reescritos** (10:57:16) - ou seja, o
perfil foi **gravado** nesse instante.

Consequencias medidas:
- O perfil chama-se `15CHARTS` e tem **16**;
- **G10 fica pior do que estava escrito**: era "15 graficos vs 11 em `Symbols`",
  passa a **16 vs 11**;
- A frase "frota 15/15" continua correcta **para EAs**, e passa a ser falsa se
  alguem a ler como "15 graficos";
- **Risco operacional: nenhum.** Grafico sem EA nao abre ordem. Mas o MT5 grava
  este estado no perfil ao fechar, e um `profile_apply` futuro reproduz os 16.

Nao foi nenhum agente a declarar. A janela (10:55-11:00) e' do ALFA (lock
10:22-10:59) e a leitura mais provavel e' grafico de medicao para o G4/G8, mas
**nao esta' escrito em lado nenhum** - fica `P1.3491` para atribuicao, sem
acusacao. Nao fecho o grafico: pode estar a ser usado.

### F-B. O "git add largo" repetiu-se no `46117fcc`

Commit `46117fcc` (CMD, 11:45) toca 10 ficheiros e leva dentro a **minha**
reescrita do `GATE_REAL.md` (zona DELTA) e o `D-110`/`P1.3489`/`P1.3490` do
`IDS.md`, ao lado dos 3 `.ps1` do P1.3488. O assunto diz "correccoes DELTA",
portanto a atribuicao existe no texto - mas nao nomeia os dois autores. Mesmo
padrao do `86d1ac96` que o ALFA apontou. Nada se perdeu (os IDs estao no corpo
do `IDS.md`, que e' a fonte citavel). Regra a partir de agora: **assunto nomeia
os dois agentes quando o commit leva ficheiros dos dois.**

### F-C. O `.ex5` em disco **nao e'** o do forward

Sao dois ficheiros diferentes e isto ja' esta' no G11, mas agora tem numero
fresco: disco = **5C99AF0C** (969 944 B, 10:25:59); frota e forward =
**943DB7CB** (970 168 B, 05:59:42). A declaracao do forward esta' **intacta**
(confirmado: nenhum `.mq5`/`.mqh` com mtime depois das 06:00 - filtro devolve
vazio). O perigo concreto: **qualquer reanexo hoje apanha o `5C99AF0C`** e o
MD5 muda a meio da janela.

---

## 3. Scoreboard: os 11 itens, o que trava cada um, de quem e'

| ID | Estado | O que falta (concreto) | Dono | Precisa de binario novo? |
|---|---|---|---|---|
| **G1** | VERMELHO | conta live real, distinta da demo | DONO | nao |
| **G2** | VERDE c/ ressalva | subir o gateway como **servico Windows** (nao sobrevive a reboot) | DONO (Q-022) | nao |
| **G3** | VERDE auditado | taxa de emissao `[SCORE]` = **4 linhas em 8 dias** → sem amostragem forcada nao se reproduz em forward (`P1.3489`) | DELTA mede / ALFA corrige | **SIM** |
| **G4** | VERMELHO | 24 h de contador com mercado aberto (`[ATR] SEM LEITURA`=0, `HANDLE MORTO`=0 ja' medidos em 4 h 20) | DONO autoriza / DELTA mede | nao |
| **G5** | VERMELHO | **decisao do DONO**: 37 trades/3 meses → 100 trades exige ~8,1 meses | DONO (Q-026) | nao |
| **G6** | VERMELHO | backtest ok (DD 1,77 %), falta forward **e** 0/30 | tempo | nao |
| **G7** | VERMELHO | PF 0,6603 < 1,20 - o sistema perde por unidade de risco | ALFA | **SIM** |
| **G8** | VERMELHO | 44 trades < 100 e a v1.2.188 tem 0 trades (a frase "0 shorts" era falsa: 68,2 % short) | DELTA mede | nao (o forward resolve) |
| **G9** | VERMELHO | declarar `<= 3 / <= 6 / <= 0,5`; em uso 10,0 / 15,0 / 1,0 | DONO (Q-017) | nao |
| **G10** | VERMELHO | universo coerente: **16 graficos vs 11 `Symbols`** (+ F-A) | DONO (Q-013) | nao |
| **G11** | VERMELHO | 30 dias no binario declarado; arranca **09/11 00:05** | DONO autoriza / DELTA mede | nao |

**Leitura:** 8 dos 9 vermelhos **nao precisam de uma linha de codigo**. So' G3 e
G7 pedem source - e G7 (PF) e' a decisao de risco/retorno que nenhum agente
pode tomar sozinho.

---

## 4. As 5 decisoes que nao sao dos agentes

1. **Q-026 / G5** - janela de 100 trades. Alargar para ~8 meses (e o forward de
   30 dias deixa de fazer sentido sozinho) ou baixar o piso de 100. **Sem
   decisao, o G5 nunca fecha** por construcao.
2. **Q-017 / G9** - escrever por carta os limites de conta real. Os valores em
   uso sao de treino: `MaxDailyLossPercent 10,0` (limite pedido 3),
   `MaxDrawdownPercent 50,0` (6), `RiskPercent 1,0` (0,5). **Nao se abrem
   posicoes de conta real com estes numeros**, com ou sem forward.
3. **Q-013 / G10** - universo: 11 nomes em `Symbols`, 16 graficos, 1 modelo
   publicado (XAUUSD). Decidir se o forward mede 1 simbolo ou 15.
4. **Q-022 / G2** - gateway como servico. Hoje e' processo manual: um reboot
   as 23:50 deixa o forward cego ate' alguem o levantar.
5. **G1** - quando a conta real existe. Nao ha resposta tecnica a dar aqui.

---

## 5. Caminho critico ate' 09/11 00:05 (18 h)

Isto **nao** e' plano de trabalho, e' lista de verificacao. Nada de source.

| Quando | O que | Quem | Como se prova |
|---|---|---|---|
| antes de 08/11 23:50 | nada a fazer. **Nenhum** compile, nenhum `profile_apply`, nenhum reanexo | todos | journal sem `[START]` novos |
| 08/11 23:50 | `DonoRelatorio` dispara | tarefa | `Get-ScheduledTaskInfo` |
| 09/11 **00:04** | confirmar que o binario em memoria continua o 943DB7CB e que o disco ainda tem 5C99 (nao reanexar) | DELTA | `[VERSION]` + hash |
| 09/11 **00:05** | `XAU_AI_PRO_ForwardInicio` dispara (nunca correu: `last=30/11/1999`) | tarefa | idem |
| 09/11 00:05-00:10 | confirmar que `sem tick` cai e `COTACAO VELHA` desaparece | DELTA | `get_expert_journal` |
| 09/11 00:10 | **1ª captura** `delta-captura-d089.ps1 -Dia 20261109` | DELTA | ficheiro de saida |
| diario 00:10 | repetir a captura; `G11 = n/30` | DELTA | idem |

**Regra de aceitacao ja' escrita (P1.3490):** so' conta como exercicio do
Q-079/B a linha `TREND CONTRA OK` que contiver **`dentro da folga`**. As 57
historicas sao todas fallback (`contramao PERMITIDA`) e **nao promovem nada**.

---

## 6. As tres opcoes de proximo passo

### Opcao A - **Congelar e medir** (recomendada)
Nao se toca em source ate' 09/12. O forward arranca no 943DB7CB e corre 30 dias
limpos. Em paralelo so' trabalho **que nao muda binario**: docs, scripts de
medicao, `.set`, decisoes do DONO, atribuicao do F-A.

- Custo: 30 dias sem corrigir P1.3478/P1.3485.
- Ganho: a unica janela que nao se repete. Uma correccao agora custa **mais 30
  dias**, nao mais um dia.

### Opcao B - Corrigir P1 agora
`P1.3478` (TrendFilter devolve EMA de outro simbolo), `P1.3485` (o `.set` nao e'
a corrida A), `P1.3486` (cabecalhos de versao). Isto **obriga a compile** →
`.ex5` novo → **MD5 novo** → reanexo → o forward de 09/11 mede outro build, ou
seja, **os 30 dias recomecam**.

- Custo: **30 dias**, e o G11 volta a 0/30 no dia em que se decide.
- Ganho: menos ruido de log e um `.set` reprodutivel. Nada que mude o PF.

### Opcao C - Hibrido (o que eu faria se o DONO quisesse corrigir)
Fazer **P1.3486 e P1.3485 agora** (sao texto e `.set`: nao mudam binario) e
deixar **P1.3478 para depois dos 30 dias**. Ganha-se reprodutibilidade sem
mexer no MD5.

---

## 7. O que estragava tudo (e como se evita)

O forward vale o que valer o **binario unico**. Tres gestos partem-no:

1. **Compilar** → muda o `.ex5` em disco; o proximo reanexo apanha o novo.
2. **`profile_apply` / `chart_add_expert` / template com EA** → reanexa e le' o
   `.ex5` **do disco**, que hoje e' o `5C99AF0C`.
3. **Reiniciar o terminal** → nao divide o binario (recarrega o mesmo em
   memoria, como se provou as 09:34), mas reinicia o uptime e **adia o job das
   24 h do G4**. E, se o `.chr` for salvo com o grafico 16, o perfil muda.

Prevencao: **nenhum compile, nenhum reanexo, nenhum `profile_apply` ate'
09/12.** Se for inevitavel, o MD5 do DOSSIE muda e o G11 volta a 0/30 - e isso
tem de estar escrito antes, nao depois.

---

## 8. Pendencias abertas que tocam a janela

| ID | Estado | Toca a janela? |
|---|---|---|
| `P1.3478` TrendFilter le' EMA de outro simbolo | medido **0** ocorrencias na v1.2.188 em 4 h 20; fecha com o job de 24 h | **nao corrigir agora** (muda MD5) |
| `P1.3485` `DELTA_186_A.set` nao e' a corrida A (16 linhas diferentes) | ABERTO, do CMD/DONO | **pode corrigir-se agora**: `.set` nao muda binario |
| `P1.3486` cabecalhos `v1.2.183` / `v1.2.9` no source | ADIADO de proposito | comentario muda o mtime → **hoje nao** |
| `P1.3489` `[SCORE]` sai 4x em 8 dias | ABERTO, defeito e' taxa de emissao | limita o G3 no forward; **correccao = novo build** |
| `P1.3490` Q-079/B nunca exercitado | ABERTO, criterio de aceitacao proposto | **e' o que o forward vai testar** |
| `P1.3491` 16º grafico sem EA (F-A) | NOVO | nao bloqueia; resolver antes de fechar o terminal |
| `P-05` `origin` (forge.mql5.io) credenciais expiradas | herdado | nao |

IDs livres: **`P1.3492`** e **`D-111`** (usei P1.3491; D-111 fica para quem
decidir).

---

## 9. O que este consolidado NAO faz

- **Nao promove nada.** GATE_REAL continua **2 de 11**; forward **0 de 30**.
- **Nao assina dossie.** O `DOSSIE_FINAL.md` so' se assina com **11/11 + 30
  dias**, e o numero e' sempre `x/11`, nunca "10/10".
- **Nao decide** G5, G9, G10, G2 nem G1 - sao do DONO e estao no §4.
- **Nao corrige** nenhum P1. Nenhum `.mq5`/`.mqh` foi tocado, nada foi
  compilado, nada foi reanexado, nenhuma ordem foi enviada, o risco esta'
  intocado.

---

## 10. Se so' houver tempo para ler uma coisa

> Falta **meio dia** para a unica janela de 30 dias que este projecto tem.
> O binario esta' congelado e provado no 943DB7CB. **A decisao de hoje nao e'
> o que corrigir - e' nao corrigir nada durante 18 horas** e responder as 5
> perguntas do §4, que sao as unicas que continuam a travar o GATE sem
> depender de mercado.
