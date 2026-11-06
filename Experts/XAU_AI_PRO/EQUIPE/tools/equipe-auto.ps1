# =====================================================================
# equipe-auto.ps1  ::  RELATORIO UNICO, SOMENTE LEITURA  (DELTA)
#
# Corre de uma vez tudo o que se pode medir sem tocar em nada:
#   canal (EOL/UTF-8/BOM), auditor completo, espelho, disco,
#   consumidores de espaco, fila do dono, pedidos abertos, git.
#
# NAO escreve no canal. NAO altera ficheiros do EA. NAO compila.
# A unica escrita possivel e o relatorio em _SYNC\relatorios\ (-Salvar).
#
# Uso:
#   powershell -NoProfile -ExecutionPolicy Bypass -File equipe-auto.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File equipe-auto.ps1 -Salvar
#   powershell -NoProfile -ExecutionPolicy Bypass -File equipe-auto.ps1 -Silencioso
#
# Saida: bloco legivel + codigo 0 = tudo conforme, 1 = ha problema real.
# =====================================================================
param(
  [string]$Root = '',
  [switch]$Salvar,
  [switch]$Silencioso
)

$ErrorActionPreference = 'Continue'
# PSScriptRoot = <MQL5>\Experts\XAU_AI_PRO\EQUIPE\tools
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }   # -> <MQL5>\Experts\XAU_AI_PRO\EQUIPE
$Equipe = $Root
$Ea     = Split-Path -Parent $Equipe                            # -> <MQL5>\Experts\XAU_AI_PRO
$Mql5   = Split-Path -Parent (Split-Path -Parent $Ea)           # -> <MQL5>
$Data   = Split-Path -Parent $Mql5                              # -> pasta do terminal
$Tester = Join-Path $Data 'Tester'
$Files  = Join-Path $Mql5 'Files'
$Tools  = Join-Path $Equipe 'tools'
$Sync   = Join-Path $Tools 'equipe-sync.ps1'
$Audit  = Join-Path $Mql5 'Tools\equipe-audit.ps1'

$linhas = New-Object System.Collections.Generic.List[string]
$falhas = New-Object System.Collections.Generic.List[string]
$avisos = New-Object System.Collections.Generic.List[string]

function Add([string]$t) { $script:linhas.Add($t); if (-not $Silencioso) { Write-Host $t } }
function Sec([string]$t) { Add ''; Add ('== ' + $t + ' ' + ('=' * [Math]::Max(2, 58 - $t.Length))) }

Add ('EQUIPE-AUTO :: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' :: DELTA')
Add ('raiz EQUIPE :: ' + $Equipe)
Add ('raiz EA     :: ' + $Ea)
Add ('raiz MQL5 :: ' + $Mql5)

# ------------------------------------------------------------------ canal
Sec 'CANAL'
if (Test-Path -LiteralPath $Sync) {
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Sync check 2>&1
  $txt = ($out | Out-String).Trim()
  Add ('  ' + $txt)
  if ($txt -notmatch 'INTEGRO') { $falhas.Add('canal: ' + $txt) }
} else { $falhas.Add('canal: equipe-sync.ps1 ausente em ' + $Sync) }

# ------------------------------------------------------------------ auditor
Sec 'AUDITOR (read-only)'
if (Test-Path -LiteralPath $Audit) {
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Audit all 2>&1
  $rc  = $LASTEXITCODE
  $res = ($out | Select-String -Pattern 'RESULTADO' | Select-Object -Last 1).Line
  Add ('  ' + ($res -replace '\s+', ' ').Trim() + '   (exit ' + $rc + ')')
  ($out | Select-String -Pattern '\[FAIL\]|\[ERRO\]|\[WARN\]' | Select-Object -First 12) | ForEach-Object {
    $l = ($_.Line -replace '\s+', ' ').Trim()
    Add ('  ' + $l)
    if ($l -match '\[FAIL\]|\[ERRO\]') { $avisos.Add('auditor: ' + $l) }
  }
  if ($rc -ne 0) { $falhas.Add('auditor saiu com exit ' + $rc) }
} else { $falhas.Add('auditor ausente: ' + $Audit) }

# ------------------------------------------------------------------ disco
Sec 'DISCO'
try {
  $d = Get-PSDrive -Name ($Data.Substring(0,1)) -ErrorAction Stop
  $livre = [math]::Round($d.Free / 1MB, 0)
  $usado = [math]::Round($d.Used / 1MB, 0)
  Add ('  livre: ' + $livre + ' MB   usado: ' + $usado + ' MB   total: ' + ($livre + $usado) + ' MB')
  if ($livre -lt 1000) { $falhas.Add('disco abaixo de 1000 MB livres: ' + $livre + ' MB') }
  elseif ($livre -lt 2000) { $avisos.Add('disco entre 1000 e 2000 MB livres: ' + $livre + ' MB') }
} catch { $avisos.Add('disco: nao medido (' + $_.Exception.Message + ')') }

function Get-Tamanho([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { return $null }
  $m = Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue |
       Measure-Object -Property Length -Sum
  return [pscustomobject]@{ MB = [math]::Round($m.Sum / 1MB, 1); N = $m.Count }
}

Sec 'CONSUMIDORES (MB / ficheiros)'
$zonas = @(
  @{ N = 'Tester\logs (fora da raiz de escrita)'; P = (Join-Path $Tester 'logs') },
  @{ N = 'MQL5\Files';                            P = $Files },
  @{ N = 'Files\XAU_AI_PRO';                      P = (Join-Path $Files 'XAU_AI_PRO') },
  @{ N = 'Files\Data';                            P = (Join-Path $Files 'Data') },
  @{ N = 'Files\Temp';                            P = (Join-Path $Files 'Temp') },
  @{ N = 'Files\Backup';                          P = (Join-Path $Files 'Backup') }
)
foreach ($z in $zonas) {
  $t = Get-Tamanho $z.P
  if ($null -eq $t) { Add ('  ' + $z.N.PadRight(38) + 'ausente') }
  else {
    Add ('  ' + $z.N.PadRight(38) + ([string]$t.MB).PadLeft(9) + ' MB ' + ([string]$t.N).PadLeft(7) + ' f')
    if ($z.N -like 'Tester*' -and $t.MB -gt 1500) { $avisos.Add('Tester\logs com ' + $t.MB + ' MB - fora da raiz de escrita, so o DONO apaga') }
  }
}

$logs = Join-Path $Tester 'logs'
if (Test-Path -LiteralPath $logs) {
  $top = Get-ChildItem -LiteralPath $logs -File -ErrorAction SilentlyContinue |
         Sort-Object Length -Descending | Select-Object -First 3
  foreach ($f in $top) { Add ('    maior: ' + $f.Name.PadRight(20) + ([string][math]::Round($f.Length/1MB,1)).PadLeft(8) + ' MB') }
}

# ------------------------------------------------------------------ fila do DONO
Sec 'FILA DO DONO / PEDIDOS'
$inboxDono = Join-Path $Equipe 'INBOX_DONO.md'
if (Test-Path -LiteralPath $inboxDono) {
  $c = Get-Content -LiteralPath $inboxDono -Raw
  $ab = ([regex]::Matches($c, '(?m)^---\s*$')).Count
  $fe = ([regex]::Matches($c, 'estado:\s*FECHADO')).Count
  Add ('  INBOX_DONO.md: ' + [math]::Round((Get-Item -LiteralPath $inboxDono).Length/1KB,1) + ' KB :: ' + $ab + ' blocos :: ' + $fe + ' marcados FECHADO :: ~' + [math]::Max(0, $ab - $fe) + ' por responder')
  if (($ab - $fe) -gt 0) { $avisos.Add(($ab - $fe).ToString() + ' bloco(s) por responder na fila do DONO') }
}
$pedidos = Join-Path $Equipe 'PEDIDOS.md'
if (Test-Path -LiteralPath $pedidos) {
  $p = Get-Content -LiteralPath $pedidos -Raw
  foreach ($est in @('PEDIDO','ACEITE','EM CURSO','BLOQUEADO','DEVOLVIDO')) {
    $n = ([regex]::Matches($p, '\|\s*' + $est + '\s*\|')).Count
    if ($n -gt 0) { Add ('  PEDIDOS.md ' + $est.PadRight(10) + ': ' + $n) }
  }
}

# ------------------------------------------------------------------ ids
Sec 'IDS / DECISOES'
$dec = Join-Path $Equipe 'DECISOES.md'
$ids = Join-Path $Equipe 'IDS.md'
if ((Test-Path -LiteralPath $dec) -and (Test-Path -LiteralPath $ids)) {
  $dc = Get-Content -LiteralPath $dec -Raw
  $blocos = ([regex]::Matches($dc, '(?m)^## D-0\d\d')).Count
  $usados = ([regex]::Matches((Get-Content -LiteralPath $ids -Raw), '(?m)^USADO\s*\|\s*D\s*\|\s*D-(\d{3})')).Count
  Add ('  DECISOES.md: ' + $blocos + ' blocos D-xxx :: IDS.md: ' + $usados + ' IDs USADO')
  if ($usados -gt $blocos) { $avisos.Add('IDS.md tem ' + ($usados - $blocos) + ' ID(s) USADO sem bloco no DECISOES.md') }
}

# ------------------------------------------------------------------ espelho (rapido)
Sec 'ESPELHO / CODIGO'
$ea = $Ea
$fonte = $Ea
$ex5   = Join-Path $fonte 'XAU_AI_PRO.ex5'
if (Test-Path -LiteralPath $ex5) {
  $f = Get-Item -LiteralPath $ex5
  Add ('  XAU_AI_PRO.ex5 :: ' + $f.Length + ' B :: ' + $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))
}
$mq5 = (Get-ChildItem -LiteralPath $fonte -Recurse -File -Include *.mq5, *.mqh -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum)
Add ('  fontes .mq5/.mqh: ' + $mq5.Count + ' ficheiros :: ' + [math]::Round($mq5.Sum/1KB,1) + ' KB')

# ------------------------------------------------------------------ git
Sec 'GIT'
$g = $Mql5
while ($g -and -not (Test-Path -LiteralPath (Join-Path $g '.git'))) { $g = Split-Path -Parent $g }
if ($g) {
  $st = & git -C $g status --porcelain 2>&1
  $br = (& git -C $g rev-parse --abbrev-ref HEAD 2>&1 | Out-String).Trim()
  $n  = ($st | Where-Object { $_.Trim() -ne '' }).Count
  Add ('  repo: ' + $g)
  Add ('  branch: ' + $br + ' :: alterados/nao rastreados: ' + $n)
} else { Add '  repo git nao encontrado acima de MQL5' }

# ------------------------------------------------------------------ veredicto
Sec 'VEREDICTO'
if ($falhas.Count -eq 0) {
  Add '  CONFORME :: 0 falhas'
} else {
  Add ('  FALHAS (' + $falhas.Count + '):')
  $falhas | ForEach-Object { Add ('   - ' + $_) }
}
if ($avisos.Count -gt 0) {
  Add ('  AVISOS (' + $avisos.Count + '):')
  $avisos | ForEach-Object { Add ('   ~ ' + $_) }
}

if ($Salvar) {
  $dir = Join-Path $Equipe '_SYNC\relatorios'
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $arq = Join-Path $dir ('auto_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.txt')
  [System.IO.File]::WriteAllText($arq, ($linhas -join "`n") + "`n", (New-Object System.Text.UTF8Encoding($false)))
  if (-not $Silencioso) { Write-Host ''; Write-Host ('gravado :: ' + $arq) }
}

if ($falhas.Count -eq 0) { exit 0 } else { exit 1 }
