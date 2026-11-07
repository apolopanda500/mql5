<#
.SYNOPSIS
   Sonda o gateway de IA local (AIGatewayUrl) e diz exatamente o que falhou.

.DESCRIPTION
   O EA usa GET em /api/ai/predict e le a porta e o token de
   MQL5\Files\XAU_AI_PRO\.env (XAU_GATEWAY_PORT / XAU_GATEWAY_TOKEN). Esta sonda
   segue o MESMO contrato, para nao produzir um 401 falso:

     1. porta TCP aberta?          (fechada = servico ausente, NAO e token)
     2. raiz HTTP responde?        (404/401/200 = servico vivo)
     3. rota de predicao SEM token (200 = sem auth; 401 = exige token)
     4. rota de predicao COM token (200 = token valido)

   Correcao de 06/11/2026 (DELTA, D-056): a versao anterior usava a porta 9001
   (bridge interno do terminal64) e POST numa rota que e GET na 9011. O 401 da
   9001 era lido como "falta token", quando o servico do gateway estava noutra
   porta. Agora o padrao e 9011 e o metodo e GET.

   O token NUNCA e impresso. Vem de $env:XAU_AI_GATEWAY_TOKEN ou, se ausente,
   do .env do gateway.

.PARAMETER BaseUrl
   Base do gateway. Padrao: http://127.0.0.1:9011 (ou a porta de XAU_GATEWAY_PORT
   no .env, quando -BaseUrl nao e passado).

.PARAMETER Symbol
   Simbolo enviado na query string. Padrao: XAUUSD

.PARAMETER Timeframe
   Timeframe enviado na query string. Padrao: H1

.EXAMPLE
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\api-probe.ps1

.EXAMPLE
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\api-probe.ps1 -Symbol USDCNH
#>
[CmdletBinding()]
param(
   [string]$BaseUrl   = 'http://127.0.0.1:9011',
   [string]$Path      = '/api/ai/predict',
   [string]$Symbol    = 'XAUUSD',
   [string]$Timeframe = 'H1',
   [int]$TimeoutSec   = 8
)

$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

$script:Fail = 0

function Write-Step { param([string]$T) Write-Host ''; Write-Host "== $T" -ForegroundColor Cyan }
function Write-Ok   { param([string]$T) Write-Host "[ OK ] $T" -ForegroundColor Green }
function Write-Bad  { param([string]$T) Write-Host "[FAIL] $T" -ForegroundColor Red; $script:Fail++ }
function Write-Warn { param([string]$T) Write-Host "[WARN] $T" -ForegroundColor Yellow }
function Write-Info { param([string]$T) Write-Host "[info] $T" -ForegroundColor Gray }

# ---------------------------------------------------------------- .env do EA
# Mesmo ficheiro que AIConnector.mqh le: MQL5\Files\XAU_AI_PRO\.env.
$EnvFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'Files\XAU_AI_PRO\.env'

function Get-EnvValue {
   param([string]$Key)
   if(-not (Test-Path -LiteralPath $EnvFile)) { return '' }
   try {
      foreach($linha in [System.IO.File]::ReadAllLines($EnvFile)) {
         $l = $linha.Trim()
         if($l.StartsWith('#')) { continue }
         $eq = $l.IndexOf('=')
         if($eq -lt 1) { continue }
         $k = $l.Substring(0, $eq).Trim()
         if($k -ne $Key) { continue }
         $v = $l.Substring($eq + 1).Trim()
         return $v.Trim('"').Trim("'")
      }
   } catch { }
   return ''
}

# A porta do .env manda no EA (AIGatewayPortaEnv), portanto a sonda usa a mesma,
# salvo se o operador passou -BaseUrl explicitamente.
if(-not $PSBoundParameters.ContainsKey('BaseUrl')) {
   $envPort = Get-EnvValue 'XAU_GATEWAY_PORT'
   if($envPort -match '^\d+$') { $BaseUrl = "http://127.0.0.1:$envPort" }
}

# ---------------------------------------------------------------- normalizacao
if($BaseUrl -notmatch '^https?://') {
   Write-Bad "BaseUrl invalida (precisa de http:// ou https://): $BaseUrl"
   exit 1
}
$uriBase = [System.Uri]$BaseUrl
$host_   = $uriBase.Host
$port_   = if($uriBase.Port -gt 0) { $uriBase.Port } else { if($uriBase.Scheme -eq 'https') { 443 } else { 80 } }

Write-Host ''
Write-Host 'PROBE DO GATEWAY DE IA' -ForegroundColor White
Write-Info "base    : $BaseUrl"
Write-Info "host    : $host_"
Write-Info "porta   : $port_"
Write-Info "metodo  : GET (o mesmo do EA)"
Write-Info "rota    : $Path`?symbol=$Symbol&timeframe=$Timeframe"
if(Test-Path -LiteralPath $EnvFile) { Write-Info "env     : $EnvFile" } else { Write-Info "env     : ausente ($EnvFile)" }

# ------------------------------------------------------------------- 1. TCP
Write-Step '1/4  porta TCP'
$tcp = $false
try {
   $tcp = Test-NetConnection -ComputerName $host_ -Port $port_ -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction Stop
} catch {
   $tcp = $false
}
if($tcp) {
   Write-Ok "porta $port_ aceita conexao (servico esta de pe)"
} else {
   Write-Bad "porta $port_ FECHADA - nao ha servico nesta porta; NAO e falta de token"
   Write-Info "suba o backend na porta $port_ ou confira XAU_GATEWAY_PORT no .env"
   Write-Info "a 9001 e o bridge do terminal64 (MT5), nao o gateway - 401 nessa porta nao prova nada sobre o token"
   Write-Host ''
   Write-Host "RESULTADO: $($script:Fail) falha(s) - servico ausente" -ForegroundColor Red
   Write-Host ''
   exit $script:Fail
}

# ------------------------------------------------------------------ 2. raiz
function Invoke-Probe {
   param([string]$Method, [string]$Url, [string]$Body, [hashtable]$Headers)

   $out = [pscustomobject]@{ Status = 0; Detail = ''; Content = '' }
   $rp  = @{ Uri = $Url; Method = $Method; TimeoutSec = $TimeoutSec; UseBasicParsing = $true }
   if($Headers) { $rp.Headers = $Headers }
   if($Body)    { $rp.Body = $Body; $rp.ContentType = 'application/json' }

   try {
      $r = Invoke-WebRequest @rp
      $out.Status  = [int]$r.StatusCode
      $out.Content = [string]$r.Content
   } catch {
      $resp = $_.Exception.Response
      if($resp -ne $null) {
         $out.Status = [int]$resp.StatusCode
         try {
            $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $out.Content = $sr.ReadToEnd()
            $sr.Close()
         } catch { }
      }
      $out.Detail = $_.Exception.Message
   }
   return $out
}

Write-Step '2/4  raiz HTTP'
$rootUrl = "$($uriBase.Scheme)://$($host_):$port_/"
$root = Invoke-Probe -Method 'GET' -Url $rootUrl
if($root.Status -gt 0) {
   Write-Ok "raiz respondeu HTTP $($root.Status) - servico HTTP vivo"
   if($root.Content) { Write-Info ("corpo: " + $root.Content.Substring(0, [Math]::Min(160, $root.Content.Length))) }
} else {
   Write-Bad "raiz nao respondeu ($($root.Detail)) - servico nao e HTTP ou esta travado"
}

# -------------------------------------------------- 3. predicao sem token
Write-Step '3/4  rota de predicao SEM token'
$predUrl = "$($uriBase.Scheme)://$($host_):$port_$Path`?symbol=$Symbol&timeframe=$Timeframe"
$noAuth  = Invoke-Probe -Method 'GET' -Url $predUrl
if($noAuth.Status -eq 200) {
   Write-Ok 'HTTP 200 - gateway aceita sem token; AIGatewayToken pode ficar vazio'
} elseif($noAuth.Status -eq 401) {
   Write-Warn 'HTTP 401 - o servico esta VIVO e EXIGE token (nao e porta fechada)'
   Write-Info 'no EA, o token vem de XAU_GATEWAY_TOKEN no .env; header "Authorization: Bearer <token>"'
} elseif($noAuth.Status -eq 405) {
   Write-Warn 'HTTP 405 - metodo errado; a rota do gateway e GET (esta sonda ja usa GET)'
   Write-Info 'se aparecer 405, o servico nessa porta nao e o gateway esperado'
} elseif($noAuth.Status -gt 0) {
   Write-Warn "HTTP $($noAuth.Status) - resposta inesperada (servico vivo)"
} else {
   Write-Bad "sem resposta ($($noAuth.Detail))"
}

# ----------------------------------------------------- 4. predicao com token
Write-Step '4/4  rota de predicao COM token'
$token = $env:XAU_AI_GATEWAY_TOKEN
if([string]::IsNullOrWhiteSpace($token)) { $token = Get-EnvValue 'XAU_GATEWAY_TOKEN' }
if([string]::IsNullOrWhiteSpace($token)) {
   Write-Info 'token nao encontrado (nem env nem .env) - passo pulado'
} else {
   Write-Info "token resolvido ($($token.Length) caracteres; valor nao impresso)"
   $authHdr = @{ Authorization = "Bearer $token" }
   $withAuth = Invoke-Probe -Method 'GET' -Url $predUrl -Headers $authHdr
   if($withAuth.Status -eq 200) {
      Write-Ok 'HTTP 200 - token valido, gateway autenticado'
      if($withAuth.Content) { Write-Info ("corpo: " + $withAuth.Content.Substring(0, [Math]::Min(240, $withAuth.Content.Length))) }
   } elseif($withAuth.Status -eq 401) {
      Write-Bad 'HTTP 401 - token RECUSADO; confira o XAU_GATEWAY_TOKEN do .env'
   } else {
      Write-Warn "HTTP $($withAuth.Status) - resposta inesperada com token"
   }
}

# ------------------------------------------------------------------ veredito
Write-Host ''
if($script:Fail -eq 0) {
   Write-Host 'RESULTADO: sonda concluida sem falhas de infraestrutura' -ForegroundColor Green
} else {
   Write-Host "RESULTADO: $($script:Fail) falha(s) - ver itens [FAIL] acima" -ForegroundColor Red
}
Write-Host ''
Write-Host 'Lembrete: no MT5, o WebRequest so funciona com' -ForegroundColor Gray
Write-Host '  Ferramentas > Opcoes > Expert Advisors > "Permitir WebRequest para URLs listadas"' -ForegroundColor Gray
Write-Host "  e o dominio $($uriBase.Scheme)://${host_}:${port_} presente na lista." -ForegroundColor Gray
Write-Host ''
exit $script:Fail
