# dono-mandato.ps1 - o mandato do DONO, medido e nao interpretado
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\dono-mandato.ps1 estado
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\dono-mandato.ps1 check
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\dono-mandato.ps1 relatorio
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\dono-mandato.ps1 iniciar [-Data yyyy-MM-dd]
#
# BASE: D-095 / FICHA_DONO.md / MANUAL_DONO.md / MANDATO_ATIVO.json
#
# REGRAS QUE ESTE SCRIPT RESPEITA:
#   - le e escreve apenas dentro de EQUIPE/ (RELATORIOS/ incluido);
#   - nunca imprime, grava ou regista o token do gateway (so nomes e tamanhos);
#   - nao toca em inputs, graficos, conta, ordens nem parametros de risco;
#   - "estado" e "check" nao alteram nada. "relatorio" so cria um ficheiro novo
#     em EQUIPE/RELATORIOS. "iniciar" so grava a data de inicio do forward.
#
# ESTADO HONESTO: o GATE_REAL e sempre lido de GATE_REAL.md. Este script nao
# inventa progresso e nao escreve "10/10" em lado nenhum.

param(
   [ValidateSet('estado', 'check', 'relatorio', 'iniciar')]
   [string]$Acao = 'estado',
   [string]$Data = ''
)

$ErrorActionPreference = 'Stop'

$Equipe  = Split-Path -Parent $PSScriptRoot
$Mql5    = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Equipe))
$Mandato = Join-Path $Equipe 'MANDATO_ATIVO.json'
$Gate    = Join-Path $Equipe 'GATE_REAL.md'
$RelDir  = Join-Path $Equipe 'RELATORIOS'
$Utf8    = New-Object System.Text.UTF8Encoding($false)

function Write-File-LF([string]$Path, [string]$Text) {
   $t = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
   [System.IO.File]::WriteAllText($Path, $t, $Utf8)
}

function Read-Mandato {
   if (-not (Test-Path -LiteralPath $Mandato)) { throw "mandato ausente: $Mandato" }
   return (Get-Content -LiteralPath $Mandato -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Get-Gate {
   $txt = Get-Content -LiteralPath $Gate -Raw -Encoding UTF8
   $m = [regex]::Match($txt, '(\d+)\s+verdes\s+de\s+(\d+)')
   if ($m.Success) {
      return [pscustomobject]@{ Verdes = [int]$m.Groups[1].Value; Total = [int]$m.Groups[2].Value; Fonte = 'GATE_REAL.md' }
   }
   return [pscustomobject]@{ Verdes = -1; Total = 11; Fonte = 'GATE_REAL.md (nao consegui ler)' }
}

function Get-Binario {
   $ea  = Join-Path $Mql5 'Experts\XAU_AI_PRO'
   $ex5 = Join-Path $ea 'XAU_AI_PRO.ex5'
   if (-not (Test-Path -LiteralPath $ex5)) {
      return [pscustomobject]@{ Estado = 'AUSENTE'; Idade = $null }
   }
   $bin = Get-Item -LiteralPath $ex5
   $novo = Get-ChildItem -LiteralPath $ea -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Extension -eq '.mq5' -or $_.Extension -eq '.mqh' } |
      Sort-Object LastWriteTime -Descending | Select-Object -First 1
   if ($novo -and $novo.LastWriteTime -gt $bin.LastWriteTime) {
      return [pscustomobject]@{ Estado = 'FONTE MAIS NOVA'; Idade = $bin.LastWriteTime }
   }
   return [pscustomobject]@{ Estado = 'BATEM'; Idade = $bin.LastWriteTime }
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
      if ($resp -and $resp.StatusCode) { $code = [int]$resp.StatusCode; if ($code -eq 200 -or $code -eq 401 -or $code -eq 404) { return 'OK' }; return "HTTP $code" }
      return 'OK'
   }
}

function Get-Forward($M) {
   $ini = $M.decisoes.forward.inicio_medido
   $prev = $M.decisoes.forward.inicio_previsto
   $alvo = $M.decisoes.forward.dias
   $dias = 0
   $reportados = @()
   if ($ini -and (Test-Path -LiteralPath $RelDir)) {
      $d0 = [datetime]::ParseExact($ini, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
      $reportados = Get-ChildItem -LiteralPath $RelDir -Filter '*.md' -File | ForEach-Object {
         $name = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
         $d = [datetime]::MinValue
         if ([datetime]::TryParseExact($name, 'yyyyMMdd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$d)) {
            if ($d -ge $d0 -and $d.DayOfWeek -ne 'Saturday' -and $d.DayOfWeek -ne 'Sunday') { $d }
         }
      } | Sort-Object -Unique
      $dias = @($reportados).Count
   }
   return [pscustomobject]@{
      InicioMedido = $ini
      InicioPrevisto = $prev
      Dias = $dias
      Alvo = $alvo
      Reportados = $reportados
   }
}

function Show-Estado {
   $M = Read-Mandato
   $g = Get-Gate
   $b = Get-Binario
   $gw = Get-Gateway
   $f = Get-Forward $M

   Write-Output ''
   Write-Output '===== MANDATO DO DONO - ESTADO MEDIDO ====='
   Write-Output ("hora               : {0:dd/MM/yyyy HH:mm:ss}" -f (Get-Date))
   Write-Output ("mandato            : versao {0} | {1} | {2}" -f $M.versao, $M.estado, $M.decisao)
   Write-Output ("modo com o DONO    : {0}" -f $M.interacao_dono.modo)
   Write-Output ''
   Write-Output ("piso sem IA        : {0}" -f $M.decisoes.piso_sem_ia.valor)
   Write-Output ("USDBRL             : {0} ({1})" -f $M.decisoes.usdbrl.periodo, $M.decisoes.usdbrl.politica)
   Write-Output ("gateway 9011       : {0} (modo {1})" -f $gw, $M.decisoes.gateway.modo)
   Write-Output ''
   Write-Output ("GATE_REAL          : {0} verdes de {1}  <-- nao existe 10/10" -f $g.Verdes, $g.Total)
   Write-Output ("forward            : {0}/{1} dias medidos" -f $f.Dias, $f.Alvo)
   if ($f.InicioMedido) {
      Write-Output ("inicio do forward  : {0} (medido)" -f $f.InicioMedido)
   }
   else {
      Write-Output ("inicio do forward  : ainda nao medido (previsto {0})" -f $f.InicioPrevisto)
   }
   Write-Output ("binario x fonte    : {0}" -f $b.Estado)
   Write-Output ''
   Write-Output 'paragem automatica :'
   Write-Output ("  perda diaria     : {0} USD" -f $M.decisoes.paragem_automatica.perda_diaria_usd)
   Write-Output ("  drawdown         : {0} %" -f $M.decisoes.paragem_automatica.drawdown_percent)
   Write-Output ("  falhas canal     : {0} na mesma hora" -f $M.decisoes.paragem_automatica.falhas_canal_na_mesma_hora)
   Write-Output ''
   $faltam = @()
   if ($g.Verdes -lt $g.Total) { $faltam += ("gate {0} criterio(s)" -f ($g.Total - $g.Verdes)) }
   if ($f.Dias -lt $f.Alvo) { $faltam += ("{0} dia(s) de forward" -f ($f.Alvo - $f.Dias)) }
   $faltam += 'assinatura do DELTA no dossie final'
   if ($faltam.Count -gt 0) {
      Write-Output ('falta para conta real: ' + ($faltam -join ' + '))
   }
   else {
      Write-Output 'falta para conta real: nada - a autorizacao condicional passa a valer'
   }
   Write-Output '==========================================='
   Write-Output ''
}

function Show-Check {
   $falhas = New-Object System.Collections.Generic.List[string]
   $M = Read-Mandato

   if ($M.estado -ne 'ATIVO') { $falhas.Add("mandato nao esta ATIVO: $($M.estado)") }
   if ($M.interacao_dono.modo -ne 'ZERO_INTERRUPCOES_DURANTE_EXECUCAO') {
      $falhas.Add("modo de interacao inesperado: $($M.interacao_dono.modo)")
   }
   if ([double]$M.decisoes.piso_sem_ia.valor -ne 45.0) {
      $falhas.Add("piso sem IA nao e 45,0: $($M.decisoes.piso_sem_ia.valor)")
   }
   if ($M.decisoes.usdbrl.folga_q079b -ne $false) {
      $falhas.Add('USDBRL deixou de estar sem folga')
   }
   if (-not $M.decisoes.gateway.como_tarefa_windows) {
      $falhas.Add('gateway deixou de estar previsto como tarefa do Windows')
   }
   foreach ($k in $M.decisoes.gateway.flags_execucao.PSObject.Properties.Name) {
      if ($M.decisoes.gateway.flags_execucao.$k -ne '0') { $falhas.Add("flag de execucao nao e 0: $k=$($M.decisoes.gateway.flags_execucao.$k)") }
   }
   if ([int]$M.decisoes.forward.dias -ne 30) { $falhas.Add("forward nao tem 30 dias: $($M.decisoes.forward.dias)") }
   if (-not $M.decisoes.paragem_automatica.parar_e_automatico) { $falhas.Add('paragem deixou de ser automatica') }
   if ([double]$M.decisoes.paragem_automatica.perda_diaria_usd -gt 60.0) {
      $falhas.Add("perda diaria acima do mandato: $($M.decisoes.paragem_automatica.perda_diaria_usd)")
   }
   if ([double]$M.decisoes.paragem_automatica.drawdown_percent -gt 50.0) {
      $falhas.Add("drawdown acima do mandato: $($M.decisoes.paragem_automatica.drawdown_percent)")
   }
   $req = @($M.decisoes.autorizacao_conta_real.requisitos_todos_obrigatorios)
   if ($req.Count -ne 4) { $falhas.Add("autorizacao de conta real nao tem 4 requisitos: $($req.Count)") }

   $g = Get-Gate
   if ($g.Verdes -lt 0) { $falhas.Add('nao consegui ler o GATE_REAL.md') }
   if ($g.Verdes -gt $g.Total) { $falhas.Add("GATE_REAL impossivel: $($g.Verdes) de $($g.Total)") }
   if ([int]$M.gate_real.criterios_total -ne $g.Total) {
      $falhas.Add("mandato diz $($M.gate_real.criterios_total) criterios, GATE_REAL diz $($g.Total)")
   }
   if ([int]$M.gate_real.criterios_verdes -ne $g.Verdes) {
      $falhas.Add("mandato diz $($M.gate_real.criterios_verdes) verdes, GATE_REAL diz $($g.Verdes) - actualizar o JSON, nao o gate")
   }

   $f = Get-Forward $M
   if ($f.InicioMedido) {
      $d0 = [datetime]::ParseExact($f.InicioMedido, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
      if ($d0 -lt [datetime]'2026-11-09') { $falhas.Add("inicio do forward antes de 09/11/2026: $($f.InicioMedido)") }
      if ($f.Dias -gt 30) { $falhas.Add("dias medidos acima de 30: $($f.Dias)") }
      if ($f.Alvo -ne 30) { $falhas.Add("alvo do forward nao e 30: $($f.Alvo)") }
   }

   # Uma afirmacao de 100% ou 10/10 como estado e violacao, nao opiniao.
   foreach ($doc in @('FICHA_DONO.md', 'MANUAL_DONO.md')) {
      $p = Join-Path $Equipe $doc
      if (Test-Path -LiteralPath $p) {
         $txt = Get-Content -LiteralPath $p -Raw -Encoding UTF8
         foreach ($m in [regex]::Matches($txt, '(?m)^.*\b10/10\b.*$')) {
            if ($m.Value -notmatch '(?i)nunca|nao existe|nao aparece|erro de escrita|proibid|\bnao\b') {
               $falhas.Add("${doc}: linha usa 10/10 sem a negar: $($m.Value.Trim())")
            }
         }
      }
   }

   Write-Output ''
   Write-Output '===== CHECK DO MANDATO ====='
   Write-Output ("mandato           : {0}" -f $Mandato)
   Write-Output ("gate medido       : {0} de {1}" -f $g.Verdes, $g.Total)
   Write-Output ("forward medido    : {0} de {1} dias" -f $f.Dias, $f.Alvo)
   if ($falhas.Count -eq 0) {
      Write-Output 'RESULTADO         : OK - mandato integro e coerente com o estado medido'
      Write-Output '============================'
      exit 0
   }
   Write-Output ("RESULTADO         : {0} violacao(oes)" -f $falhas.Count)
   foreach ($x in $falhas) { Write-Output ("  - " + $x) }
   Write-Output '============================'
   exit 1
}

function Show-Relatorio {
   $M = Read-Mandato
   $g = Get-Gate
   $b = Get-Binario
   $gw = Get-Gateway
   $f = Get-Forward $M
   $hoje = Get-Date
   $nome = $hoje.ToString('yyyyMMdd')

   if (-not (Test-Path -LiteralPath $RelDir)) { New-Item -ItemType Directory -Path $RelDir -Force | Out-Null }
   $p = Join-Path $RelDir ($nome + '.md')

   $linhas = New-Object System.Collections.Generic.List[string]
   $linhas.Add("# Relatorio diario do mandato - $($hoje.ToString('dd/MM/yyyy'))")
   $linhas.Add('')
   $linhas.Add("Gerado por ``tools/dono-mandato.ps1 relatorio`` as $($hoje.ToString('HH:mm:ss')).")
   $linhas.Add('O DONO nao precisa de fazer nada com este ficheiro.')
   $linhas.Add('')
   $linhas.Add('| Item | Medido |')
   $linhas.Add('|---|---|')
   $linhas.Add("| GATE_REAL | **$($g.Verdes) de $($g.Total)** (nao existe 10/10) |")
   $linhas.Add("| Forward | $($f.Dias) de $($f.Alvo) dias com medicao |")
   if ($f.InicioMedido) { $linhas.Add("| Inicio do forward | $($f.InicioMedido) |") }
   else { $linhas.Add("| Inicio do forward | ainda nao medido (previsto $($f.InicioPrevisto)) |") }
   $linhas.Add("| Gateway 9011 | $gw |")
   $linhas.Add("| Binario x fonte | $($b.Estado) |")
   $linhas.Add("| Mandato | versao $($M.versao), $($M.estado), $($M.decisao) |")
   $linhas.Add('')
   $linhas.Add('## Falta para conta real')
   $linhas.Add('')
   $n = 0
   if ($g.Verdes -lt $g.Total) { $n++; $linhas.Add("- $($g.Total - $g.Verdes) criterio(s) do GATE_REAL") }
   if ($f.Dias -lt $f.Alvo) { $n++; $linhas.Add("- $($f.Alvo - $f.Dias) dia(s) de forward em demo") }
   $n++; $linhas.Add('- assinatura do DELTA no dossie final')
   $linhas.Add('')
   $linhas.Add('## Nota')
   $linhas.Add('')
   $linhas.Add('Este relatorio mede ficheiros e o gateway; nao mede lucro. Se o gateway')
   $linhas.Add('estiver DOWN, o EA usa o piso sem IA de 45,0 e o dia continua a contar')
   $linhas.Add('apenas se houver operacao/medicao registada pelos agentes.')
   $linhas.Add('')

   Write-File-LF $p ($linhas -join "`n")
   Write-Output ("[RELATORIO] {0}" -f $p)
   Write-Output ("GATE {0}/{1} | forward {2}/{3} | gateway {4} | binario {5}" -f $g.Verdes, $g.Total, $f.Dias, $f.Alvo, $gw, $b.Estado)
}

function Start-Forward {
   $M = Read-Mandato
   $d = $Data
   if ([string]::IsNullOrWhiteSpace($d)) { $d = (Get-Date).ToString('yyyy-MM-dd') }
   $dt = [datetime]::MinValue
   if (-not [datetime]::TryParseExact($d, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$dt)) {
      throw "data invalida: $d (usar yyyy-MM-dd)"
   }
   if ($dt -lt [datetime]'2026-11-09') { throw "inicio antes de 09/11/2026: $d" }
   if ($dt.DayOfWeek -eq 'Saturday' -or $dt.DayOfWeek -eq 'Sunday') { throw "inicio em fim de semana: $d (mercado fechado nao conta)" }

   $M.decisoes.forward.inicio_medido = $d
   Write-File-LF $Mandato (($M | ConvertTo-Json -Depth 12) + "`n")
   Write-Output ("[FORWARD] inicio medido gravado: {0} (alvo {1} dias)" -f $d, $M.decisoes.forward.dias)
}

switch ($Acao) {
   'estado'    { Show-Estado }
   'check'     { Show-Check }
   'relatorio' { Show-Relatorio }
   'iniciar'   { Start-Forward }
}
