# equipe-watch.ps1 - comunicacao em tempo real entre ALFA / DELTA / CMD

param(
    [int]$Segundos = 60,
    [switch]$Quem
)

$ErrorActionPreference = 'Stop'

if ($PSScriptRoot -ne '') {
    $Root = Split-Path $PSScriptRoot -Parent
} else {
    $Root = (Get-Location).Path
}
if (-not (Test-Path -LiteralPath $Root)) { Write-Output "ERRO: raiz nao existe :: $Root"; exit 1 }
$Root = (Resolve-Path -LiteralPath $Root).Path

$watchFiles = @('INBOX_AGENTE_1.md','INBOX_AGENTE_2.md','INBOX_AGENTE_3.md','INBOX_DONO.md','PEDIDOS.md','LOCK.md','PRESENCA.md')

function Show-Quem {
    $p = Join-Path $Root 'PRESENCA.md'
    if (-not (Test-Path -LiteralPath $p)) { Write-Output 'PRESENCA.md inexistente.'; return }
    $lines = [System.IO.File]::ReadAllLines($p, [System.Text.Encoding]::UTF8) | Where-Object { $_ -match '\|\s*(ALFA|DELTA|CMD|DONO)\s*\|' }
    Write-Output '===== PRESENCA (ultimas por agente) ====='
    foreach ($ag in @('ALFA','DELTA','CMD','DONO')) {
        $last = $lines | Where-Object { $_ -match "\|\s*$ag\s*\|" } | Select-Object -Last 1
        if ($last) { Write-Output $last } else { Write-Output "$ag :: sem registo" }
    }
    Write-Output '========================================='
}

if ($Quem) { Show-Quem; exit 0 }

$state = @{}
foreach ($f in $watchFiles) {
    $fp = Join-Path $Root $f
    if (Test-Path -LiteralPath $fp) {
        $state[$f] = (Get-Item -LiteralPath $fp).Length
    } else {
        $state[$f] = 0
    }
}

Write-Output "equipe-watch: a monitorizar $Root durante $Segundos s. Ctrl+C para parar."
Write-Output "Ficheiros: $($watchFiles -join ', ')"

$end = (Get-Date).AddSeconds($Segundos)
while ((Get-Date) -lt $end) {
    Start-Sleep -Milliseconds 500
    foreach ($f in $watchFiles) {
        $fp = Join-Path $Root $f
        if (-not (Test-Path -LiteralPath $fp)) { continue }
        $len = (Get-Item -LiteralPath $fp).Length
        if ($len -gt $state[$f]) {
            $state[$f] = $len
            $ts = Get-Date -Format 'HH:mm:ss'
            Write-Output "[$ts] MUDANCA :: $f (agora $len bytes)"
            if ($f -like 'INBOX_*') {
                $txt = [System.IO.File]::ReadAllText($fp, [System.Text.Encoding]::UTF8)
                $abertos = ([regex]::Matches($txt, 'estado:\s*\*{0,2}\s*(ABERTO|PEDIDO|BLOQUEADO)', 'IgnoreCase')).Count
                Write-Output "            pedidos abertos neste inbox: $abertos"
            }
            if ($f -eq 'LOCK.md') {
                $lock = [System.IO.File]::ReadAllText($fp, [System.Text.Encoding]::UTF8)
                if ($lock -match 'OCUPADO') {
                    $dono = ''; $motivo = ''
                    if ($lock -match 'Dono:\*\*\s*(.+)') { $dono = $Matches[1].Trim() }
                    if ($lock -match 'Motivo:\*\*\s*(.+)') { $motivo = $Matches[1].Trim() }
                    Write-Output "            LOCK OCUPADO por $dono :: $motivo"
                } else {
                    Write-Output '            LOCK livre'
                }
            }
            if ($f -eq 'PRESENCA.md') {
                $last = [System.IO.File]::ReadAllLines($fp, [System.Text.Encoding]::UTF8) | Where-Object { $_ -match '\|' } | Select-Object -Last 1
                if ($last) { Write-Output "            ultima presenca: $last" }
            }
        }
    }
}

Write-Output "equipe-watch: fim ($Segundos s)."
