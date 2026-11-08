# agente-briefing.ps1 - contexto completo para qualquer agente, em um comando
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\agente-briefing.ps1
#
# Le o estado real (git, fontes, gate, mandato, gateway, tarefas, canal) e grava
# EQUIPE/BRIEFING_ATUAL.md. Nao altera nada fora desse ficheiro de leitura.
#
# BASE: AGENTES.md / D-095 / D-096 / D-097

$ErrorActionPreference = 'Stop'

$Equipe = Split-Path -Parent $PSScriptRoot
$Mql5   = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Equipe))
$EaDir  = Join-Path $Mql5 'Experts\XAU_AI_PRO'
$Gate   = Join-Path $Equipe 'GATE_REAL.md'
$Mand   = Join-Path $Equipe 'MANDATO_ATIVO.json'
$Out    = Join-Path $Equipe 'BRIEFING_ATUAL.md'
$Utf8   = New-Object System.Text.UTF8Encoding($false)

function Get-Prop([string]$File, [string]$Pattern) {
   if (-not (Test-Path -LiteralPath $File)) { return '?' }
   $m = [regex]::Match((Get-Content -LiteralPath $File -Raw -Encoding UTF8), $Pattern)
   if ($m.Success) { return $m.Groups[1].Value }
   return '?'
}

function Get-Gate {
   $m = [regex]::Match((Get-Content -LiteralPath $Gate -Raw -Encoding UTF8), '(\d+)\s+verdes\s+de\s+(\d+)')
   if ($m.Success) { return ("{0} de {1}" -f $m.Groups[1].Value, $m.Groups[2].Value) }
   return 'nao lido'
}

function Get-Git([string[]]$GitArgs) {
   try { return ((& git -C $Mql5 @GitArgs 2>$null) -join "`n").Trim() } catch { return '?' }
}

$head      = Get-Git @('rev-parse', '--short', 'HEAD')
$branch    = Get-Git @('rev-parse', '--abbrev-ref', 'HEAD')
$upstream  = Get-Git @('rev-parse', '--short', 'github/main')
$dirty     = Get-Git @('status', '--porcelain')
$nDirty    = @($dirty -split "`n" | Where-Object { $_.Trim() }).Count
$lastCommits = Get-Git @('log', '--oneline', '-5')

$verProp  = Get-Prop (Join-Path $EaDir 'XAU_AI_PRO.mq5') '#property\s+version\s+"?([^"\r\n]+)"?'
$verEa    = Get-Prop (Join-Path $EaDir 'Enterprise\VersionManager.mqh') '#define\s+EA_VERSION_STRING\s+"([^"]+)"'
$verEv    = Get-Prop (Join-Path $EaDir 'Monitoring\EventEmitter.mqh') '#define\s+EV_VERSION_STRING\s+"([^"]+)"'

$ex5 = Join-Path $EaDir 'XAU_AI_PRO.ex5'
if (Test-Path -LiteralPath $ex5) {
   $b = Get-Item -LiteralPath $ex5
   $bin = ("{0} B | {1:dd/MM HH:mm:ss} | MD5 {2}" -f $b.Length, $b.LastWriteTime, (Get-FileHash -LiteralPath $ex5 -Algorithm MD5).Hash.Substring(0, 12))
   $novo = Get-ChildItem -LiteralPath $EaDir -Recurse -File | Where-Object { $_.Extension -eq '.mq5' -or $_.Extension -eq '.mqh' } |
      Sort-Object LastWriteTime -Descending | Select-Object -First 1
   $binEstado = if ($novo -and $novo.LastWriteTime -gt $b.LastWriteTime) { 'FONTE MAIS NOVA' } else { 'BATEM' }
}
else { $bin = 'AUSENTE'; $binEstado = 'AUSENTE' }

function Get-Gateway {
   # /api/health devolve 401 sem token e 404 com token: qualquer resposta HTTP
   # prova servidor vivo. -SkipHttpErrorCheck nao existe em PS 5.1 (P1.3487).
   $tcp = $null
   try {
      $tcp = New-Object System.Net.Sockets.TcpClient
      $iar = $tcp.BeginConnect('127.0.0.1', 9011, $null, $null)
      if (-not $iar.AsyncWaitHandle.WaitOne(3000, $false)) { return 'DOWN (porta 9011 fechada)' }
      $tcp.EndConnect($iar)
   }
   catch { return 'DOWN (porta 9011 fechada)' }
   finally { if ($tcp) { try { $tcp.Close() } catch { } } }
   try {
      $r = Invoke-WebRequest -Uri 'http://127.0.0.1:9011/api/health' -TimeoutSec 4 -UseBasicParsing
      return ('UP (HTTP {0})' -f [int]$r.StatusCode)
   }
   catch {
      $resp = $_.Exception.Response
      if ($resp -and $resp.StatusCode) { return ('UP (HTTP {0})' -f [int]$resp.StatusCode) }
      return 'UP (porta 9011, sem resposta HTTP)'
   }
}
$gw = Get-Gateway

$tarefas = @(Get-ScheduledTask -TaskName 'XAU_AI_PRO_*' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty TaskName)
$m = Get-Content -LiteralPath $Mand -Raw -Encoding UTF8 | ConvertFrom-Json
$ini = $m.decisoes.forward.inicio_medido
$rel = Join-Path $Equipe 'RELATORIOS'
$dias = 0
if ($ini -and (Test-Path -LiteralPath $rel)) {
   $d0 = [datetime]::ParseExact($ini, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
   $dias = @(Get-ChildItem -LiteralPath $rel -Filter '*.md' -File | ForEach-Object {
      $d = [datetime]::MinValue
      if ([datetime]::TryParseExact($_.BaseName, 'yyyyMMdd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$d)) {
         if ($d -ge $d0 -and $d.DayOfWeek -ne 'Saturday' -and $d.DayOfWeek -ne 'Sunday') { $d }
      }
   } | Sort-Object -Unique).Count
}

$L = New-Object System.Collections.Generic.List[string]
$L.Add("# BRIEFING ATUAL - gerado por agente-briefing.ps1")
$L.Add('')
$L.Add(("**Hora:** {0:dd/MM/yyyy HH:mm:ss} | **Para:** qualquer agente | **Base:** AGENTES.md" -f (Get-Date)))
$L.Add('')
$L.Add('## 1. Repositorio')
$L.Add('')
$L.Add('| Item | Valor |')
$L.Add('|---|---|')
$L.Add("| HEAD | ``$head`` ($branch) |")
$L.Add("| github/main | ``$upstream`` |")
$L.Add("| Ficheiros alterados | $nDirty |")
$L.Add("| Versao (3 fontes) | #property $verProp / EA $verEa / EV $verEv |")
$L.Add("| Binario | $bin |")
$L.Add("| Binario x fonte | $binEstado |")
$L.Add('')
$L.Add('## 2. Projeto')
$L.Add('')
$L.Add('| Item | Valor |')
$L.Add('|---|---|')
$L.Add("| GATE_REAL | **$(Get-Gate)** |")
$L.Add("| Forward | $dias de $($m.decisoes.forward.dias) dias |")
$L.Add("| Inicio do forward | $(if ($ini) { $ini } else { 'nao medido (previsto ' + $m.decisoes.forward.inicio_previsto + ')' }) |")
$L.Add("| Gateway 9011 | $gw |")
$L.Add("| Mandato | $($m.estado) / $($m.decisao) |")
$L.Add("| Tarefas | $($tarefas.Count) ($($tarefas -join ', ')) |")
$L.Add('')
$L.Add('## 3. Ultimos commits')
$L.Add('')
$L.Add('```')
$L.Add($lastCommits)
$L.Add('```')
$L.Add('')
$L.Add('## 4. Trabalho por agente')
$L.Add('')
$L.Add('- **ALFA:** fechar G3-G8 com medicao; compile so por `compile-ea.ps1`;')
$L.Add('  corrigir P1 dentro do mandato. Nao parar por atraso corrigivel.')
$L.Add('- **DELTA:** medir com mercado aberto (`[SCORE]`, `[CENARIO]`,')
$L.Add('  `TREND CONTRA OK`, IA vs sem IA); separar manual do EA; assinar o')
$L.Add('  `DOSSIE_FINAL.md` so com 11/11 + 30 dias.')
$L.Add('- **CMD:** gateway, tarefas, canal, git, CI; correr `ordem-master.ps1`')
$L.Add('  quando o DONO der a ordem; manter este briefing vivo.')
$L.Add('')
$L.Add('## 5. Comandos de seguranca')
$L.Add('')
$L.Add('```')
$L.Add('sync-agent.ps1 check        # canal')
$L.Add('dono-mandato.ps1 check      # mandato')
$L.Add('dono-mandato.ps1 estado     # estado medido')
$L.Add('ordem-master.ps1 estado     # ordem unica')
$L.Add('mcp-check.ps1               # MCP e servicos')
$L.Add('```')
$L.Add('')
$L.Add('## 6. Regras')
$L.Add('')
$L.Add('- `10/10` nunca e estado; o estado e `x/11`.')
$L.Add('- Nao tocar em risco; nao abrir conta real sem os 4 requisitos.')
$L.Add('- Commits por caminho explicito; push so `github main`.')
$L.Add('- Canal: UTF-8 sem BOM, LF puro, lock antes de escrever.')
$L.Add('- Nao chamar o DONO durante a execucao.')

[System.IO.File]::WriteAllText($Out, ($L -join "`n") + "`n", $Utf8)

Write-Output ''
Write-Output '===== BRIEFING DO AGENTE ====='
Write-Output ("HEAD            : {0} ({1}) | github/main {2} | sujos {3}" -f $head, $branch, $upstream, $nDirty)
Write-Output ("versao          : #property {0} / EA {1} / EV {2}" -f $verProp, $verEa, $verEv)
Write-Output ("binario         : {0} | {1}" -f $binEstado, $bin)
Write-Output ("GATE_REAL       : {0}" -f (Get-Gate))
Write-Output ("forward         : {0}/{1}" -f $dias, $m.decisoes.forward.dias)
Write-Output ("gateway 9011    : {0}" -f $gw)
Write-Output ("tarefas         : {0}" -f $tarefas.Count)
Write-Output ''
Write-Output ("ficheiro        : {0}" -f $Out)
Write-Output '=============================='
