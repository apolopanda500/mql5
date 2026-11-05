# Autoupdate / auto-deploy do XAU_AI_PRO

Documento operacional do ciclo 104 (04/11/2026 21:30). Substitui o procedimento
manual de "compilar a mao + reanexar a mao + verificar a versao a olho".

## Porque existe

Três defeitos recorrentes deste projecto nasceram de passos manuais:

1. **HG-01 / HG-02** - o header dizia `v1.2.141` enquanto `#property version`
   ainda era `"1.340"`. O compilador nao avisa; o erro so aparece a correr.
2. **Compile falhado apaga o `.ex5`** - ja aconteceu (`Result: 8 errors`) e deixaria
   os 15 graficos sem binario no reload seguinte.
3. **Compilar nao reanexa** - o MT5 guarda os inputs no acto do attach. Sem
   `profile_apply` os graficos continuam a correr a build ANTERIOR em memoria, o que
   ja produziu "provas" com a build errada.

## Como usar

```powershell
# ciclo normal: gate de versao + compilar + verificar o .ex5 + imprimir o reattach
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\auto-deploy.ps1

# idem, e depois commit/push para os dois remotes
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\auto-deploy.ps1 -Commit -Message "tipo(escopo): descricao"

# so o gate de versao e a verificacao do binario actual (sem compilar)
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\auto-deploy.ps1 -SkipCompile
```

Saida esperada de um ciclo limpo:

```
=== 1. Gate de versao (HG-01 / HG-02) ===
  [..]   header              = 1.2.146
  [..]   #property version   = "1.346"   (esperado "1.346")
  [..]   EA_VERSION_STRING   = "1.2.146"
  [OK]   versao tripla coerente: 1.2.146
=== 2. Compilacao via metaeditor64 ===
  [..]   Result: 0 errors, 0 warnings, 19634 ms elapsed, cpu='X64 Regular'
=== 3. Verificacao do .ex5 publicado ===
  [OK]   .ex5 publicado e mais recente que todas as fontes
=== 4. Reattach obrigatorio (passo MCP, nao automatizavel) ===
```

## O que esta automatizado e o que nao esta

| Passo | Automatizado | Ferramenta |
|---|---|---|
| Coerencia da versao tripla | **sim** | `Tools\auto-deploy.ps1` (bloqueante) |
| Compilacao | **sim** | `metaeditor64.exe /compile /log /inc` |
| Leitura do log UTF-16 e contagem de erros/avisos | **sim** | o mesmo script |
| Prova de que o `.ex5` existe e e mais recente que as fontes | **sim** | o mesmo script |
| Commit e push para `github` e `origin` | **sim** (`-Commit`) | o mesmo script |
| **Reattach nos 15 graficos** | **NAO** | `profile_apply` (MCP) |

O reattach nao pode viver num `.ps1` porque `profile_apply` e uma accao do servidor
MCP do terminal; nao existe equivalente em MQL5, em CLI nem em ficheiro de
configuracao que dispare a reanexacao em quente. O script imprime a sequencia
obrigatoria em vez de a fingir:

```
1) metatrader5__profile_apply  profile_name=Default
2) metatrader5__profile_apply  profile_name=XAI_P216_LIVE
3) metatrader5__get_expert_journal  filter=[START]
4) metatrader5__get_expert_journal  filter=PRICE=0.00000
```

O passo 1 e necessario: `profile_apply` de um perfil diferente do que esta seleccionado
nao recarrega os `.chr` se o perfil alvo ja for o actual. Aplicar `Default` primeiro
forca a releitura.

## O que este script NAO faz (deliberado)

- **nao** faz self-update do binario a partir de git/HTTP (opcao 3 do ciclo 103).
  Essa opcao continua proibida sem confirmacao explicita do dono: exige hash/assinatura
  e uma trava de seguranca, e um EA que se substitui a si proprio e superficie de
  ataque. Se for pedida, entra como `P-06` com desenho proprio;
- **nao** altera risco, inputs, `.set`, contas nem ordens;
- **nao** faz `reset`, `checkout` destrutivo, force-push nem rebase.

## Relacao com o toolkit existente

`Tools\agent-toolkit.ps1` continua a ser o ciclo generico (`status`, `check`,
`compile`, `commit`, `push`, `deploy`, `full`), com validacao estatica UTF-8 e
balanceamento de chaves. O `auto-deploy.ps1` e o portao especifico do EA:
acrescenta o gate da versao tripla e a prova de frescura do `.ex5`, que o toolkit
nao tem. Os dois nao se substituem.

## Historico

| Ciclo | Data | Resultado |
|---|---|---|
| 104 | 04/11/2026 21:30 | script criado; primeira execucao `0 errors, 0 warnings`, `.ex5` 869028 B, reattach confirmado em 15 graficos |
