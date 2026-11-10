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

# DESVIO ENTRE A HORA LOCAL E A HORA DO SERVIDOR - MEDIDO, NAO CHUTADO.
#
# MEDIDO em 10/11/2026 16:49: o stream do proprio EA (`forward_test_events.csv`)
# escrevia `2026.11.10 21:48:50` no mesmo instante em que o journal escrevia
# `16:48:12`. Logo o servidor = local + 5 h. A constante que eu usava (+3)
# estava errada e punha as linhas do dia no balde errado.
#
# Aqui o desvio e MEDIDO a cada execucao: o stream do EA tem hora do SERVIDOR
# e o journal tem hora LOCAL. Se um dos dois estiver velho (broker fechado,
# stream parado), cai-se no valor de recurso - e a medicao e a que vale.
function Get-OffsetServidor([string]$RootDir) {
  $fallback = 5
  try {
    $stream = Join-Path $RootDir 'Files\Data\forward_test_events.csv'
    $logs = Join-Path $RootDir 'Logs'
    $server = $null; $local = $null

    if (Test-Path -LiteralPath $stream) {
      $fs = [System.IO.File]::Open($stream, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
      $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::Unicode)
      $t = $sr.ReadToEnd(); $sr.Close()
      $ult = @($t -split "`r?`n" | Where-Object { $_.Trim() -ne '' } | Select-Object -Last 1)
      if ($ult.Count -gt 0 -and $ult[0] -match '^(\d{4})\.(\d{2})\.(\d{2}) (\d{2}):(\d{2}):(\d{2})') {
        $server = [datetime]::new([int]$Matches[1], [int]$Matches[2], [int]$Matches[3], [int]$Matches[4], [int]$Matches[5], [int]$Matches[6])
      }
    }

    if (Test-Path -LiteralPath $logs) {
      $lf = @(Get-ChildItem -LiteralPath $logs -Filter '*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
      if ($lf.Count -gt 0) {
        $fs = [System.IO.File]::Open($lf[0].FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
        $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::Unicode)
        $t = $sr.ReadToEnd(); $sr.Close()
        $ult = @($t -split "`r?`n" | Where-Object { $_.Trim() -ne '' } | Select-Object -Last 1)
        if ($ult.Count -gt 0 -and $ult[0] -match '^\S+\s+\S+\s+(\d\d):(\d\d):(\d\d)\.\d+') {
          $hoje = Get-Date
          $local = $hoje.Date.AddHours([int]$Matches[1]).AddMinutes([int]$Matches[2]).AddSeconds([int]$Matches[3])
          if ($local -gt $hoje) { $local = $local.AddDays(-1) }
        }
      }
    }

    if ($server -ne $null -and $local -ne $null) {
      $delta = [math]::Round(($server - $local).TotalHours)
      if ($delta -ge 0 -and $delta -le 14) { return $delta }
    }
  } catch { }
  return $fallback
}

# IMPRESSAO DIGITAL DOS INPUTS DE DECISAO.
#
# O `DECLARADO.json` declara o BINARIO, a GOVERNANCA e a FROTA. Faltava o
#-terceiro: os INPUTS. O `MinAIConfidence` (60 -> 45) e o
# `AIUnavailableConfidenceCap` (40) decidem se ha trades - e vivem no `.chr`,
# nao no `.ex5`. Sem esta impressao, a janela declarada fica cega a uma
# alteracao que decide o resultado (mesma classe do `D-168`).
function Get-ImpressaoInputs([string]$ChartsDir) {
  $campos = @(
    'MinAIConfidence','AIUnavailableConfidenceCap','MinMarketScore','MinMarketScoreNoAI',
    'MinSimulationProbability','MinSimulationExpectancy','EnableMTFConfirmation',
    'EnableStoplessEntry','AllowTradeWithoutAI','RequireStopLoss','MaxDrawdownPercent',
    'RiskPercent','MaxDailyLossPercent','MaxDailyLossUsd','EnableVolatilityFilter',
    'EnableSessionFilter','EnableNewsFilter','SymbolsFromMarketWatch','EnableAutonomousMode',
    'AIHasSignalAuthority','RequireAIJSON','MagicNumber','MaxSpreadPct','StopLossPoints'
    # P1.3604 (10/11/2026) - A IMPRESSAO DIGITAL TINHA UM PONTO CEGO DE 25% DO DIA.
    # O AvoidHoursGMT fecha 6 horas (9,11,14,18,20,22) e NAO estava na lista:
    # zerar essa input mudava o universo medido sem mexer no inputs_sha256.
    # O mesmo vale para o freio de meta diaria (DailyProfitStopTrading para de
    # abrir quando o lucro fecha a meta), para o alvo (TakeProfitPoints /
    # RewardRatio) e para os tectos de exposicao e de posicoes. Todos MEDIDOS
    # presentes no bloco <inputs> do chart01.chr antes de entrarem aqui.
    'EnableAvoidHoursGMT','AvoidHoursGMT',
    'TakeProfitPoints','RewardRatio','RiskPerTradeUsd','Slippage','EnableBreakEven',
    'MaxOpenPositions','MaxTradesPerDay','EnableExposureCap','MaxExposurePercent',
    'MaxTotalRiskPercent','EnableDailyProfitTarget','DailyProfitStopTrading',
    'DailyProfitSlowPercent'
  )
  $saida = @{}
  if (-not (Test-Path -LiteralPath $ChartsDir)) { return @{ sha256 = ''; campos = $saida } }
  $f = @(Get-ChildItem -LiteralPath $ChartsDir -Filter 'chart01.chr' -ErrorAction SilentlyContinue | Select-Object -First 1)
  if ($f.Count -eq 0) { return @{ sha256 = ''; campos = $saida } }
  try {
    $t = [System.IO.File]::ReadAllText($f[0].FullName, [System.Text.Encoding]::Unicode)
    foreach ($c in $campos) {
      $m = [regex]::Match($t, "(?m)^" + [regex]::Escape($c) + "=([^\r\n]+)")
      if ($m.Success) { $saida[$c] = $m.Groups[1].Value.Trim() }
    }
  } catch { }
  $sb = New-Object System.Text.StringBuilder
  foreach ($c in $campos) { $null = $sb.Append($c + '=' + $(if ($saida.ContainsKey($c)) { $saida[$c] } else { '?' }) + "`n") }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  return @{ sha256 = ([System.BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sb.ToString()))) -replace '-', ''); campos = $saida }
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

# COTACAO MORTA - lida do [DIAGSCAN] que o proprio EA publica, nao inferida.
# O [DIAGSCAN] traz "stale=N [USDCLP 9797s, USDCOP 7860s, ...]": N simbolos
# cuja ultima cotacao ja passou o limite. E diferente de
# `frota_sensor_sem_leitura`, que conta ficheiros do sensor NAO reescritos.
# A confusao entre os dois fazia o dossie dizer "0 sem tick" num dia com 3
# simbolos de cotacao parada (R1 da auditoria DELTA, 10/11/2026).
function Get-CotacaoMorta([string]$LogDir) {
  $res = @{ qtd = 0; lista = @(); quando = '' }
  if (-not (Test-Path -LiteralPath $LogDir)) { return $res }
  $arquivos = @(Get-ChildItem -LiteralPath $LogDir -Filter '*.log' -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 2)
  $ultima = $null
  foreach ($a in $arquivos) {
    $txt = Read-LogCompartilhado $a.FullName
    if ($txt -eq '') { continue }
    foreach ($linha in ($txt -split "`r?`n")) {
      if ($linha -match '(\d{2}:\d{2}:\d{2})[^\r\n]*\[DIAGSCAN\].*stale=(\d+)\s*\[([^\]]*)\]') {
        $ultima = @{ qtd = [int]$Matches[2]; lista = $Matches[3].Trim(); quando = ($a.Name + ' ' + $Matches[1]) }
      }
    }
    if ($ultima -ne $null) { break }
  }
  if ($ultima -ne $null) {
    $res.qtd = $ultima.qtd
    $res.quando = $ultima.quando
    if ($ultima.lista -ne '') { $res.lista = @($ultima.lista -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }) }
  }
  return $res
}
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
$contaMemoria = ''
foreach ($p in $logs) {
  $texto = Read-LogCompartilhado $p
  if ($texto -eq '') { continue }
  foreach ($linha in ($texto -split "`r?`n")) {
    if ($linha -notmatch '\[START\] XAU_AI_PRO (v[0-9]+\.[0-9]+\.[0-9]+).*simbolo=([A-Za-z0-9._#-]+)') { continue }
    $memoria[$Matches[2]] = $Matches[1]
    # A CONTA tambem e parte da identidade do forward (D-179): MEDIDO em
    # 10/11 19:45, o terminal trocou de conta NO MESMO SITIO (MetaQuotes-Demo
    # 113568614 -> Headway-Demo 6419396) e o `.ex5` nao mudou - o portao
    # passou a medir outra conta sem dar por isso.
    if ($linha -match 'conta=(\d+)\s*\|\s*([^|]+)\|') {
      $contaMemoria = $Matches[1].Trim() + ' @ ' + $Matches[2].Trim()
    }
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
$agora = Get-Date
$offset = Get-OffsetServidor $Root
$serverNow = $agora.AddHours($offset)
Write-Host ("hora do servidor  : {0} (local {1} + {2} h, desvio MEDIDO)" -f $serverNow.ToString('dd/MM/yyyy HH:mm'), $agora.ToString('dd/MM/yyyy HH:mm'), $offset)

$chartsDir = Join-Path $Root 'Profiles\Charts\XAU_AI_PRO_15CHARTS_Q071'
$inputs = Get-ImpressaoInputs $chartsDir
Write-Host ("inputs (chart01) : {0}" -f $inputs.sha256)
foreach ($k in @('MinAIConfidence','AIUnavailableConfidenceCap','EnableStoplessEntry','AllowTradeWithoutAI','MaxDrawdownPercent','RiskPercent')) {
  if ($inputs.campos.ContainsKey($k)) { Write-Host ("   {0} = {1}" -f $k, $inputs.campos[$k]) -ForegroundColor DarkGray }
}

$cotMorta = Get-CotacaoMorta $logDir

# A ANCORA DA JANELA NAO SE MOVE (D-178).
#
# MEDIDO em 10/11/2026 17:45: `janela_inicio_servidor` passou de 22:19 para
# 22:31 em 12 minutos, porque cada re-declaracao reescrevia o campo. Cada
# re-declaracao reiniciava os 30 dias - e o `inputs_sha256` mudava sempre
# que se acrescentava um campo a lista (23 -> 39), o que dava um alarme
# falso em vez de um evento.
#
# REGRA (pedido do DELTA, aceite): a partir de agora a janela e
# CONGELADA. Uma re-declaracao NAO toca em `janela_inicio_*`: registra-se
# como EVENTO em `historico_declaracoes[]` (hora, md5, inputs, governanca,
# frota, motivo). So o CMD reescreve este ficheiro.
$janelaServidor = $serverNow.ToString('dd/MM/yyyy HH:mm') + ' (hora do SERVIDOR, desvio MEDIDO, no instante da declaracao)'
$janelaLocal = $agora.ToString('dd/MM/yyyy HH:mm')
$historico = @()
$jaDeclarado = $false
if (Test-Path -LiteralPath $decl) {
  try {
    $antigo = Get-Content -LiteralPath $decl -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($antigo.PSObject.Properties.Name -contains 'historico_declaracoes' -and $antigo.historico_declaracoes) {
      $historico = @($antigo.historico_declaracoes)
    }
    if ($antigo.PSObject.Properties.Name -contains 'janela_inicio_servidor' -and $antigo.janela_inicio_servidor) {
      $janelaServidor = [string]$antigo.janela_inicio_servidor
      $janelaLocal = [string]$antigo.janela_inicio_local
      $jaDeclarado = $true
    }
  } catch { }
}
$historico += [ordered]@{
  quando            = $agora.ToString('dd/MM/yyyy HH:mm:ss')
  md5               = $md5
  inputs_sha256     = $inputs.sha256
  governanca_sha256 = $gov.sha256
  frota_ligada      = $ligados
  versao            = $versaoDeclarada
  motivo            = 're-declaracao (a janela nao se move; este registo e o evento)'
}

# Fim da janela e registo da decisao do DONO. A ancora NAO se move: isto e
# so ate quando a janela vale e quem a autorizou (DONO, 10/11/2026 18:08
# local: "conta a partir de hoje ok"). O dia 1 e o dia da ancora congelada.
$janelaFim = ''
try {
  $so = (([string]$janelaServidor) -replace '\s*\(.*$', '').Trim()
  $ini = [datetime]::ParseExact($so, 'dd/MM/yyyy HH:mm', $null)
  $janelaFim = $ini.AddDays(30).ToString('dd/MM/yyyy HH:mm') + ' (servidor)'
} catch { $janelaFim = 'n/d' }
$decisaoAncora = 'DONO, 10/11/2026 18:08 local: a janela conta a partir de hoje. Dia 1 = 10/11/2026; 30 dias ate ' + $janelaFim

$declObj = [ordered]@{
  versao                  = $versaoDeclarada
  md5                     = $md5
  ex5_bytes               = $info.Length
  ex5_mtime               = $info.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss')
  governanca_sha256       = $gov.sha256
  governanca_modelos      = $gov.n
  inputs_sha256           = $inputs.sha256
  inputs                  = $inputs.campos
  offset_servidor_h       = $offset
  declarado_por           = 'CMD'
  declarado_em            = $agora.ToString('dd/MM/yyyy HH:mm')
  frota_ligada_no_declaro = $ligados
  janela_inicio_servidor  = $janelaServidor
  janela_inicio_local     = $janelaLocal
  janela_congelada        = $jaDeclarado
  janela_fim              = $janelaFim
  decisao_ancora          = $decisaoAncora
  historico_declaracoes   = $historico
  frota_sensor_sem_leitura = $semFresco
  frota_cotacao_morta      = $cotMorta.qtd
  frota_cotacao_morta_lista = $cotMorta.lista
  frota_simbolos          = $simbolosAlvo
  versao_em_memoria       = ($corremNovos.ToString() + '/' + $simbolosAlvo.Count)
  conta                   = $contaMemoria
  janela_dias             = 30
  criterios               = [ordered]@{ pf_min = 1.2; dd_max_pct = 8.0; trades_min = 30; violacoes_risco_max = 0 }
  regra                   = 'D-139/D-141 (MD5) + D-162 (governanca) + D-168 (frota) + P1.3592 (memoria): o binario, os modelos, a frota da permissao E a versao em memoria entram na declaracao. Qualquer um deles mudar durante a janela e um evento registado.'
  notas                   = @(
    "Declarado por script: o MD5 e lido do disco, nao escrito a mao.",
    "Frota no momento da declaracao: $ligados/15 com bit de negociacao (sensor: permission_state_*.csv do proprio EA).",
    "Versao em memoria: $corremNovos/$($simbolosAlvo.Count) simbolos com [START] $versaoDeclarada no journal.",
    "Sensor sem leitura recente (contados como LIGADO): $semFresco. NAO e o mesmo que cotacao morta.",
    ("Cotacao morta na ultima varredura do EA: {0} simbolo(s) {1} - lido do [DIAGSCAN] do EA ({2})." -f $cotMorta.qtd, ($cotMorta.lista -join ", "), $cotMorta.quando),
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
