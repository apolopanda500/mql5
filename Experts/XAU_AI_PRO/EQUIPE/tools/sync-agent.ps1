# sync-agent.ps1 - canal de sincronizacao da EQUIPE (ALFA / DELTA / CMD / DONO)
#
# Porque existe: em 05/11/2026 o canal por ficheiros falhou tres vezes de forma
# medida, e cada falha custou trabalho repetido:
#   1. ESCRITA PERDIDA  - duas escritas simultaneas no mesmo .md e a ultima
#      ganha. Aconteceu ao DELTA as 22:12 (cabecalho de INBOX_AGENTE_2.md) e ao
#      rodape de DECISOES.md.
#   2. IDS COLIDIDOS    - tres secoes chamadas `D-012` e, cinco minutos depois
#      de renumerar, dois `D-013`, porque dois agentes reservaram o "proximo
#      numero" ao mesmo tempo.
#   3. ATO SERIALIZADO  - compile e reattach nao podem correr em paralelo (o
#      .ex5 carrega o estado de TODOS os fontes do disco), mas nada impedia.
#   4. DONO FORA DO CANAL - o dono decide tudo (`PROTOCOLO.md` 5.2) e nao tinha
#      ficheiro proprio: as perguntas ficavam espalhadas no chat.
#
# O que este script garante:
#   - toda a escrita passa por um Mutex nomeado -> append atomico, nada se perde;
#   - IDs sao reservados em ledger com o mesmo Mutex -> nunca dois iguais;
#   - ha um LOCK visivel com dono, motivo e validade -> 1 compile / 1 reattach;
#   - o DONO tem INBOX_DONO.md com perguntas numeradas `Q-nnn` e campo RESPOSTA.
#
# Uso (a partir de qualquer pasta; caminhos resolvidos pelo script):
#   powershell -NoProfile -ExecutionPolicy Bypass -File EQUIPE\Tools\sync-agent.ps1 help
#
# Regras que este script NAO pode violar:
#   - nao apaga texto de outro agente (so faz append ou substitui um bloco que
#     ele proprio inseriu, com -Substituir explicito);
#   - nunca toca em parametros de risco, conta real, `git push` ou CodeBase;
#   - escreve sempre UTF-8 SEM BOM (o mojibake que ja apareceu no canal vinha
#     de ferramentas que escrevem ANSI/CP1252 por omissao).

#Requires -Version 5.1
[CmdletBinding()]
param(
   [Parameter(Mandatory = $true, Position = 0)]
   [ValidateSet('help', 'status', 'post', 'read', 'ask', 'answer', 'id', 'lock', 'check', 'log', 'note', 'ping')]
   [string]$Cmd,

   [string]$From = '',            # ALFA | DELTA | CMD | DONO
   [string]$To = '',              # ALFA | DELTA | CMD | DONO
   [string]$Assunto = '',
   [string]$Arquivo = '',         # ex: DECISOES.md:250
   [string]$Precisa = '',
   # Aceita os DOIS vocabularios: o antigo (ABERTO/RESPONDIDO/FECHADO) e o do
   # PEDIDO_DE_AJUDA.md (PEDIDO/ACEITE/FEITO/DEVOLVIDO/BLOQUEADO/FECHADO).
   # Sem isto o protocolo escrito nao podia ser usado: -Estado ACEITE falhava
   # antes de escrever (defeito apontado pelo DELTA no D-021).
   [ValidateSet('ABERTO', 'RESPONDIDO', 'FECHADO', 'PEDIDO', 'ACEITE', 'FEITO', 'DEVOLVIDO', 'BLOQUEADO')]
   [string]$Estado = 'ABERTO',

   [string]$Agent = '',           # read/status: de quem e a caixa
   [string]$Pergunta = '',
   [string]$Opcoes = '',
   [string]$Prazo = '',
   [string]$Q = '',               # answer: Q-001
   [string]$Resposta = '',

   [ValidateSet('D', 'P1', 'T')]
   [string]$Tipo = 'D',

   [ValidateSet('pegar', 'liberar', 'ver')]
   [string]$Acao = 'ver',
   [string]$Motivo = '',
   [int]$TtlMin = 30,

   [int]$Tail = 40,
   [string]$Substituir = '',      # post: texto exato a substituir (opcional)
   [string]$Corpo = ''            # note: texto a anexar ao ficheiro do canal
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# 0. Caminhos e UTF-8 sem BOM
# ---------------------------------------------------------------------------
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Equipe    = Split-Path -Parent $ScriptDir
$EaDir     = Split-Path -Parent $Equipe
# O script vive em EQUIPE\tools, logo $ScriptDir e um nivel mais fundo do que
# quando estava em EQUIPE. Subir tres niveis a partir de $Equipe deixava
# $Mql5 em `MQL5\Experts` -> nem `MQL5\Logs` nem o repo git eram encontrados
# (era o que fazia `[START] no log` valer sempre 0).
$Mql5      = Split-Path -Parent (Split-Path -Parent $EaDir)

$Decisoes  = Join-Path $Equipe 'DECISOES.md'
$Protocolo = Join-Path $Equipe 'PROTOCOLO.md'
$LockFile  = Join-Path $Equipe 'LOCK.md'
$Ledger    = Join-Path $Equipe 'IDS.md'
$InboxDono = Join-Path $Equipe 'INBOX_DONO.md'
$AuditLog  = Join-Path $Equipe 'SYNC_LOG.md'

$AgentMap = @{ 'ALFA' = 1; 'DELTA' = 2; 'CMD' = 3 }

function Get-InboxPath {
   param([string]$Who)
   $u = $Who.ToUpperInvariant()
   if ($u -eq 'DONO') { return $InboxDono }
   if ($AgentMap.ContainsKey($u)) { return (Join-Path $Equipe ("INBOX_AGENTE_{0}.md" -f $AgentMap[$u])) }
   throw "Destinatario invalido: '$Who'. Use ALFA, DELTA, CMD ou DONO."
}

function Get-AgenteValido {
   param([string]$Who, [string]$Campo)
   if ([string]::IsNullOrWhiteSpace($Who)) { throw "Falta -$Campo. Use ALFA, DELTA, CMD ou DONO." }
   $u = $Who.ToUpperInvariant()
   if ($u -ne 'DONO' -and -not $AgentMap.ContainsKey($u)) {
      throw "'$Who' nao e um participante. Use ALFA, DELTA, CMD ou DONO."
   }
   return $u
}

function Now-Stamp { return (Get-Date -Format 'dd/MM/yyyy HH:mm:ss') }
function Now-Short { return (Get-Date -Format 'dd/MM HH:mm') }

# ---------------------------------------------------------------------------
# 1. Mutex: a unica forma de escrever. Serializa os tres agentes.
# ---------------------------------------------------------------------------
$MutexName = 'Local\XAI_EQUIPE_' + ([Math]::Abs($Equipe.ToLowerInvariant().GetHashCode().ToString().GetHashCode()))
$Mutex = New-Object System.Threading.Mutex($false, $MutexName)

function Invoke-Locked {
   param([scriptblock]$Action, [string]$Who = 'sistema')
   $got = $false
   try {
      $got = $Mutex.WaitOne(20000)
      if (-not $got) { throw "Mutex ocupado ha 20 s. Outro agente esta a escrever; tente de novo." }
      & $Action
   }
   finally {
      if ($got) { $Mutex.ReleaseMutex() }
   }
}

function Read-Text {
   param([string]$Path)
   if (-not (Test-Path -LiteralPath $Path)) { return '' }
   return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Read-LogLines {
   <# Le um log do terminal sem o bloquear.
      Dois factos medidos que obrigam a isto:
      1. o terminal mantem MQL5\Logs\AAAAAMMDD.log aberto -> ReadAllBytes
         rebenta com "o processo nao pode acessar o arquivo";
      2. esses logs sao UTF-16LE com BOM (FF FE), nao UTF-8 -> lidos como UTF-8
         davam texto partido e nenhum [START] era encontrado.
  #>
   param([string]$Path)
   $fs = $null
   try {
      $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open,
         [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
      $len = [int]$fs.Length
      if ($len -eq 0) { return @() }
      $buf = New-Object byte[] $len
      $read = 0
      while ($read -lt $len) {
         $n = $fs.Read($buf, $read, $len - $read)
         if ($n -le 0) { break }
         $read += $n
      }
   }
   finally {
      if ($fs) { $fs.Close(); $fs.Dispose() }
   }

   if ($read -ge 2 -and $buf[0] -eq 0xFF -and $buf[1] -eq 0xFE) {
      return [System.Text.Encoding]::Unicode.GetString($buf, 2, $read - 2) -split "`r?`n"
   }
   if ($read -ge 2 -and $buf[0] -eq 0xFE -and $buf[1] -eq 0xFF) {
      return [System.Text.Encoding]::BigEndianUnicode.GetString($buf, 2, $read - 2) -split "`r?`n"
   }
   if ($read -ge 3 -and $buf[0] -eq 0xEF -and $buf[1] -eq 0xBB -and $buf[2] -eq 0xBF) {
      return [System.Text.Encoding]::UTF8.GetString($buf, 3, $read - 3) -split "`r?`n"
   }
   return [System.Text.Encoding]::UTF8.GetString($buf, 0, $read) -split "`r?`n"
}

function Write-TextAtomic {
   param([string]$Path, [string]$Text)
   $tmp = $Path + '.tmp-sync'
   [System.IO.File]::WriteAllText($tmp, $Text, $Utf8NoBom)
   if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Force }
   Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Add-Block {
   <# Append atomico. Garante exactamente uma linha em branco de separacao. #>
   param([string]$Path, [string]$Block)
   Invoke-Locked {
      $old = Read-Text $Path
      # O canal tem ficheiros em LF e ficheiros em CRLF. Anexar sempre CRLF a
      # um ficheiro LF MISTURA as terminacoes e parte a leitura por numero de
      # linha (um leitor que divida por CRLF ve o ficheiro como 1 so linha -
      # aconteceu com o DECISOES.md as 22:41). O bloco passa a seguir o EOL
      # dominante do ficheiro, sem reescrever o que ja la esta.
      $block = $Block
      if ($old.Length -gt 0) {
         $crlfOld = ([regex]::Matches($old, "`r`n")).Count
         $lfOld = ([regex]::Matches($old, "`n")).Count - $crlfOld
         if ($lfOld -gt $crlfOld) { $block = $Block -replace "`r`n", "`n" }
      }
      $sep = if ($block.Contains("`r`n")) { "`r`n" } else { "`n" }
      if ($old.Length -gt 0 -and -not $old.EndsWith("`n")) { $old += $sep }
      Write-TextAtomic -Path $Path -Text ($old + $block)
   }
}

function Add-Audit {
   param([string]$Who, [string]$What)
   Add-Block -Path $AuditLog -Block (
      "- {0} | {1} | {2}`r`n" -f (Now-Stamp), $Who, $What
   )
}

# ---------------------------------------------------------------------------
# 2. IDs: reserva atomica, sem colisao
# ---------------------------------------------------------------------------
function Get-Usados {
   <# Le os IDs ja usados no ledger E nos cabecalhos de DECISOES.md. #>
   param([string]$Type)
   $set = New-Object System.Collections.Generic.HashSet[string]

   $led = Read-Text $Ledger
   foreach ($m in [regex]::Matches($led, 'USADO\s*\|\s*(' + [regex]::Escape($Type) + ')\s*\|\s*([A-Z0-9\.\-]+)')) {
      [void]$set.Add($m.Groups[2].Value.ToUpperInvariant())
   }

   $dec = Read-Text $Decisoes
   foreach ($m in [regex]::Matches($dec, '(?m)^##\s+(D-\d{3})')) {
      [void]$set.Add($m.Groups[1].Value.ToUpperInvariant())
   }
   return $set
}

function Get-ProximoId {
   param([string]$Type)
   return Invoke-Locked {
      if (-not (Test-Path -LiteralPath $Ledger)) {
         Write-TextAtomic -Path $Ledger -Text (
            "# REGISTRO DE IDs - EQUIPE`n`n" +
            "Ledger de reserva. Cada linha e um ID entregue a UM agente.`n" +
            "Formato: ``USADO | <tipo> | <id> | <agente> | <data hora> | <assunto>```n`n"
         )
      }

      $usados = Get-Usados -Type $Type
      $max = 0
      foreach ($u in $usados) {
         $m = [regex]::Match($u, '(\d+)$')
         if ($m.Success) {
            $n = [int]$m.Groups[1].Value
            if ($n -gt $max) { $max = $n }
         }
      }
      $next = $max + 1

      if ($Type -eq 'D') { $id = 'D-{0:000}' -f $next }
      elseif ($Type -eq 'P1') { $id = 'P1.{0}' -f (1130 + $next - 1) }   # base P1.130
      else { $id = 'T-{0:000}' -f $next }

      $who = if ($From) { $From.ToUpperInvariant() } else { 'sistema' }
      $led = Read-Text $Ledger
      # Canal e LF puro: o ledger tambem. Antes escrevia CRLF e o proprio
      # `check` passou a acusar IDS.md com 1 CR (medido 22:56 no D-024).
      if (-not $led.EndsWith("`n")) { $led += "`n" }
      $led += ("USADO | {0} | {1} | {2} | {3} | {4}`n" -f $Type, $id, $who, (Now-Stamp), $Assunto)
      Write-TextAtomic -Path $Ledger -Text $led

      return $id
   }
}

# ---------------------------------------------------------------------------
# 3. LOCK: 1 compile / 1 reattach por vez
# ---------------------------------------------------------------------------
function Get-LockState {
   $txt = Read-Text $LockFile
   if ([string]::IsNullOrWhiteSpace($txt)) {
      return [pscustomobject]@{ Livre = $true; Dono = ''; Motivo = ''; Expira = $null; Expirado = $false; Ocupado = $false; Texto = '' }
   }
   # O LOCK.md escreve os campos em negrito (`- **Dono:** ALFA`). Comparar com
   # `^-\s*Dono:` nunca casava: um LOCK tomado lia-se sempre como LIVRE e a
   # serializacao de compile/reattach nao existia de facto. Achata-se a enfase.
   $flat = $txt -replace '\*', ''
   $dono = ''
   $motivo = ''
   $expira = $null
   $m = [regex]::Match($flat, '(?m)^-\s*Dono:\s*(.+)$')
   if ($m.Success) { $dono = $m.Groups[1].Value.Trim() }
   $m = [regex]::Match($flat, '(?m)^-\s*Motivo:\s*(.+)$')
   if ($m.Success) { $motivo = $m.Groups[1].Value.Trim() }
   $m = [regex]::Match($flat, '(?m)^-\s*Expira:\s*(.+)$')
   if ($m.Success) {
      try { $expira = [datetime]::ParseExact($m.Groups[1].Value.Trim(), 'dd/MM/yyyy HH:mm:ss', $null) } catch { $expira = $null }
   }
   $liberado = ($flat -match 'ESTADO:\s*LIVRE')
   $ocupado  = ($flat -match 'ESTADO:\s*OCUPADO')
   $vencido  = $ocupado -and ($expira -ne $null) -and ($expira -le (Get-Date))
   $vivo     = $ocupado -and (-not $liberado) -and ($expira -ne $null) -and ($expira -gt (Get-Date))
   return [pscustomobject]@{ Livre = (-not $vivo); Dono = $dono; Motivo = $motivo; Expira = $expira; Expirado = $vencido; Ocupado = $ocupado; Texto = $txt }
}

# ---------------------------------------------------------------------------
# 4. Comandos
# ---------------------------------------------------------------------------
function Show-Help {
   @'
sync-agent.ps1 - canal de sincronizacao ALFA / DELTA / CMD / DONO

  status  [-Agent ALFA]            estado medido: versao, binario x fontes, git, logs, lock
  post    -From ALFA -To DELTA -Assunto "..." [-Arquivo "DECISOES.md:250"]
                                   [-Precisa "..."] [-Estado ABERTO]
  read    -Agent ALFA [-Tail 40]   ultimas linhas da minha caixa
  note    -From ALFA -Arquivo DECISOES.md -Corpo "texto"
                                   anexa a um .md do canal dentro do Mutex (so append)
  ping    -From CMD [-Assunto "..."] [-Precisa ONLINE|OCUPADO|AUSENTE]
                                   regista presenca em PRESENCA.md (heartbeat em tempo real)
  ask     -From ALFA -Pergunta "..." -Opcoes "(a)...; (b)..." [-Prazo "06/11 12:00"]
                                   abre Q-nnn em INBOX_DONO.md (decisao DO DONO)
  answer  -Q Q-001 -Resposta "(a)"  SO O DONO: responde e fecha a pergunta
  id      -Tipo D|P1|T [-From ALFA] [-Assunto "..."]   reserva o proximo ID livre
  lock    -Acao pegar|liberar|ver -From ALFA -Motivo compile [-TtlMin 30]
  check                            integridade: IDs duplicados, encoding, BOM, caixas, lock
  log     [-Tail 30]               ultimas entradas de SYNC_LOG.md

Regras:
  * toda a escrita passa por Mutex -> nada se perde por escrita simultanea
  * IDs sao reservados no ledger IDS.md dentro do mesmo Mutex -> zero colisao
  * LOCK.md visivel com dono/motivo/validade -> 1 compile e 1 reattach por vez
  * INBOX_DONO.md e a unica caixa do dono; pergunta sem RESPOSTA nao esta fechada
  * o script nunca apaga texto de outro agente e nunca escreve ANSI/CP1252
'@ | Write-Output
}

function Show-Status {
   param([string]$Who)

   $srcMain = Join-Path $EaDir 'XAU_AI_PRO.mq5'
   $ex5     = Join-Path $EaDir 'XAU_AI_PRO.ex5'
   $verMgr  = Join-Path $EaDir 'Enterprise\VersionManager.mqh'

   $verProp = 'nao lido'
   $src = Read-Text $srcMain
   $m = [regex]::Match($src, '#property\s+version\s+"([^"]+)"')
   if ($m.Success) { $verProp = $m.Groups[1].Value }
   $verReadable = 'nao lido'
   $vm = Read-Text $verMgr
   $m = [regex]::Match($vm, 'EA_VERSION_STRING\s+"([^"]+)"')
   if ($m.Success) { $verReadable = $m.Groups[1].Value }

   $ex5Info = if (Test-Path -LiteralPath $ex5) { Get-Item -LiteralPath $ex5 } else { $null }

   # fontes mais recentes que o binario
   $maisNovo = $null
   $pendente = 0
   # `-Include` com `-LiteralPath` e `-Recurse` NAO filtra (quirk do PowerShell):
   # contava .md, .ex5 e tudo o mais como "fonte pendente". Filtra-se a extensao
   # a mao, que e o unico jeito previsivel.
   $srcFiles = Get-ChildItem -LiteralPath $EaDir -Recurse -File -ErrorAction SilentlyContinue |
   Where-Object { $_.Extension -eq '.mq5' -or $_.Extension -eq '.mqh' }
   foreach ($f in $srcFiles) {
      if ($ex5Info -and $f.LastWriteTime -gt $ex5Info.LastWriteTime) {
         $pendente++
         if (-not $maisNovo -or $f.LastWriteTime -gt $maisNovo.LastWriteTime) { $maisNovo = $f }
      }
   }

   # git, com guarda de raiz
   $gitInfo = 'sem repositorio git dentro de MQL5'
   $gitCmd = Get-Command git -ErrorAction SilentlyContinue
   if ($gitCmd) {
      $top = $null
      try { $top = (& git -C $EaDir rev-parse --show-toplevel 2>$null) } catch { $top = $null }
      if ($top) {
         $topPath = $top.ToString().Trim()
         # git devolve `C:/Users/...` com barras normais, $Mql5 usa `\`. Sem
         # normalizar, a guarda de raiz dizia "repositorio fora das raizes
         # permitidas" para um repo que esta exactamente em MQL5.
         $topPath = ($topPath -replace '/', '\').TrimEnd('\')
         $mql5Norm = $Mql5.TrimEnd('\')
         $inside = ($topPath -eq $mql5Norm) -or
         $topPath.StartsWith($mql5Norm + '\', [StringComparison]::OrdinalIgnoreCase)
         if (-not $inside) {
            $gitInfo = "IGNORADO: repositorio esta fora das raizes permitidas ($topPath)"
         }
         else {
            $branch = (& git -C $topPath rev-parse --abbrev-ref HEAD 2>$null)
            $last   = (& git -C $topPath log -1 --format='%h %ad %s' --date=format:'%d/%m %H:%M' 2>$null)
            $dirty  = @(& git -C $topPath status --porcelain 2>$null).Count
            $gitInfo = "branch=$branch | ultimo=$last | alterados=$dirty"
         }
      }
   }

   # logs do terminal: [START] / [STOP] do EA
   $logDir = Join-Path $Mql5 'Logs'
   $startCount = 0
   $lastStart = 'nenhum'
   if (Test-Path -LiteralPath $logDir) {
      $log = Get-ChildItem -LiteralPath $logDir -Filter '*.log' -File -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending | Select-Object -First 1
      if ($log) {
         $lines = Read-LogLines -Path $log.FullName
         foreach ($l in $lines) {
            if ($l -match '\[START\]\s+XAU_AI_PRO') {
               $startCount++
               # O inicio da linha do log chega por vezes com bytes partidos; o
               # campo estavel e a hora HH:MM:SS.mmm.
               $mm = [regex]::Match($l, '(\d{2}:\d{2}:\d{2}\.\d{3})')
               if ($mm.Success) { $lastStart = $mm.Groups[1].Value }
            }
         }
      }
   }

   $lock = Get-LockState
   $lockTxt = if ($lock.Livre) { 'LIVRE' } else { "OCUPADO por $($lock.Dono) ($($lock.Motivo)) ate $($lock.Expira.ToString('dd/MM HH:mm'))" }

   $donoAbertas = Get-PerguntasAbertas

   Write-Output ''
   Write-Output '===== ESTADO MEDIDO ====='
   Write-Output ("hora            : {0}" -f (Now-Stamp))
   Write-Output ("EA              : versao legivel {0} | #property {1}" -f $verReadable, $verProp)
   if ($ex5Info) {
      Write-Output ("binario         : {0} B | {1}" -f $ex5Info.Length, $ex5Info.LastWriteTime.ToString('dd/MM HH:mm:ss'))
   }
   else {
      Write-Output 'binario         : AUSENTE'
   }
   if ($pendente -eq 0) {
      Write-Output 'binario x fonte : BATEM (nenhum .mq5/.mqh mais novo que o .ex5)'
   }
   else {
      Write-Output ("binario x fonte : COMPILE PENDENTE - {0} ficheiro(s); mais novo {1} {2}" -f `
            $pendente, $maisNovo.Name, $maisNovo.LastWriteTime.ToString('dd/MM HH:mm:ss'))
   }
   Write-Output ("git             : {0}" -f $gitInfo)
   Write-Output ("[START] no log  : {0} (ultimo {1})" -f $startCount, $lastStart)
   Write-Output ("lock            : {0}" -f $lockTxt)
   Write-Output ("perguntas DONO  : {0} em aberto" -f $donoAbertas.Count)
   if ($donoAbertas.Count -gt 0) {
      foreach ($p in $donoAbertas) { Write-Output ("                  {0} - {1}" -f $p.Id, $p.Titulo) }
   }
   if ($Who) {
      $ib = Get-InboxPath -Who $Who
      $st = if (Test-Path -LiteralPath $ib) { (Get-Item -LiteralPath $ib) } else { $null }
      Write-Output ("caixa {0,-5}     : {1}" -f $Who.ToUpperInvariant(), $(if ($st) { "$($st.Length) B, ultima escrita $($st.LastWriteTime.ToString('dd/MM HH:mm'))" } else { 'AUSENTE' }))
   }
   Write-Output '=========================='
   Write-Output ''
}

function Show-Post {
   $from = Get-AgenteValido -Who $From -Campo 'From'
   $to = Get-AgenteValido -Who $To -Campo 'To'
   if ([string]::IsNullOrWhiteSpace($Assunto)) { throw 'Falta -Assunto.' }
   if ($from -eq $to) { throw 'Origem e destino iguais.' }

   $ib = Get-InboxPath -Who $to
   if (-not (Test-Path -LiteralPath $ib)) { throw "Caixa inexistente: $ib" }

   $block = @()

   if ($Substituir) {
      Invoke-Locked {
         $old = Read-Text $ib
         if ($old -notlike "*$Substituir*") { throw "Texto a substituir nao encontrado em $ib" }
         $new = $old.Replace($Substituir, '')
         Write-TextAtomic -Path $ib -Text $new
      }
   }

   $block += "`r`n---`r`n"
   $block += "## {0} - {1} -> {2} | {3}`r`n" -f (Now-Short), $from, $to, $Assunto
   $block += "`r`n"
   if ($Arquivo) { $block += "- **arquivo:** ``$Arquivo```r`n" }
   if ($Precisa) { $block += "- **precisa:** $Precisa`r`n" }
   $block += "- **estado:** $Estado | **hora:** $(Now-Short) | **de:** $from`r`n"
   if ($Corpo) { $block += "`r`n$Corpo`r`n" }

   Add-Block -Path $ib -Block ($block -join '')
   Add-Audit -Who $from -What "post -> $to | $Assunto"

   Write-Output "OK: bloco de $from para $to escrito em $(Split-Path -Leaf $ib) ($(Now-Short))."
}

function Show-Read {
   param([string]$Who, [int]$Lines)
   $a = Get-AgenteValido -Who $Who -Campo 'Agent'
   $ib = Get-InboxPath -Who $a
   if (-not (Test-Path -LiteralPath $ib)) { throw "Caixa inexistente: $ib" }
   Write-Output ''
   Write-Output ("===== {0} (ultimas {1} linhas) =====" -f (Split-Path -Leaf $ib), $Lines)
   $all = [System.IO.File]::ReadAllLines($ib, [System.Text.Encoding]::UTF8)
   $skip = [Math]::Max(0, $all.Count - $Lines)
   for ($i = $skip; $i -lt $all.Count; $i++) { Write-Output $all[$i] }
   Write-Output '===================================='
   Write-Output ''
}

function Test-BlocoTemResposta {
   <# Diz se o bloco tem ALGUMA linha RESPOSTA com texto.
   Olha TODAS as ocorrencias, e nao so a primeira: ha perguntas com uma
   `- **RESPOSTA:**` vazia (do formato) e a resposta preenchida na linha
   seguinte, e outras com duas respostas (uma por destinatario). #>
   param([string]$Bloco)
   foreach ($m in [regex]::Matches($Bloco, '(?m)^-[ \t]*\*{0,2}[ \t]*RESPOSTA[ \t]*:?[ \t]*\*{0,2}[ \t]*([^\r\n]*)$')) {
      $v = $m.Groups[1].Value.Trim()
      if ($v -ne '' -and $v -notmatch '^_*$') { return $true }
   }
   return $false
}

function Get-PerguntasAbertas {
   <# Perguntas Q-nnn sem campo RESPOSTA preenchido. #>
   $txt = Read-Text $InboxDono
   if ([string]::IsNullOrWhiteSpace($txt)) { return @() }
   $out = New-Object System.Collections.Generic.List[object]
   # O split anterior consumia o proprio `## ` e deixava `Q-001` sem cabecalho
   # no bloco seguinte -> a fila do DONO lia sempre 0 perguntas. O lookahead
   # tem de vir ANTES do `##` para o cabecalho ficar no bloco certo.
   $blocks = [regex]::Split($txt, '(?m)^(?=##\s+Q-\d{3})')
   foreach ($b in $blocks) {
      # Aceita os dois separadores que o canal ja usa: `Q-001 | assunto | data`
      # (formato do INBOX_DONO.md) e `Q-001 - assunto`. Antes exigia-se `-` e
      # por isso a fila do DONO aparecia sempre como "0 em aberto".
      $m = [regex]::Match($b, '^##\s+(Q-\d{3})\s*[|]\s*([^|\r\n]+)', 'Multiline')
      if (-not $m.Success) { $m = [regex]::Match($b, '^##\s+(Q-\d{3})\s*-\s*([^\r\n]+)', 'Multiline') }
      if (-not $m.Success) { continue }
      $id = $m.Groups[1].Value
      $titulo = $m.Groups[2].Value.Trim()
      # DEFEITO CORRIGIDO (07/11/2026): o canal escreve a resposta em NEGRITO -
      # `- **RESPOSTA:** texto` - e a regex so aceitava `- RESPOSTA:`. Resultado:
      # 9 perguntas ja respondidas (Q-016..019, 025, 026, 065, 068, 070) eram
      # contadas como abertas, e o `check` anunciava 29 quando a fila real tinha
      # 20. Aceita as duas formas, procura em TODAS as linhas (ha blocos com uma
      # RESPOSTA vazia e outra preenchida) e conta vazio como aberta.
      $aberta = -not (Test-BlocoTemResposta $b)
      $out.Add([pscustomobject]@{ Id = $id; Titulo = $titulo; Aberta = $aberta })
   }
   # A virgula impede o PowerShell de desenrolar a lista: com 0 ou 1 item o
   # chamador recebia $null/objecto e `.Count` rebentava em StrictMode.
   return ,@($out | Where-Object { $_.Aberta })
}

function Get-PerguntasFechadasSemResposta {
   <# Integridade: `estado:` diz FECHADA/RESPONDIDA mas nao ha texto de RESPOSTA.
   Nao e uma pergunta aberta (o estado diz que nao), nem uma pergunta fechada
   de verdade (nao ha decisao escrita). Fica de fora das duas contagens e e
   denunciada no `check` para alguem repor o texto. #>
   $txt = Read-Text $InboxDono
   if ([string]::IsNullOrWhiteSpace($txt)) { return ,@() }
   $out = New-Object System.Collections.Generic.List[object]
   $blocks = [regex]::Split($txt, '(?m)^(?=##\s+Q-\d{3})')
   foreach ($b in $blocks) {
      $m = [regex]::Match($b, '^##\s+(Q-\d{3})\s*[|]\s*([^|\r\n]+)', 'Multiline')
      if (-not $m.Success) { $m = [regex]::Match($b, '^##\s+(Q-\d{3})\s*-\s*([^\r\n]+)', 'Multiline') }
      if (-not $m.Success) { continue }
      $est = [regex]::Match($b, 'estado:\s*\*{0,2}\s*([A-Z/]+)')
      if (-not $est.Success) { continue }
      if ($est.Groups[1].Value -notmatch '^(FECHAD[OA]|RESPONDID[OA])$') { continue }
      if (Test-BlocoTemResposta $b) { continue }
      $out.Add($m.Groups[1].Value)
   }
   return ,@($out.ToArray())
}

function Show-Ask {
   $from = Get-AgenteValido -Who $From -Campo 'From'
   if ($from -eq 'DONO') { throw 'O DONO responde (answer), nao pergunta.' }
   if ([string]::IsNullOrWhiteSpace($Pergunta)) { throw 'Falta -Pergunta.' }
   if (-not (Test-Path -LiteralPath $InboxDono)) { throw "Caixa do dono inexistente: $InboxDono" }

   $qid = Invoke-Locked {
      $txt = Read-Text $InboxDono
      $max = 0
      # Contar QUALQUER Q-nnn do inbox, nao so os cabecalhos `## Q-nnn`.
      # Um cabecalho no formato antigo (`## 06/11/2026 ... Q-024`) era
      # invisivel e o contador voltava a entregar um ID ja usado. Medido em
      # 06/11/2026 20:21: a Q-024 saiu duas vezes (DELTA 20:13, ALFA 20:21).
      foreach ($m in [regex]::Matches($txt, 'Q-(\d{3})')) {
         $n = [int]$m.Groups[1].Value
         if ($n -gt $max) { $max = $n }
      }
      # O ledger e a fonte de verdade da reserva: um Q ja entregue a outro
      # agente nunca pode ser recalculado a partir do texto do inbox.
      foreach ($u in (Get-Usados -Type 'Q')) {
         $m = [regex]::Match($u, '(\d+)$')
         if ($m.Success) {
            $n = [int]$m.Groups[1].Value
            if ($n -gt $max) { $max = $n }
         }
      }
      $id = 'Q-{0:000}' -f ($max + 1)
      # Reserva no ledger dentro do mesmo Mutex: dois agentes em paralelo nao
      # podem receber o mesmo Q.
      $led = Read-Text $Ledger
      if (-not $led.EndsWith("`n")) { $led += "`n" }
      $quem = if ($From) { $From.ToUpperInvariant() } else { 'sistema' }
      $assunto = ($Pergunta -replace '\s+', ' ').Trim()
      $led += ("USADO | Q | {0} | {1} | {2} | {3}`n" -f $id, $quem, (Now-Stamp), $assunto)
      Write-TextAtomic -Path $Ledger -Text $led
      return $id
   }

   $b = @()
   $b += "`r`n---`r`n"
   $b += "## {0} - {1}`r`n" -f $qid, $Pergunta
   $b += "`r`n"
   $b += "- **de:** $from | **hora:** $(Now-Short)`r`n"
   if ($Prazo) { $b += "- **prazo:** $Prazo`r`n" }
   if ($Arquivo) { $b += "- **arquivo:** ``$Arquivo```r`n" }
   if ($Opcoes) { $b += "- **opcoes:** $Opcoes`r`n" }
   $b += "- **estado:** ABERTA`r`n"
   $b += "- **RESPOSTA:**`r`n"
   $b += "`r`n"

   Add-Block -Path $InboxDono -Block ($b -join '')
   Add-Audit -Who $from -What "$qid aberta | $Pergunta"

   Write-Output "OK: $qid aberta em INBOX_DONO.md. O dono responde com:"
   Write-Output ("  sync-agent.ps1 answer -Q {0} -Resposta `"(a)`"" -f $qid)
}

function Show-Answer {
   $who = Get-AgenteValido -Who $From -Campo 'From'
   if ($who -ne 'DONO') { throw 'So o DONO responde (-From DONO). Agente que responde a pergunta do dono usa: post -From ALFA -To DONO.' }
   if ($Q -notmatch '^Q-\d{3}$') { throw 'Use -Q Q-001.' }
   if ([string]::IsNullOrWhiteSpace($Resposta)) { throw 'Falta -Resposta.' }

   Invoke-Locked {
      $txt = Read-Text $InboxDono
      if ($txt -notmatch ('(?m)^##\s+' + [regex]::Escape($Q) + '\s*-')) {
         throw "$Q nao existe em INBOX_DONO.md."
      }
      # encontra o bloco deste Q e substitui a linha RESPOSTA dentro dele
      $parts = [regex]::Split($txt, '(?m)(?=^##\s+Q-\d{3})')
      $done = $false
      for ($i = 0; $i -lt $parts.Count; $i++) {
         if ($parts[$i] -match ('^##\s+' + [regex]::Escape($Q) + '\s*-')) {
            $seg = $parts[$i]
            if ($seg -match '(?m)^-\s*RESPOSTA:\s*.*$') {
               $seg = [regex]::Replace($seg, '(?m)^-\s*RESPOSTA:\s*.*$',
                  ('- **RESPOSTA:** {0} | **respondida por:** DONO | **hora:** {1}' -f $Resposta.Trim(), (Now-Short)), 1)
            }
            else {
               # Canal e LF puro (D-023). Este ramo escrevia `r`n e o `check`
               # passava a acusar CR depois de cada resposta do DONO - o mesmo
               # defeito do IDS.md, do Show-Check e do LOCK.md.
               $seg += "`n- **RESPOSTA:** $($Resposta.Trim()) | **respondida por:** DONO | **hora:** $(Now-Short)`n"
            }
            if ($seg -match '(?m)^-\s*\*\*estado:\*\*\s*ABERTA\s*$') {
               $seg = [regex]::Replace($seg, '(?m)^(-\s*\*\*estado:\*\*\s*)ABERTA\s*$', '${1}FECHADA (dono, ' + (Now-Short) + ')', 1)
            }
            $parts[$i] = $seg
            $done = $true
            break
         }
      }
      if (-not $done) { throw "Bloco $Q nao localizado para resposta." }
      Write-TextAtomic -Path $InboxDono -Text ($parts -join '')
   }

   Add-Audit -Who 'DONO' -What "$Q respondida | $Resposta"
   Write-Output "OK: $Q fechada com a resposta: $Resposta"
}

function Show-Id {
   $t = $Tipo
   $id = Get-ProximoId -Type $t
   $who = 'sistema'
   if ($From) { $who = $From.ToUpperInvariant() }
   Write-Output ("OK: proximo ID reservado para {0}: {1}" -f $who, $id)
   Write-Output "Use exactamente este. O ledger IDS.md registou a reserva."
}

function Show-Lock {
   $l = Get-LockState
   switch ($Acao) {
      'ver' {
         if ($l.Livre) { Write-Output 'LOCK: LIVRE' }
         else { Write-Output ("LOCK: OCUPADO por {0} | motivo: {1} | expira: {2}" -f $l.Dono, $l.Motivo, $l.Expira.ToString('dd/MM HH:mm:ss')) }
      }
      'pegar' {
         $who = Get-AgenteValido -Who $From -Campo 'From'
         if ([string]::IsNullOrWhiteSpace($Motivo)) { throw 'Falta -Motivo (compile, reattach, edit).' }
         if (-not $l.Livre -and $l.Dono.ToUpperInvariant() -ne $who) {
            throw ("LOCK ocupado por {0} ({1}) ate {2}. Espere ou combine na caixa dele." -f $l.Dono, $l.Motivo, $l.Expira.ToString('dd/MM HH:mm'))
         }
         $exp = (Get-Date).AddMinutes($TtlMin)
         $expTxt = $exp.ToString('dd/MM/yyyy HH:mm:ss')
         $body = @(
            '# LOCK DE OPERACAO - EQUIPE'
            ''
            ('- **Dono:** ' + $who)
            ('- **Motivo:** ' + $Motivo)
            ('- **Tomado:** ' + (Now-Stamp))
            ('- **Expira:** ' + $expTxt)
            ('- **TTL:** ' + $TtlMin + ' min')
            ''
            '- **ESTADO:** OCUPADO'
            ''
            '> O `.ex5` carrega o estado de TODOS os fontes do disco: 1 compile e'
            '> 1 reattach por vez (`PROTOCOLO.md` 5.5/5.6). Liberte ao terminar:'
            ('> `sync-agent.ps1 lock -Acao liberar -From ' + $who + '`')
            ''
         # Canal e LF puro (D-023): o LOCK.md escrevia CRLF e o proprio `check`
         # passou a acusar "LOCK.md: 13 CR" logo apos cada `lock pegar`.
         ) -join "`n"
         Invoke-Locked {
            Write-TextAtomic -Path $LockFile -Text $body
         }
         Add-Audit -Who $who -What "lock pegar | $Motivo | ${TtlMin} min"
         Write-Output "OK: LOCK tomado por $who para '$Motivo' ate $($exp.ToString('dd/MM HH:mm'))."
      }
      'liberar' {
         $who = Get-AgenteValido -Who $From -Campo 'From'
         if (-not $l.Livre -and $l.Dono.ToUpperInvariant() -ne $who) {
            throw "O LOCK e de $($l.Dono); so ele liberta."
         }
         Invoke-Locked {
            Write-TextAtomic -Path $LockFile -Text (
               "# LOCK DE OPERACAO - EQUIPE`n`n" +
               "- **ESTADO:** LIVRE`n" +
               "- **Ultimo dono:** {0}`n" -f $who +
               "- **Libertado:** {0}`n" -f (Now-Stamp)
            )
         }
         Add-Audit -Who $who -What 'lock liberar'
         Write-Output "OK: LOCK liberto por $who."
      }
   }
}

function Show-Check {
   $problemas = New-Object System.Collections.Generic.List[string]

   # 1. IDs duplicados em DECISOES.md
   $dec = Read-Text $Decisoes
   $ids = @()
   foreach ($m in [regex]::Matches($dec, '(?m)^##\s+(D-\d{3})')) { $ids += $m.Groups[1].Value }
   $dups = $ids | Group-Object | Where-Object { $_.Count -gt 1 }
   if ($dups) {
      foreach ($d in $dups) { $problemas.Add("ID duplicado em DECISOES.md: $($d.Name) x$($d.Count)") }
   }

   # 2. IDs duplicados no ledger
   $led = Read-Text $Ledger
   $lid = @()
   foreach ($m in [regex]::Matches($led, '(?m)^USADO\s*\|\s*[A-Z0-9]+\s*\|\s*([A-Z0-9\.\-]+)')) { $lid += $m.Groups[1].Value }
   $ldup = $lid | Group-Object | Where-Object { $_.Count -gt 1 }
   if ($ldup) { foreach ($d in $ldup) { $problemas.Add("ID reservado duas vezes no ledger: $($d.Name) x$($d.Count)") } }

   # 3. encoding / BOM / caracteres de substituicao
   # UTF-8 estrito: valida se os bytes decodificam sem erro (detecta ANSI/CP1252).
   # Alinhado com o equipe-sync.ps1 check do DELTA (D-023): os dois checks tem
   # de concordar. O criterio deste passou a ser TAO estrito como o dele.
   $utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
   $md = Get-ChildItem -LiteralPath $Equipe -Filter '*.md' -File -ErrorAction SilentlyContinue
   foreach ($f in $md) {
      $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
      if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
         $problemas.Add("BOM UTF-8 presente (indesejado): $($f.Name)")
      }
      try { [void]$utf8Strict.GetString($bytes) }
      catch { $problemas.Add("$($f.Name): bytes nao sao UTF-8 valido (ANSI/CP1252 ou corrupcao)") }
      $txt = [System.Text.Encoding]::UTF8.GetString($bytes)
      $crlfN = ([regex]::Matches($txt, "`r`n")).Count
      $lfN = ([regex]::Matches($txt, "`n")).Count - $crlfN
      # DEFEITO CORRIGIDO (D-023): antes so acusava EOL MISTURADO
      # ($crlfN -gt 0 -and $lfN -gt 0), logo um ficheiro 100% CRLF passava limpo.
      # O canal e LF puro: qualquer CR e defeito.
      if ($crlfN -gt 0) {
         $problemas.Add("$($f.Name): $crlfN CR (CRLF) num canal LF puro - um leitor que divida por CRLF ve o ficheiro como 1 linha")
      }
      $moji = ([regex]::Matches($txt, [string][char]0xFFFD)).Count
      if ($moji -gt 0) { $problemas.Add("$($f.Name): $moji caracter(es) de substituicao U+FFFD (mojibake provavel)") }
      if ($txt.Length -gt 0 -and -not $txt.EndsWith("`n")) { $problemas.Add("$($f.Name): nao termina com newline (append seguinte cola no texto)") }
   }

   # 4. caixas dos agentes existem
   foreach ($a in @('ALFA', 'DELTA', 'CMD', 'DONO')) {
      $p = Get-InboxPath -Who $a
      if (-not (Test-Path -LiteralPath $p)) { $problemas.Add("caixa em falta: $(Split-Path -Leaf $p)") }
   }

   # 5. lock preso
   $l = Get-LockState
   if ($l.Expirado) {
      $problemas.Add("LOCK vencido de $($l.Dono) ($($l.Motivo)) - liberte com: lock -Acao liberar -From $($l.Dono)")
   }

   # 6. pergunta fechada sem texto de resposta
   $semResposta = Get-PerguntasFechadasSemResposta
   foreach ($q in $semResposta) {
      $problemas.Add("${q}: estado FECHADA/RESPONDIDA mas sem texto de RESPOSTA - a decisao nao esta escrita")
   }

   Write-Output ''
   Write-Output '===== CHECK DO CANAL ====='
   Write-Output ("ficheiros .md     : {0}" -f $md.Count)
   Write-Output ("IDs D-xxx usados  : {0} ({1} unicos)" -f $ids.Count, ($ids | Sort-Object -Unique).Count)
   Write-Output ("IDs no ledger     : {0}" -f $lid.Count)
   Write-Output ("perguntas abertas : {0}" -f (Get-PerguntasAbertas).Count)
   if ($problemas.Count -eq 0) {
      Write-Output 'RESULTADO         : OK - sem problemas detectados'
   }
   else {
      Write-Output ("RESULTADO         : {0} problema(s)" -f $problemas.Count)
      foreach ($p in $problemas) { Write-Output ("  - {0}" -f $p) }
   }
   Write-Output '=========================='
   Write-Output ''
}

function Show-Log {
   param([int]$Lines)
   if (-not (Test-Path -LiteralPath $AuditLog)) { Write-Output 'SYNC_LOG.md ainda vazio.'; return }
   $all = [System.IO.File]::ReadAllLines($AuditLog, [System.Text.Encoding]::UTF8)
   $skip = [Math]::Max(0, $all.Count - $Lines)
   Write-Output ''
   Write-Output '===== SYNC_LOG.md ====='
   for ($i = $skip; $i -lt $all.Count; $i++) { Write-Output $all[$i] }
   Write-Output '======================='
   Write-Output ''
}

function Show-Note {
   <# Anexa texto a um ficheiro do canal, dentro do Mutex.
      E o primitivo que faltava: tres agentes a editar o mesmo DECISOES.md
      com `Set-Content`/`Out-File` foi o que perdeu escritas as 22:12.
      Regras: so ANEXA (nunca reescreve nem apaga), so aceita nome simples
      (sem caminho), e o ficheiro tem de ja existir no canal.
  #>
   $who = Get-AgenteValido -Who $From -Campo 'From'
   if ([string]::IsNullOrWhiteSpace($Corpo)) { throw 'Falta -Corpo (texto a anexar).' }
   if ([string]::IsNullOrWhiteSpace($Arquivo)) { throw 'Falta -Arquivo (ex: DECISOES.md).' }
   if ($Arquivo -match '[\\/:*?"<>|]') {
      throw "Arquivo tem de ser um nome simples dentro da pasta EQUIPE, sem caminho: '$Arquivo'."
   }
   if ($Arquivo -notmatch '\.md$') { throw 'Arquivo tem de ser .md.' }

   $path = Join-Path $Equipe $Arquivo
   if (-not (Test-Path -LiteralPath $path)) { throw "Ficheiro inexistente no canal: $Arquivo" }

   Add-Block -Path $path -Block ("`r`n" + $Corpo + "`r`n")
   Add-Audit -Who $who -What "note -> $Arquivo"
   Write-Output "OK: nota anexada a $Arquivo por $who."
}

function Show-Ping {
    $who = Get-AgenteValido -Who $From -Campo 'From'
    if ([string]::IsNullOrWhiteSpace($Assunto)) { $Assunto = 'turno em curso' }
    $estado = 'ONLINE'
    if (-not [string]::IsNullOrWhiteSpace($Precisa)) { $estado = $Precisa.ToUpper() }
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $linha = "$ts | $who | $estado | $Assunto"
    $path = Join-Path $Equipe 'PRESENCA.md'
    if (-not (Test-Path -LiteralPath $path)) {
        throw 'PRESENCA.md inexistente no canal.'
    }
    Add-Block -Path $path -Block ("`r`n" + $linha + "`r`n")
    Add-Audit -Who $who -What "ping -> $estado ($Assunto)"
    Write-Output "OK: presenca registada por $who :: $estado :: $Assunto"
}

# ---------------------------------------------------------------------------
# 5. Despacho
# ---------------------------------------------------------------------------
switch ($Cmd) {
   'help' { Show-Help }
   'status' { Show-Status -Who $Agent }
   'post' { Show-Post }
   'read' { Show-Read -Who $Agent -Lines $Tail }
   'ask' { Show-Ask }
   'answer' { Show-Answer }
   'id' { Show-Id }
   'lock' { Show-Lock }
   'check' { Show-Check }
   'log' { Show-Log -Lines $Tail }
   'note' { Show-Note }
    'ping' { Show-Ping }
}
