# mcp-check.ps1 - estado dos MCP, servicos e ferramentas externas
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\mcp-check.ps1
#
# Verifica o que os agentes usam para trabalhar: internet, Context7, GitHub CLI,
# git remotes, gateway 9011 e tarefas. Nao imprime tokens. Nao altera nada.
#
# BASE: AGENTES.md / D-097 (autoridade para reparar o que estiver caido).

$ErrorActionPreference = 'Continue'

$Equipe = Split-Path -Parent $PSScriptRoot
$Mql5   = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Equipe))
$ok = 0; $falha = 0

function Testar([string]$Nome, [scriptblock]$Prova) {
   try {
      $r = & $Prova
      if ($r) { Write-Output ("  [OK]    {0,-26} {1}" -f $Nome, $r); $script:ok++ }
      else { Write-Output ("  [FALHA] {0,-26}" -f $Nome); $script:falha++ }
   }
   catch {
      Write-Output ("  [FALHA] {0,-26} {1}" -f $Nome, $_.Exception.Message)
      $script:falha++
   }
}

Write-Output ''
Write-Output '===== MCP E SERVICOS ====='

Testar 'internet' {
   $r = Invoke-WebRequest -Uri 'https://example.com' -TimeoutSec 8 -UseBasicParsing -SkipHttpErrorCheck
   if ($r.StatusCode -eq 200) { 'HTTP 200' } else { "HTTP $($r.StatusCode)" }
}

Testar 'Context7 (docs)' {
   $r = Invoke-WebRequest -Uri 'https://context7.com' -TimeoutSec 10 -UseBasicParsing -SkipHttpErrorCheck
   if ($r.StatusCode -lt 500) { "HTTP $($r.StatusCode)" } else { '' }
}

Testar 'GitHub CLI' {
   $v = (& gh --version 2>$null | Select-Object -First 1)
   if ($v) { $v } else { '' }
}

Testar 'GitHub auth' {
   $s = (& gh auth status 2>&1 | Out-String)
   if ($s -match 'Logged in') { 'autenticado' } else { '' }
}

Testar 'git remotes' {
   $rem = (& git -C $Mql5 remote 2>$null) -join ','
   if ($rem -match 'github') { $rem } else { '' }
}

Testar 'push para github' {
   $u = (& git -C $Mql5 rev-parse --abbrev-ref '@{u}' 2>$null)
   if ($u) { $u } else { '' }
}

Testar 'gateway 9011' {
   $r = Invoke-WebRequest -Uri 'http://127.0.0.1:9011/api/health' -TimeoutSec 4 -UseBasicParsing -SkipHttpErrorCheck
   if ($r.StatusCode -eq 200 -or $r.StatusCode -eq 401) { "HTTP $($r.StatusCode)" } else { '' }
}

Testar 'tarefas do mandato' {
   $t = @(Get-ScheduledTask -TaskName 'XAU_AI_PRO_*' -ErrorAction SilentlyContinue)
   if ($t.Count -ge 3) { "$($t.Count) tarefas" } else { '' }
}

Testar 'canal (sync-agent)' {
   $s = (& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sync-agent.ps1') check 2>&1) -join "`n"
   if ($s -match 'RESULTADO\s*:\s*OK') { 'OK' } else { '' }
}

Testar 'mandato (dono-mandato)' {
   & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'dono-mandato.ps1') check *> $null
   if ($LASTEXITCODE -eq 0) { 'OK' } else { '' }
}

Testar 'MCP do OpenCode' {
   $cfg = Join-Path $env:USERPROFILE '.config\opencode\opencode.json'
   if (-not (Test-Path -LiteralPath $cfg)) { return '' }
   $j = Get-Content -LiteralPath $cfg -Raw -Encoding UTF8 | ConvertFrom-Json
   $servidores = @($j.mcp.PSObject.Properties | Where-Object { $_.Value.enabled -ne $false })
   if ($servidores.Count -gt 0) { "$($servidores.Count) ativos: " + (($servidores | ForEach-Object { $_.Name }) -join ', ') } else { '' }
}

Write-Output ''
Write-Output ("RESULTADO: {0} OK, {1} FALHA(S)" -f $ok, $falha)
if ($falha -gt 0) {
   Write-Output 'Se algo falhar, reparar e registar no SYNC_LOG.md (autoridade D-097).'
   Write-Output 'Nunca colar tokens em prompts de MCP.'
   exit 1
}
Write-Output 'Tudo o que os agentes precisam esta a responder.'
Write-Output '=========================='
exit 0
