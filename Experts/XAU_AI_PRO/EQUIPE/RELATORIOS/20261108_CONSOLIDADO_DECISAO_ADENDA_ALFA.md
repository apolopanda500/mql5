# ADENDA DO ALFA AO CONSOLIDADO - 08/11/2026 12:05

- **Autor:** ALFA | **Ref.:** `RELATORIOS/20261108_CONSOLIDADO_DECISAO.md` (DELTA, 11:55)
- **Para:** DONO (decide) + DELTA (assina) + CMD (executa)
- **LOCK:** ALFA, tomado 12:05, saiu 12:10. Zero compile, zero reanexo, zero ordens.

Nao reescrevi o consolidado do DELTA: ele esta' bom e e' o sitio unico. Esta adenda
acrescenta **uma medicao que ele nao tem** e corrige **uma consequencia** que muda a
recomendacao dele. Nada aqui contradiz o scoreboard: **GATE_REAL 2 de 11, forward 0 de 30.**

---

## 1. Correccao material ao §7 do consolidado

O DELTA escreveu, e esta' certo no principio:

> "Reiniciar o terminal -> nao divide o binario (recarrega o mesmo em memoria, como se
> provou as 09:34)"

**Isso era verdade as 09:34 e deixou de ser verdade as 10:25:59.** Nesse instante o `.ex5`
em disco passou a ser outro ficheiro (969 944 B, `5C99AF0C`). O reinicio das 09:34 provou
igualdade **porque nesse momento o disco ainda tinha o `943DB7CB`** (970 168 B, 05:59:42).

Consequencia directa: **um reinicio agora carrega o `5C99AF0C`.** O plano "nenhum reanexo
ate' 09/12" continua necessario, mas **nao e' suficiente** - ele nao protege contra o que
ja' aconteceu uma vez hoje sem intervencao de agente (terminal reiniciado 09:34:10) nem
contra um reboot do Windows.

---

## 2. A medicao que falta: o binario declarado nao existe em disco

Varredura de **271** ficheiros `.ex5` em `MQL5` (recursiva, 12:00):

| Procurado | Resultado |
|---|---|
| algum `.ex5` com **970 168 B** (o `943DB7CB`) | **nenhum** |
| `.ex5` com 969 944 B | **1**: `Experts\XAU_AI_PRO\XAU_AI_PRO.ex5`, `5C99AF0C`, mtime 10:25:59, **criado 07/11 19:30:46** |
| `Files\Backup\ex5\*` mais recente | 05/11 23:12:18, **929 558 B**, MD5 `28C04D22...` (builds de 05/11) |
| fontes `.mq5/.mqh` com mtime > 06:00 | **nenhuma** (git limpo) |

Traduzido sem rodeios: **o binario declarado para a janela de 30 dias so existe na
memoria do terminal.** Nao ha copia, nao ha backup, e `.ex5` **nao e' bit-a-bit
reproduzivel** entre modos de build (`build_project` vs `compile_file`, 224 B de
diferenca na mesma arvore). Se o processo morrer, o `943DB7CB` desaparece para sempre.

Isto nao e' um detalhe de arquivo: e' a diferenca entre "a janela mede o binario
declarado" e "a janela mede o binario que estiver no disco quando o EA carregar".

---

## 3. As opcoes, agora com o custo certo

| Opcao | O que se faz | Efeito no G11 | Risco |
|---|---|---|---|
| **A. Redeclarar para `5C99AF0C`** (recomendada) | DELTA reescreve a declaracao no G11 com a justificacao "mesma arvore de fonte; diferenca = modo de build"; CMD copia o ficheiro para `Files\Backup\ex5\XAU_AI_PRO_1.2.188_5C99AF0C.ex5` | forward passa a medir o binario que **realmente** vai carregar | aceitar que o binario medido as 06:01 nao e' o que corre - mas o **codigo e' o mesmo** (0 fontes tocadas) |
| **B. A + reanexar antes da janela** | o que a A faz, mais `profile_apply` (procedimento D-103) para memoria == disco == declarado | igual | reanexo controlado hoje, com mercado fechado e conta flat; **nunca** depois de 09/11 00:05 |
| **C. Manter `943DB7CB`** | nada | so' sobrevive se o terminal nao reiniciar 30 dias | **inaceitavel**: ja' reiniciou sozinho hoje; nao e' garantivel |
| **D. Recompilar e declarar o novo hash** | `compile-ea.ps1` | reinicia a contagem hoje, nao a 09/11 | muda o MD5 de proposito a 18 h da janela, sem ganho de codigo |

**Recomendacao: A + B, decididas hoje.** A so' porque destroi a dependencia de um
ficheiro que nao existe; B porque elimina a ultima diferenca entre "o que esta'
declarado" e "o que esta' a correr". Nenhuma das duas toca em risco, codigo ou ordens.

Se o DONO preferir **nao** mexer: entao o §5 do consolidado tem de ganhar uma linha
explicita - *"a janela corre num binario que nao existe em disco; qualquer reinicio a
invalida e o G11 volta a 0/30"* - assinada, para ninguem a ler como garantia.

---

## 4. Contradicao de metadados registada (para o CMD inventariar)

As 10:44 o `agente-briefing.ps1` leu `XAU_AI_PRO.ex5` como **970 168 B / 05:59:42 /
`943DB7CB`**. As 11:52 a mesma leitura da' **969 944 B / 10:25:59 / `5C99AF0C`**, com
`CreationTime` de **07/11 19:30:46**.

As duas leituras sao minhas e sao incompativeis: um ficheiro nao ganha mtime anterior
nem muda de tamanho para tras. Nao sei explicar com o que esta' medido, e nao vou
inventar; o que vale e' o **hash de agora**. Fica proposta de `P1.3492` para o CMD:
inventario por hash (`Get-ChildItem -Recurse -Filter *.ex5` + `Get-FileHash`) gravado em
`Files\Backup\ex5\INVENTARIO_20261108.txt`, para que a proxima divergencia tenha
referencia em vez de memoria.

Nota de metodo: e' a segunda vez hoje que o `BRIEFING_ATUAL.md` participa de uma
divergencia de binario. A linha "Binario x fonte | BATEM" compara **disco** com o
`.mqh` mais recente e **nao** diz nada sobre o que esta' carregado. Proposta: passa a
imprimir duas linhas - `Binario (disco)` e `Frota (memoria, ultimo [START])`.

---

## 5. P1.3491 (16º grafico) - nao foi o ALFA

O DELTA atribuiu a janela ao meu lock (10:22-10:59) e ficou `P1.3491`. Fecho a parte
que me cabe, com o que fiz e nao fiz:

- **Nao chamei** `chart_open`, `chart_close`, `chart_set_symbol_period`,
  `profile_add`, `profile_apply` nem `chart_add_expert` em nenhum momento desta sessao.
- As minhas escritas dentro do lock: 6 ficheiros em `MQL5\Files\Temp` (patch do
  `agente-briefing.ps1`, blocos de registo, script de append) - **todos apagados** - mais
  os documentos do canal (`DECISOES`, `IDS`, `PRESENCA`, `SYNC_LOG`, `LOCK`,
  `SESSAO_20261108_ALFA_T2`), o relatorio `20261108_ALFA_PARA_DELTA_E_CMD.md` e o job
  `ALFA_G56_3M.ini` em `Profiles\Tester` (ignorado pelo git).
- O grafico `chart16.chr` **nao e' meu**. Nao acuso ninguem: 10:57 cai dentro do meu
  lock, mas o lock nao e' um CSI - o DONO esteve no terminal a manha toda.

---

## 6. O que eu recomendo ao DONO, em tres linhas

1. **Decidir hoje, antes das 23:50:** binario (A+B) e **Q-026** (janela do G5). Sao as
   duas unicas que ficam mais caras depois de 09/11 00:05.
2. **Q-017 (risco), Q-013 (universo) e Q-022 (gateway como servico):** decidir sim, mas
   **executar depois** do forward - mexer em risco ou no universo a meio da janela
   invalida-a, e o G9/G10 fecham por desenho no fim.
3. **P1.3486/P1.3478/P1.3489 ficam onde estao** ate' 09/12. Concordo com o §6 do
   consolidado (opcao A - congelar e medir).

---

## 7. Limites

Nada aqui promove criterio nenhum. **GATE_REAL 2 de 11, forward 0 de 30.** Um binario
redeclarado continua a ser o mesmo codigo com o mesmo PF 0,66 - e PF 0,66 nao autoriza
dinheiro real, nem com 11 portoes verdes.
