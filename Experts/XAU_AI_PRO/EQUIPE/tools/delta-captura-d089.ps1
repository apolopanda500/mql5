# ============================================================
# delta-captura-d089.ps1
# Captura da janela forward D-089 - SOMENTE LEITURA.
# Autor: DELTA - 08/11/2026
#
# Le MQL5\Logs\<dia>.log e separa, por simbolo:
#   Q079              -> TREND CONTRA OK que contenham "dentro da folga"
#                        (UNICO criterio que prova o Q-079/B)
#   TREND_OK_FALLBACK -> TREND CONTRA OK por "contramao PERMITIDA"
#                        (NAO conta para o Q-079/B)
#   VETO_ADX          -> contramao vetada | ADX indisponivel (fix D-086)
#   SCORE             -> [SCORE] CALCULATED com PTS= / TOTAL=
#   IA_ON / IA_OFF    -> [AI] PYTHON vs [AI] INDISPONIVEL
#
# Nao compila, nao reanexa, nao envia ordem, nao escreve no EA.
# Nao altera GATE_REAL, IDS, PENDENCIAS, PRESENCA nem SYNC_LOG.
#
# Uso:
#   powershell -NoProfile -ExecutionPolicy Bypass -File `
#     "EQUIPE\tools\delta-captura-d089.ps1" -Dia 20261109
# ============================================================

[CmdletBinding()]
param(
   [string]$Dia = (Get-Date -Format 'yyyyMMdd'),
   [string]$LogsDir = ''
)

$ErrorActionPreference = 'Stop'

if([string]::IsNullOrWhiteSpace($LogsDir))
{
   # tools -> EQUIPE -> XAU_AI_PRO -> Experts -> MQL5
   $LogsDir = Join-Path $PSScriptRoot '..\..\..\..\Logs'
}

$LogsDir = (Resolve-Path -LiteralPath $LogsDir).Path
$log     = Join-Path $LogsDir ($Dia + '.log')

Write-Host ''
Write-Host '=== CAPTURA D-089 | DELTA | somente leitura ==='
Write-Host ("dia       : " + $Dia)
Write-Host ("log       : " + $log)

if(-not (Test-Path -LiteralPath $log))
{
   Write-Host ''
   Write-Host 'RESULTADO: log do dia inexistente.'
   Write-Host 'Se o dia ainda nao comecou, isto e o esperado (forward arranca 09/11 00:05).'
   exit 2
}

$info = Get-Item -LiteralPath $log
Write-Host ("bytes     : " + $info.Length)
Write-Host ("mtime     : " + $info.LastWriteTime)

# ---------- leitura ----------
$linhas = Get-Content -LiteralPath $log

function Get-Simbolo([string]$msg, [string]$src)
{
   $m = [regex]::Match($msg, 'Symbol=([A-Za-z0-9]+)')
   if($m.Success){ return $m.Groups[1].Value }

   $m = [regex]::Match($src, '\(([A-Za-z0-9]+),\s*(M\d+|H\d+|D1|W1|MN1)\)')
   if($m.Success){ return $m.Groups[1].Value + ',' + $m.Groups[2].Value }

   return '?'
}

$dados = @{}   # simbolo -> hashtable de contadores

function Inc([string]$sym, [string]$key)
{
   if(-not $script:dados.ContainsKey($sym))
   {
      $script:dados[$sym] = @{ Q079 = 0; TREND_OK_FALLBACK = 0; VETO_ADX = 0; SCORE = 0; IA_ON = 0; IA_OFF = 0 }
   }
   $script:dados[$sym][$key]++
}

$semTick    = 0
$primeira   = $null
$ultima     = $null
$scoreLinhas = New-Object System.Collections.ArrayList

foreach($l in $linhas)
{
   if([string]::IsNullOrWhiteSpace($l)){ continue }

   $campos = $l -split "`t"
   if($campos.Count -lt 5){ continue }

   $hora = $campos[2]
   $src  = $campos[3]
   $msg  = $campos[4]

   if($null -eq $primeira){ $primeira = $hora }
   $ultima = $hora

   # NOTA: nao usar -like com '[...]' - em PowerShell o bracket e' classe de
   # caracteres e '[AI]' casaria 'A ' ou 'I ', nao o literal. Usar Contains.
   if($msg.Contains('sem tick')){ $semTick++ }

   $sym = Get-Simbolo $msg $src

   if($msg.Contains('TREND CONTRA OK'))
   {
      if($msg.Contains('dentro da folga')){ Inc $sym 'Q079' }
      else                                { Inc $sym 'TREND_OK_FALLBACK' }
      continue
   }

   if($msg.Contains('ADX indisponivel')){ Inc $sym 'VETO_ADX'; continue }

   if($msg.Contains('SCORE] CALCULATED') -or $msg.Contains('SCORE CALCULATED'))
   {
      Inc $sym 'SCORE'
      [void]$scoreLinhas.Add($msg)
      continue
   }

   if($msg.Contains('[AI] PYTHON'))      { Inc $sym 'IA_ON';  continue }
   if($msg.Contains('[AI] INDISPONIVEL')){ Inc $sym 'IA_OFF'; continue }
}

# ---------- resumo ----------
Write-Host ''
Write-Host '=== JANELA COBERTA ==='
Write-Host ("primeira linha : " + $primeira)
Write-Host ("ultima linha   : " + $ultima)
Write-Host ("linhas         : " + $linhas.Count)
Write-Host ("'sem tick'     : " + $semTick)

Write-Host ''
Write-Host '=== POR SIMBOLO ==='
if($dados.Count -eq 0)
{
   Write-Host 'nenhum evento dos padroes procurados neste dia.'
}
else
{
   $dados.GetEnumerator() |
      Sort-Object Name |
      Select-Object @{n='Simbolo';e={$_.Name}},
                    @{n='Q079';e={$_.Value.Q079}},
                    @{n='Fallback';e={$_.Value.TREND_OK_FALLBACK}},
                    @{n='VetoADX';e={$_.Value.VETO_ADX}},
                    @{n='Score';e={$_.Value.SCORE}},
                    @{n='IA_ON';e={$_.Value.IA_ON}},
                    @{n='IA_OFF';e={$_.Value.IA_OFF}} |
      Format-Table -AutoSize
}

$totQ079 = 0; $totFb = 0; $totVeto = 0; $totScore = 0
foreach($k in $dados.Keys)
{
   $totQ079  += $dados[$k].Q079
   $totFb    += $dados[$k].TREND_OK_FALLBACK
   $totVeto  += $dados[$k].VETO_ADX
   $totScore += $dados[$k].SCORE
}

Write-Host '=== TOTAIS ==='
Write-Host ("Q-079/B exercitado (dentro da folga) : " + $totQ079)
Write-Host ("TREND CONTRA OK por fallback         : " + $totFb)
Write-Host ("veto ADX indisponivel                : " + $totVeto)
Write-Host ("[SCORE] CALCULATED                   : " + $totScore)

Write-Host ''
Write-Host '=== VEREDITO DO INSTRUMENTO ==='
if($totQ079 -gt 0)
{
   Write-Host 'Q-079/B EXERCITADO - a folga ATR disparou e ha prova em log.'
}
elseif($totFb -gt 0)
{
   Write-Host 'ATENCAO: houve TREND CONTRA OK, mas 100% por fallback.'
   Write-Host '         Isto NAO prova o Q-079/B. Nao promover por este numero.'
}
else
{
   Write-Host 'Nenhum TREND CONTRA OK no dia. Gate nao exercitado.'
}

if($totScore -gt 0)
{
   Write-Host ''
   Write-Host '=== [SCORE] CALCULATED (amostras) ==='
   $scoreLinhas | Select-Object -First 20 | ForEach-Object { Write-Host ('  ' + $_) }
}
else
{
   Write-Host ''
   Write-Host 'Sem [SCORE] CALCULATED: PTS=/TOTAL= nao amostrados neste dia (gate 1x/15min).'
}

Write-Host ''
Write-Host 'Lembrete: forward 0 de 30 dias; GATE_REAL 2 de 11; nao existe 10/10.'
Write-Host '=== fim ==='
