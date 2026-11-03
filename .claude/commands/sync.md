---
description: Sincroniza o repositorio local com o GitHub (status, commit, push, conflito).
---

# /sync — sincronizacao com o GitHub

Repositorio: `C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5`
Branch `main`, upstream `github/main` (`apolopanda500/mql5`).

## Passos

1. Pre-flight e leitura do estado:

```powershell
cd /d "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5"
git status -sb
git rev-list --left-right --count github/main...HEAD
```

O segundo comando imprime `<behind> <ahead>`.

2. Ciclo completo (para na primeira falha):

```powershell
$TK = "C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Tools\agent-toolkit.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $TK full -Message "tipo(escopo): descricao"
```

3. Conferir: working tree limpo e `0 0` em ahead/behind.

## Se o push for rejeitado (`fetch first`)

O remoto tem commits novos. Merge, nunca rebase:

```powershell
git fetch github main
git merge --no-edit github/main
git push github main
```

## Se houver conflito

1. `git status --short` para listar os arquivos em conflito.
2. Ler o conflito (`read_file_by_lines` nas faixas com `<<<<<<<`).
3. Resolver preservando a intencao dos dois lados; recompilar.
4. `git add <arquivo>` + commit + push.

## Limites

- Nunca `git reset --hard`, `checkout` destrutivo, `rebase` ou `force-push`.
- Nunca publicar em `origin` (forge.mql5.io / CodeBase) sem autorizacao.
- Nunca commitar `.ex5`, `.log`, `.dat`, `Data/*.csv` ou backup de edicao —
  eles estao no `.gitignore`.
- Nunca reescrever historico para reduzir `.git` sem autorizacao explicita.
