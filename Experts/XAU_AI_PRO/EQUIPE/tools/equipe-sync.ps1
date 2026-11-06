# equipe-sync.ps1 - modulo de sincronizacao do canal EQUIPE/ (ALFA, DELTA, CMD, DONO)
#
# AUTORIZADO pelo dono em 05/11/2026 22:23 ("autorizacao total para os 3" +
# "crie e autorize scripts ou modulos de sincronizacao entre 3 agentes e o
# quarto eu o DONO"). Registro: EQUIPE/DECISOES.md D-015.
#
# O que faz: mede o canal, verifica integridade, serializa escritas com lock,
# e produz um retrato unico (SYNC_STATUS.md + status.json) que o DONO le sem
# precisar de abrir 10 ficheiros.
#
# NAO faz e nunca fara: commit, push, compile, reattach, ordem, alteracao de
# parametro de risco. So toca em EQUIPE/*.md e EQUIPE/_SYNC/.
#
# USO (a partir de MQL5\Experts\XAU_AI_PRO\EQUIPE, ou com -Root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 status
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 check
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 dono
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 quem
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 pedidos -De DELTA
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 snapshot
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 aviso -Para ALFA -Assunto "..." -Corpo "texto ASCII"
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 aviso -Para CMD -Assunto "..." -CorpoArquivo corpo.txt
#     (corpo com acento/§ TEM de ir por -CorpoArquivo: o cmd converte-o para 1 byte e estraga o UTF-8)
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 append -Arquivo QUADRO_ESTADO.md -Corpo "texto"
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 lock   -De DELTA -Motivo "editar QUADRO"
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\equipe-sync.ps1 unlock -De DELTA
#
# REGRA DE OURO desta ferramenta: escrita byte-a-byte com ISO-8859-1 (28591),
# que e 1:1 byte<->char e por isso preserva BOM e bytes UTF-8 quebrados. Nunca
# reescreve o ficheiro inteiro: so anexa, ou substitui uma ancora contada.

param(
  [Parameter(Position=0)][string]$Cmd = 'status',
  [string]$Root = '',
  [string]$Arquivo = '',
  [string]$Corpo = '',
  [string]$CorpoArquivo = '',
  [string]$Antigo = '',
  [string]$Para = '',
  [string]$Assunto = '',
  [string]$De = '',
  [string]$Motivo = '',
  [string]$Id = '',
  [string]$Precisa = '',
  [string]$Prazo = '',
  [int]$MaxLinhas = 40
)

$ErrorActionPreference = 'Stop'
$enc = [System.Text.Encoding]::GetEncoding(28591)
$encUtf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
if($CorpoArquivo -ne ''){
  if(-not (Test-Path -LiteralPath $CorpoArquivo)){ Write-Output ('ERRO: CorpoArquivo nao existe :: ' + $CorpoArquivo); exit 1 }
  $Corpo = $enc.GetString([System.IO.File]::ReadAllBytes($CorpoArquivo))
}

if($Root -eq ''){
  if($PSScriptRoot -ne ''){ $Root = Split-Path $PSScriptRoot -Parent }
  else { $Root = (Get-Location).Path }
}
if(-not (Test-Path -LiteralPath $Root)){ Write-Output ('ERRO: raiz nao existe :: ' + $Root); exit 1 }
$Root = (Resolve-Path -LiteralPath $Root).Path
$SyncDir = Join-Path $Root '_SYNC'
$BackupDir = Join-Path $SyncDir 'backup'
# LOCK unico do canal: LOCK.md - o MESMO ficheiro que o tools\sync-agent.ps1
# usa. O antigo _SYNC\LOCK deixa de ser escrito: dois locks era o defeito
# medido (o ALFA tomava um, o DELTA tomava outro, nenhum via o do outro).
$LockFile = Join-Path $Root 'LOCK.md'
# Fila de pedidos de ajuda (D-021): um pedido tem ID `R-nnn`, dono, prazo e
# estado. Sem ID o pedido nao se fecha - foi o que se mediu as 22:44: 9 blocos
# ABERTOS em tres caixas e nenhum fechavel.
$PedidosFile = Join-Path $Root 'PEDIDOS.md'

function Get-CanalArquivos {
  Get-ChildItem -LiteralPath $Root -Filter '*.md' -File | Sort-Object Name
}

function Get-AgenteAtual {
  if($De -ne ''){ return $De.ToUpper() }
  return 'DESCONHECIDO'
}

function Get-HoraLocal { (Get-Date).ToString('dd/MM/yyyy HH:mm') }
function Test-CorpoSeguro {
  if($CorpoArquivo -ne ''){ return }
  if($Corpo -match '[^\x00-\x7F]'){
    Write-Output 'RECUSADO: corpo com caracteres nao-ASCII passado por linha de comando (o cmd converte-o para 1 byte e estraga o UTF-8 do canal) :: escreve o corpo num ficheiro UTF-8 e usa -CorpoArquivo'
    exit 1
  }
}
function Get-HoraCurta { (Get-Date).ToString('dd/MM HH:mm') }

function Get-LockMd {
  # Le LOCK.md no formato do sync-agent.ps1 (campos em negrito + ESTADO +
  # Expira). Devolve $null quando esta livre ou vencido; senao "dono | motivo
  # | expira HH:mm".
  if(-not (Test-Path -LiteralPath $LockFile)){ return $null }
  $txt = $enc.GetString([System.IO.File]::ReadAllBytes($LockFile)) -replace '\*', ''
  if($txt -notmatch 'ESTADO:\s*OCUPADO'){ return $null }
  $dono = ''
  $motivo = ''
  $m = [regex]::Match($txt, '(?m)^-\s*Dono:\s*(.+)$')
  if($m.Success){ $dono = $m.Groups[1].Value.Trim() }
  $m = [regex]::Match($txt, '(?m)^-\s*Motivo:\s*(.+)$')
  if($m.Success){ $motivo = $m.Groups[1].Value.Trim() }
  $exp = $null
  $m = [regex]::Match($txt, '(?m)^-\s*Expira:\s*(.+)$')
  if($m.Success){ try { $exp = [datetime]::ParseExact($m.Groups[1].Value.Trim(), 'dd/MM/yyyy HH:mm:ss', $null) } catch { $exp = $null } }
  if($exp -ne $null -and $exp -le (Get-Date)){ return $null }
  $quando = ''
  if($exp -ne $null){ $quando = ' | expira ' + $exp.ToString('dd/MM HH:mm') }
  return ($dono + ' | ' + $motivo + $quando)
}

function Test-Lock { return (Get-LockMd) }

function Set-Lock {
  $quem = Get-AgenteAtual
  if($quem -eq 'DESCONHECIDO'){ Write-Output 'RECUSADO: lock exige -De ALFA|DELTA|CMD|DONO'; exit 1 }
  if($Motivo -eq ''){ Write-Output 'RECUSADO: lock exige -Motivo (compile, reattach, edit)'; exit 1 }
  $tem = Get-LockMd
  if($tem -ne $null -and -not $tem.StartsWith($quem)){
    Write-Output ('RECUSADO: LOCK.md ocupado :: ' + $tem + ' :: so o dono liberta')
    exit 2
  }
  $ttl = 15
  $agora = (Get-Date).ToString('dd/MM/yyyy HH:mm:ss')
  $exp = (Get-Date).AddMinutes($ttl).ToString('dd/MM/yyyy HH:mm:ss')
  $txt = '# LOCK DE OPERACAO - EQUIPE' + "`n`n" +
         '- **Dono:** ' + $quem + "`n" +
         '- **Motivo:** ' + $Motivo + "`n" +
         '- **Tomado:** ' + $agora + "`n" +
         '- **Expira:** ' + $exp + "`n" +
         '- **TTL:** ' + $ttl + " min`n`n" +
         '- **ESTADO:** OCUPADO' + "`n`n" +
         '> O `.ex5` carrega o estado de TODOS os fontes: 1 compile e 1 reattach' + "`n" +
         '> por vez. Liberte ao terminar: `tools\equipe-sync.ps1 unlock -De ' + $quem + '`' + "`n"
  if(Test-Path -LiteralPath $LockFile){ [void](Backup-Arquivo $LockFile) }
  [System.IO.File]::WriteAllBytes($LockFile, $enc.GetBytes($txt))
  Write-Output ('OK lock :: ' + $quem + ' | ' + $Motivo + ' | expira ' + $exp)
}

function Remove-Lock {
  $quem = Get-AgenteAtual
  if($quem -eq 'DESCONHECIDO'){ Write-Output 'RECUSADO: unlock exige -De ALFA|DELTA|CMD|DONO'; exit 1 }
  $dono = Get-LockMd
  if($dono -ne $null -and -not $dono.StartsWith($quem)){
    Write-Output ('RECUSADO: o LOCK.md e de outro agente :: ' + $dono + ' :: so ele liberta')
    exit 3
  }
  $txt = '# LOCK DE OPERACAO - EQUIPE' + "`n`n" +
         '- **ESTADO:** LIVRE' + "`n" +
         '- **Ultimo dono:** ' + $quem + "`n" +
         '- **Libertado:** ' + (Get-Date).ToString('dd/MM/yyyy HH:mm:ss') + "`n"
  if(Test-Path -LiteralPath $LockFile){ [void](Backup-Arquivo $LockFile) }
  [System.IO.File]::WriteAllBytes($LockFile, $enc.GetBytes($txt))
  Write-Output ('OK unlock :: ' + $quem + ' | ' + (Get-HoraLocal))
}

function Test-LockLivre {
  $d = Test-Lock
  if($d -ne $null -and -not $d.StartsWith((Get-AgenteAtual))){ Write-Output ('RECUSADO: canal bloqueado :: ' + $d + ' :: quem escreve tem de ser o dono do lock'); exit 2 }
}

function Backup-Arquivo([string]$Path){
  if(-not (Test-Path -LiteralPath $BackupDir)){ New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
  $nome = [System.IO.Path]::GetFileNameWithoutExtension($Path)
  $dest = Join-Path $BackupDir ($nome + '.' + (Get-Date).ToString('yyyyMMdd_HHmmss') + '.bak')
  [System.IO.File]::WriteAllBytes($dest, [System.IO.File]::ReadAllBytes($Path))
  return $dest
}

function Add-BlocoBruto([string]$Path, [string]$texto){
  $t = $enc.GetString([System.IO.File]::ReadAllBytes($Path))
  if(-not $t.EndsWith("`n")){ $t = $t + "`n" }
  $t = $t + $texto
  if(-not $t.EndsWith("`n")){ $t = $t + "`n" }
  [System.IO.File]::WriteAllBytes($Path, $enc.GetBytes($t))
  return (Get-Item -LiteralPath $Path).Length
}

function Replace-Ancora([string]$Path, [string]$velho, [string]$novo){
  $t = $enc.GetString([System.IO.File]::ReadAllBytes($Path))
  $c = [regex]::Matches($t, [regex]::Escape($velho)).Count
  if($c -ne 1){
    Write-Output ('NAO GRAVADO ' + [System.IO.Path]::GetFileName($Path) + ' :: count=' + $c)
    return $false
  }
  $t = $t.Replace($velho, $novo)
  [System.IO.File]::WriteAllBytes($Path, $enc.GetBytes($t))
  Write-Output ('OK ' + [System.IO.Path]::GetFileName($Path) + ' :: ' + (Get-Item -LiteralPath $Path).Length + ' bytes')
  return $true
}

# ---------------- fila de pedidos R-nnn (D-021) ----------------

function Initialize-Pedidos {
  if(Test-Path -LiteralPath $PedidosFile){ return }
  $cab = "# PEDIDOS DE AJUDA - fila R-nnn`n`n"
  $cab = $cab + "Registo unico dos pedidos entre agentes (ALFA, DELTA, CMD, DONO).`n"
  $cab = $cab + "Escrito por tools\equipe-sync.ps1. Nao editar a mao: uma linha por pedido.`n`n"
  $cab = $cab + "Estados: PEDIDO | ACEITE | FEITO | FECHADO | DEVOLVIDO | BLOQUEADO.`n`n"
  $cab = $cab + "| ID | De -> Para | Assunto | Precisa | Prazo | Estado | Hora |`n"
  $cab = $cab + "|---|---|---|---|---|---|---|`n"
  [System.IO.File]::WriteAllBytes($PedidosFile, $enc.GetBytes($cab))
}

function Get-PedidoProximoId {
  Initialize-Pedidos
  $t = $enc.GetString([System.IO.File]::ReadAllBytes($PedidosFile))
  $max = 0
  foreach($m in [regex]::Matches($t, '\|\s*R-(\d{3})\s*\|')){
    $n = [int]$m.Groups[1].Value
    if($n -gt $max){ $max = $n }
  }
  return ('R-{0:000}' -f ($max + 1))
}

function Get-PedidoLinha([string]$pedidoId){
  Initialize-Pedidos
  $t = $enc.GetString([System.IO.File]::ReadAllBytes($PedidosFile))
  $ms = [regex]::Matches($t, '(?m)^\|\s*' + [regex]::Escape($pedidoId) + '\s*\|.*$')
  if($ms.Count -eq 0){ return '' }
  return $ms[0].Value.TrimEnd()
}

function Add-PedidoLinha([string]$linha){
  Initialize-Pedidos
  $bkp = Backup-Arquivo $PedidosFile
  $n = Add-BlocoBruto $PedidosFile ($linha + "`n")
  Write-Output ('OK pedido :: ' + $linha)
  Write-Output ('   bytes=' + $n + ' :: backup=' + [System.IO.Path]::GetFileName($bkp))
}

# Muda estado de um pedido. A linha e substituida inteira, com contagem exacta:
# se a ancora nao aparecer 1 vez, nada e gravado.
function Set-PedidoEstado([string]$pedidoId, [string]$novoEstado, [string]$nota){
  $id = $pedidoId.ToUpper()
  $velha = Get-PedidoLinha $id
  if($velha -eq ''){ Write-Output ('ERRO: pedido inexistente :: ' + $id); exit 1 }
  $c = $velha.Split('|')
  if($c.Count -lt 9){ Write-Output ('ERRO: linha de pedido invalida :: ' + $velha); exit 1 }
  $c[6] = ' ' + $novoEstado + ' '
  $c[7] = ' ' + (Get-HoraCurta) + ' '
  if($nota -ne ''){ $c[3] = ' ' + $c[3].Trim() + ' :: ' + $nota + ' ' }
  $nova = ($c -join '|').TrimEnd()
  $bkp = Backup-Arquivo $PedidosFile
  $t = $enc.GetString([System.IO.File]::ReadAllBytes($PedidosFile))
  $n = ([regex]::Matches($t, [regex]::Escape($velha))).Count
  if($n -ne 1){
    Write-Output ('RECUSADO :: nenhuma gravacao :: ancora do pedido ' + $id + ' aparece ' + $n + ' vez(es)')
    exit 2
  }
  $t = $t.Replace($velha, $nova)
  [System.IO.File]::WriteAllBytes($PedidosFile, $enc.GetBytes($t))
  Write-Output ('OK ' + $id + ' -> ' + $novoEstado + ' :: ' + $nova)
  Write-Output ('   backup=' + [System.IO.Path]::GetFileName($bkp))
}

function Show-FilaPedidos {
  Initialize-Pedidos
  $t = $enc.GetString([System.IO.File]::ReadAllBytes($PedidosFile))
  $linhas = [regex]::Matches($t, '(?m)^\|\s*R-\d{3}\s*\|.*$')
  Write-Output ''
  Write-Output ('===== PEDIDOS.md :: fila R-nnn (' + $linhas.Count + ' pedido(s)) =====')
  if($linhas.Count -eq 0){ Write-Output '  (vazia)' }
  foreach($l in $linhas){ Write-Output ('  ' + $l.Value) }
}

function Get-InboxNome([string]$agente){
  switch($agente.ToUpper()){
    'ALFA'  { return 'INBOX_AGENTE_1.md' }
    'DELTA' { return 'INBOX_AGENTE_2.md' }
    'CMD'   { return 'INBOX_AGENTE_3.md' }
    'DONO'  { return 'INBOX_DONO.md' }
    default { return '' }
  }
}

function Get-Metricas([string]$Path){
  $b = [System.IO.File]::ReadAllBytes($Path)
  $t = $enc.GetString($b)
  $cr = 0
  for($i = 0; $i -lt $b.Length; $i++){ if($b[$i] -eq 13){ $cr++ } }
  $linhas = ([regex]::Matches($t, "`n")).Count
  $aberto = ([regex]::Matches($t, 'estado:\s*\*{0,2}\s*ABERTO\s*(\||$)')).Count
  $fechado = ([regex]::Matches($t, 'estado:\s*\*{0,2}\s*FECHADO\s*(\||$)')).Count
  $resp = ([regex]::Matches($t, 'estado:\s*\*{0,2}\s*RESPONDIDO\s*(\||$)')).Count
  $rodape = ''
  $m = [regex]::Matches($t, 'Ultima alteracao: (.*)')
  if($m.Count -gt 0){ $rodape = $m[$m.Count - 1].Groups[1].Value }
  $utfOk = $true
  try { $null = $encUtf8Strict.GetString($b) } catch { $utfOk = $false }
  $obj = New-Object psobject
  $obj | Add-Member NoteProperty Nome ([System.IO.Path]::GetFileName($Path))
  $obj | Add-Member NoteProperty Bytes $b.Length
  $obj | Add-Member NoteProperty Linhas $linhas
  $obj | Add-Member NoteProperty CR $cr
  $obj | Add-Member NoteProperty Aberto $aberto
  $obj | Add-Member NoteProperty Respondido $resp
  $obj | Add-Member NoteProperty Fechado $fechado
  $obj | Add-Member NoteProperty Rodapes $m.Count
  $obj | Add-Member NoteProperty Rodape $rodape
  $obj | Add-Member NoteProperty Utf8Ok $utfOk
  $obj | Add-Member NoteProperty Hora (Get-Item -LiteralPath $Path).LastWriteTime.ToString('dd/MM HH:mm:ss')
  return $obj
}

# ============================== COMANDOS ==============================

switch($Cmd.ToLower()){

  'status' {
    Write-Output ('CANAL :: ' + $Root)
    Write-Output ('HORA  :: ' + (Get-HoraLocal))
    $lk = Test-Lock
    if($lk -ne $null){ Write-Output ('LOCK  :: ' + $lk) } else { Write-Output 'LOCK  :: livre' }
    Write-Output ''
    $linhas = @()
    foreach($f in Get-CanalArquivos){
      $m = Get-Metricas $f.FullName
      $linhas += ('{0,-22} {1,7} B  {2,4} ln  CR={3,3}  ABERTO={4,2} RESP={5,2} FECH={6,2}  utf8={7}  {8}' -f $m.Nome, $m.Bytes, $m.Linhas, $m.CR, $m.Aberto, $m.Respondido, $m.Fechado, $m.Utf8Ok, $m.Hora)
    }
    $linhas | ForEach-Object { Write-Output $_ }
  }

  'check' {
    $problemas = 0
    foreach($f in Get-CanalArquivos){
      $m = Get-Metricas $f.FullName
      if($m.CR -ne 0){ Write-Output ('FALHA ' + $m.Nome + ' :: CR=' + $m.CR + ' (EOL tem de ser LF puro)'); $problemas++ }
      if(-not $m.Utf8Ok){ Write-Output ('FALHA ' + $m.Nome + ' :: UTF-8 invalido'); $problemas++ }
      if($m.Bytes -eq 0){ Write-Output ('FALHA ' + $m.Nome + ' :: ficheiro vazio'); $problemas++ }
      $t = $enc.GetString([System.IO.File]::ReadAllBytes($f.FullName))
      $ids = [regex]::Matches($t, '(?m)^#{2,3}\s+(D-\d{3}|P-\d{3}|Q-\d{3})')
      $grupos = @{}
      foreach($i in $ids){
        $k = $i.Groups[1].Value
        if($grupos.ContainsKey($k)){ $grupos[$k] = $grupos[$k] + 1 } else { $grupos[$k] = 1 }
      }
      foreach($k in ($grupos.Keys | Sort-Object)){
        if($grupos[$k] -gt 1){ Write-Output ('FALHA ' + $m.Nome + ' :: ID duplicado ' + $k + ' x' + $grupos[$k]); $problemas++ }
      }
    }
    $obrig = @('PROTOCOLO.md','QUADRO_ESTADO.md','DECISOES.md','INBOX_AGENTE_1.md','INBOX_AGENTE_2.md','INBOX_AGENTE_3.md','INBOX_DONO.md')
    foreach($o in $obrig){
      if(-not (Test-Path -LiteralPath (Join-Path $Root $o))){ Write-Output ('FALHA canal :: falta ' + $o); $problemas++ }
    }
    if($problemas -eq 0){ Write-Output 'CANAL INTEGRO :: 0 problemas' } else { Write-Output ('CANAL COM ' + $problemas + ' PROBLEMAS') }
  }

  'dono' {
    $p = Join-Path $Root 'INBOX_DONO.md'
    if(-not (Test-Path -LiteralPath $p)){ Write-Output 'ERRO: INBOX_DONO.md nao existe'; exit 1 }
    $t = $enc.GetString([System.IO.File]::ReadAllBytes($p))
    $blocos = [regex]::Split($t, '(?m)^(?=#{2,3}\s+)')
    Write-Output ('FILA DO DONO :: ' + $Root)
    Write-Output ''
    $n = 0
    foreach($b in $blocos){
      if($b -notmatch '(?m)^#{2,3}\s+Q-\d{3}'){ continue }
      if($b -notmatch 'estado:\s*\*{0,2}\s*ABERTO\s*(\||$)'){ continue }
      $n++
      $linhas = @($b -split "`n")
      Write-Output $linhas[0]
      for($i = 1; $i -lt $linhas.Count -and $i -le $MaxLinhas; $i++){
        $l = $linhas[$i]
        if($l.Trim() -ne ''){ Write-Output ('   ' + $l.Trim()) }
      }
      Write-Output ''
    }
    Write-Output ('TOTAL ABERTO PARA O DONO :: ' + $n)
  }

  'quem' {
    Write-Output 'ITENS ABERTOS POR DESTINO (procura "estado: ABERTO" e o nome do agente)'
    Write-Output ''
    $alvos = @('ALFA','DELTA','CMD','DONO')
    foreach($a in $alvos){
      $total = 0
      foreach($f in Get-CanalArquivos){
        if($f.Name -eq 'PROTOCOLO.md'){ continue }
        $t = $enc.GetString([System.IO.File]::ReadAllBytes($f.FullName))
        $re = '(?m)^.*->\s*' + $a + '\b.*$'
        foreach($l in [regex]::Matches($t, $re)){
          $idx = $l.Index
          $fim = $t.IndexOf("`n`n", $idx)
          if($fim -lt 0){ $fim = [Math]::Min($idx + 1200, $t.Length) }
          $trecho = $t.Substring($idx, [Math]::Min($fim - $idx, 1200))
          if($trecho -match 'estado:\s*\*{0,2}\s*ABERTO\s*(\||$)'){ $total++ }
        }
      }
      Write-Output ('{0,-6} :: {1,3} item(ns) ABERTO' -f $a, $total)
    }
  }

  'snapshot' {
    if(-not (Test-Path -LiteralPath $SyncDir)){ New-Item -ItemType Directory -Path $SyncDir -Force | Out-Null }
    $ms = @()
    foreach($f in Get-CanalArquivos){ $ms += Get-Metricas $f.FullName }
    $lk = Test-Lock

    $md = New-Object System.Text.StringBuilder
    [void]$md.AppendLine('# SYNC STATUS - retrato medido do canal EQUIPE/')
    [void]$md.AppendLine('')
    [void]$md.AppendLine('Gerado por `EQUIPE/tools/equipe-sync.ps1 snapshot` as **' + (Get-HoraLocal) + '**.')
    [void]$md.AppendLine('Este ficheiro e **gerado** - nao escrever a mao. Fonte: os `.md` de `EQUIPE/`.')
    [void]$md.AppendLine('')
    if($lk -ne $null){ [void]$md.AppendLine('**LOCK activo:** ' + $lk) } else { [void]$md.AppendLine('**LOCK:** livre') }
    [void]$md.AppendLine('')
    [void]$md.AppendLine('## 1. Ficheiros do canal')
    [void]$md.AppendLine('')
    [void]$md.AppendLine('| Arquivo | Bytes | Linhas | CR | ABERTO | RESP | FECH | UTF-8 | Ultima escrita |')
    [void]$md.AppendLine('|---|---|---|---|---|---|---|---|---|')
    foreach($m in $ms){
      [void]$md.AppendLine('| `' + $m.Nome + '` | ' + $m.Bytes + ' | ' + $m.Linhas + ' | ' + $m.CR + ' | ' + $m.Aberto + ' | ' + $m.Respondido + ' | ' + $m.Fechado + ' | ' + $m.Utf8Ok + ' | ' + $m.Hora + ' |')
    }
    [void]$md.AppendLine('')
    [void]$md.AppendLine('## 2. Ultimo rodape de cada ficheiro')
    [void]$md.AppendLine('')
    foreach($m in $ms){ [void]$md.AppendLine('- `' + $m.Nome + '` (' + $m.Rodapes + '): ' + $m.Rodape) }
    [void]$md.AppendLine('')
    [void]$md.AppendLine('## 3. Como ler isto')
    [void]$md.AppendLine('')
    [void]$md.AppendLine('- **ABERTO** conta linhas de estado, nao decisoes pendentes. Serve para ver')
    [void]$md.AppendLine('  para onde o canal esta a empurrar o trabalho, nao para fechar nada.')
    [void]$md.AppendLine('- **CR tem de ser 0** em todos: os `.md` do canal sao LF puro.')
    [void]$md.AppendLine('- **Rodapes > 1** significa que varias escritas coexistram no mesmo ficheiro -')
    [void]$md.AppendLine('  e normal nos `append-only` (`PENDENCIAS`, `PROGRESS`, `HANDOFF`) e no')
    [void]$md.AppendLine('  `DECISOES`; nao e normal numa inbox.')
    [void]$md.AppendLine('- A fila do DONO e `INBOX_DONO.md`; para a listar: `equipe-sync.ps1 dono`.')
    $mdPath = Join-Path $SyncDir 'SYNC_STATUS.md'
    [System.IO.File]::WriteAllBytes($mdPath, $enc.GetBytes($md.ToString()))

    $jsonObj = New-Object psobject
    $jsonObj | Add-Member NoteProperty gerado (Get-HoraLocal)
    $jsonObj | Add-Member NoteProperty raiz $Root
    if($lk -ne $null){ $jsonObj | Add-Member NoteProperty lock $lk } else { $jsonObj | Add-Member NoteProperty lock 'livre' }
    $jsonObj | Add-Member NoteProperty arquivos $ms
    $jsonPath = Join-Path $SyncDir 'status.json'
    $json = ConvertTo-Json -InputObject $jsonObj -Depth 6
    [System.IO.File]::WriteAllBytes($jsonPath, $enc.GetBytes($json))

    Write-Output ('OK SYNC_STATUS.md :: ' + (Get-Item -LiteralPath $mdPath).Length + ' bytes')
    Write-Output ('OK status.json    :: ' + (Get-Item -LiteralPath $jsonPath).Length + ' bytes')
  }

  'append' {
    Test-CorpoSeguro
    if($Arquivo -eq '' -or $Corpo -eq ''){ Write-Output 'RECUSADO: append exige -Arquivo <nome.md> e -Corpo "<texto>"'; exit 1 }
    $p = Join-Path $Root $Arquivo
    if(-not (Test-Path -LiteralPath $p)){ Write-Output ('RECUSADO: nao existe :: ' + $Arquivo); exit 1 }
    Test-LockLivre
    $bkp = Backup-Arquivo $p
    $n = Add-BlocoBruto $p $Corpo
    Write-Output ('OK append ' + $Arquivo + ' :: ' + $n + ' bytes :: backup=' + [System.IO.Path]::GetFileName($bkp))
  }

  'substituir' {
    Test-CorpoSeguro
    if($Arquivo -eq '' -or $Antigo -eq '' -or $Corpo -eq ''){ Write-Output 'RECUSADO: substituir exige -Arquivo, -Antigo e -Corpo'; exit 1 }
    $p = Join-Path $Root $Arquivo
    if(-not (Test-Path -LiteralPath $p)){ Write-Output ('RECUSADO: nao existe :: ' + $Arquivo); exit 1 }
    Test-LockLivre
    $bkp = Backup-Arquivo $p
    $ok = Replace-Ancora $p $Antigo $Corpo
    if($ok){ Write-Output ('backup=' + [System.IO.Path]::GetFileName($bkp)) }
  }

  'aviso' {
    Test-CorpoSeguro
    if($Para -eq '' -or $Corpo -eq ''){ Write-Output 'RECUSADO: aviso exige -Para ALFA|DELTA|CMD|DONO e -Corpo "<texto>"'; exit 1 }
    $inbox = Get-InboxNome $Para
    if($inbox -eq ''){ Write-Output ('RECUSADO: destino invalido :: ' + $Para); exit 1 }
    $p = Join-Path $Root $inbox
    if(-not (Test-Path -LiteralPath $p)){ Write-Output ('RECUSADO: nao existe :: ' + $inbox); exit 1 }
    Test-LockLivre
    $quem = Get-AgenteAtual
    if($Assunto -eq ''){ $Assunto = 'aviso' }
    $bloco = "`n---`n`n## " + (Get-HoraLocal) + " - " + $quem + " -> " + $Para.ToUpper() + ": " + $Assunto + "`n`n" + $Corpo + "`n`n- **estado:** ABERTO/RESPONDIDO/FECHADO | " + (Get-HoraCurta) + " | " + $quem + "`n"
    $bkp = Backup-Arquivo $p
    $n = Add-BlocoBruto $p $bloco
    Write-Output ('OK aviso -> ' + $inbox + ' :: ' + $n + ' bytes :: de=' + $quem + ' :: backup=' + [System.IO.Path]::GetFileName($bkp))
  }

  'eol' {
    # Normaliza CRLF -> LF. A regra do canal e LF puro; o texto nao muda.
    $alvos = @()
    if($Arquivo -ne ''){ $alvos = @((Join-Path $Root $Arquivo)) }
    else {
      $alvos = @(Get-CanalArquivos | ForEach-Object { $_.FullName })
      if(Test-Path -LiteralPath $LockFile){ $alvos += $LockFile }
    }
    $n = 0
    foreach($p in $alvos){
      if(-not (Test-Path -LiteralPath $p)){ continue }
      $b = [System.IO.File]::ReadAllBytes($p)
      $cr = 0
      for($i = 0; $i -lt $b.Length; $i++){ if($b[$i] -eq 13){ $cr++ } }
      if($cr -eq 0){ continue }
      $txt = $enc.GetString($b) -replace "`r`n", "`n"
      $txt = $txt -replace "`r", "`n"
      $bkp = Backup-Arquivo $p
      [System.IO.File]::WriteAllBytes($p, $enc.GetBytes($txt))
      Write-Output ('OK eol :: ' + [System.IO.Path]::GetFileName($p) + ' :: CR ' + $cr + ' -> 0 :: backup=' + [System.IO.Path]::GetFileName($bkp))
      $n++
    }
    if($n -eq 0){ Write-Output 'OK eol :: nada a corrigir, todos LF' } else { Write-Output ('OK eol :: ' + $n + ' ficheiro(s) normalizado(s)') }
  }

  'pedidos' {
    # Leitor de pedidos de ajuda (D-020 + D-021). O protocolo dizia o formato
    # mas nao havia como responder a pergunta "o que e que me pediram e o que
    # esta aberto": os pedidos ficam em blocos `## <hora> - X -> Y | assunto`
    # dentro da caixa do destinatario. Este comando le as 4 caixas.
    # Sem -De mostra o canal inteiro; com -De ALFA|DELTA|CMD|DONO filtra.
    $alvo = $De.ToUpper()
    if($alvo -ne '' -and (Get-InboxNome $alvo) -eq ''){ Write-Output ('ERRO: agente invalido :: ' + $De); exit 1 }
    $total = 0
    $abertos = 0
    foreach($ag in @('ALFA','DELTA','CMD','DONO')){
      if($alvo -ne '' -and $ag -ne $alvo){ continue }
      $inbox = Join-Path $Root (Get-InboxNome $ag)
      if(-not (Test-Path -LiteralPath $inbox)){ continue }
      $linhas = [System.IO.File]::ReadAllLines($inbox, [System.Text.Encoding]::UTF8)
      $achou = $false
      for($i = 0; $i -lt $linhas.Count; $i++){
        $m = [regex]::Match($linhas[$i], '^##\s+(?:.*?)(ALFA|DELTA|CMD|DONO)\s*->\s*(ALFA|DELTA|CMD|DONO)\s*[:|]\s*(.+)$')
        if(-not $m.Success){ continue }
        $de = $m.Groups[1].Value
        $para = $m.Groups[2].Value
        if($para -ne $ag){ continue }
        $assunto = $m.Groups[3].Value.Trim()
        $estado = 'SEM-ESTADO'
        $arq = ''
        for($j = $i + 1; $j -lt [Math]::Min($i + 14, $linhas.Count); $j++){
          if($linhas[$j] -match '^##\s'){ break }
          $me = [regex]::Match($linhas[$j], 'estado:\*{0,2}\s*([A-Za-z-]+)')
          if($me.Success -and $estado -eq 'SEM-ESTADO'){ $estado = $me.Groups[1].Value.ToUpper() }
          $ma = [regex]::Match($linhas[$j], 'arquivo:\*{0,2}\s*`?([^`]+)`?')
          if($ma.Success -and $arq -eq ''){ $arq = $ma.Groups[1].Value.Trim() }
        }
        if(-not $achou){
          Write-Output ''
          Write-Output ('===== ' + (Get-InboxNome $ag) + ' :: pedidos para ' + $ag + ' =====')
          $achou = $true
        }
        $total++
        $vivo = ($estado -ne 'FECHADO' -and $estado -ne 'FEITO')
        if($vivo){ $abertos++ }
        $tag = '[ABERTO] '
        if(-not $vivo){ $tag = '[FECHADO]' }
        Write-Output ($tag + ' ' + $estado.PadRight(11) + ' de ' + $de.PadRight(5) + ' ' + $assunto)
        if($arq -ne ''){ Write-Output ('            arquivo: ' + $arq + ' :: linha ' + ($i + 1)) }
      }
    }
    Write-Output ''
    Write-Output ('PEDIDOS :: total=' + $total + ' :: abertos=' + $abertos)
  }

  'pedir' {
    $quem = $De.ToUpper()
    $alvo = $Para.ToUpper()
    if($quem -eq '' -or $alvo -eq ''){ Write-Output 'ERRO: usa -De <AGENTE> -Para <AGENTE>'; exit 1 }
    if((Get-InboxNome $quem) -eq '' -or (Get-InboxNome $alvo) -eq ''){ Write-Output 'ERRO: agente invalido (ALFA|DELTA|CMD|DONO)'; exit 1 }
    if($quem -eq $alvo){ Write-Output 'ERRO: origem e destino iguais'; exit 1 }
    if($Assunto -eq ''){ Write-Output 'ERRO: falta -Assunto (accao concreta, nao tema)'; exit 1 }
    Test-LockLivre
    $id = Get-PedidoProximoId
    $prec = '-'
    if($Precisa -ne ''){ $prec = $Precisa }
    $prz = '-'
    if($Prazo -ne ''){ $prz = $Prazo }
    $linha = '| ' + $id + ' | ' + $quem + ' -> ' + $alvo + ' | ' + $Assunto + ' | ' + $prec + ' | ' + $prz + ' | PEDIDO | ' + (Get-HoraCurta) + ' |'
    Add-PedidoLinha $linha
    Write-Output ('   destinatario ve com: equipe-sync.ps1 pedidos -De ' + $alvo)
  }

  'aceitar' { Set-PedidoEstado $Id 'ACEITE' '' }
  'feito'   { Set-PedidoEstado $Id 'FEITO' $Corpo }
  'devolver'{ Set-PedidoEstado $Id 'DEVOLVIDO' $Corpo }
  'bloquear'{ Set-PedidoEstado $Id 'BLOQUEADO' $Corpo }
  'fechar'  { Set-PedidoEstado $Id 'FECHADO' '' }

  'lock'   { Set-Lock }
  'unlock' { Remove-Lock }

  'lockstatus' {
    $lk = Test-Lock
    if($lk -ne $null){ Write-Output ('LOCK :: ' + $lk) } else { Write-Output 'LOCK :: livre' }
  }

  default {
    Write-Output ('COMANDO DESCONHECIDO :: ' + $Cmd)
    Write-Output 'validos: status | check | dono | quem | pedidos | snapshot | append | substituir | aviso | eol | lock | unlock | lockstatus'
    exit 1
  }
}
