<#
=====================================================================
 equipe-audit.ps1 - auditor SO-DE-LEITURA do canal EQUIPE/
=====================================================================
 Complemento do `EQUIPE/tools/equipe-sync.ps1` (DELTA, D-015). Divergencia
 de jurisdicao, decidida em `D-016`:

   EQUIPE/tools/equipe-sync.ps1  -> ESCRITA no canal (lock, backup, ancora)
   Tools/equipe-audit.ps1        -> este ficheiro: MEDICAO, nunca escreve

 Este script NAO escreve um unico byte. Nao cria ficheiros, nao faz lock,
 nao altera o canal. Se precisares de escrever, usa a ferramenta do DELTA.

 ACOES
   status  - canal, repo pai, repo aninhado, versao do EA e .ex5
   canal   - tabela por ficheiro: bytes, linhas, CR, ABERTO/RESP/FECHADO, UTF-8
   dono    - decisoes abertas + pedidos ABERTOS -> DONO + fila do dono
   inbox   - pedidos de uma caixa (-Agente ALFA|DELTA|CMD)
   verify  - UTF-8 estrito + artefactos de substituicao + ponteiros
   mirror  - hash de cada fonte do EA contra o espelho em Files/XAU_AI_PRO
   repos   - estado git dos dois repositorios
   all     - status + dono + verify + mirror

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File Tools\equipe-audit.ps1 all
   ... -File Tools\equipe-audit.ps1 inbox -Agente DELTA

 CODIGO DE SAIDA
   0 = tudo medido e conforme
   1 = pelo menos um problema real (UTF-8 invalido, espelho divergente, ...)
=====================================================================
#>
[CmdletBinding()]
param(
  [ValidateSet('status','canal','dono','inbox','verify','mirror','repos','all')]
  [string]$Action = 'status',

  [ValidateSet('ALFA','DELTA','CMD','DONO')]
  [string]$Agente = 'CMD'
)

$ErrorActionPreference = 'Continue'
$script:Failures = 0
$script:Root    = Split-Path -Parent $PSScriptRoot
$script:Equipe  = Join-Path $script:Root 'Experts\XAU_AI_PRO\EQUIPE'
$script:Inbox   = @{
  ALFA  = 'INBOX_AGENTE_1.md'
  DELTA = 'INBOX_AGENTE_2.md'
  CMD   = 'INBOX_AGENTE_3.md'
  DONO  = 'INBOX_DONO.md'
}
$script:Canal = @(
  'PROTOCOLO.md','QUADRO_ESTADO.md','DECISOES.md','CONSOLIDACAO.md',
  'AGENTE_1.md','AGENTE_2.md','AGENTE_3.md',
  'INBOX_AGENTE_1.md','INBOX_AGENTE_2.md','INBOX_AGENTE_3.md','INBOX_DONO.md'
)

# ---------------------------------------------------------------- helpers
function Write-Section([string]$Text) {
  Write-Host ''
  Write-Host ('== ' + $Text + ' ' + ('=' * [Math]::Max(0, 58 - $Text.Length))) -ForegroundColor Cyan
}
function Write-Ok([string]$Text)    { Write-Host ('  [OK]   ' + $Text) -ForegroundColor Green }
function Write-Warn2([string]$Text) { Write-Host ('  [WARN] ' + $Text) -ForegroundColor Yellow }
function Write-Err([string]$Text)   { Write-Host ('  [FAIL] ' + $Text) -ForegroundColor Red; $script:Failures++ }

# Linha-modelo de documentacao (ex.: "| **estado:** ABERTO ou FECHADO | <hora> |")
# nao e um pedido real: tem placeholder.
function Test-Placeholder([string]$Linha) {
  return ($Linha -match '<[^>]+>' -or $Linha -match 'ABERTO ou FECHADO')
}

function Get-Abertos([string]$Texto) {
  return @($Texto -split "`r?`n" | Where-Object {
    $_ -match 'estado:\s*\*{0,2}\s*ABERTO' -and -not (Test-Placeholder $_)
  })
}

function Read-Utf8([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  try { return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) }
  catch { return $null }
}

# UTF-8 estrito: devolve $null se valido, ou o offset do primeiro byte invalido.
function Test-Utf8Strict([string]$Path) {
  $bytes = [System.IO.File]::ReadAllBytes($Path)
  $strict = New-Object System.Text.UTF8Encoding($false, $true)
  try { $null = $strict.GetString($bytes); return $null }
  catch {
    # Localizar o offset a mao para dar mensagem util.
    $i = 0
    while ($i -lt $bytes.Length) {
      $b = $bytes[$i]
      if ($b -lt 0x80) { $i++; continue }
      $len = 0
      if     (($b -band 0xE0) -eq 0xC0) { $len = 2 }
      elseif (($b -band 0xF0) -eq 0xE0) { $len = 3 }
      elseif (($b -band 0xF8) -eq 0xF0) { $len = 4 }
      else { return @{ Offset = $i; Byte = $b } }
      for ($k = 1; $k -lt $len; $k++) {
        if (($i + $k) -ge $bytes.Length -or (($bytes[$i + $k] -band 0xC0) -ne 0x80)) {
          $prev = if ($i -gt 0) { $bytes[$i - 1] } else { 0 }
          return @{ Offset = $i; Byte = $b; Antes = $prev }
        }
      }
      $i += $len
    }
    return @{ Offset = -1; Byte = 0 }
  }
}

function Get-Decisoes {
  $txt = Read-Utf8 (Join-Path $script:Equipe 'DECISOES.md')
  if (-not $txt) { return @() }
  $out = @(); $atual = $null
  foreach ($l in ($txt -split "`r?`n")) {
    if ($l -match '^##\s+(D-[0-9]{3})\s*\|\s*[^|]*\|\s*(.+)$') {
      if ($atual) { $out += $atual }
      $atual = [pscustomobject]@{
        Id = $Matches[1]; Assunto = $Matches[2].Trim(); Estado = ''
        Corpo = New-Object System.Collections.Generic.List[string]
      }
      continue
    }
    if ($atual) {
      if ($l -match '\*\*Estado:\*\*\s*(.+)' -and -not $atual.Estado) { $atual.Estado = $Matches[1].Trim() }
      $atual.Corpo.Add($l)
    }
  }
  if ($atual) { $out += $atual }

  # Um bloco FECHADA pode fechar outros IDs: tabela "| `D-00x` |" ou "superado por".
  $fechadas = New-Object System.Collections.Generic.HashSet[string]
  foreach ($d in $out) {
    if ($d.Estado -notmatch 'FECHADA') { continue }
    foreach ($l in $d.Corpo) {
      if ($l -match '^\|\s*`(D-[0-9]{3})`') { $null = $fechadas.Add($Matches[1]) }
      if ($l -match '(SUPERSEDID|superado por|fica superado)') {
        foreach ($m in [regex]::Matches($l, 'D-[0-9]{3}')) { $null = $fechadas.Add($m.Value) }
      }
    }
  }
  foreach ($d in $out) {
    if ($fechadas.Contains($d.Id) -and $d.Estado -match 'ABERTA|PROPOSTA') {
      $d.Estado = 'FECHADA (por bloco/superada - ver DECISOES.md)'
    }
  }
  return $out
}

# ---------------------------------------------------------------- canal
function Measure-Arquivo([string]$Path) {
  $bytes = [System.IO.File]::ReadAllBytes($Path)
  $cr = 0; foreach ($b in $bytes) { if ($b -eq 0x0D) { $cr++ } }
  $txt = Read-Utf8 $Path
  $linhas = @($txt -split "`n").Count
  [pscustomobject]@{
    Nome    = Split-Path $Path -Leaf
    Bytes   = $bytes.Length
    Linhas  = $linhas
    CR      = $cr
    Abertos = (Get-Abertos $txt).Count
    Resp    = @($txt -split "`r?`n" | Where-Object { $_ -match 'estado:\s*\*{0,2}\s*RESPONDIDO' }).Count
    Fech    = @($txt -split "`r?`n" | Where-Object { $_ -match 'estado:\s*\*{0,2}\s*FECHADO' }).Count
    Utf8Ok  = ($null -eq (Test-Utf8Strict $Path))
    Mtime   = (Get-Item $Path).LastWriteTime.ToString('dd/MM HH:mm:ss')
  }
}

function Invoke-Canal {
  Write-Section 'CANAL (medido agora)'
  Write-Host ('  ' + $script:Equipe) -ForegroundColor DarkGray
  $linhas = @()
  foreach ($f in $script:Canal) {
    $p = Join-Path $script:Equipe $f
    if (-not (Test-Path -LiteralPath $p)) { Write-Err ('falta ' + $f); continue }
    $linhas += Measure-Arquivo $p
  }
  $linhas | Format-Table -AutoSize Nome, Bytes, Linhas, CR, Abertos, Resp, Fech, Utf8Ok, Mtime | Out-String -Width 200 | Write-Host
  $comCr = @($linhas | Where-Object { $_.CR -gt 0 })
  if ($comCr.Count -gt 0) { Write-Warn2 ('EOL misto (CR presente, o check do DELTA exige LF puro): ' + (($comCr | ForEach-Object { $_.Nome + '=' + $_.CR }) -join ', ')) }
  $ruins = @($linhas | Where-Object { -not $_.Utf8Ok })
  if ($ruins.Count -eq 0) { Write-Ok 'todos os ficheiros do canal sao UTF-8 valido' }
}

# ---------------------------------------------------------------- status
function Invoke-Repos {
  Write-Section 'REPO PAI (mql5)'
  Push-Location $script:Root
  Write-Host ('  branch : ' + (git rev-parse --abbrev-ref HEAD 2>$null))
  Write-Host ('  estado : ' + (git status -sb 2>$null | Select-Object -First 1))
  $dirty = @(git status --porcelain 2>$null)
  Write-Host ('  alterados/nao rastreados : ' + $dirty.Count)
  foreach ($l in ($dirty | Select-Object -First 12)) { Write-Host ('    ' + $l) -ForegroundColor DarkGray }
  Pop-Location

  Write-Section 'REPO ANINHADO (app)'
  $app = Join-Path $script:Root 'Files\XAU_AI_PRO'
  if (Test-Path -LiteralPath (Join-Path $app '.git')) {
    Push-Location $app
    Write-Host ('  branch : ' + (git rev-parse --abbrev-ref HEAD 2>$null))
    Write-Host ('  estado : ' + (git status -sb 2>$null | Select-Object -First 1))
    $d2 = @(git status --porcelain 2>$null)
    Write-Host ('  alterados/nao rastreados : ' + $d2.Count)
    foreach ($l in ($d2 | Select-Object -First 12)) { Write-Host ('    ' + $l) -ForegroundColor DarkGray }
    Pop-Location
  } else { Write-Warn2 'repo aninhado nao encontrado' }
}

function Invoke-Status {
  Write-Section 'EA'
  $vm = Join-Path $script:Root 'Experts\XAU_AI_PRO\Enterprise\VersionManager.mqh'
  if (Test-Path -LiteralPath $vm) {
    $m = Select-String -Path $vm -Pattern '#define\s+EA_VERSION_STRING\s+"([^"]+)"' | Select-Object -First 1
    if ($m) { Write-Host ('  versao no fonte : ' + $m.Matches[0].Groups[1].Value) }
  }
  $ex5 = Join-Path $script:Root 'Experts\XAU_AI_PRO\XAU_AI_PRO.ex5'
  if (Test-Path -LiteralPath $ex5) {
    $f = Get-Item $ex5
    Write-Host ('  .ex5 : ' + $f.Length + ' B | ' + $f.LastWriteTime.ToString('dd/MM HH:mm:ss'))
  } else { Write-Warn2 '.ex5 ausente' }
  Invoke-Repos
}

# ---------------------------------------------------------------- dono
function Invoke-Dono {
  Write-Section 'DECISOES QUE ESPERAM O DONO'
  $abertas = @(Get-Decisoes | Where-Object { $_.Estado -match 'ABERTA|PROPOSTA' })
  if ($abertas.Count -eq 0) { Write-Ok 'nenhuma decisao ABERTA/PROPOSTA' }
  foreach ($d in $abertas) {
    $e = $d.Estado; if ($e.Length -gt 70) { $e = $e.Substring(0, 70) + '...' }
    Write-Host ('  ' + $d.Id + '  ' + $d.Assunto) -ForegroundColor White
    Write-Host ('        ' + $e) -ForegroundColor DarkGray
  }

  Write-Section 'PEDIDOS ABERTOS DIRIGIDOS AO DONO'
  $achou = $false
  foreach ($k in @('ALFA','DELTA','CMD')) {
    $txt = Read-Utf8 (Join-Path $script:Equipe $script:Inbox[$k])
    if (-not $txt) { continue }
    foreach ($l in ($txt -split "`r?`n")) {
      if ($l -match '->\s*DONO' -and $l -match 'estado:\s*\*{0,2}\s*ABERTO') {
        $achou = $true
        $t = $l.Trim(); if ($t.Length -gt 150) { $t = $t.Substring(0, 150) + '...' }
        Write-Host ('  [' + $k + '] ' + $t) -ForegroundColor White
      }
    }
  }
  if (-not $achou) { Write-Ok 'nenhum pedido ABERTO dirigido ao dono' }

  Write-Section 'FILA DO DONO (Q-0NN)'
  $pd = Join-Path $script:Equipe $script:Inbox['DONO']
  if (Test-Path -LiteralPath $pd) {
    $txt = Read-Utf8 $pd
    $itens = @(); $atual = $null
    foreach ($l in ($txt -split "`r?`n")) {
      if ($l -match '^##\s+(Q-[0-9]{3})\s*[|\-]\s*(.+)$') {
        if ($atual) { $itens += $atual }
        $atual = [pscustomobject]@{ Id = $Matches[1]; Assunto = $Matches[2].Trim(); Estado = '' }
        continue
      }
      if ($atual -and $l -match 'estado:\s*\*{0,2}\s*(ABERTO|FECHADO|RESPONDIDO|RESOLVIDO)') {
        if (-not $atual.Estado) { $atual.Estado = $Matches[1] }
      }
    }
    if ($atual) { $itens += $atual }
    $abertos = @($itens | Where-Object { $_.Estado -eq '' -or $_.Estado -eq 'ABERTO' })
    if ($abertos.Count -eq 0) { Write-Ok 'nada aberto na fila do dono' }
    else { Write-Host ('  abertos: ' + $abertos.Count + ' de ' + $itens.Count + ' itens') -ForegroundColor DarkGray }
    foreach ($q in $abertos) {
      Write-Host ('  ' + $q.Id + '  ' + $q.Assunto) -ForegroundColor White
    }
  } else { Write-Warn2 'fila do dono ausente (INBOX_DONO.md)' }
}

# ---------------------------------------------------------------- inbox
function Invoke-Inbox {
  if ($Agente -eq 'DONO') { Invoke-Dono; return }
  $p = Join-Path $script:Equipe $script:Inbox[$Agente]
  Write-Section ('INBOX ' + $Agente + ' (' + $script:Inbox[$Agente] + ')')
  if (-not (Test-Path -LiteralPath $p)) { Write-Err 'ficheiro nao existe'; return }
  $txt = Read-Utf8 $p
  $abertos = @(Get-Abertos $txt)
  if ($abertos.Count -eq 0) { Write-Ok 'nenhum pedido aberto'; return }
  foreach ($l in $abertos) {
    $t = $l.Trim(); if ($t.Length -gt 170) { $t = $t.Substring(0, 170) + '...' }
    Write-Host ('  ' + $t) -ForegroundColor White
  }
  Write-Host ('  abertos: ' + $abertos.Count) -ForegroundColor DarkGray
}

# ---------------------------------------------------------------- verify
function Invoke-Verify {
  Write-Section 'INTEGRIDADE DO CANAL'
  $faltam = @($script:Canal | Where-Object { -not (Test-Path -LiteralPath (Join-Path $script:Equipe $_)) })
  if ($faltam.Count -eq 0) { Write-Ok 'todos os ficheiros obrigatorios existem' }
  else { Write-Err ('faltam: ' + ($faltam -join ', ')) }

  foreach ($f in $script:Canal) {
    $p = Join-Path $script:Equipe $f
    if (-not (Test-Path -LiteralPath $p)) { continue }
    $bad = Test-Utf8Strict $p
    if ($null -ne $bad) {
      $extra = ''
      if ($bad.ContainsKey('Antes')) { $extra = (' | anterior=0x' + $bad.Antes.ToString('X2')) }
      Write-Err ($f + ': UTF-8 invalido no byte ' + $bad.Offset + ' (0x' + $bad.Byte.ToString('X2') + ')' + $extra)
    }
  }

  # Artefactos de substituicao: "CMD (CMD)", "(ALFA) (ALFA)", etc.
  $ruins = 0
  foreach ($f in $script:Canal) {
    $p = Join-Path $script:Equipe $f
    if (-not (Test-Path -LiteralPath $p)) { continue }
    $txt = Read-Utf8 $p
    if (-not $txt) { continue }
    foreach ($m in [regex]::Matches($txt, '(ALFA|DELTA|CMD|DONO)\s*\((ALFA|DELTA|CMD|DONO)\)')) {
      if ($m.Groups[1].Value -ne $m.Groups[2].Value) { continue }
      # Se o casamento esta entre backticks, o canal esta a DOCUMENTAR o defeito
      # (ex.: "ficou `CMD (CMD)`"), nao a exibi-lo. Contar backticks ate a linha.
      $inicioLinha = $txt.LastIndexOf("`n", [Math]::Max(0, $m.Index - 1)) + 1
      $antes = $txt.Substring($inicioLinha, $m.Index - $inicioLinha)
      if ((($antes.ToCharArray() | Where-Object { $_ -eq '`' }).Count % 2) -eq 1) { continue }
      $s = [Math]::Max(0, $m.Index - 14)
      $ctx = $txt.Substring($s, [Math]::Min(40, $txt.Length - $s)).Replace("`r", ' ').Replace("`n", ' ')
      Write-Err ($f + ': artefacto de substituicao -> ' + $ctx.Trim()); $ruins++
    }
    if ($txt -match '_LEGADOEQUIPE') { Write-Warn2 ($f + ': nome do legado colado -> ' + $Matches[0]) }
  }
  if ($ruins -eq 0) { Write-Ok 'sem artefactos de substituicao' }

  $p1 = Join-Path $script:Root 'Experts\XAU_AI_PRO\AGENTE_1.md'
  $p3 = Join-Path $script:Root 'AGENTE_3.md'
  foreach ($ptr in @($p1, $p3)) {
    if (Test-Path -LiteralPath $ptr) {
      $t = Read-Utf8 $ptr
      if ($t -match 'EQUIPE[\\/]AGENTE_[13]\.md') { Write-Ok ((Split-Path $ptr -Leaf) + ' aponta para EQUIPE') }
      else { Write-Warn2 ((Split-Path $ptr -Leaf) + ' existe mas nao aponta para EQUIPE') }
    }
  }
}

# ---------------------------------------------------------------- mirror
function Invoke-Mirror {
  Write-Section 'ESPELHO (EA -> Files/XAU_AI_PRO/MQL5)'
  $a = Join-Path $script:Root 'Experts\XAU_AI_PRO'
  $b = Join-Path $script:Root 'Files\XAU_AI_PRO\MQL5\Experts\XAU_AI_PRO'
  if (-not (Test-Path -LiteralPath $b)) { Write-Err ('espelho ausente: ' + $b); return }
  $tot = 0; $bad = @()
  Get-ChildItem $a -Recurse -File -Include *.mq5, *.mqh -ErrorAction SilentlyContinue | ForEach-Object {
    $rel = $_.FullName.Substring($a.Length).TrimStart('\')
    $dst = Join-Path $b $rel
    $tot++
    if (-not (Test-Path -LiteralPath $dst)) { $bad += ('FALTA ' + $rel) }
    elseif ((Get-FileHash -LiteralPath $_.FullName).Hash -ne (Get-FileHash -LiteralPath $dst).Hash) { $bad += ('DIFF  ' + $rel) }
  }
  Write-Host ('  fontes: ' + $tot + ' | divergentes: ' + $bad.Count)
  if ($bad.Count -eq 0) { Write-Ok 'espelho identico ao EA' }
  else {
    $bad | Select-Object -First 25 | ForEach-Object { Write-Warn2 $_ }
    if ($bad.Count -gt 25) { Write-Warn2 ('... e mais ' + ($bad.Count - 25)) }
    Write-Err ('espelho divergente em ' + $bad.Count + ' ficheiro(s) - o espelho nao e fonte: copiar EA -> espelho')
  }
}

# ---------------------------------------------------------------- main
if (-not (Test-Path -LiteralPath $script:Equipe)) { throw ('canal nao encontrado: ' + $script:Equipe) }

switch ($Action) {
  'status' { Invoke-Status; Invoke-Canal }
  'canal'  { Invoke-Canal }
  'dono'   { Invoke-Dono }
  'inbox'  { Invoke-Inbox }
  'verify' { Invoke-Verify }
  'mirror' { Invoke-Mirror }
  'repos'  { Invoke-Repos }
  'all'    { Invoke-Status; Invoke-Canal; Invoke-Dono; Invoke-Verify; Invoke-Mirror }
}

Write-Host ''
if ($script:Failures -gt 0) {
  Write-Host ('RESULTADO: ' + $script:Failures + ' problema(s)') -ForegroundColor Red
  exit 1
}
Write-Host 'RESULTADO: ok' -ForegroundColor Green
exit 0
