# ordem-master.ps1 - a ordem do DONO: INICIAR / ESTADO / FINALIZAR
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\ordem-master.ps1 iniciar
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\ordem-master.ps1 estado
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\ordem-master.ps1 finalizar
#
# BASE: D-095 / D-096 / ORDEM_MASTER.md / MANDATO_ATIVO.json
#
# O que este script NAO faz, por desenho:
#   - nao abre ordens, nao altera risco, nao toca em inputs nem em graficos;
#   - nao liga conta real;
#   - nao escreve "10/10" como estado;
#   - nao fecha o projecto: no maximo prepara o DOSSIE_FINAL.md para o DELTA
#     assinar. Quem assina e' quem mediu, nao quem entrega.
#
# "iniciar" arranca infraestrutura e verifica o mandato. "finalizar" so fecha
# com 11/11 + 30 dias + assinatura do DELTA + nenhuma paragem ativa.

param(
   [ValidateSet('iniciar', 'estado', 'finalizar')]
   [string]$Acao = 'estado'
)

$ErrorActionPreference = 'Stop'

$Equipe   = Split-Path -Parent $PSScriptRoot
$Mql5     = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Equipe))
$Tools    = $PSScriptRoot
$Mandato  = Join-Path $Equipe 'MANDATO_ATIVO.json'
$Gate     = Join-Path $Equipe 'GATE_REAL.md'
$RelDir   = Join-Path $Equipe 'RELATORIOS'
$EstadoPath = Join-Path $Equipe 'ORDEM_MASTER_ESTADO.json'
$Dossie   = Join-Path $Equipe 'DOSSIE_FINAL.md'
$DonoPs1  = Join-Path $Tools 'dono-mandato.ps1'
$GwPs1    = Join-Path $Tools 'gateway-start.ps1'
$SyncPs1  = Join-Path $Tools 'sync-agent.ps1'
$Utf8     = New-Object System.Text.UTF8Encoding($false)

function Write-LF([string]$Path, [string]$Text) {
   [System.IO.File]::WriteAllText($Path, $Text.Replace("`r`n", "`n").Replace("`r", "`n"), $Utf8)
}

function Get-Gate {
   $m = [regex]::Match((Get-Content -LiteralPath $Gate -Raw -Encoding UTF8), '(\d+)\s+verdes\s+de\s+(\d+)')
   if ($m.Success) { return [pscustomobject]@{ Verdes = [int]$m.Groups[1].Value; Total = [int]$m.Groups[2].Value } }
   return [pscustomobject]@{ Verdes = -1; Total = 11 }
}

function Get-Forward($M) {
   $ini = $M.decisoes.forward.inicio_medido
   if (-not $ini) { return [pscustomobject]@{ Inicio = $null; Dias = 0; Alvo = [int]$M.decisoes.forward.dias } }
   if (-not (Test-Path -LiteralPath $RelDir)) { return [pscustomobject]@{ Inicio = $ini; Dias = 0; Alvo = [int]$M.decisoes.forward.dias } }
   $d0 = [datetime]::ParseExact($ini, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
   $dias = @(Get-ChildItem -LiteralPath $RelDir -Filter '*.md' -File | ForEach-Object {
      $d = [datetime]::MinValue
      if ([datetime]::TryParseExact($_.BaseName, 'yyyyMMdd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$d)) {
         if ($d -ge $d0 -and $d.DayOfWeek -ne 'Saturday' -and $d.DayOfWeek -ne 'Sunday') { $d }
      }
   } | Sort-Object -Unique).Count
   return [pscustomobject]@{ Inicio = $ini; Dias = $dias; Alvo = [int]$M.decisoes.forward.dias }
}

function Get-Binario {
   $ea  = Join-Path $Mql5 'Experts\XAU_AI_PRO'
   $ex5 = Join-Path $ea 'XAU_AI_PRO.ex5'
   if (-not (Test-Path -LiteralPath $ex5)) { return 'AUSENTE' }
   $bin = Get-Item -LiteralPath $ex5
   $novo = Get-ChildItem -LiteralPath $ea -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Extension -eq '.mq5' -or $_.Extension -eq '.mqh' } |
      Sort-Object LastWriteTime -Descending | Select-Object -First 1
   if ($novo -and $novo.LastWriteTime -gt $bin.LastWriteTime) { return 'FONTE MAIS NOVA' }
   return 'BATEM'
}

function Get-Gateway {
   # /api/health devolve 401 sem token e 404 com token: qualquer resposta HTTP
   # prova servidor vivo. -SkipHttpErrorCheck nao existe em PS 5.1 (P1.3488).
   $tcp = $null
   try {
      $tcp = New-Object System.Net.Sockets.TcpClient
      $iar = $tcp.BeginConnect('127.0.0.1', 9011, $null, $null)
      if (-not $iar.AsyncWaitHandle.WaitOne(3000, $false)) { return 'DOWN' }
      $tcp.EndConnect($iar)
   }
   catch { return 'DOWN' }
   finally { if ($tcp) { try { $tcp.Close() } catch { } } }
   try {
      $r = Invoke-WebRequest -Uri 'http://127.0.0.1:9011/api/health' -TimeoutSec 4 -UseBasicParsing
      if ($r.StatusCode -eq 200 -or $r.StatusCode -eq 401 -or $r.StatusCode -eq 404) { return 'OK' }
      return "HTTP $($r.StatusCode)"
   }
   catch {
      $resp = $_.Exception.Response
      if ($resp -and $resp.StatusCode) { return "HTTP $([int]$resp.StatusCode)" }
      return 'OK'
   }
}

function Ensure-Tarefas {
   $defs = @(
      @{ Nome = 'XAU_AI_PRO_DonoRelatorio';     Cmd = ('powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}" relatorio' -f $DonoPs1); Extra = @('/SC', 'DAILY', '/ST', '23:50') },
      @{ Nome = 'XAU_AI_PRO_GatewayKeepalive';   Cmd = ('powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}"' -f $GwPs1); Extra = @('/SC', 'MINUTE', '/MO', '5') },
      @{ Nome = 'XAU_AI_PRO_ForwardInicio';      Cmd = ('powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}" iniciar -Data 2026-11-09' -f $DonoPs1); Extra = @('/SC', 'ONCE', '/SD', '09/11/2026', '/ST', '00:05') }
   )
   $resultado = @()
   foreach ($d in $defs) {
      $t = Get-ScheduledTask -TaskName $d.Nome -ErrorAction SilentlyContinue
      if ($t) {
         $resultado += [pscustomobject]@{ Tarefa = $d.Nome; Estado = 'JA_EXISTE' }
         continue
      }
      $argList = @('/Create', '/TN', $d.Nome, '/TR', $d.Cmd, '/F') + $d.Extra
      $out = & schtasks.exe @argList 2>&1
      if ($LASTEXITCODE -eq 0) { $resultado += [pscustomobject]@{ Tarefa = $d.Nome; Estado = 'CRIADA' } }
      else { $resultado += [pscustomobject]@{ Tarefa = $d.Nome; Estado = 'FALHOU' } }
   }
   return $resultado
}

function Show-Checklist {
   Write-Output ''
   Write-Output 'CHECKLIST DOS AGENTES (a partir de agora, sem consultar o DONO)'
   Write-Output '  ALFA  : fechar G3-G8 com medicao; compile so por compile-ea.ps1 (backup antes);'
   Write-Output '          corrigir P1 dentro do mandato; nao parar por atraso corrigivel.'
   Write-Output '  DELTA : medir todos os dias com mercado aberto ([SCORE], [CENARIO],'
   Write-Output '          TREND CONTRA OK, com IA vs sem IA); separar manual do EA;'
   Write-Output '          assinar DOSSIE_FINAL.md so com 11/11 + 30 dias.'
   Write-Output '  CMD   : gateway, tarefas, canal, git, CI; correr ordem-master quando o DONO der a ordem.'
   Write-Output '  DONO  : escreve INICIAR / ESTADO / FINALIZAR. Nada mais.'
   Write-Output ''
   Write-Output 'PROIBIDO A TODOS: 10/10 como estado; conta real sem os 4 requisitos;'
   Write-Output 'tocar em risco; remover guarda; chamar o DONO durante a execucao.'
}

function Show-Estado {
   $M = Get-Content -LiteralPath $Mandato -Raw -Encoding UTF8 | ConvertFrom-Json
   $g = Get-Gate
   $f = Get-Forward $M
   $b = Get-Binario
   $gw = Get-Gateway
   $tarefas = @(Get-ScheduledTask -TaskName 'XAU_AI_PRO_*' -ErrorAction SilentlyContinue)

   Write-Output ''
   Write-Output '===== ORDEM MASTER - ESTADO ====='
   Write-Output ("hora            : {0:dd/MM/yyyy HH:mm:ss}" -f (Get-Date))
   Write-Output ("GATE_REAL       : {0} de {1}   <-- nao existe 10/10" -f $g.Verdes, $g.Total)
   Write-Output ("forward         : {0} de {1} dias medidos" -f $f.Dias, $f.Alvo)
   if ($f.Inicio) { Write-Output ("inicio forward  : {0}" -f $f.Inicio) }
   else { Write-Output ("inicio forward  : ainda nao medido (previsto {0})" -f $M.decisoes.forward.inicio_previsto) }
   Write-Output ("gateway 9011    : {0} (modo {1})" -f $gw, $M.decisoes.gateway.modo)
   Write-Output ("binario x fonte : {0}" -f $b)
   Write-Output ("tarefas ativas  : {0} ({1})" -f $tarefas.Count, (($tarefas | ForEach-Object { $_.TaskName }) -join ', '))
   Write-Output ("mandato         : {0} | {1}" -f $M.estado, $M.decisao)
   $falta = @()
   if ($g.Verdes -lt $g.Total) { $falta += ("gate {0}" -f ($g.Total - $g.Verdes)) }
   if ($f.Dias -lt $f.Alvo) { $falta += ("{0} dias forward" -f ($f.Alvo - $f.Dias)) }
   $falta += 'assinatura DELTA'
   Write-Output ("falta           : {0}" -f ($falta -join ' + '))
   Write-Output '================================='
   Write-Output ''
}

function Start-Ordem {
   Write-Output ''
   Write-Output '===== INICIAR - ordem do DONO ====='
   $erros = New-Object System.Collections.Generic.List[string]

   # 1. mandato
   & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $DonoPs1 check | Out-Null
   $checkOk = ($LASTEXITCODE -eq 0)
   Write-Output ("1. mandato           : {0}" -f $(if ($checkOk) { 'OK' } else { 'VIOLADO' }))
   if (-not $checkOk) {
      Write-Output '   INICIAR cancelado: corrigir o mandato antes de arrancar.'
      exit 1
   }

   # 2. ficheiros base
   $base = @('FICHA_DONO.md', 'MANUAL_DONO.md', 'MANDATO_ATIVO.json', 'GATE_REAL.md', 'ORDEM_MASTER.md')
   $faltaBase = @($base | Where-Object { -not (Test-Path -LiteralPath (Join-Path $Equipe $_)) })
   Write-Output ("2. ficheiros base    : {0}" -f $(if ($faltaBase.Count -eq 0) { 'OK' } else { 'FALTA ' + ($faltaBase -join ', ') }))
   if ($faltaBase.Count -gt 0) { $erros.Add('ficheiros base em falta') }

   # 3. gateway
   $gw = Get-Gateway
   if ($gw -ne 'OK') {
      & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $GwPs1 | Out-Null
      Start-Sleep -Seconds 2
      $gw = Get-Gateway
   }
   Write-Output ("3. gateway 9011      : {0}" -f $gw)
   if ($gw -ne 'OK') { $erros.Add('gateway nao responde') }

   # 4. tarefas
   $t = Ensure-Tarefas
   $okT = @($t | Where-Object { $_.Estado -ne 'FALHOU' }).Count
   Write-Output ("4. tarefas Windows   : {0} de 3 prontas" -f $okT)
   foreach ($x in $t) { Write-Output ("     {0,-32} {1}" -f $x.Tarefa, $x.Estado) }
   if ($okT -lt 3) { $erros.Add('tarefa do Windows em falta') }

   # 5. canal
   $canalSaida = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SyncPs1 check 2>&1
   $canalOk = ($LASTEXITCODE -eq 0) -and (($canalSaida -join "`n") -match 'RESULTADO\s*:\s*OK')
   Write-Output ("5. canal            : {0}" -f $(if ($canalOk) { 'OK' } else { 'COM PROBLEMAS' }))
   if (-not $canalOk) { $erros.Add('canal com problemas') }

   # 6. binario
   $b = Get-Binario
   Write-Output ("6. binario x fonte  : {0}" -f $b)
   if ($b -eq 'AUSENTE' -or $b -eq 'FONTE MAIS NOVA') { $erros.Add('binario nao corresponde a fonte - recompilar com compile-ea.ps1') }

   $M = Get-Content -LiteralPath $Mandato -Raw -Encoding UTF8 | ConvertFrom-Json
   $payload = [ordered]@{
      ordem          = 'INICIAR'
      hora           = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
      mandato_ok     = $checkOk
      gateway        = $gw
      tarefas        = @($t | ForEach-Object { [ordered]@{ tarefa = $_.Tarefa; estado = $_.Estado } })
      canal_ok       = $canalOk
      binario_fonte  = $b
      gate_verdes    = (Get-Gate).Verdes
      gate_total     = (Get-Gate).Total
      forward_dias   = (Get-Forward $M).Dias
      forward_alvo   = (Get-Forward $M).Alvo
      paragem_ativa  = $false
      erros          = @($erros)
   }
   try { Write-LF $EstadoPath ($payload | ConvertTo-Json -Depth 8); Write-Output ("   estado gravado    : {0}" -f $EstadoPath) } catch { Write-Output ("   ERRO ao gravar estado: {0}" -f $_.Exception.Message) }

   Show-Checklist

   if ($erros.Count -eq 0) {
      Write-Output ''
      Write-Output 'RESULTADO: INICIADO - infraestrutura pronta e mandato intacto.'
      Write-Output 'O DONO nao tem de fazer mais nada. Relatorio diario as 23:50.'
      Write-Output '============================'
      exit 0
   }
   Write-Output ''
   Write-Output ("RESULTADO: INICIADO COM {0} PENDENCIA(S) - o DONO nao precisa de agir; os agentes corrigem:" -f $erros.Count)
   foreach ($e in $erros) { Write-Output ('  - ' + $e) }
   Write-Output '============================'
   exit 2
}

function Stop-Ordem {
   Write-Output ''
   Write-Output '===== FINALIZAR - pedido do DONO ====='
   $M = Get-Content -LiteralPath $Mandato -Raw -Encoding UTF8 | ConvertFrom-Json
   $g = Get-Gate
   $f = Get-Forward $M

   $assinado = $false
   if (Test-Path -LiteralPath $Dossie) {
      $assinado = ((Get-Content -LiteralPath $Dossie -Raw -Encoding UTF8) -match 'ASSINADO POR DELTA')
   }
   $paragem = $false
   if (Test-Path -LiteralPath $EstadoPath) {
      try { $paragem = [bool]((Get-Content -LiteralPath $EstadoPath -Raw -Encoding UTF8 | ConvertFrom-Json).paragem_ativa) } catch { $paragem = $false }
   }

   $okGate = ($g.Verdes -eq $g.Total)
   $okFwd  = ($f.Dias -ge $f.Alvo)

   Write-Output ("gate         : {0} de {1} ({2})" -f $g.Verdes, $g.Total, $(if ($okGate) { 'OK' } else { 'FALTA' }))
   Write-Output ("forward      : {0} de {1} dias ({2})" -f $f.Dias, $f.Alvo, $(if ($okFwd) { 'OK' } else { 'FALTA' }))
   Write-Output ("assinatura   : {0}" -f $(if ($assinado) { 'DELTA ASSINOU' } else { 'FALTA' }))
   Write-Output ("paragem      : {0}" -f $(if ($paragem) { 'ATIVA - nao fecha' } else { 'nenhuma' }))

   if (-not ($okGate -and $okFwd -and $assinado) -or $paragem) {
      Write-Output ''
      Write-Output 'RESULTADO: NAO FECHA - falta prova. Nada foi alterado.'
      Write-Output ("  - {0} criterio(s) do GATE_REAL" -f [Math]::Max(0, $g.Total - $g.Verdes))
      Write-Output ("  - {0} dia(s) de forward com medicao" -f [Math]::Max(0, $f.Alvo - $f.Dias))
      if (-not $assinado) { Write-Output '  - assinatura do DELTA em DOSSIE_FINAL.md' }
      if ($paragem) { Write-Output '  - paragem automatica ativa: causa tem de ser registada e resolvida' }
      Write-Output '============================'
      exit 1
   }

   # Os quatro requisitos existem: prepara o dossie (o CMD nao assina).
   if (-not (Test-Path -LiteralPath $Dossie)) {
      $linhas = @(
         '# DOSSIE FINAL - XAU_AI_PRO',
         '',
         ("Gerado por ``ordem-master.ps1 finalizar`` em {0:dd/MM/yyyy HH:mm}." -f (Get-Date)),
         '',
         '## Medicao',
         '',
         '| Item | Valor |',
         '|---|---|',
         ("| GATE_REAL | {0} de {1} |" -f $g.Verdes, $g.Total),
         ("| Forward | {0} de {1} dias |" -f $f.Dias, $f.Alvo),
         ("| Inicio do forward | {0} |" -f $f.Inicio),
         ("| Gateway | {0} |" -f (Get-Gateway)),
         ("| Binario x fonte | {0} |" -f (Get-Binario)),
         '',
         '## Assinatura',
         '',
         'Este dossie so vale com a linha abaixo preenchida pelo DELTA, que e quem mediu.',
         '',
         'ASSINADO POR DELTA: ____________________  data: __________',
         ''
      )
      Write-LF $Dossie ($linhas -join "`n")
      Write-Output ''
      Write-Output ("RESULTADO: REQUISITOS CUMPRIDOS - dossie criado em {0}" -f $Dossie)
      Write-Output 'Falta a assinatura do DELTA. O CMD nao assina o que nao mediu.'
      Write-Output '============================'
      exit 0
   }

   Write-Output ''
   Write-Output 'RESULTADO: FECHADO - 11/11 + 30 dias + assinatura do DELTA + sem paragem.'
   Write-Output 'A autorizacao condicional de conta real passa a valer. O DONO decide o dia.'
   Write-Output '============================'
   exit 0
}

switch ($Acao) {
   'iniciar'   { Start-Ordem }
   'estado'    { Show-Estado }
   'finalizar' { Stop-Ordem }
}
