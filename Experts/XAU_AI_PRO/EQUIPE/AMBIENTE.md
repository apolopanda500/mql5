# AMBIENTE - a maquina de trabalho (medido, nao estimado)

**Criado:** 07/11/2026 23:05 | **Autor:** CMD | **Base:** D-098, D-099
**Regra:** este documento diz o que existe. Se algo mudar, mede-se de novo.

---

## 1. Hardware e sistema

| Item | Valor |
|---|---|
| Sistema | Windows 11 Pro, build 26200 |
| CPU | Intel Core i5-4590 @ 3.30 GHz (4 nucleos) |
| RAM | 15,9 GB (8,5 GB livres em repouso) |
| Disco C: | 217,8 GB usados, **6,3 GB livres** (era 4,8 GB antes da limpeza) |
| Antivirus | Windows Defender activo (padrao) |

**Nota honesta:** 6,3 GB livres e' pouco para treino de modelos local. O ambiente
esta' limpo e organizado, mas expandir modelos grandes exige disco externo ou
limpeza mais profunda (WinSxS/Windows Update), que precisa de Administrador.

---

## 2. Ferramentas instaladas

| Ferramenta | Versao | Caminho |
|---|---|---|
| Node.js | presente | `C:\Program Files\nodejs` |
| npm | presente | idem |
| Git | presente | `C:\Program Files\Git\cmd` |
| GitHub CLI (gh) | 2.97.0 | `C:\Program Files\GitHub CLI` |
| OpenCode CLI | presente | `%APPDATA%\npm\opencode.ps1` |
| **Python** | **3.13.18** (novo) | `%USERPROFILE%\.local\bin\python.exe` |
| **uv / uvx** | **0.13.7** (novo) | `%USERPROFILE%\.local\bin` |
| **ripgrep (rg)** | **15.2.0** (novo) | `C:\AI\tools\rg.exe` |
| **jq** | **1.8.2** (novo) | `C:\AI\tools\jq.exe` |
| **7-Zip (7zr)** | **26.04** (novo) | `C:\AI\tools\7zr.exe` |
| curl | presente | `C:\Windows\System32` |

Instalado nesta sessao: **Python 3.13.18 via uv**, **uv 0.13.7**, **ripgrep
15.2.0**, **jq 1.8.2** e **7-Zip 26.04**. O `PATH` do utilizador ja inclui
`%USERPROFILE%\.local\bin` e `C:\AI\tools`, por isso `python`, `uv`, `rg`, `jq` e
`7zr` funcionam em qualquer terminal novo.

**Nota medida:** terminais abertos antes da alteracao do PATH continuam a nao ver
`rg`/`jq`/`7zr`; basta abrir um terminal novo. `ambiente-check.ps1` detecta os
binarios em `C:\AI\tools` mesmo nesse caso.

**Ausentes (nao bloqueiam):** winget. Instalar quando houver necessidade; o
agente tem autoridade para isso (D-097).

---

## 3. MCP activos no OpenCode (10)

`C:\Users\Micro\.config\opencode\opencode.json` (backup `.bak` antes de cada
alteracao):

| Servidor | Ferramentas | Papel |
|---|---|---|
| filesystem | 16 | ficheiros dentro de `MQL5` |
| memory | 9 | memoria partilhada dos agentes |
| context7 | 2 | documentacao de bibliotecas |
| sequential_thinking | 1 | raciocinio em passos |
| **playwright** | 25 | navegar/testar na web (novo) |
| **sentry** | 70 | erros e telemetria (novo) |
| **fetch** | 1 | ler qualquer URL em markdown (novo) |
| **git** | 14 | historico do repositorio (novo) |
| supabase | 17 | base de dados do projecto |
| render | 28 | servicos externos |

Verificacao: `tools/mcp-check.ps1` -> **11 OK, 0 falhas**.

**Seguranca:** o `opencode.json` contem uma credencial de servico externo. Nao e'
versionado e nenhum agente a copia para o canal. Deve ser rotacionada pelo DONO
quando for conveniente.

---

## 4. Estrutura de trabalho

```
C:\AI
├─ projects\      xau-ai-pro -> junction para MQL5 do terminal MT5
├─ tools\         binarios locais
├─ models\        modelos (fora do git)
├─ data\          datasets
├─ logs\          logs de automacao
├─ backups\       copias de seguranca
├─ scripts\       automacao transversal
├─ docs\          notas de ambiente
└─ sandbox\       testes descartaveis
```

O projeto continua a viver no terminal MetaTrader 5; `C:\AI\projects\xau-ai-pro`
e' uma **junction** (nao duplica dados).

---

## 5. Limpeza feita (07/11/2026)

| Item | Antes | Depois |
|---|---|---|
| Disco C: livre | 4,80 GB | **6,27 GB** |
| cache npm | 1693 MB | 479 MB |
| `%TEMP%` | 495 MB | 238 MB |

Ferramenta permanente: `tools/limpeza-segura.ps1` (simulacao por omissao,
`-Executar` para limpar). **Nunca** toca em projetos, git, backups, Downloads,
Documentos, lixeira, historico de conta, modelos ou dados.

---

## 6. Rotina

| Quando | O que |
|---|---|
| Semanal | `tools/limpeza-segura.ps1` (simulacao) e `-Executar` se houver ganho |
| Antes de compile | `tools/compile-ea.ps1` (backup do `.ex5`) |
| Antes de commit | `tools/sync-agent.ps1 check` + `tools/dono-mandato.ps1 check` |
| Ao entrar | `tools/agente-briefing.ps1` |
| Quando algo falha | `tools/mcp-check.ps1` |
