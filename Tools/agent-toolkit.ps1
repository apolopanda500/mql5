<#
=====================================================================
 Agent Toolkit - MQL5 / XAU_AI_PRO
=====================================================================
 Automacao de ciclo completo para o agente (e para o operador):
   status   - resumo do estado do repositorio git
   check    - validacao estatica MQL5 (UTF-8, chaves, #includes)
   compile  - compilacao real via metaeditor64.exe (EA XAU_AI_PRO)
   commit   - git add -A respeitando .gitignore + commit
   push     - push para o remote/branch configurado
   deploy   - check + compile + confirma .ex5 publicado no terminal
   full     - check + compile + commit + push (para no 1o erro)

 Uso (a partir de qualquer pasta):
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\agent-toolkit.ps1 status
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\agent-toolkit.ps1 commit -Message "feat(xau): ..."
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\agent-toolkit.ps1 deploy
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\agent-toolkit.ps1 full -Message "chore(repo): ..."

 Regras:
   - Nao use -Message vazio: o script rejeita o commit.
   - O script impede commit/push se a compilacao falhar.
   - Nao faz reset, checkout destrutivo, force-push nem rebase.
=====================================================================
#>
[CmdletBinding()]
param(
   [ValidateSet('status', 'check', 'compile', 'commit', 'push', 'deploy', 'full')]
   [string]$Action = 'status',

   # Mensagem de commit (obrigatoria para commit/full)
   [string]$Message = '',

   # Remote e branch de sincronizacao
   [string]$Remote = 'github',
   [string]$Branch = 'main',

   # Caminho do MetaEditor (detectado automaticamente se vazio)
   [string]$MetaEditor = ''
)

$ErrorActionPreference = 'Stop'
$script:Failures = 0

# ---------------------------------------------------------------------
# Localizacao do repositorio (este script vive em <repo>\Tools)
# ---------------------------------------------------------------------
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$EaFolder = Join-Path $RepoRoot 'Experts\XAU_AI_PRO'
$EaSource = Join-Path $EaFolder 'XAU_AI_PRO.mq5'
$EaBinary = Join-Path $EaFolder 'XAU_AI_PRO.ex5'

function Write-Section([string]$Text) {
   Write-Host ''
   Write-Host ('=== ' + $Text + ' ' + ('=' * [Math]::Max(0, 60 - $Text.Length))) -ForegroundColor Cyan
}

function Write-Ok([string]$Text) { Write-Host ('  [OK]   ' + $Text) -ForegroundColor Green }
function Write-Warn2([string]$Text) { Write-Host ('  [WARN] ' + $Text) -ForegroundColor Yellow }
function Write-Err([string]$Text) { Write-Host ('  [FAIL] ' + $Text) -ForegroundColor Red; $script:Failures++ }

function Invoke-Git {
   param([string[]]$Arguments, [switch]$AllowFail)
   $out = & git -C $RepoRoot @Arguments 2>&1
   $code = $LASTEXITCODE
   if ($code -ne 0 -and -not $AllowFail) {
      throw ("git " + ($Arguments -join ' ') + " falhou (exit $code): " + ($out -join ' '))
   }
   return [pscustomobject]@{ Code = $code; Output = $out }
}

# ---------------------------------------------------------------------
# STATUS
# ---------------------------------------------------------------------
function Invoke-Status {
   Write-Section 'GIT STATUS'
   Write-Host ("  repo    : " + $RepoRoot)
   Write-Host ("  branch  : " + (Invoke-Git @('rev-parse', '--abbrev-ref', 'HEAD')).Output)

   $up = Invoke-Git -Arguments @('rev-parse', '--abbrev-ref', '@{u}') -AllowFail
   if ($up.Code -eq 0) { Write-Host ("  upstream: " + $up.Output) } else { Write-Warn2 'sem upstream configurado' }

   $status = @((Invoke-Git @('status', '--porcelain=v1', '-uall')).Output | Where-Object { $_ -ne '' })
   if ($status.Count -eq 0) {
      Write-Ok 'working tree limpo'
   }
   else {
      $modified = @($status | Where-Object { $_.Substring(1, 1) -eq 'M' })
      $deleted = @($status | Where-Object { $_.Substring(1, 1) -eq 'D' -or $_.Substring(0, 1) -eq 'D' })
      $untracked = @($status | Where-Object { $_.StartsWith('??') })
      $staged = @($status | Where-Object { $_.Substring(0, 1) -ne ' ' -and $_.Substring(0, 1) -ne '?' })
      Write-Host ("  total={0}  staged={1}  modified={2}  deleted={3}  untracked={4}" -f `
            $status.Count, $staged.Count, $modified.Count, $deleted.Count, $untracked.Count)
      if ($untracked.Count -gt 0) {
         Write-Host '  untracked (primeiros 15):'
         $untracked | Select-Object -First 15 | ForEach-Object { Write-Host ('    ' + $_) }
      }
   }

   $ab = (Invoke-Git -Arguments @('rev-list', '--left-right', '--count', 'HEAD...@{u}') -AllowFail).Output
   if ($ab) { Write-Host ("  ahead/behind vs upstream: " + ($ab -join '')) }
}

# ---------------------------------------------------------------------
# CHECK - validacao estatica nativa (nao precisa de Python)
# ---------------------------------------------------------------------
function Test-BraceBalance {
   param([string]$Path)

   $text = [System.IO.File]::ReadAllText($Path)
   $depth = 0
   $line = 1
   $state = 'code'

   for ($i = 0; $i -lt $text.Length; $i++) {
      $c = $text[$i]
      $n = if (($i + 1) -lt $text.Length) { $text[$i + 1] } else { [char]0 }

      if ($c -eq "`n") {
         $line++
         if ($state -eq 'line') { $state = 'code' }
         continue
      }

      if ($state -eq 'line') { continue }
      if ($state -eq 'block') {
         if ($c -eq '*' -and $n -eq '/') { $state = 'code'; $i++ }
         continue
      }
      if ($state -eq 'str') {
         if ($c -eq '\') { $i++ }
         elseif ($c -eq '"') { $state = 'code' }
         continue
      }
      if ($state -eq 'chr') {
         if ($c -eq '\') { $i++ }
         elseif ($c -eq "'") { $state = 'code' }
         continue
      }

      if ($c -eq '/' -and $n -eq '/') { $state = 'line'; $i++; continue }
      if ($c -eq '/' -and $n -eq '*') { $state = 'block'; $i++; continue }
      if ($c -eq '"') { $state = 'str'; continue }
      if ($c -eq "'") { $state = 'chr'; continue }

      if ($c -eq '{') { $depth++ }
      elseif ($c -eq '}') {
         $depth--
         if ($depth -lt 0) { return @{ Ok = $false; Reason = "chave } extra na linha ~$line" } }
      }
   }

   if ($depth -ne 0) { return @{ Ok = $false; Reason = "chaves desbalanceadas (depth=$depth)" } }
   if ($state -eq 'block') { return @{ Ok = $false; Reason = 'comentario de bloco /* nao fechado' } }
   return @{ Ok = $true; Reason = '' }
}

function Get-MqlSources {
   if (-not (Test-Path -LiteralPath $EaFolder)) { return @() }
   return @(Get-ChildItem -LiteralPath $EaFolder -Recurse -File |
         Where-Object {
            $_.Extension -in @('.mq5', '.mqh') -and
            $_.FullName -notmatch '\.(pre_p\d+|bak_before_p\d+)$'
         })
}

function Invoke-Check {
   Write-Section 'VALIDACAO ESTATICA MQL5'
   $sources = Get-MqlSources
   if ($sources.Count -eq 0) { Write-Err "nenhum fonte .mq5/.mqh em $EaFolder"; return }
   Write-Host ("  arquivos analisados: " + $sources.Count)

   # 1) encoding UTF-8 estrito
   $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
   $badEncoding = 0
   foreach ($f in $sources) {
      try { [void]$utf8.GetString([System.IO.File]::ReadAllBytes($f.FullName)) }
      catch { Write-Err ("UTF-8 invalido: " + $f.FullName.Replace($RepoRoot + '\', '')); $badEncoding++ }
   }
   if ($badEncoding -eq 0) { Write-Ok 'encoding UTF-8 valido em todos os fontes' }

   # 2) balanceamento de chaves
   $badBraces = 0
   foreach ($f in $sources) {
      $r = Test-BraceBalance -Path $f.FullName
      if (-not $r.Ok) { Write-Err ($f.FullName.Replace($RepoRoot + '\', '') + ' -> ' + $r.Reason); $badBraces++ }
   }
   if ($badBraces -eq 0) { Write-Ok 'chaves balanceadas em todos os fontes' }

   # 3) #include locais existentes
   $badIncludes = 0
   foreach ($f in $sources) {
      $dir = Split-Path -Parent $f.FullName
      Select-String -LiteralPath $f.FullName -Pattern '^\s*#include\s+"([^"]+)"' | ForEach-Object {
         $rel = $_.Matches[0].Groups[1].Value
         $cand = @(
            (Join-Path $dir $rel),
            (Join-Path $EaFolder $rel),
            (Join-Path $RepoRoot ('Include\' + $rel)),
            (Join-Path $RepoRoot ('Include\' + (Split-Path -Leaf $rel)))
         )
         $found = $cand | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
         if (-not $found) {
            Write-Err ($f.Name + ':' + $_.LineNumber + ' include nao resolvido -> ' + $rel)
            $badIncludes++
         }
      }
   }
   if ($badIncludes -eq 0) { Write-Ok 'todos os #include locais resolvidos' }

   if ($script:Failures -eq 0) { Write-Ok 'validacao estatica sem problemas' }
}

# ---------------------------------------------------------------------
# COMPILE
# ---------------------------------------------------------------------
function Resolve-MetaEditor {
   if ($MetaEditor -and (Test-Path -LiteralPath $MetaEditor)) { return $MetaEditor }
   $cands = @(
      'C:\Program Files\MetaTrader 5\metaeditor64.exe',
      'C:\Program Files (x86)\MetaTrader 5\metaeditor64.exe',
      'C:\Program Files\MetaTrader 5\metaeditor.exe'
   )
   foreach ($c in $cands) { if (Test-Path -LiteralPath $c) { return $c } }
   return $null
}

function Invoke-Compile {
   Write-Section 'COMPILACAO MQL5'
   if (-not (Test-Path -LiteralPath $EaSource)) { Write-Err "fonte nao encontrada: $EaSource"; return }

   $me = Resolve-MetaEditor
   if (-not $me) { Write-Err 'metaeditor64.exe nao encontrado (informe -MetaEditor)'; return }
   Write-Host ("  compiler : " + $me)

   $log = [System.IO.Path]::ChangeExtension($EaSource, '.log')
   if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log -Force }

   $before = if (Test-Path -LiteralPath $EaBinary) { (Get-Item -LiteralPath $EaBinary).LastWriteTime } else { $null }

   & $me "/compile:$EaSource" '/log' | Out-Null

   if (-not (Test-Path -LiteralPath $log)) {
      Write-Err 'nenhum log de compilacao gerado'
      return
   }

   $logText = Get-Content -LiteralPath $log -Raw
   $errors = ([regex]::Matches($logText, '(?m):\s+error\s+')).Count
   $warns = ([regex]::Matches($logText, '(?m):\s+warning\s+')).Count
   $summary = (Select-String -LiteralPath $log -Pattern 'errors?,.*warnings?' | Select-Object -Last 1).Line

   if ($summary) { Write-Host ('  ' + $summary.Trim()) }

   if ($errors -gt 0) {
      Write-Err ("compilacao com $errors erro(s)")
      Select-String -LiteralPath $log -Pattern ':\s+error\s+' | Select-Object -First 25 |
      ForEach-Object { Write-Host ('    ' + $_.Line.Trim()) -ForegroundColor DarkYellow }
      return
   }

   if ($warns -gt 0) { Write-Warn2 ("compilacao ok, porem com $warns warning(s)") }
   else { Write-Ok 'compilacao: 0 errors, 0 warnings' }

   if (Test-Path -LiteralPath $EaBinary) {
      $after = (Get-Item -LiteralPath $EaBinary).LastWriteTime
      if ($null -eq $before -or $after -gt $before) {
         Write-Ok ("binario atualizado: XAU_AI_PRO.ex5 (" + $after.ToString('yyyy-MM-dd HH:mm:ss') + ")")
      }
      else {
         Write-Warn2 'binario .ex5 nao mudou de timestamp'
      }
   }
   else {
      Write-Err 'binario .ex5 nao gerado'
   }

   Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------
# COMMIT / PUSH
# ---------------------------------------------------------------------
function Invoke-Commit {
   Write-Section 'COMMIT'
   if (-not $Message -or $Message.Trim().Length -lt 5) {
      Write-Err 'informe -Message "tipo(escopo): descricao" (minimo 5 caracteres)'
      return
   }
   $lines = @((Invoke-Git @('status', '--porcelain=v1', '-uall')).Output | Where-Object { $_ -ne '' })
   if ($lines.Count -eq 0) { Write-Warn2 'nada para commitar'; return }

   Invoke-Git @('add', '--all') | Out-Null
   Write-Host '  staging concluido (respeitando .gitignore)'

   Invoke-Git @('commit', '-m', $Message) | Out-Null
   Write-Ok ('commit criado: ' + ((Invoke-Git @('log', '-1', '--oneline')).Output))

   $left = @((Invoke-Git @('status', '--porcelain=v1', '-uall')).Output | Where-Object { $_ -ne '' })
   if ($left.Count -gt 0) { Write-Warn2 ("ainda restam " + $left.Count + " entrada(s) fora do commit") }
}

function Invoke-Push {
   Write-Section ('PUSH -> ' + $Remote + '/' + $Branch)
   $r = Invoke-Git -Arguments @('push', $Remote, $Branch) -AllowFail
   if ($r.Code -ne 0) { Write-Err (($r.Output | Where-Object { $_ -match '\S' }) -join ' '); return }
   Write-Ok (($r.Output | Where-Object { $_ -match '\S' }) -join ' ')
}

# ---------------------------------------------------------------------
# EXECUCAO
# ---------------------------------------------------------------------
switch ($Action) {
   'status' { Invoke-Status }
   'check' { Invoke-Check }
   'compile' { Invoke-Compile }
   'commit' { Invoke-Commit }
   'push' { Invoke-Push }
   'deploy' {
      Invoke-Check
      if ($script:Failures -eq 0) { Invoke-Compile }
      if ($script:Failures -eq 0) { Write-Ok 'deploy local pronto (ex5 publicado na pasta do EA)' }
   }
   'full' {
      Invoke-Check
      if ($script:Failures -eq 0) { Invoke-Compile }
      if ($script:Failures -eq 0) { Invoke-Commit }
      if ($script:Failures -eq 0) { Invoke-Push }
   }
}

Write-Host ''
if ($script:Failures -gt 0) {
   Write-Host ("RESULTADO: " + $script:Failures + " falha(s)") -ForegroundColor Red
   exit 1
}
Write-Host 'RESULTADO: OK' -ForegroundColor Green
exit 0
