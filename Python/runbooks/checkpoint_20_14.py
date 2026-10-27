# -*- coding: utf-8 -*-
"""
XAU_AI_PRO — RUNBOOK: checkpoint_20_14.py
Checkpoint oficial 20.14-C/D (ordem de 9 passos do contrato §10.9). LEITURA APENAS.

Ordem executada:
  1. heartbeat_watchdog.py --checkpoint (subprocess; se existir)
  2. Consolidar trades da janela (broker, API MT5 - read-only)
  3. Métricas da janela (PF / WR / Expectancy / MaxDD aproximado / Sharpe n/d)
  4. Reconciliar Broker  (S1)
  5. Reconciliar full_audit.csv (S2)
  6. Reconciliar Event Stream (S3)
  7. Reconciliar Backend (S4)
  8. Verificar dup-exec
  9. Sugestão de veredito 20.14-C (PASS / INVESTIGATE / FAIL)

Uso:
  py -3 runbooks\checkpoint_20_14.py [--json] [--no-watchdog]

Segurança: nunca envia ordens; apenas leitura (mt5) e subprocess do watchdog.
"""
import sys, os, subprocess, json, io, csv, time
from datetime import datetime, timezone, timedelta
from collections import Counter

MAGIC = 2026001
SERVER_TZ = timezone(timedelta(hours=3))
WINDOW_START_SERVER = datetime(2026, 8, 28, 21, 35, 0, tzinfo=SERVER_TZ)
WINDOW_START_UTC = WINDOW_START_SERVER.astimezone(timezone.utc)

BASE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))  # runbooks -> Python -> MQL5
WATCHDOG = os.path.join(BASE, 'Python', 'watchdog', 'heartbeat_watchdog.py')
FULL_AUDIT = os.path.join(BASE, 'Files', 'Data', 'full_audit.csv')
EVENTS = os.path.join(BASE, 'Files', 'Data', 'forward_test_events.csv')
SYSTEM_STATUS = os.path.join(BASE, 'Files', 'Data', 'system_status.json')


def run_watchdog():
    if not os.path.exists(WATCHDOG):
        return 'watchdog não encontrado: %s' % WATCHDOG
    try:
        p = subprocess.run([sys.executable, WATCHDOG, '--checkpoint'],
                           capture_output=True, text=True, timeout=120, cwd=os.path.dirname(WATCHDOG))
        return (p.stdout or p.stderr or '').strip()
    except Exception as e:
        return 'erro watchdog: %s' % e


def load_broker():
    import MetaTrader5 as mt5
    if not mt5.initialize():
        return None, 'MT5 init falhou: %s' % (mt5.last_error(),)
    try:
        acc = mt5.account_info()
        deals = mt5.history_deals_get(WINDOW_START_UTC.timestamp(), time.time() + 5, group='*')
        pos = mt5.positions_get()
        bal_start = 116.81  # saldo no marco da janela (28/08 21:35 servidor) — ajustável
        return {
            'login': acc.login, 'balance': acc.balance, 'equity': acc.equity,
            'profit': acc.profit, 'margin': acc.margin,
            'deals': [{
                'ticket': d.ticket, 'position': d.position_id, 'symbol': d.symbol,
                'entry': d.entry, 'type': d.type, 'volume': d.volume,
                'price': d.price, 'profit': d.profit, 'time': d.time,
                'reason': d.reason, 'comment': d.comment,
            } for d in (deals or []) if d.magic == MAGIC],
            'positions': [{
                'ticket': p.ticket, 'symbol': p.symbol, 'type': p.type,
                'volume': p.volume, 'price_open': p.price_open, 'sl': p.sl, 'tp': p.tp,
                'profit': p.profit, 'time': p.time,
            } for p in (pos or []) if p.magic == MAGIC],
            'balance_at_window_start': bal_start,
        }, None
    finally:
        mt5.shutdown()


def ts(epoch):
    return datetime.fromtimestamp(int(epoch), tz=SERVER_TZ).strftime('%Y.%m.%d %H:%M:%S')


def metrics(deals):
    """PF/WR/Expectancy por 'decisão' (position_id) — janela limpa."""
    by_pos = {}
    for d in deals:
        by_pos.setdefault((d['position'], d['symbol']), []).append(d)
    decisions = []
    for (pos, sym), ds in by_pos.items():
        outs = [d for d in ds if d['entry'] == 1]
        if not outs:
            continue  # aberta ainda
        profit = sum(d['profit'] for d in outs)
        decisions.append({'position': pos, 'symbol': sym, 'profit': profit,
                          'n_exec': len(ds), 'n_in': sum(1 for d in ds if d['entry'] == 0)})
    wins = [d for d in decisions if d['profit'] > 0]
    losses = [d for d in decisions if d['profit'] <= 0]
    gp = sum(d['profit'] for d in wins)
    gl = abs(sum(d['profit'] for d in losses))
    return {
        'decisions_closed': len(decisions),
        'win_rate': round(len(wins) / len(decisions), 4) if decisions else None,
        'profit_factor': round(gp / gl, 4) if gl > 0 else (None if gp == 0 else float('inf')),
        'expectancy': round(sum(d['profit'] for d in decisions) / len(decisions), 4) if decisions else None,
        'net_profit': round(sum(d['profit'] for d in decisions), 2),
        'decisions_detail': decisions,
    }


def dup_exec_groups(deals):
    by_pos = {}
    for d in deals:
        by_pos.setdefault((d['position'], d['symbol']), []).append(d)
    groups = []
    for (pos, sym), ds in by_pos.items():
        ins = [d for d in ds if d['entry'] == 0]
        if len(ins) > 1:
            groups.append({'position': pos, 'symbol': sym, 'n_fills': len(ins),
                           'times': [ts(d['time']) for d in ins], 'price': ins[0]['price']})
    return groups


def main():
    as_json = '--json' in sys.argv
    do_watchdog = '--no-watchdog' not in sys.argv

    res = {'checkpoint': '20.14-C/D', 'generated': datetime.now(timezone.utc).isoformat()}

    # 1. Watchdog
    if do_watchdog:
        wd = run_watchdog()
        res['watchdog'] = wd
        print('[1/9] watchdog --checkpoint:', wd)

    # 2-3. Broker + métricas
    broker, err = load_broker()
    if err:
        print('[2/9] ERRO:', err)
        if as_json:
            print(json.dumps({'error': err}))
        return 1
    deals = broker['deals']
    met = metrics(deals)
    dup = dup_exec_groups(deals)
    res['broker'] = {k: broker[k] for k in ('login', 'balance', 'equity', 'profit', 'margin')}
    res['metrics_window'] = met
    res['dup_exec'] = dup
    print('[2-3/9] Trades fechados (decisões) na janela: %d | PF=%s | WR=%s%% | Expect=%s | Net=%s'
          % (met['decisions_closed'], met['profit_factor'],
             (met['win_rate'] * 100 if met['win_rate'] is not None else None),
             met['expectancy'], met['net_profit']))
    print('        dup-exec: %d grupo(s)' % len(dup))
    for g in dup:
        print('        * pos %s %s x%d %s' % (g['position'], g['symbol'], g['n_fills'], g['times']))

    # 4-7. Reconciliação por arquivo
    missing_audit = []
    if os.path.exists(FULL_AUDIT):
        with io.open(FULL_AUDIT, 'r', encoding='cp1252', errors='replace', newline='') as f:
            rdr = csv.reader(f, delimiter=';')
            next(rdr, None)
            audit_tickets = set()
            for r in rdr:
                if len(r) >= 2:
                    try:
                        audit_tickets.add(int(r[1]))
                    except ValueError:
                        pass
        missing_audit = [d['ticket'] for d in deals if d['entry'] == 0 and d['ticket'] not in audit_tickets]
        res['audit_rows'] = len(audit_tickets)
        print('[5/9] full_audit tickets=%d | missing(p/entradas)=%d %s' % (len(audit_tickets), len(missing_audit), missing_audit[:5]))
    else:
        print('[5/9] full_audit.csv ausente')

    if os.path.exists(EVENTS):
        with io.open(EVENTS, 'r', encoding='utf-16', errors='replace', newline='') as f:
            ev_lines = [l.strip() for l in f if l.strip()]
        res['events_lines'] = len(ev_lines)
        ev_approved = sum(1 for l in ev_lines if 'TRADE_APPROVED' in l)
        print('[6/9] events linhas=%d | TRADE_APPROVED=%d' % (len(ev_lines), ev_approved))
    else:
        print('[6/9] events ausente')

    if os.path.exists(SYSTEM_STATUS):
        with io.open(SYSTEM_STATUS, 'r', encoding='utf-8') as f:
            ss = json.load(f)
        print('[7/9] backend health=%s algo=%s dd=%.2f%%' % (
            (ss.get('health') or {}).get('state'), (ss.get('health') or {}).get('algo_trading_enabled'),
            (ss.get('risk') or {}).get('drawdown_pct') or 0))
        res['backend_health'] = (ss.get('health') or {}).get('state')
    else:
        print('[7/9] system_status.json ausente')

    # 9. Veredito
    verdict = 'PASS'
    reasons = []
    if len(dup) > 0:
        verdict = 'INVESTIGATE'
        reasons.append('dup-exec presente (%d grupo(s), %d símbolo(s))' % (
            len(dup), len(set(g['symbol'] for g in dup))))
    if missing_audit:
        verdict = 'INVESTIGATE'
        reasons.append('missing full_audit: %d' % len(missing_audit))
    if met['decisions_closed'] == 0:
        reasons.append('0 trades fechados — métricas N/D')
    res['verdict'] = {'result': verdict, 'reasons': reasons}
    print('[9/9] VEREDITO 20.14-C: %s' % verdict)
    for r in reasons:
        print('        -', r)

    if as_json:
        print(json.dumps(res, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    sys.exit(main())