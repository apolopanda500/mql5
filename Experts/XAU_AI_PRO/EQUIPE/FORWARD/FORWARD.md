# FORWARD 30 DIAS - G11 (medicao diaria automatica)

Gerado por `Tools\forward-gate.ps1`. Dia do servidor = local + 5 h. Cada linha e um DIA do servidor; a coluna Amostras diz quantas leituras houve nesse dia.

| Dia servidor | Amostras | 1a leitura | Ultima leitura | MD5 ok | Gov. ok | Frota ON | Ver. memoria | Sinais | AllowTrade(bloq) | Trades | P/L dia | DD % | IA disp. | 1003 | Bloq. sem permissao no dia | Campos em falta | Dados ate (P/L,funil) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-11-10 | 23 | 10/11/2026 09:15:39 | 10/11/2026 18:22:36 | sim | sim | 15/15 | v1.2.203 | 11 | 11 | 0 | -61.8 | 0.39 | 1 | 82 | 15 | schema(13/23), governanca_sha256(4/23), frota_ligada(9/23), sem_permissao(6/23) | 18:19:11,17:10:12 |

**Declarado:** v1.2.203 MD5 10C4DF68A60CDDB0252F12C30AF4A86A (1023258 B)

**Governanca dos modelos:** CB7D8FD8D5CECAF51BC650FF491B2F6FA1DBCA57621ED140E9EE0C3E661187F7 (87 meta.json) - o binario esta no MD5, os modelos NAO: esta impressao e o que impede os 30 dias de medirem um alvo que se mexe.

**Detalhe:** `medicao.jsonl` (append-only, uma linha por execucao, `schema` por linha) e a prova de cobertura; `medicao_diaria.jsonl` e o derivado desta tabela.

**Leituras:** a coluna `Dados ate (P/L,funil)` traz a hora da fonte do P/L (master) e do funil (scanner). O `DD %` e `(pico - equity)/pico` do dia, com o pico do `[SESSION] estado salvo` e a equity do `system_status.json` (ao vivo); quando essa leitura nao existe, cai para a `Amplitude` do `[STATUS] HEALTHY`. As quatro horas (status, master, funil, 1003) e a equity ao vivo estao em `ultima_medicao.log`.
