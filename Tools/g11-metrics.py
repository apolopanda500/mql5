#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""g11-metrics.py - metricas do G11 (forward de 30 dias) a partir do
stream de eventos do proprio EA.

FONTE DA VERDADE: `Files\\Data\\forward_test_events.csv` (UTF-16LE com BOM).
Cada `TRADE_CLOSE` traz `Value=profit=<valor>`: e o resultado realizado de
um ticket. O journal e a leitura humana disto; este ficheiro e a leitura de
maquina.

METRICAS POR DIA DO SERVIDOR (a partir de `janela_inicio`):
    trades   - TRADE_CLOSE no dia
    wins     - profit > 0
    losses   - profit < 0
    pf       - soma(ganhos) / |soma(perdas)|
    dd_usd   - queda maxima da curva de P/L acumulada (pico -> vale)
    dd_pct   - dd_usd / saldo de referencia x 100

O `GATE_REAL` exige PF >= 1.2, DD <= 8%, >= 30 trades e 0 violacoes de risco.

USO
    python Tools\\g11-metrics.py --janela 2026-11-11 --saida EQUIPE\\FORWARD\\trades.jsonl
    python Tools\\g11-metrics.py --janela 2026-11-11 --print
"""
from __future__ import annotations

import argparse
import collections
import csv
import datetime as dt
import json
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
MQL5 = os.path.dirname(AQUI)
EVENTOS = os.path.join(MQL5, 'Files', 'Data', 'forward_test_events.csv')


def parse_time(t: str):
    t = (t or '').strip()
    for f in ('%Y.%m.%d %H:%M:%S', '%Y-%m-%d %H:%M:%S', '%Y-%m-%dT%H:%M:%S'):
        try:
            return dt.datetime.strptime(t, f)
        except Exception:
            pass
    return None


def parse_profit(valor: str):
    """`profit=-119.40` -> -119.40. Tolera `profit: 12.5` e numero puro."""
    v = (valor or '').strip()
    if not v:
        return None
    if '=' in v:
        v = v.split('=', 1)[1].strip()
    elif ':' in v:
        v = v.split(':', 1)[1].strip()
    try:
        return float(v)
    except Exception:
        return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--janela', default='', help='inicio da janela do servidor (YYYY-MM-DD)')
    ap.add_argument('--saida', default=os.path.join(AQUI, 'Experts', 'XAU_AI_PRO', 'EQUIPE', 'FORWARD', 'trades.jsonl'))
    ap.add_argument('--saldo', type=float, default=0.0, help='saldo de referencia para o DD em %')
    ap.add_argument('--print', action='store_true')
    args = ap.parse_args()

    if not os.path.exists(EVENTOS):
        print(f'ERRO: stream de eventos nao encontrado: {EVENTOS}', file=sys.stderr)
        return 1

    inicio = None
    if args.janela:
        try:
            inicio = dt.datetime.strptime(args.janela, '%Y-%m-%d').date()
        except Exception:
            print(f'ERRO: --janela invalido: {args.janela}', file=sys.stderr)
            return 1

    trades = []
    with open(EVENTOS, encoding='utf-16-le', errors='replace') as fh:
        rdr = csv.DictReader(fh)
        for row in rdr:
            row = {(k.lstrip('\ufeff') if k else k): v for k, v in row.items()}
            if (row.get('Event') or '').strip() != 'TRADE_CLOSE':
                continue
            quando = parse_time(row.get('Time', ''))
            if quando is None:
                continue
            if inicio and quando.date() < inicio:
                continue
            trades.append({
                'quando': quando,
                'simbolo': (row.get('Symbol') or '').strip(),
                'ticket': (row.get('Ticket') or '').strip(),
                'profit': parse_profit(row.get('Value', '')),
            })

    por_dia = collections.defaultdict(list)
    for t in trades:
        por_dia[t['quando'].date()].append(t)

    # curva acumulada -> drawdown maximo
    acumulado = 0.0
    pico = 0.0
    dd_max = 0.0
    for t in sorted(trades, key=lambda x: x['quando']):
        p = t['profit'] or 0.0
        acumulado += p
        if acumulado > pico:
            pico = acumulado
        vale = pico - acumulado
        if vale > dd_max:
            dd_max = vale

    gains = [t['profit'] for t in trades if t['profit'] and t['profit'] > 0]
    losses = [t['profit'] for t in trades if t['profit'] and t['profit'] < 0]
    pf = (sum(gains) / abs(sum(losses))) if losses and sum(losses) != 0 else (None if not losses else 0.0)

    linha = {
        'medido_em': dt.datetime.now().isoformat(timespec='seconds'),
        'janela_inicio': args.janela or '',
        'dias_com_trades': len(por_dia),
        'trades_total': len(trades),
        'wins': len(gains),
        'losses': len(losses),
        'bruto': round(sum(t['profit'] or 0.0 for t in trades), 2),
        'pf': round(pf, 4) if pf is not None else None,
        'dd_max_usd': round(dd_max, 2),
        'dd_max_pct': round(dd_max / args.saldo * 100, 3) if args.saldo else None,
        'por_dia': {str(d): len(v) for d, v in sorted(por_dia.items())},
        'ultimos': [{'quando': t['quando'].isoformat(), 'simbolo': t['simbolo'],
                     'ticket': t['ticket'], 'profit': t['profit']}
                    for t in sorted(trades, key=lambda x: x['quando'])[-10:]],
    }

    os.makedirs(os.path.dirname(os.path.abspath(args.saida)), exist_ok=True)
    with open(args.saida, 'a', encoding='utf-8') as fh:
        fh.write(json.dumps(linha, ensure_ascii=False) + '\n')

    if args.print:
        print(json.dumps(linha, indent=2, ensure_ascii=False))
    else:
        print(f'G11: trades={linha["trades_total"]} wins={linha["wins"]} losses={linha["losses"]} '
              f'PF={linha["pf"]} DD={linha["dd_max_usd"]} USD ({linha["dd_max_pct"]}%) '
              f'dias_com_trades={linha["dias_com_trades"]}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
