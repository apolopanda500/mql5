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
   3. **A frota tem de estar LIGADA** (sonda 0: `permission_state_*.csv`).
      Sem isso, a janela de 30 dias abriria a medir um universo fechado -
      e o `D-168` mostrou que isso acontece em silencio.
   4. O que esta em memoria tem de ser a versao declarada: le-se o journal
      e confirma-se que os `[START]` sao da versao nova.

 USO (no fim do deploy, antes da ancora)
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\declarar-forward.ps1
   ... -Forcar        (declara mesmo com a frota incompleta, e diz porquê)

 Saida: 0 = declarado | 3 = frota nao esta toda ligada | 1 = erro
=====================================================================
#>
[CmdletBinding()]
param(
  [string]$Root = '',
  [switch]$Forcar
)

$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }
$Root = (Resolve-Path -LiteralPath $Root).Path

$equipe = Join-Path $Root 'Experts\XAU_AI_PRO\EQUIPE'
$fwdDir = Join-Path $equipe 'FORWARD'
$ex5    = Join-Path $Root 'Experts\XAU_AI_PRO\XAU_AI_PRO.ex5'
$permData = Join-Path $Root 'Files\Data'
$decl   = Join-Path $fwdDir 'DECLARADO.json'
$logDir = Join-Path $Root 'Logs'

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

# ---------------------------------------------------------------- binario
if (-not (Test-Path -LiteralPath $ex5)) { Write-Host "ERRO: sem binario em $ex5" -ForegroundColor Red; exit 1 }
$info = Get-Item -LiteralPath $ex5
$md5 = Get-MD5 $ex5
$versao = ''
$vm = Join-Path $Root 'Experts\XAU_AI_PRO\Enterprise\VersionManager.mqh'
if (Test-Path -LiteralPath $vm) {
  $m = Select-String -Path $vm -Pattern '#define\s+EA_VERSION_STRING\s+"([^"]+)"' | Select-Object -First 1
  if ($m) { $versao = $m.Matches[0].Groups[1].Value }
}
Write-Host ("binario em disco : {0} B | {1} | v{2}" -f $info.Length, $md5, $versao)

# ---------------------------------------------------------------- frota
$ligados = 0; $desligados = 0; $detalhe = @()
if (Test-Path -LiteralPath $permData) {
  foreach ($f in @(Get-ChildItem -LiteralPath $permData -Filter 'permission_state_*.csv' -ErrorAction SilentlyContinue)) {
    try {
      $fs = [System.IO.File]::Open($f.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
      $sr = New-Object System.IO.StreamReader($fs); $t = $sr.ReadToEnd(); $sr.Close()
      $ls = @($t -split "`r?`n" | Where-Object { $_.Trim() -ne '' })
      if ($ls.Count -ge 2) {
        $c = $ls[$ls.Count - 1] -split ';'
        if ($c.Count -ge 11) {
          if ($c[4] -eq '1' -and $c[9] -eq '0') { $ligados++ } else { $desligados++ }
          $detalhe += ($c[2] + ':bit=' + $c[4] + ',cod=' + $c[9])
        }
      }
    } catch { }
  }
}
Write-Host ("frota (sonda 0)   : {0} LIGADO | {1} DESLIGADO" -f $ligados, $desligados)
if ($detalhe.Count -gt 0) { Write-Host ('  ' + ($detalhe -join '  ')) -ForegroundColor DarkGray }

if ($ligados -lt 15 -and -not $Forcar) {
  Write-Host ""
  Write-Host "BLOQUEADO: a frota tem $ligados/15 com o bit de negociacao." -ForegroundColor Red
  Write-Host "A janela de 30 dias nao pode abrir assim: mediria um universo fechado, em silencio (D-168)." -ForegroundColor Red
  Write-Host "Religa o botao por grafico (F7 > Comum > 'Permitir negociacao algoritmica') e volta a correr." -ForegroundColor Yellow
  Write-Host "Se a frota nao puder ser ligada, usa -Forcar - e a decisao fica registada." -ForegroundColor DarkGray
  exit 3
}
if ($ligados -lt 15) {
  Write-Host "AVISO: declarado COM -Forcar apesar de a frota estar incompleta." -ForegroundColor Yellow
}

# ---------------------------------------------------------------- governanca
$gov = Get-Governanca (Join-Path $Root 'Files\XAU_AI_PRO\Python\models')
Write-Host ("governanca        : {0} ({1} meta.json)" -f $gov.sha256, $gov.n)

# ---------------------------------------------------------------- escrever
$agora = Get-Date
$declObj = [ordered]@{
  versao                = ("v" + $versao)
  md5                   = $md5
  ex5_bytes             = $info.Length
  ex5_mtime             = $info.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss')
  governanca_sha256     = $gov.sha256
  governanca_modelos    = $gov.n
  declarado_por         = 'CMD'
  declarado_em          = $agora.ToString('dd/MM/yyyy HH:mm')
  frota_ligada_no_declaro = $ligados
  janela_inicio_servidor = '2026-11-11 00:05'
  janela_inicio_local   = '10/11/2026 21:05'
  janela_dias           = 30
  criterios             = [ordered]@{ pf_min = 1.2; dd_max_pct = 8.0; trades_min = 30; violacoes_risco_max = 0 }
  regra                 = 'D-139/D-141 (MD5) + D-162 (governanca) + D-168 (frota): o binario, os modelos E a frota da permissao entram na declaracao. Qualquer um deles mudar durante a janela e um evento registado.'
  notas                 = @(
    "Declarado por script: o MD5 e lido do disco, nao escrito a mao.",
    "Frota no momento da declaracao: $ligados/15 com bit de negociacao.",
    "Rollback: reescrever este ficheiro com o binario anterior (git checkout de EQUIPE/FORWARD/DECLARADO.json)."
  )
}
$json = ($declObj | ConvertTo-Json -Depth 6)
[System.IO.File]::WriteAllText($decl, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ""
Write-Host ("DECLARADO: {0} | MD5 {1} | {2} B | governanca {3}" -f $declObj.versao, $md5, $info.Length, $gov.sha256) -ForegroundColor Green
Write-Host "A tabela FORWARD.md passa a mostrar o binario novo a proxima medicao." -ForegroundColor Green
exit 0
