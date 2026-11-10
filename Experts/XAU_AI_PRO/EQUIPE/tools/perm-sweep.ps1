<#
   perm-sweep.ps1 - EQUIPE (ALFA/DELTA) - 10/11/2026
   Varredura da permissao de negociacao POR GRAFICO (MQL_TRADE_ALLOWED).

   Porque existe: o bit MQL_TRADE_ALLOWED e' estado de sessao do terminal, NAO
   vive no .chr nem no .tpl (medido: bloco <expert> identico num grafico com
   permissao e noutro sem). Cai a cada arranque do EA e nao ha ferramenta MCP
   que o reponha - so' o botao "Negociacao algoritmica" do terminal (ou F7 >
   Comum > Permitir negociacao algoritmica, por grafico).

   ------------------------------------------------------------------
   v1.2.194 (10/11/2026) - P1.3590: SONDA 0, e a unica autoritativa.
   ------------------------------------------------------------------
   MEDIDO: as 12:53:20.473 o EA em USDCZK escreveu
     [DIAGSCAN] portao do grafico=FECHADO | codigo=3
   e as 12:56:25.652 o script XAI_PermProbe no MESMO grafico escreveu
     [PERMPROBE] USDCZK | MQL_TRADE_ALLOWED=1 ... | codigo=0
   O mesmo par em USDBRL (EA codigo=3 as 12:58:20.222, sonda mql=1 as
   12:56:25.651). Nao houve reinicio entre as leituras e o script nao altera
   nada: a diferenca e' de QUEM le. Num SCRIPT, MQLInfoInteger(MQL_TRADE_ALLOWED)
   devolve a permissao do TERMINAL; num EA devolve a permissao DAQUELE GRAFICO.
   Portanto uma varredura feita com script certifica "15/15 LIGADO" com a frota
   toda fechada - e' o erro que este ficheiro passa a recusar.

   Sondas, por ordem de confianca:
     0. permission_state_<SIMBOLO>.csv  (EA, v1.2.194+) - AUTORITATIVA
        reescrita por cada instancia no OnInit e quando o codigo muda (<=60 s)
     1. [PERM] MQL_TRADE_ALLOWED=<0|1>  (journal do EA, 1 linha por reinicio)
     2. [DIAGSCAN] portao do grafico=... codigo=<0..5> (journal, ~5 min, UMA
        instancia de cada vez - nao cobre os 15)
     3. status.json / heartbeat (recurso: so' quando 0 e 1 nao existem)
   Codigos (Core/TradeGate.mqh): 0 OK | 1 terminal off | 2 conta off | 3 EA off
                                 | 4 broker sem EA | 5 desligado

   Nota operacional: o terminal mantem o journal aberto em escrita exclusiva.
   A leitura usa FileShare.ReadWrite|Delete, senao da' "arquivo em uso".

   Uso:  powershell -NoProfile -ExecutionPolicy Bypass -File perm-sweep.ps1
   Nao escreve nada, nao altera nada, nao toca em ordens.
#>

$ErrorActionPreference = 'Stop'

$root    = 'C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075'
$logs    = Join-Path $root 'MQL5\Logs'
$data    = Join-Path $root 'MQL5\Files\Data'
$status  = Join-Path $data 'system_status.json'
$hb      = Join-Path $root 'Common\Files\XAU_AI_PRO_heartbeat.json'
$profile = Join-Path $root 'MQL5\Profiles\Charts\XAU_AI_PRO_15CHARTS_Q071'

$CODEMAP = @{ '0'='OK'; '1'='TERMINAL_OFF'; '2'='CONTA_OFF'; '3'='EA_OFF'; '4'='BROKER_SEM_EA'; '5'='DESLIGADO' }

function Read-Shared([string]$path) {
   $share = [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete
   $fs = New-Object IO.FileStream($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, $share)
   try {
      $sr = New-Object IO.StreamReader($fs, [Text.Encoding]::UTF8)
      try { return $sr.ReadToEnd() } finally { $sr.Dispose() }
   } finally { $fs.Dispose() }
}

function Split-Lines([string]$txt) {
   return @(($txt -split "`n") | ForEach-Object { $_.TrimEnd("`r") } | Where-Object { $_.Trim() -ne '' })
}

function Read-StateFile([string]$path) {
   if (-not (Test-Path -LiteralPath $path)) { return $null }
   try { $lines = Split-Lines (Read-Shared $path) } catch { return $null }
   if ($lines.Count -lt 2) { return $null }
   $f = $lines[$lines.Count - 1] -split ';'
   if ($f.Count -lt 11) { return $null }
   return [pscustomobject]@{
      symbol = $f[2]; login = $f[3]; mql = $f[4]; terminal = $f[5]
      account = $f[6]; expert = $f[7]; connected = $f[8]; code = $f[9]; stage = $f[10]
   }
}

function Read-ProbeScript([string]$path) {
   # sonda do SCRIPT: registada de proposito, para poder ser ACUSADA de divergir
   if (-not (Test-Path -LiteralPath $path)) { return $null }
   try { $lines = Split-Lines (Read-Shared $path) } catch { return $null }
   if ($lines.Count -lt 2) { return $null }
   $f = $lines[$lines.Count - 1] -split ';'
   if ($f.Count -lt 10) { return $null }
   return [pscustomobject]@{ mql = $f[4]; code = $f[9]; at = $f[1] }
}

# universo: os simbolos do perfil vivo
$symbols = @()
Get-ChildItem -LiteralPath $profile -Filter 'CHART*.CHR' | Sort-Object Name | ForEach-Object {
   $m = [regex]::Match([IO.File]::ReadAllText($_.FullName), '(?m)^symbol=(\S+)')
   if ($m.Success) { $symbols += $m.Groups[1].Value }
}

# sonda 1 e 2: journal do dia
$logFile = Join-Path $logs ((Get-Date).ToString('yyyyMMdd') + '.log')
$perm = @{}; $permAt = @{}; $diag = @{}; $diagAt = @{}
$logLines = 0
if (Test-Path -LiteralPath $logFile) {
   $txt = Read-Shared $logFile
   foreach ($l in ($txt -split "`n")) {
      $logLines++
      $ms = [regex]::Match($l, 'XAU_AI_PRO \((\w+),')
      if (-not $ms.Success) { continue }
      $sym = $ms.Groups[1].Value
      $mt = [regex]::Match($l, '(\d\d:\d\d:\d\d\.\d\d\d)')
      $t = ''
      if ($mt.Success) { $t = $mt.Groups[1].Value }
      $mp = [regex]::Match($l, 'MQL_TRADE_ALLOWED=(\d)')
      if ($mp.Success) { $perm[$sym] = $mp.Groups[1].Value; $permAt[$sym] = $t }
      $md = [regex]::Match($l, 'DIAGSCAN.*codigo=(\d+)')
      if ($md.Success) { $diag[$sym] = $md.Groups[1].Value; $diagAt[$sym] = $t }
   }
}

# sonda 3: sistema
$sysSym = ''; $sysCode = ''; $sysAt = ''
if (Test-Path -LiteralPath $status) {
   $sj = Read-Shared $status
   $m = [regex]::Match($sj, '"ea_trade_allowed":(true|false)')
   if ($m.Success) { if ($m.Groups[1].Value -eq 'true') { $sysCode = '0' } else { $sysCode = '3' } }
   $m = [regex]::Match($sj, '"trade_gate_code":(\d+)')
   if ($m.Success) { $sysCode = $m.Groups[1].Value }
   $m = [regex]::Match($sj, '"symbol":\s*"([^"]*)"')
   if ($m.Success) { $sysSym = $m.Groups[1].Value }
   $m = [regex]::Match($sj, '"generated_at":\s*"([^"]*)"')
   if ($m.Success) { $sysAt = $m.Groups[1].Value }
}

# sonda 3b: heartbeat (quem escreveu por ultimo)
$hbSym = ''; $hbCode = ''; $hbAt = ''
if (Test-Path -LiteralPath $hb) {
   try {
      $h = Read-Shared $hb
      $m = [regex]::Match($h, '"symbol":\s*"([^"]*)"');      if ($m.Success) { $hbSym = $m.Groups[1].Value }
      $m = [regex]::Match($h, '"trade_gate_code":\s*(\d+)'); if ($m.Success) { $hbCode = $m.Groups[1].Value }
      $m = [regex]::Match($h, '"timestamp":\s*"([^"]*)"');   if ($m.Success) { $hbAt = $m.Groups[1].Value }
   } catch { }
}

$agora = Get-Date
$temEstado = 0; $semEstado = @()

Write-Output ''
Write-Output '=== PERMISSAO POR GRAFICO (MQL_TRADE_ALLOWED) ==='
Write-Output ("hora local: {0}   |   journal: {1}   |   linhas: {2}" -f $agora.ToString('HH:mm:ss'), (Split-Path $logFile -Leaf), $logLines)
Write-Output ''

# v1.2.192 (10/11/2026) - P1.3521: o veredicto desta tabela estava INVERTIDO no
# probe mais importante. MEDIDO ao correr a versao anterior as 10:43:15 de
# 10/11/2026: imprimiu 'XAUUSD LIGADO' com a propria coluna a mostrar [PERM] 0
# @10:03:27.570, 'USDCOP LIGADO' com [PERM] 0 @10:10:05.637 e 'USDRUB LIGADO'
# com [PERM] 0 @10:29:26.988, e 'NZDUSD DESLIGADO(TERMINAL_OFF)' com [PERM] 1
# @09:09:35.736. A causa e' de LINGUAGEM, nao de leitura: [PERM] publica o BIT
# (MQL_TRADE_ALLOWED=1 -> pode negociar, =0 -> barrado), enquanto [DIAGSCAN],
# status.json e heartbeat publicam o CODIGO do portao (0=OK, 3=EA_OFF). Passa a
# haver normalizacao para CODIGO antes de comparar. Outras duas correcoes do
# mesmo bloco: a ordem passou a ser por HORA real (TimeSpan) e nao por texto,
# e nasce a coluna IDADE (a partir de 20 min o veredicto leva a marca VENCIDO).

Write-Output ("{0,-8} {1,-26} {2,-8} {3,-14} {4,-30} {5,-18} {6}" -f 'SIMBOLO', 'VEREDICTO', 'IDADE', 'SONDA', '[ESTADO] bit/cod', '[DIAGSCAN] cod', 'OUTRA SONDA')
Write-Output ('-' * 118)

$on = 0; $off = 0; $unk = 0; $velho = 0; $diverge = 0
foreach ($s in $symbols) {
   $verdict = 'DESCONHECIDO'; $idade = '-'; $sonda = '-'
   $estadoTxt = '-'

   # --- SONDA 0: ficheiro do EA (autoritativa) -------------------------
   $stPath = Join-Path $data ('permission_state_' + $s + '.csv')
   $st = Read-StateFile $stPath
   if ($st -ne $null) {
      $temEstado++
      $code = $st.code
      $estadoTxt = 'bit=' + $st.mql + ' cod=' + $code + ' ' + $st.stage
      $sonda = 'EA/estado'
      try {
         $mins = [int]($agora - (Get-Item -LiteralPath $stPath).LastWriteTime).TotalMinutes
         $idade = "$mins min"
      } catch { }
   } else {
      $semEstado += $s
      # --- sondas 1/2: journal do EA -----------------------------------
      $ev = @()
      if ($perm.ContainsKey($s)) {
         $cbit = if ($perm[$s] -eq '1') { '0' } else { '3' }
         $ev += [pscustomobject]@{ code=$cbit; at=$permAt[$s]; sonda='PERM' }
      }
      if ($diag.ContainsKey($s)) { $ev += [pscustomobject]@{ code=$diag[$s]; at=$diagAt[$s]; sonda='DIAGSCAN' } }
      $ev = @($ev | Where-Object { $_.code -ne '' } |
              Sort-Object { try { [TimeSpan]::Parse($_.at) } catch { [TimeSpan]::Zero } } -Descending)
      if ($ev.Count -gt 0) {
         $last = $ev[0]
         $code = $last.code
         $sonda = $last.sonda
         try {
            $mins = [int]($agora.TimeOfDay - [TimeSpan]::Parse($last.at)).TotalMinutes
            $idade = "$mins min"
         } catch { }
      } else {
         # --- sonda 3: recurso -----------------------------------------
         $fb = ''
         if ($sysSym -eq $s -and $sysCode -ne '') { $fb = $sysCode }
         elseif ($hbSym -eq $s -and $hbCode -ne '') { $fb = $hbCode }
         if ($fb -ne '') { $code = $fb; $sonda = 'status/hb' } else { $code = '' }
      }
   }

   if ($code -ne '') {
      if ($code -eq '0') { $verdict = 'LIGADO'; $on++ }
      else { $verdict = 'DESLIGADO(' + $CODEMAP[$code] + ')'; $off++ }
      if ($idade -ne '-') {
         if ([int]($idade -replace ' min','') -gt 20) { $verdict += ' VENCIDO'; $velho++ }
      }
   } else { $unk++ }

   # --- acusacao da sonda do SCRIPT ------------------------------------
   $PS = Read-ProbeScript (Join-Path $data ('permission_probe_' + $s + '.csv'))
   $flag = ''
   if ($PS -ne $null -and $code -ne '') {
      if ($PS.mql -eq '1' -and $code -ne '0') { $flag = 'SONDA-SCRIPT-DIVERGE(mql=1 vs cod=' + $code + ')'; $diverge++ }
   }

   $p = '-'; if ($perm.ContainsKey($s)) { $p = $perm[$s] + ' @' + $permAt[$s] }
   $d = '-'; if ($diag.ContainsKey($s)) { $d = $diag[$s] + ' @' + $diagAt[$s] }
   $o = ''
   if ($flag -ne '') { $o += $flag + ' ' }
   if ($sysSym -eq $s) { $o += 'status=' + $sysCode + ' ' }
   if ($hbSym  -eq $s) { $o += 'hb=' + $hbCode }
   Write-Output ("{0,-8} {1,-26} {2,-8} {3,-14} {4,-30} {5,-18} {6}" -f $s, $verdict, $idade, $sonda, $estadoTxt, $d, $o.Trim())
}

Write-Output ('-' * 118)
Write-Output ("LIGADO={0}  DESLIGADO={1}  DESCONHECIDO={2}  VENCIDO={3}  de {4} graficos" -f $on, $off, $unk, $velho, $symbols.Count)
Write-Output ("sonda 0 (EA/estado) presente em {0} de {1} graficos" -f $temEstado, $symbols.Count)
if ($semEstado.Count -gt 0) {
   Write-Output ("sem estado do EA (cai nas sondas do journal): {0}" -f ($semEstado -join ', '))
}
if ($diverge -gt 0) {
   Write-Output ''
   Write-Output ("ATENCAO: {0} grafico(s) com SONDA-SCRIPT-CEGA. O XAI_PermProbe (script) le o bit do" -f $diverge)
   Write-Output 'grafico. Causa NAO isolada (hipotese: num script o bit lido seria o do TERMINAL).'
   Write-Output 'ate o teste das 20:30 nao certifique a frota com script - use a coluna [ESTADO] (EA).'
}
Write-Output ''
Write-Output 'Sondas: [ESTADO] = ficheiro do EA (v1.2.194+) | [PERM] 1x por reinicio | [DIAGSCAN] 5 min, 1 instancia.'
Write-Output 'Para repor: F7 > Comum > Permitir negociacao algoritmica, POR GRAFICO (o reattach por template nao repoe o bit).'
Write-Output 'A reposicao em massa pelo botao do terminal NAO foi medida - nao a use como garantia.' 