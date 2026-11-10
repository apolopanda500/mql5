<#
=====================================================================
 declarar-forward.ps1 - declara o binario do forward de 30 dias
=====================================================================
 Substitui a declaracao manual (o `DECLARADO.json`) por uma declaracao
 ATOMICA e VERIFICADA, feita no fim do deploy.

 Regras que este script impoe (e que uma edicao a mao nao impunha):
   1. O binario declarado e **o que esta em disco** (MD5 lido, nao escrito).
   2. A governanca dos modelos e declarada em conjunto (D-162): o EA decide
      com os `.meta.json`, e um binario estavel com governanca mudada mede
      um alvo movel.
   3. **A frota tem de estar LIGADA** (sonda 0, escrita pelo PROPRIO EA:
      `permission_state_*.csv`). Sem isso, a janela de 30 dias abriria a
      medir um universo fechado - e o `D-168` mostrou que isso acontece
      em silencio.
   4. **O que esta em memoria tem de ser a versao declarada** (P1.3592):
      le-se o journal e confirma-se que o ultimo `[START]` de cada simbolo
      e da versao nova. Um deploy que nao reata deixa o disco novo e a
      frota velha - e a janela mediria um binario que nao corre.

 PORQUE A SONDA DE SCRIPT NAO SERVE (P1.3590/P1.3592, medido 10/11/2026)
   As leituras `permission_probe_*.csv` do script `XAI_PermProbe` NAO
   valem como sensor da frota: no MESMO grafico e no MESMO minuto o script
   leu MQL_TRADE_ALLOWED=1 e o EA leu codigo=3 (TG_MQL_OFF):
     12:53:20  XAU_AI_PRO    (USDCZK,H1) [DIAGSCAN] FECHADO codigo=3
     12:56:25  XAI_PermProbe (USDCZK,H1) [PERMPROBE] MQL_TRADE_ALLOWED=1
   Num script o bit devolve a permissao do TERMINAL; num EA devolve a
   permissao DAQUELE GRAFICO. Uma varredura feita com o script certifica
   "15/15 LIGADO" com a frota toda fechada. Este script recusa-se a ler
   os `permission_probe_*.csv`, mesmo como fallback.

 FRESCURA (P1.3593) - porque nao bloqueia por omissao
   O `CPermState::Publish` do v1.2.194 e' chamado em OnInit (forcado) e em
   OnTick (quando o codigo muda, ou a cada 60 s). Num grafico SEM TICK -
   medido no USDRUB: 9379 s sem tick - o ficheiro deixa de ser reescrito
   depois do arranque e fica velho. Isso ja' aconteceu nesta casa com o
   heartbeat (P1.84): "sem tick nao ha OnTick", e a correcao foi passar a
   liveness para OnTimer. Enquanto o Publish nao estiver tambem no timer,
   bloquear por idade punha a declaracao refem de um simbolo de cotacao
   morta. Logo: idade velha e' AVISO (contada e listada); com
   `-ExigirFresco` passa a BLOQUEIO, para quando o EA ja' publicar no timer.

 USO (no fim do deploy, antes da ancora)
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\declarar-forward.ps1
   ... -Simular       (ensaiar tudo e NAO escrever o DECLARADO.json)
   ... -ExigirFresco  (idade do sensor passa a bloquear)
   ... -Forcar        (declara mesmo com a frota incompleta, e diz porquê)

 Saida: 0 = declarado | 3 = frota nao esta toda ligada (ou sensor ausente)
        4 = o que esta em memoria nao e a versao do disco
        1 = erro
=====================================================================
#>
[CmdletBinding()]
param(
  [string]$Root = '',
  [switch]$Forcar,
  [switch]$Simular,
  [switch]$ExigirFresco,
  [int]$MaxIdadeMin = 10
)

$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }
$Root = (Resolve-Path -LiteralPath $Root).Path

$equipe   = Join-Path $Root 'Experts\XAU_AI_PRO\EQUIPE'
$fwdDir   = Join-Path $equipe 'FORWARD'
$ex5      = Join-Path $Root 'Experts\XAU_AI_PRO\XAU_AI_PRO.ex5'
$permData = Join-Path $Root 'Files\Data'
$decl     = Join-Path $fwdDir 'DECLARADO.json'
$logDir   = Join-Path $Root 'Logs'

function Get-MD5([string]$Path) {
  $fs = [System.IO.File]::OpenRead($Path)
  try {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    return ([System.BitConverter]::ToString($md5.ComputeHash($fs)) -replace '-', '')
  } finally { $fs.Close() }
}

function Get-Governanca([string]$ModelosDir) {
  if (-not (Test-Path -LiteralPath $ModelosDir)) { return @{ sha256 = ''; n = 0 } }
  $nomes = @()
  foreach ($f in @(Get-ChildItem -LiteralPath $ModelosDir -Filter '*.meta.json' -ErrorAction SilentlyContinue)) { $nomes += $f.Name }
  [Array]::Sort($nomes)
  $sb = New-Object System.Text.StringBuilder; $n = 0
  foreach ($nome in $nomes) {
    $null = $sb.Append($nome + ':' + (Get-MD5 (Join-Path $ModelosDir $nome)) + "`n"); $n++
  }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  return @{ sha256 = ([System.BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sb.ToString()))) -replace '-', ''); n = $n }
}

# Le um ficheiro de log que o terminal tem aberto (FILE_SHARE_READ|WRITE).
function Read-LogCompartilhado([string]$Path) {
  try {
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read,
                                 ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
    $sr = New-Object System.IO.StreamReader($fs)
    $t = $sr.ReadToEnd(); $sr.Close()
    return $t
  } catch { return '' }
}

if ($Simular) { Write-Host "MODO SIMULACAO: nada sera escrito." -ForegroundColor Cyan; Write-Host "" }

# ---------------------------------------------------------------- binario
if (-not (Test-Path -LiteralPath $ex5)) { Write-Host "ERRO: sem binario em $ex5" -ForegroundColor Red; exit 1 }
$info = Get-Item -LiteralPath $ex5
$md5  = Get-MD5 $ex5
$versao = ''
$vm = Join-Path $Root 'Experts\XAU_AI_PRO\Enterprise\VersionManager.mqh'
if (Test-Path -LiteralPath $vm) {
  $m = Select-String -Path $vm -Pattern '#define\s+EA_VERSION_STRING\s+"([^"]+)"' | Select-Object -First 1
  if ($m) { $versao = $m.Matches[0].Groups[1].Value }
}
if ($versao -eq '') { Write-Host "ERRO: nao consegui ler EA_VERSION_STRING de $vm" -ForegroundColor Red; exit 1 }
$versaoDeclarada = 'v' + $versao
Write-Host ("binario em disco : {0} B | {1} | {2}" -f $info.Length, $md5, $versaoDeclarada)

# ---------------------------------------------------------------- frota (sonda 0 = o proprio EA)
$agora = Get-Date
$ligados = 0; $desligados = 0; $semFresco = 0; $ficheiros = 0
$detalhe = @(); $simbolosON = @(); $simbolosVelhos = @()
if (Test-Path -LiteralPath $permData) {
  # so' a sonda 0 do EA: permission_state_<SIMBOLO>.csv (nunca permission_probe_*, que e' de script)
  foreach ($f in @(Get-ChildItem -LiteralPath $permData -Filter 'permission_state_*.csv' -ErrorAction SilentlyContinue)) {
    $ficheiros++
    $idadeMin = [int]((($agora - $f.LastWriteTime).TotalMinutes))
    try {
      $fs = [System.IO.File]::Open($f.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
      $sr = New-Object System.IO.StreamReader($fs); $t = $sr.ReadToEnd(); $sr.Close()
      $ls = @($t -split "`r?`n" | Where-Object { $_.Trim() -ne '' })
      if ($ls.Count -ge 2) {
        # schema v1.2.194: server_time;local_time;symbol;login;mql;terminal;account;expert;connected;code;stage
        $c = $ls[$ls.Count - 1] -split ';'
        if ($c.Count -ge 11) {
          $sym  = $c[2]
          $pode = ($c[4] -eq '1' -and $c[9] -eq '0')
          if ($pode -and $idadeMin -le $MaxIdadeMin) {
            $ligados++; $simbolosON += $sym
            $detalhe += ($sym + ':bit=1,cod=0,' + $idadeMin + 'min')
          }
          elseif ($pode -and -not $ExigirFresco) {
            $ligados++; $semFresco++; $simbolosON += $sym; $simbolosVelhos += $sym
            $detalhe += ($sym + ':bit=1,cod=0,SEM TICK ha ' + $idadeMin + 'min')
          }
          elseif ($pode) {
            $desligados++; $simbolosVelhos += $sym
            $detalhe += ($sym + ':bit=1 mas STALE ' + $idadeMin + 'min (-ExigirFresco)')
          }
          else {
            $desligados++
            $detalhe += ($sym + ':bit=' + $c[4] + ',cod=' + $c[9] + ',' + $idadeMin + 'min')
          }
        }
      }
    } catch { }
  }
}
Write-Host ("frota (sonda 0)   : {0} LIGADO ({1} frescos, {2} sem tick) | {3} DESLIGADO | {4} ficheiros" -f `
            $ligados, ($ligados - $semFresco), $semFresco, $desligados, $ficheiros) -ForegroundColor Gray
if ($ficheiros -eq 0) {
  Write-Host "  sensor AUSENTE: nenhum permission_state_*.csv. O EA que o escreve e o v1.2.194." -ForegroundColor Yellow
  Write-Host "  Antes do deploy o estado da frota e' DESCONHECIDO - e desconhecido nao declara." -ForegroundColor Yellow
  Write-Host "  (Os permission_probe_*.csv NAO servem: sao de um script, nao do EA. Ver cabecalho.)" -ForegroundColor DarkGray
}
if ($detalhe.Count -gt 0) { Write-Host ('  ' + ($detalhe -join '  ')) -ForegroundColor DarkGray }
if ($semFresco -gt 0) {
  Write-Host ("  NOTA: {0} simbolo(s) com bit ligado mas sensor sem tick ({1}). Conta como LIGADO." -f $semFresco, ($simbolosVelhos -join ',')) -ForegroundColor Yellow
  Write-Host "  Causa: CPermState::Publish so' e' chamado em OnInit/OnTick (P1.3593). Usa -ExigirFresco depois de o EA publicar no timer." -ForegroundColor DarkGray
}
$distintos = @($simbolosON | Select-Object -Unique).Count
if ($ligados -gt 0 -and $distintos -ne $ligados) {
  Write-Host ("  AVISO: {0} linhas LIGADO mas so {1} simbolos distintos - ha ficheiros repetidos." -f $ligados, $distintos) -ForegroundColor Yellow
}

$frotaOK = ($ligados -ge 15 -and $distintos -ge 15)
if (-not $frotaOK -and -not $Forcar) {
  Write-Host ""
  Write-Host "BLOQUEADO: a frota tem $ligados/15 com o bit de negociacao." -ForegroundColor Red
  Write-Host "A janela de 30 dias nao pode abrir assim: mediria um universo fechado, em silencio (D-168)." -ForegroundColor Red
  Write-Host "Religa o botao por grafico (F7 > Comum > 'Permitir negociacao algoritmica') e volta a correr." -ForegroundColor Yellow
  Write-Host "Se a frota nao puder ser ligada, usa -Forcar - e a decisao fica registada." -ForegroundColor DarkGray
  exit 3
}
if (-not $frotaOK) { Write-Host "AVISO: declaracao COM -Forcar apesar de a frota estar incompleta." -ForegroundColor Yellow }

# ---------------------------------------------------------------- memoria (regra 4)
# O ultimo [START] de cada simbolo ligado tem de ser da versao que esta em disco.
$memoria = @{}
$logs = @()
foreach ($dias in 1, 0) {   # do mais ANTIGO para o mais NOVO: o "ultimo [START]" tem de ser o de hoje
  $p = Join-Path $logDir (($agora.AddDays(-$dias)).ToString('yyyyMMdd') + '.log')
  if (Test-Path -LiteralPath $p) { $logs += $p }
}
foreach ($p in $logs) {
  $texto = Read-LogCompartilhado $p
  if ($texto -eq '') { continue }
  foreach ($linha in ($texto -split "`r?`n")) {
    if ($linha -notmatch '\[START\] XAU_AI_PRO (v[0-9]+\.[0-9]+\.[0-9]+).*simbolo=([A-Za-z0-9._#-]+)') { continue }
    $memoria[$Matches[2]] = $Matches[1]
  }
}
$naoCorrem = @(); $semStart = @()
$simbolosAlvo = @(Get-ChildItem -LiteralPath $permData -Filter 'permission_state_*.csv' -ErrorAction SilentlyContinue | ForEach-Object { ($_.BaseName -replace '^permission_state_', '') } | Select-Object -Unique)
# A versao em memoria e' propriedade da FROTA, nao so' dos graficos com o bit: com a frota a 0/15
# este check continua a provar que o deploy reatou (era o furo que a noite de 10/11 expos).
foreach ($sym in $simbolosAlvo) {
  if (-not $memoria.ContainsKey($sym)) { $semStart += $sym; continue }
  if ($memoria[$sym] -ne $versaoDeclarada) { $naoCorrem += ($sym + '=' + $memoria[$sym]) }
}
$corremNovos = @($simbolosAlvo | Where-Object { $memoria.ContainsKey($_) -and $memoria[$_] -eq $versaoDeclarada }).Count
Write-Host ("memoria (journal) : {0}/{1} simbolos em {2} | {3} noutra versao | {4} sem [START]" -f `
            $corremNovos, $simbolosAlvo.Count, $versaoDeclarada, $naoCorrem.Count, $semStart.Count) -ForegroundColor Gray
if ($naoCorrem.Count -gt 0) { Write-Host ('  noutra versao: ' + ($naoCorrem -join '  ')) -ForegroundColor Yellow }
if ($semStart.Count -gt 0)  { Write-Host ('  sem [START] no log: ' + ($semStart -join '  ')) -ForegroundColor Yellow }

if ($naoCorrem.Count -gt 0 -and -not $Forcar) {
  Write-Host ""
  Write-Host "BLOQUEADO: o disco tem $versaoDeclarada mas a frota corre outra versao." -ForegroundColor Red
  Write-Host "O deploy nao reatou. Declarar agora abriria a janela a medir um binario que nao corre." -ForegroundColor Red
  Write-Host "Reata os graficos (F7 ou perfil) e confirma os [START] da versao nova no journal." -ForegroundColor Yellow
  exit 4
}
if ($naoCorrem.Count -gt 0) { Write-Host "AVISO: memoria divergente do disco, declarada COM -Forcar." -ForegroundColor Yellow }

# ---------------------------------------------------------------- governanca
$gov = Get-Governanca (Join-Path $Root 'Files\XAU_AI_PRO\Python\models')
Write-Host ("governanca        : {0} ({1} meta.json)" -f $gov.sha256, $gov.n)

# ---------------------------------------------------------------- escrever
$declObj = [ordered]@{
  versao                  = $versaoDeclarada
  md5                     = $md5
  ex5_bytes               = $info.Length
  ex5_mtime               = $info.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss')
  governanca_sha256       = $gov.sha256
  governanca_modelos      = $gov.n
  declarado_por           = 'CMD'
  declarado_em            = $agora.ToString('dd/MM/yyyy HH:mm')
  frota_ligada_no_declaro = $ligados
  janela_inicio_servidor  = $agora.ToString('dd/MM/yyyy HH:mm') + ' (hora do servidor, no instante da declaracao)'
  janela_inicio_local     = $agora.ToString('dd/MM/yyyy HH:mm')
  frota_sem_tick          = $semFresco
  frota_simbolos          = $simbolosAlvo
  versao_em_memoria       = ($corremNovos.ToString() + '/' + $simbolosAlvo.Count)
  janela_dias             = 30
  criterios               = [ordered]@{ pf_min = 1.2; dd_max_pct = 8.0; trades_min = 30; violacoes_risco_max = 0 }
  regra                   = 'D-139/D-141 (MD5) + D-162 (governanca) + D-168 (frota) + P1.3592 (memoria): o binario, os modelos, a frota da permissao E a versao em memoria entram na declaracao. Qualquer um deles mudar durante a janela e um evento registado.'
  notas                   = @(
    "Declarado por script: o MD5 e lido do disco, nao escrito a mao.",
    "Frota no momento da declaracao: $ligados/15 com bit de negociacao (sensor: permission_state_*.csv do proprio EA).",
    "Versao em memoria: $corremNovos/$($simbolosAlvo.Count) simbolos com [START] $versaoDeclarada no journal.",
    "Simbolos com sensor sem tick (contados como ligados): $semFresco.",
    "A sonda de script (permission_probe_*.csv) NAO serve como sensor da frota: num script o bit devolve a permissao do terminal (medido 10/11 12:53 vs 12:56, USDCZK).",
    "Rollback: reescrever este ficheiro com o binario anterior (git checkout de EQUIPE/FORWARD/DECLARADO.json)."
  )
}

if ($Simular) {
  Write-Host ""
  Write-Host "SIMULACAO - o DECLARADO.json que SERIA escrito:" -ForegroundColor Cyan
  Write-Host ($declObj | ConvertTo-Json -Depth 6)
  Write-Host ""
  Write-Host "SIMULACAO: nada foi escrito." -ForegroundColor Cyan
  exit 0
}

$json = ($declObj | ConvertTo-Json -Depth 6)
[System.IO.File]::WriteAllText($decl, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ""
Write-Host ("DECLARADO: {0} | MD5 {1} | {2} B | governanca {3}" -f $versaoDeclarada, $md5, $info.Length, $gov.sha256) -ForegroundColor Green
Write-Host ("           frota {0}/15 (sem tick: {1}) | memoria {2}/{3}" -f $ligados, $semFresco, $corremNovos, $simbolosAlvo.Count) -ForegroundColor Green
Write-Host "A tabela FORWARD.md passa a mostrar o binario novo a proxima medicao." -ForegroundColor Green
exit 0
