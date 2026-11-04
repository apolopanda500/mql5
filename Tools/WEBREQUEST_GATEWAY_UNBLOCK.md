# Desbloquear o caminho EA -> gateway de IA

Medido em **2026-11-04, entre 16:20 e 16:35**, com o `terminal64` pid **12016**
no ar e **nenhum** processo de gateway.

Este documento substitui a conclusao anterior ("401 = credencial recusada").
Aquela conclusao estava errada: o `401` de 03/11 veio do **MCP embutido do MT5**,
que escuta a mesma porta que o EA usa, nao do gateway.

---

## 1. O que foi medido

| # | Medicao | Evidencia |
|---|---|---|
| 1 | A porta **9001** pertence ao terminal, nao ao gateway | `config\assistant.ini` -> `[MCP.MetaTrader] Endpoint=http://127.0.0.1:9001/mcp`; `Get-NetTCPConnection` mostra `127.0.0.1:9001` LISTEN no pid **12016 (terminal64)**, com 4 conexoes estabelecidas |
| 2 | Nada escuta em **9011** | `Get-NetTCPConnection -LocalPort 9011` vazio; `XAU_GATEWAY_PORT=9011` existe no ambiente do usuario |
| 3 | O EA aponta para 9001 | `Core\Config.mqh:38` -> `AIGatewayUrl = "http://127.0.0.1:9001/api/ai/predict"` |
| 4 | Os 15 graficos vivos estao com URL 9001 e **token vazio** | `Profiles\Charts\Default\*.chr` (15 ficheiros): `AIGatewayToken` len **0** em todos |
| 5 | O preset versionado tem um **placeholder** de 17 caracteres | `Presets\XAU_AI_PRO.PRO.set` -> `AIGatewayToken` len 17, contem a palavra `TOKEN`, nao e alfanumerico puro. E a origem do "17 caracteres" do relatorio anterior |
| 6 | O token real tem **64** caracteres | `Files\XAU_AI_PRO\.env`, linha 47 (`XAU_GATEWAY_TOKEN`, valor nunca impresso) |
| 7 | O EA usa **POST** | `AI\AIConnector.mqh:665-673` -> `WebRequest("POST", url, ...)` |
| 8 | O FastAPI so declara **GET** nessa rota | `backend\fastapi_gateway.py:258` -> `@app.get("/api/ai/predict")`. Nao existe `@app.post` nem `api_route` para ela |
| 9 | O **exe instalado** nem tem a rota | `%LOCALAPPDATA%\XAU AI PRO\bridge\mt5-gateway.exe`, 25/10/2026, 34 609 260 B: nao contem `/api/ai/predict` nem `/api/ai/models` -> servidor `mt5_gateway`, que responde `404 not_found` |
| 10 | A allowlist do WebRequest esta ligada, mas e ilegivel | `config\common.ini`: `WebRequest=1` + `WebRequestUrl=<blob cifrado>`. So a GUI altera/le |

## 2. As tres causas, em ordem de precedencia

1. **Porta errada (nao e configuracao de token).** O EA chama `127.0.0.1:9001`,
   que e o **MCP do proprio MT5**. Qualquer chamada ali e atendida pelo
   terminal. O gateway esta configurado para `9011` e nao esta a correr.
   O `401` de 03/11 foi o MCP a recusar uma rota que nao e dele — por isso o
   texto "token RECUSADO" induziu em erro.
2. **Metodo/rota.** Mesmo com porta e token certos: o EA faz `POST`, o FastAPI
   so aceita `GET` (**405**), e o exe instalado nem inclui a rota (**404**).
3. **Credencial.** Os 15 graficos enviam `Authorization` nenhum; o preset envia
   um placeholder de 17 caracteres. O `/api/ai/predict` e protegido pelo
   middleware (`fastapi_gateway.py:104-112`), logo sem o token exato e `401`.

Consequencia: **nao existe hoje nenhum caminho em que a IA responda ao EA**,
mesmo que o dono cole o token. Resolver apenas o token nao desbloqueia nada.

## 3. Ordem correta de desbloqueio

### Passo 0 — decidir a porta (dono)

`9001` nao pode ser usada enquanto o terminal tiver o MCP ligado — e ele esta
ligado. A decisao natural e **manter 9011** e mudar o `AIGatewayUrl` nos
graficos. A alternativa (desligar o MCP do MT5) tira funcionalidade ao terminal
para poupar uma edicao de input; nao recomendo.

### Passo 1 — subir o gateway em 9011, sem gates de trade

**Nao** use `start_gateway.bat` para este teste: ele liga
`XAU_ENABLE_REAL_ORDERS=1`, `XAU_ENABLE_MT5_EXECUTION=1` e
`XAU_ENABLE_TRADE_COMMANDS=1`. Para medir IA nao e preciso nada disso.

```
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\start-gateway.ps1
```

O script forca os cinco gates de execucao a `0`, fixa `XAU_GATEWAY_PORT` e sobe
`uvicorn backend.fastapi_gateway:app` em `127.0.0.1:9011`. Alternativa manual:

```
cd ...\MQL5\Files\XAU_AI_PRO
.\.venv\Scripts\python.exe -m uvicorn backend.fastapi_gateway:app --port 9011 --host 127.0.0.1
```

**Medido:** a `.venv` **nao existia** nesta maquina nem havia `fastapi` no Python
portatil (`Files\Temp\py311`, 3.11.9). Criada com `virtualenv` + `pip install -r
requirements.txt`. O exe instalado continua a ser anterior a rota e nao a serve.

### Passo 2 — resolver o metodo (FEITO na v1.2.132)

O EA passou a usar **GET** em `AI/AIConnector.mqh` (corpo vazio, `Authorization:
Bearer` mantido, `symbol`/`timeframe` na query string). Decisao do dono:
corrigir o cliente, nao alargar o servidor. O `result_headers` deixou de ser o
mesmo buffer do cabecalho de entrada.

Validacao: MetaEditor64 -> **0 errors, 0 warnings** (23 650 ms); `validate_mql5.py`
-> `[OK]`; `XAU_AI_PRO.ex5` regravado as 16:33:33 (825 112 bytes).

**Falta:** o terminal so recarrega o EA; os *inputs* dos 15 graficos nao mudam
sozinhos. A porta e o token continuam a ser os passos 3 e 4.

Alternativa considerada e **nao** feita: aceitar `POST` no gateway. Ficou
registada porque evitaria recompilar, mas o dono escolheu a correcao de contrato.

### Passo 3 — allowlist na GUI (dono, nao automatizavel)

`Ferramentas > Opcoes > Expert Advisors`:

- [ ] `Permitir WebRequest para URLs listadas` marcado
- [ ] `http://127.0.0.1:9011` na lista (o `9001` que ja esta la nao serve)
- [ ] (Telegram) `https://api.telegram.org`

A lista e um blob cifrado em `config\common.ini`; nenhuma ferramenta a le.

**FEITO em 04/11 18:06 — e a causa do "nao salva" esta identificada.**

O terminal **descarta em silencio** entradas escritas com caminho ou barra final
(`http://127.0.0.1:9011/api/ai/predict`, `http://127.0.0.1:9011/`). A prova e o
tamanho do `common.ini`, que **encolheu** de 5916 para 5324 B numa dessas
tentativas. Gravou quando a entrada foi escrita como:

```
http://127.0.0.1:9011
```

com `Add` -> `OK` (sub-janela dos URL) -> `OK` (janela Options). Resultado medido:

| Antes | Depois |
|---|---|
| `common.ini` 5324 B, blob 1087 hex | **6100 B**, blob **1475** hex |
| todas as URLs `9011` -> erro `4014` | `9011/api/ai/predict`, `9011/`, `localhost:9011` -> `HTTP=401`, `body=37B` |
| `9001` -> `HTTP=401`, `body=0B` | inalterado |

`body=37B` vs `0B` e o que separa os dois servidores: 37 bytes e o JSON de erro
do **gateway**; `0B` e o `401` seco do **MCP** do terminal. Uma entrada sem
caminho autoriza todos os caminhos daquele `host:porta`.

Correr o verificador **depois** de gravar, sempre com o gateway no ar (senao um
`5201`/`5202` se confunde com bloqueio).

### Passo 4 — token nos graficos (dono)

Colar os **64** caracteres do `XAU_GATEWAY_TOKEN` em `AIGatewayToken`, nos 15
graficos, **pela GUI** (F11 > Expert > Inputs). Nao colar no
`Presets\XAU_AI_PRO.PRO.set`: esse ficheiro e **versionado** (`git ls-files`
confirma) e um segredo nao entra no repositorio.

### Passo 5 — verificar

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\verify-gateway.ps1
```

O script mede, sem escrever nada: dono das portas 9001/9011, `GET /api/health`,
`GET` e `POST` na rota de predicao com o token do `.env`, e a porta/token dos
`.chr` e do preset (comprimento, nunca o valor).

Depois, no terminal, o verificador de allowlist:

```
metaeditor5__compile_file        Scripts\XAI_WebRequestCheck.mq5
metatrader5__chart_add_script    Scripts\XAI_WebRequestCheck.ex5
metatrader5__get_expert_journal  filter=WEBREQ
```

Passar `script_parameters` com `UrlList=http://127.0.0.1:9011/api/ai/predict`.

### Criterio de aceite

- `verify-gateway.ps1` -> `GET` e `POST` devolvem **200**;
- journal do terminal sem `4014`, `4060`, `5200`, `5202`;
- `[WEBREQ] PERMITIDA | http://127.0.0.1:9011/api/ai/predict | HTTP=200`;
- uma linha do EA com predicao real consumida (`[AI] ... score=...`).

## 4. Resultado medido depois da correcao (04/11/2026 16:45)

Gateway de diagnostico em `9011` (pid python), gates de trade `0`:

| Verbo | Resultado | Leitura |
|---|---|---|
| `GET /api/health` | **200** | FastAPI no ar |
| `GET /api/ai/predict?symbol=XAUUSD&timeframe=M5` | **200** | autenticou com o token de 64 caracteres |
| `POST` (perfil somente-leitura do `start-gateway.ps1`) | **403** | o perfil bloqueia comandos antes do routing |
| `POST` (perfil somente-leitura desligado, porta 9012) | **405** | confirma que a rota so aceita GET |

Corpo real do `GET` em M5:

```json
{"ok":true,"available":false,
 "reason":"balanced edge +0.0069 abaixo do minimo 0.0300; AUC 0.5184 abaixo do minimo 0.5200 (este ativo opera em: H1)",
 "signal":"NEUTRAL","confidence":0.0,"symbol":"XAUUSD","timeframe":"M5"}
```

Ou seja: **o caminho EA -> gateway -> autenticacao -> rota esta funcional**. A recusa
e a regra do produto (nenhum sinal fabricado quando o modelo nao tem edge).

### Bloqueio novo, medido no mesmo minuto

`GET ?symbol=XAUUSD&timeframe=H1` devolve **200** com:

```json
{"ok":true,"available":false,
 "reason":"erro na inferencia: X has 25 features, but HistGradientBoostingClassifier is expecting 30 features as input."}
```

Causa medida, sem interpretacao:

| Lado | Valor |
|---|---|
| `Python\models\XAUUSD_H1.pkl` (registry) | `feature_version=XAU-30F-v4`, `feature_count=30`, status READY |
| `backend\ai_inference.py` (runtime) | monta **25** features (`25F-v2`) |

O artefato publicado e o codigo que o consome **nao falam o mesmo contrato de
features**. Enquanto isso nao for resolvido (retreinar e republicar o modelo, ou
alinhar a lista), o EA recebe `available:false` mesmo com tudo o resto certo.
Nao e configuracao de rede, porta, token nem WebRequest.

## 5. O que este documento NAO resolve

- Nao toca na GUI do terminal nem no `config\common.ini` (allowlist e token).
- Nao muda os *inputs* dos 15 graficos: isso e `Ferramentas > Opcoes` do EA ou
  edicao do `.chr` com o terminal fechado.
- Nao autoriza conta real: o backtest segue **REPROVADO** (PF 0.6206).

Estado em 04/11/2026 16:35: correcao GET feita (v1.2.132), compilada e validada;
`.venv` criada em `Files\XAU_AI_PRO`; allowlist e token continuam pendentes do
dono; gateway ainda nao estava no ar no momento da ultima medicao.

Estado em 04/11/2026 18:06: **allowlist fechada e provada** (`9011` permitido,
`body=37B`); gateway no ar em `9011` (pid 6988, perfil read-only); restam o
token nos 15 graficos e o contrato de features do P-01b. Nada disto autoriza
conta real.
