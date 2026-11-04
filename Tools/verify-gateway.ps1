<#
.SYNOPSIS
   Mede o caminho EA -> gateway de IA de ponta a ponta, sem escrever nada.

.DESCRIPTION
   Responde, com numero e nao com suposicao:
     1. quem escuta 9001 e 9011 (o 9001 do MT5 e o MCP embutido, nao o gateway)
     2. o gateway responde /api/health?
     3. GET  /api/ai/predict?symbol=&timeframe=  -> qual HTTP?
     4. POST /api/ai/predict?symbol=&timeframe=  -> qual HTTP? (o EA usa POST)
     5. os graficos e o preset apontam para que porta, e com que token (so o
        COMPRIMENTO; o valor nunca e impresso)

   Le o token de Files\XAU_AI_PRO\.env somente para o passo 4. O valor nao e
   gravado, nao e impresso e nao sai daqui.

.PARAMETER Port
   Porta do gateway. Padrao 9011 (o 9001 pertence ao MCP do terminal).

.PARAMETER Symbol
   Simbolo da query string. Padrao XAUUSD.

.PARAMETER Timeframe
   Timeframe da query string. Padrao M5.

.EXAMPLE
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\verify-gateway.ps1

.EXAMPLE
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\verify-gateway.ps1 -Port 9001
#>
[CmdletBinding()]
param(
   [int]$Port         = 9011,
   [string]$Symbol    = 'XAUUSD',
   [string]$Timeframe = 'M5',
   [int]$TimeoutSec   = 20
)

$ErrorActionPreference = 'Continue'
$script:Fail = 0
$script:Warn = 0

function Write-Step { param([string]$T) Write-Host ''; Write-Host "== $T" -ForegroundColor Cyan }
function Write-Ok   { param([string]$T) Write-Host "[ OK ] $T" -ForegroundColor Green }
function Write-Bad  { param([string]$T) Write-Host "[FAIL] $T" -ForegroundColor Red;  $script:Fail++ }
function Write-Warn2{ param([string]$T) Write-Host "[WARN] $T" -ForegroundColor Yellow; $script:Warn++ }
function Write-Info { param([string]$T) Write-Host "[info] $T" -ForegroundColor Gray }

$raiz = Split-Path -Parent $PSScriptRoot          # ...\MQL5
$envArq = Join-Path $raiz 'Files\XAU_AI_PRO\.env'

# ------------------------------------------------------------------ 1. portas
Write-Step '1/5  quem escuta 9001 e 9011'

function Get-Dono {
   param([int]$P)
   try {
      # O MCP do MT5 nao aparece como 'Listen': o socket fica 'Bound' (State
      # vazio) com RemoteAddress 0.0.0.0. Por isso a escolha e por prioridade,
      # nao por igualdade de estado.
      $todas = @(Get-NetTCPConnection -LocalPort $P -ErrorAction Stop)
      if($todas.Count -eq 0) { return $null }
      $c = @($todas | Where-Object { $_.State -eq 'Listen' })[0]
      if(-not $c) { $c = @($todas | Where-Object { [string]::IsNullOrEmpty($_.State) })[0] }
      if(-not $c) { $c = $todas[0] }
      $proc = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
      return [pscustomobject]@{ Porta = $P; Pid = $c.OwningProcess; Nome = $(if($proc){ $proc.ProcessName } else { '?' }) }
   } catch { return $null }
}

$dono9001 = Get-Dono 9001
$dono9011 = Get-Dono 9011

if($dono9001) {
   if($dono9001.Nome -match 'terminal64') {
      Write-Warn2 "9001 escutado por terminal64 (pid $($dono9001.Pid)) - e o MCP EMBUTIDO do MT5 (config\assistant.ini: Endpoint=http://127.0.0.1:9001/mcp), NAO o gateway"
   } else {
      Write-Info "9001 escutado por $($dono9001.Nome) (pid $($dono9001.Pid))"
   }
} else { Write-Info '9001 livre' }

if($dono9011) {
   Write-Ok "9011 escutado por $($dono9011.Nome) (pid $($dono9011.Pid))"
} else {
   Write-Bad '9011 FECHADO - nenhum gateway no ar; suba o backend antes de testar o EA'
}

if(-not $dono9011 -and $Port -eq 9011) {
   Write-Info 'sem servico na porta testada, os passos 2-4 vao falhar por conexao. Suba o gateway:'
   Write-Info '  cd ...\MQL5\Files\XAU_AI_PRO'
   Write-Info '  .\.venv\Scripts\python.exe -m uvicorn backend.fastapi_gateway:app --port 9011 --host 127.0.0.1'
   Write-Info 'NAO use start_gateway.bat para isto: ele liga XAU_ENABLE_REAL_ORDERS=1 e os gates de trade.'
}

# ---------------------------------------------------------------- 2. token
$token = ''
if(Test-Path $envArq) {
   $linha = Get-Content $envArq | Where-Object { $_ -match '^\s*XAU_GATEWAY_TOKEN\s*=' } | Select-Object -First 1
   if($linha) { $token = ($linha -split '=',2)[1].Trim().Trim('"').Trim("'") }
}
Write-Info ("token do .env: " + $(if($token){ "presente, $($token.Length) caracteres" } else { 'AUSENTE' }))

# ---------------------------------------------------------------- 3. HTTP
function Invoke-Sonda {
   param([string]$Method, [string]$Url, [hashtable]$Headers, [string]$Body)
   $out = [pscustomobject]@{ Status = 0; Detail = ''; Content = '' }
   $rp = @{ Uri = $Url; Method = $Method; TimeoutSec = $TimeoutSec; UseBasicParsing = $true }
   if($Headers) { $rp.Headers = $Headers }
   if($Body)    { $rp.Body = $Body; $rp.ContentType = 'application/json' }
   try {
      $r = Invoke-WebRequest @rp
      $out.Status = [int]$r.StatusCode
      $out.Content = [string]$r.Content
   } catch {
      $resp = $_.Exception.Response
      if($resp) {
         try { $out.Status = [int]$resp.StatusCode } catch { }
         try {
            $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $out.Content = $sr.ReadToEnd(); $sr.Close()
         } catch { }
      }
      $out.Detail = $_.Exception.Message
   }
   return $out
}

$base = "http://127.0.0.1:$Port"
$auth = @{}
if($token) { $auth['Authorization'] = "Bearer $token" }
$cli  = @{}
if($token) { $cli['Authorization'] = "Bearer $token" }

Write-Step "2/5  GET $base/api/health"
$h = Invoke-Sonda -Method 'GET' -Url "$base/api/health" -Headers $cli
if($h.Status -eq 200) { Write-Ok "HTTP 200 - gateway FastAPI no ar" }
elseif($h.Status -eq 401) { Write-Warn2 "HTTP 401 - servico no ar, token recusado/ausente" }
elseif($h.Status -gt 0) { Write-Warn2 "HTTP $($h.Status) - resposta inesperada" }
else { Write-Bad "sem resposta ($($h.Detail))" }

Write-Step "3/5  GET $base/api/ai/predict?symbol=$Symbol&timeframe=$Timeframe"
$g = Invoke-Sonda -Method 'GET' -Url "$base/api/ai/predict?symbol=$Symbol&timeframe=$Timeframe" -Headers $auth
switch($g.Status) {
   200 { Write-Ok 'HTTP 200 - rota GET existe e autenticou' }
   401 { Write-Bad 'HTTP 401 - rota existe; token do .env nao confere com o API_TOKEN do gateway' }
   404 { Write-Bad 'HTTP 404 - o servico no ar NAO tem /api/ai/predict (mt5_gateway/exe antigo)' }
   405 { Write-Bad 'HTTP 405 - rota existe mas nao aceita GET' }
   default { if($g.Status -gt 0){ Write-Warn2 "HTTP $($g.Status)" } else { Write-Bad "sem resposta ($($g.Detail))" } }
}

Write-Step "4/5  POST $base/api/ai/predict?symbol=$Symbol&timeframe=$Timeframe  (o metodo que o EA usa)"
$p = Invoke-Sonda -Method 'POST' -Url "$base/api/ai/predict?symbol=$Symbol&timeframe=$Timeframe" -Headers $auth -Body '{}'
switch($p.Status) {
   200 { Write-Ok 'HTTP 200 - POST aceito; o EA consegue falar com este gateway' }
   401 { Write-Bad 'HTTP 401 - token recusado (mesma causa do passo 3)' }
   404 { Write-Bad 'HTTP 404 - rota ausente no servico no ar' }
   405 { Write-Bad 'HTTP 405 - ROTA SO ACEITA GET e o EA faz POST (defeito de contrato, nao de configuracao)' }
   default { if($p.Status -gt 0){ Write-Warn2 "HTTP $($p.Status)" } else { Write-Bad "sem resposta ($($p.Detail))" } }
}

# ------------------------------------------------- 5. graficos e preset
Write-Step '5/5  configuracao nos graficos e no preset'

$dirCharts = Join-Path $raiz 'Profiles\Charts\Default'
$charts = Get-ChildItem $dirCharts -Filter *.chr -ErrorAction SilentlyContinue
if($charts) {
   $resumo = @()
   foreach($c in $charts) {
      $t = Get-Content $c.FullName -Raw
      $url = [regex]::Match($t, 'AIGatewayUrl=(.*)').Groups[1].Value.Trim()
      $tok = [regex]::Match($t, 'AIGatewayToken=(.*)').Groups[1].Value.Trim()
      $resumo += [pscustomobject]@{ Arquivo = $c.Name; Url = $url; TokenLen = $tok.Length }
   }
   $resumo | Group-Object Url, TokenLen | ForEach-Object {
      $u = $_.Group[0].Url; $n = $_.Group[0].TokenLen
      Write-Info ("{0} grafico(s): url={1} tokenLen={2}" -f $_.Count, $u, $n)
      if($u -notmatch ":$Port/") { Write-Warn2 "  -> a porta dos graficos nao e $Port" }
      if($n -eq 0) { Write-Warn2 '  -> AIGatewayToken vazio: o EA nao envia Authorization' }
      elseif($token -and $n -ne $token.Length) { Write-Warn2 "  -> token do grafico tem $n caracteres; o do .env tem $($token.Length)" }
   }
} else { Write-Warn2 "nenhum .chr em $dirCharts" }

$preset = Join-Path $raiz 'Presets\XAU_AI_PRO.PRO.set'
if(Test-Path $preset) {
   $t = Get-Content $preset -Raw
   $url = [regex]::Match($t, 'AIGatewayUrl=(.*)').Groups[1].Value.Trim()
   $tok = [regex]::Match($t, 'AIGatewayToken=(.*)').Groups[1].Value.Trim()
   Write-Info "preset: url=$url tokenLen=$($tok.Length)"
   if($tok -match 'TOKEN' -or $tok -match 'SEU|COLE|AQUI') {
      Write-Warn2 'preset: o valor de AIGatewayToken e um PLACEHOLDER, nao uma credencial'
   }
   if($url -notmatch ":$Port/") { Write-Warn2 "preset: a porta nao e $Port" }
}

# ------------------------------------------------------------------ veredito
Write-Host ''
if($script:Fail -eq 0 -and $script:Warn -eq 0) {
   Write-Host 'RESULTADO: caminho EA -> gateway consistente nesta medicao' -ForegroundColor Green
} elseif($script:Fail -eq 0) {
   Write-Host "RESULTADO: nenhuma falha dura, $($script:Warn) aviso(s) de configuracao" -ForegroundColor Yellow
} else {
   Write-Host "RESULTADO: $($script:Fail) falha(s) e $($script:Warn) aviso(s) - ver acima" -ForegroundColor Red
}
Write-Host ''
Write-Host 'Lembrete: o WebRequest do MT5 exige, na GUI do terminal,' -ForegroundColor Gray
Write-Host '  Ferramentas > Opcoes > Expert Advisors > "Permitir WebRequest para URLs listadas"' -ForegroundColor Gray
Write-Host "  e http://127.0.0.1:$Port na lista. Isso nao e legivel por script." -ForegroundColor Gray
Write-Host ''
exit $script:Fail
