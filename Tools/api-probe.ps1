<#
.SYNOPSIS
   Sonda o gateway de IA local (AIGatewayUrl) e diz exatamente o que falhou.

.DESCRIPTION
   Testa em ordem de diagnostico:
     1. porta TCP aberta?
     2. raiz HTTP responde?
     3. rota de predicao SEM token?  (200 = gateway sem auth; 401 = exige token)
     4. rota de predicao COM token? (le de $env:XAU_AI_GATEWAY_TOKEN)

   O token NUNCA e gravado em arquivo nem no repositorio. Sem a variavel de
   ambiente o passo 4 e pulado.

   Codigos de erro do WebRequest do MT5 (o mesmo diagnostico, do lado do EA):
     4014 WebRequest desabilitado | 4060 URL fora da lista | 5200 URL invalida
     5201 conexao falhou         | 5202 timeout            | 5203 pedido falhou

.PARAMETER BaseUrl
   Base do gateway. Padrao: http://127.0.0.1:9001

.PARAMETER Symbol
   Simbolo enviado na query string. Padrao: XAUUSD

.PARAMETER Timeframe
   Timeframe enviado na query string. Padrao: H1

.EXAMPLE
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\api-probe.ps1

.EXAMPLE
   $env:XAU_AI_GATEWAY_TOKEN = "<token do backend>"
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\api-probe.ps1 -Symbol USDCNH
#>
[CmdletBinding()]
param(
   [string]$BaseUrl   = 'http://127.0.0.1:9001',
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
Write-Info "rota    : $Path`?symbol=$Symbol&timeframe=$Timeframe"

# ------------------------------------------------------------------- 1. TCP
Write-Step '1/4  porta TCP'
$tcp = $false
try {
   $tcp = Test-NetConnection -ComputerName $host_ -Port $port_ -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction Stop
} catch {
   $tcp = $false
}
if($tcp) { Write-Ok "porta $port_ aceita conexao (servico esta de pe)" }
else     { Write-Bad "porta $port_ FECHADA - o gateway nao esta rodando; suba o backend antes de tocar no MT5" }

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
   Write-Ok "raiz respondeu HTTP $($root.Status)"
   if($root.Content) { Write-Info ("corpo: " + $root.Content.Substring(0, [Math]::Min(160, $root.Content.Length))) }
} else {
   Write-Bad "raiz nao respondeu ($($root.Detail)) - servico nao e HTTP ou esta travado"
}

# -------------------------------------------------- 3. predicao sem token
Write-Step '3/4  rota de predicao SEM token'
$predUrl = "$($uriBase.Scheme)://$($host_):$port_$Path`?symbol=$Symbol&timeframe=$Timeframe"
$noAuth  = Invoke-Probe -Method 'POST' -Url $predUrl -Body '{}'
if($noAuth.Status -eq 200) {
   Write-Ok 'HTTP 200 - gateway aceita sem token; AIGatewayToken pode ficar vazio'
} elseif($noAuth.Status -eq 401) {
   Write-Warn 'HTTP 401 - o gateway EXIGE token'
   Write-Info 'no EA, preencha AIGatewayToken; o header usado e "Authorization: Bearer <token>"'
   Write-Info 'sem isso o EA nem envia o header e recebe 401 mesmo com WebRequest liberado'
} elseif($noAuth.Status -eq 422) {
   Write-Warn 'HTTP 422 - gateway respondeu, mas o corpo/parametros nao batem com o contrato'
   Write-Info 'envie symbol/timeframe pela query string e corpo JSON "{}"'
} elseif($noAuth.Status -gt 0) {
   Write-Warn "HTTP $($noAuth.Status) - resposta inesperada"
} else {
   Write-Bad "sem resposta ($($noAuth.Detail))"
}

# ----------------------------------------------------- 4. predicao com token
Write-Step '4/4  rota de predicao COM token'
$token = $env:XAU_AI_GATEWAY_TOKEN
if([string]::IsNullOrWhiteSpace($token)) {
   Write-Info 'XAU_AI_GATEWAY_TOKEN nao definido - passo pulado (nada de token em arquivo)'
} else {
   $authHdr = @{ Authorization = "Bearer $token" }
   $withAuth = Invoke-Probe -Method 'POST' -Url $predUrl -Body '{}' -Headers $authHdr
   if($withAuth.Status -eq 200) {
      Write-Ok 'HTTP 200 - token valido, gateway autenticado'
      if($withAuth.Content) { Write-Info ("corpo: " + $withAuth.Content.Substring(0, [Math]::Min(240, $withAuth.Content.Length))) }
   } elseif($withAuth.Status -eq 401) {
      Write-Bad 'HTTP 401 - token RECUSADO; confira o API_TOKEN do backend'
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
