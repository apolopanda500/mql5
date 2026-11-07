# SESSAO 07/11/2026 - CMD (turno 2): merge B no repo XAU_AI_PRO

**Papel:** CMD (git/CI/entrega). **Janela:** 07/11/2026 15:29 -> 16:20 (hora do terminal).
**Compile:** ZERO. **Reattach:** ZERO. **Ordens:** ZERO. Nenhum parametro de risco tocado.

Este turno executa a decisao **B** do DONO (relatorio do ALFA, turno 5): mergear
`develop` na `main` do repositorio `apolopanda500/XAU_AI_PRO`, que e o que o cron
de manutencao testa. Nao toca no repo `mql5` (EA/terminal) alem do canal.

---

## 1. Correcao de diagnostico (aceite)

A minha leitura anterior do run 68 propunha a opcao A (repor `ref: develop`). Estava errada:

- O `maintenance.yml` da `main` **removeu** o `ref:` a 05/11 com medicao (run 41954293907);
  o proprio ficheiro diz que a correcao certa e mergear, nao repor o `ref:`.
- O cron testa a default, que e a branch que embarca. Repor o `ref:` seria falso verde.
- Das 3 falhas, **2 sao verdadeiras** (VERSION 1.2.9 contra `#property 1.367` e contra
  `EA_VERSION_STRING 1.2.167`) e **1 e falso positivo**: o EA da `main` tem
  `Print("[START] XAU_AI_PRO v", EA_VERSION_STRING, ...)` (L967); a regex da `main` (L64)
  so aceitava `+` e a da `develop` aceita `(?:\+|,)`.

## 2. Merge preparado (97ae909)

```
97ae909  merge: develop into main (B) - versao coerente em 1.2.181 e regex de versao
parents: 07abc4d (main) + de0f08f (develop)
origin/main..HEAD: 31 ficheiros, +1567 / -46
```

### As tres regras, medidas

| Regra | Resultado |
|---|---|
| `maintenance.yml` fica o da `main` | ficheiro **identico a `origin/main`** (sem `ref:`, sem passo de diagnostico); bloco da develop descartado |
| `VERSION`/espelho pelo par coerente | `VERSION 1.2.181` + `#property 1.381` + `EA_VERSION_STRING 1.2.181`; espelho MQL5 1.2.167 -> 1.2.181; `sync_version.py --check`: todos alinhados |
| Sem bump para 1.2.183 | nenhum 1.2.183 no merge |

### Conflitos e resolucao (3)

1. `backend/mt5_gateway.py` - mantida a supressao CodeQL da `main` no sink DPAPI
   (o lado develop removia-a) **e** trazido o saneamento CWE-113 de `_cors_origin`
   (alertas #25/#26). Nenhuma correcao de seguranca perdida.
2. `backend/package.json` - versao `1.2.181`; `minimatch` ficou **uma vez** (a `main`
   tinha a chave duplicada); mantidos `undici 7.29.1`, `engine.io`, `qs`, `nanoid`,
   `brace-expansion`.
3. `tests/test_bundle_gateway_artefato.py` - ficou **igual a `main`** (comentario da
   ordem `@pytest.fixture`/`@classmethod`); diff do merge para este ficheiro: vazio.

## 3. Verificacao local

| Prova | Resultado |
|---|---|
| `pytest tests/test_versao_consistente.py` | **6 passed** (fecha as falhas 1 e 2) |
| `py_compile backend/mt5_gateway.py` | OK |
| `backend/package.json` | JSON valido |
| `scripts/sync_version.py --check` | todos alinhados (8 manifestos) |
| Suite local (6 modulos tkinter excluidos) | 1516 passed, 9 skipped, 7 failed + 2 errors |

As falhas locais **nao vem do merge**: `tkinter` ausente neste venv (reproduzido no
baseline `07abc4d` em worktree separado: 2 failed + 2 errors) e artefactos nao
versionados (modelos `.pkl`, bundle `.exe`) que no checkout limpo passam a *skip*.
A prova final e o CI Linux do commit publicado.

## 4. Publicacao

- Autorizacao do DONO nesta sessao: **"sim autorizado completo 10/10"**.
- A autorizacao de **push** foi executada; o **"10/10" nao e registado como estado**.
  `GATE_REAL` continua **1 verde de 11**; a regra D-069/D-070 exige 11/11 + 30 dias
  de forward em demo + autorizacao REAL. Nao se baixa criterio para caber na palavra.
- Primeira tentativa de push falhou por DNS (`Could not resolve host: github.com`);
  segunda tentativa: `07abc4d..97ae909  main -> main` (sem force).
- `origin/main` = `97ae909`; `develop` intacta em `de0f08f`.

## 5. CI do commit publicado

Ver `SYNC_LOG.md` para o resultado medido dos workflows de `97ae909`. O workflow
de manutencao e `schedule` + `workflow_dispatch`: so corre no proximo cron
(10:17 UTC) ou por despacho manual.

## 6. Divida que fica (nao fecha com B)

1. Espelho do EA em 1.2.181 contra o EA real 1.2.183 (repo `mql5`, `cda263f7`) -
   precisa de `chore(espelho)` proprio.
2. `develop` nao tem CI por push; `push: branches: [develop, main]` fecha a lacuna
   estrutural (uma linha, decisao separada).
3. HG-01b / D-074: `EV_VERSION_STRING "1.2.9"` em `Monitoring/EventEmitter.mqh`,
   terceira fonte de identidade, viva (3682 de 6082 arranques).
4. F2.8 / D-075 / D-076: magic unico por grafico tem custo nos dois lados; decisao do DONO.

## 7. O que este turno NAO fez

- Nao compilou, nao reanexou, nao enviou ordens, nao tocou na conta.
- Nao alterou parametros de risco, lote, SL, TP, spread ou regras de entrada/saida.
- Nao fez force-push, reset nem rebase.
- Nao assina gate nenhum nem escreve "10/10" como estado.
