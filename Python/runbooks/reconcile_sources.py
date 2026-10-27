# -*- coding: utf-8 -*-
r"""
XAU_AI_PRO — RUNBOOK: reconcile_sources.py (F4 v1.2.2)
Reconciliacao das 4 fontes da janela limpa 20.14/20.8 (LEITURA APENAS — nunca envia ordens).

Fontes:
  S1 BROKER   -> MT5 Python API (deals magic 2026001)  [fonte canonica]
  S2 AUDIT    -> MQL5/Files/Data\full_audit.csv          (ANSI)
  S3 EVENTS   -> MQL5/Files/Data\forward_test_events.csv (UTF-16 LE + BOM)
  S4 BACKEND  -> MQL5/Files/Data\system_status.json + dataset.csv

F4 - cadeia por ticket (auditoria Broker x Audit x Events):
  * deal de ENTRADA (broker)         -> ticket do deal
  * full_audit (coluna Ticket)       -> POSITION_ID (nao o deal ticket)
  * evento TRADE_OPEN (col Ticket)   -> ticket do deal
  Checagens:
    - entry broker sem linha no full_audit (position_id ausente)
    - entry broker sem evento TRADE_OPEN (deal ticket ausente)
    - evento TRADE_OPEN sem deal correspondente no broker

Janela limpa F4: inicio 2026-09-01 21:33:40 UTC (2026-09-02 00:33:40 servidor UTC+3) = reload build F4 definitivo (escritores open->seek->write->flush->close sob lock).
Uso:
  py -3 runbooks\reconcile_sources.py            -> relatorio completo (stdout)
  py -3 runbooks\reconcile_sources.py --json     -> saida JSON (para automacao)
Requisitos: pacote MetaTrader5 instalado e terminal MT5 aberto.

Seguranca: nenhuma chamada a order_send / position_close / order_modify.
"""
import sys, os, json, io, csv, time
from datetime import datetime, timezone, timedelta
from collections import Counter

MAGIC = 2026001
SERVER_TZ = timezone(timedelta(hours=3))          # servidor = UTC+3
WINDOW_START_SERVER = datetime(2026, 9, 2, 0, 33, 40, tzinfo=SERVER_TZ)  # 00:33:40 server = reload build F4 definitivo (open->close sob lock)
WINDOW_START_UTC = WINDOW_START_SERVER.astimezone(timezone.utc)

BASE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))  # runbooks -> Python -> MQL5
DATA_DIR = os.path.join(BASE, 'Files', 'Data')
COMMON_DIR = os.path.join(BASE, 'Files', 'Common')

FULL_AUDIT = os.path.join(DATA_DIR, 'full_audit.csv')
EVENTS = os.path.join(DATA_DIR, 'forward_test_events.csv')
SYSTEM_STATUS = os.path.join(DATA_DIR, 'system_status.json')
DATASET = os.path.join(DATA_DIR, 'dataset.csv')

EVENT_TIME_FMT = '%Y.%m.%d %H:%M:%S'


def server_now():
    return datetime.now(tz=SERVER_TZ)


def ts_server(epoch):
    # ATENCAO: a API MT5 Python desta instalacao devolve d.time ja deslocado para o
    # horario do servidor (ex.: deal 21:45:07 server aparece com epoch cujo
    # utcfromtimestamp == 21:45:07). Portanto NAO somamos SERVER_TZ de novo:
    # interpretamos o epoch como UTC e re-marcamos o fuso como SERVER_TZ.
    return datetime.fromtimestamp(int(epoch), tz=timezone.utc).replace(tzinfo=SERVER_TZ)


def broker_deals():
    """Le deals do broker via API MT5 (read-only). Retorna lista de dicts da janela limpa."""
    import MetaTrader5 as mt5
    if not mt5.initialize():
        raise RuntimeError('MT5 initialize falhou: %s' % (mt5.last_error(),))
    try:
        inf = mt5.account_info()
        if inf is None:
            raise RuntimeError('account_info None')
        now = time.time()
        # Range amplo (1 dia antes da janela) para o terminal sincronizar o bloco de
        # historico; o filtro por WINDOW_START_SERVER abaixo descarta o excedente.
        from_ts = WINDOW_START_UTC.timestamp() - 86400
        to_ts = now + 3600
        deals = mt5.history_deals_get(from_ts, to_ts, group='*')
        if deals is None:
            # retry apos sync (deals muito recentes podem demorar no cache da API)
            time.sleep(2)
            deals = mt5.history_deals_get(from_ts, to_ts, group='*')
        if deals is None:
            raise RuntimeError('history_deals_get None: %s' % (mt5.last_error(),))
        out = []
        for d in deals:
            if d.magic != MAGIC:
                continue
            t = ts_server(d.time)
            if t < WINDOW_START_SERVER:
                continue
            out.append({
                'deal': d.ticket, 'order': d.order, 'position': d.position_id,
                'symbol': d.symbol, 'entry': d.entry, 'type': d.type,
                'price': d.price, 'volume': d.volume, 'profit': d.profit,
                'time_server': t.strftime('%Y.%m.%d %H:%M:%S'),
                'reason': d.reason, 'comment': (d.comment or ''),
            })
        # Sincronizacao adicional: se a janela ainda nao tem deals (cache da API atrasado),
        # tenta mais algumas vezes com espera curta.
        for attempt in range(3):
            if len(out) > 0:
                break
            time.sleep(3)
            deals = mt5.history_deals_get(from_ts, to_ts, group='*')
            if deals is None:
                continue
            out = []
            for d in deals:
                if d.magic != MAGIC:
                    continue
                t = ts_server(d.time)
                if t < WINDOW_START_SERVER:
                    continue
                out.append({
                    'deal': d.ticket, 'order': d.order, 'position': d.position_id,
                    'symbol': d.symbol, 'entry': d.entry, 'type': d.type,
                    'price': d.price, 'volume': d.volume, 'profit': d.profit,
                    'time_server': t.strftime('%Y.%m.%d %H:%M:%S'),
                    'reason': d.reason, 'comment': (d.comment or ''),
                })
        return out
    finally:
        mt5.shutdown()


def broker_open_positions():
    """Posicoes abertas via API MT5 (LEITURA APENAS). None se indisponivel."""
    import MetaTrader5 as mt5
    if not mt5.initialize():
        return None
    try:
        pos = mt5.positions_get()
        if pos is None:
            return None
        ea = [p for p in pos if p.magic == MAGIC]
        return {
            'total': len(pos),
            'ea_magic': len(ea),
            'by_symbol': dict(Counter(p.symbol for p in ea)),
        }
    finally:
        mt5.shutdown()


def audit_rows():
    """Le full_audit.csv (ANSI / cp1252). Ticket = POSITION_ID (col 2)."""
    rows = []
    if not os.path.exists(FULL_AUDIT):
        return rows
    with io.open(FULL_AUDIT, 'r', encoding='cp1252', errors='replace', newline='') as f:
        rdr = csv.reader(f, delimiter=';')
        header = next(rdr, None)
        for r in rdr:
            if len(r) < 2:
                continue
            try:
                ticket = int(r[1])
            except ValueError:
                continue
            rows.append({'row': r, 'ticket': ticket})
    return rows


def event_rows():
    """Le forward_test_events.csv (UTF-16)."""
    rows = []
    if not os.path.exists(EVENTS):
        return rows
    with io.open(EVENTS, 'r', encoding='utf-16', errors='replace', newline='') as f:
        for line in f:
            line = line.strip().replace('\r', '')
            if not line:
                continue
            parts = line.split(',')
            if len(parts) >= 3:
                rows.append({'line': line, 'parts': parts})
    return rows


def event_records(rows):
    """Estrutura os eventos (10 colunas). Ticket = col 5 (index 4). Filtra pela janela (col 0 = Time server)."""
    out = []
    for r in rows:
        p = r['parts']
        if len(p) < 5:
            continue
        # F4: considera apenas eventos dentro da janela limpa (Time server >= WINDOW_START_SERVER)
        try:
            ev_time = datetime.strptime(p[0].strip(), EVENT_TIME_FMT).replace(tzinfo=SERVER_TZ)
        except ValueError:
            ev_time = None
        if ev_time is None or ev_time < WINDOW_START_SERVER:
            continue
        try:
            ticket = int(p[4]) if p[4].strip().isdigit() else 0
        except ValueError:
            ticket = 0
        out.append({
            'time': p[0], 'event': p[1], 'symbol': p[2], 'tf': p[3],
            'ticket': ticket, 'severity': p[5] if len(p) > 5 else '',
            'module': p[6] if len(p) > 6 else '',
            'message': p[7] if len(p) > 7 else '',
            'value': p[8] if len(p) > 8 else '',
            'status': p[9] if len(p) > 9 else '',
        })
    return out


def backend_status():
    info = {'exists': False, 'health': None, 'algo': None, 'dataset_bytes': None}
    if os.path.exists(SYSTEM_STATUS):
        try:
            with io.open(SYSTEM_STATUS, 'r', encoding='utf-8') as f:
                j = json.load(f)
            info['exists'] = True
            info['health'] = (j.get('health') or {}).get('state')
            info['algo'] = (j.get('health') or {}).get('algo_trading_enabled')
            db = j.get('database') or {}
            info['dataset_bytes'] = db.get('dataset_bytes')
        except Exception as e:
            info['error'] = str(e)
    return info


def extract_audit_tickets(rows):
    """Tickets unicos de entrada (col 2 = Ticket = POSITION_ID). full_audit grava apenas ENTRY."""
    tickets = {}
    for r in rows:
        t = r['ticket']
        tickets[t] = tickets.get(t, 0) + 1
    return tickets


def main():
    as_json = '--json' in sys.argv
    print('== RECONCILIAÇÃO 20.8 — janela limpa (>= %s servidor) ==' % WINDOW_START_SERVER.strftime('%Y.%m.%d %H:%M:%S'))
    print('Agora:', server_now().strftime('%Y.%m.%d %H:%M:%S'), 'servidor | UTC:', datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S'))

    # S1 Broker
    deals = broker_deals()
    in_deals = [d for d in deals if d['entry'] == 0]      # DEAL_ENTRY_IN
    out_deals = [d for d in deals if d['entry'] == 1]     # DEAL_ENTRY_OUT
    positions_by_pos = {}
    for d in deals:
        positions_by_pos.setdefault(d['position'], []).append(d)

    # S2 Audit
    audit = audit_rows()
    audit_tickets = extract_audit_tickets(audit)

    # S3 Events (filtrados pela janela em event_records)
    events = event_rows()
    ev_approved = [e for e in events if 'TRADE_APPROVED' in e['line']]
    ev_recs = event_records(events)
    ev_trade_open = [r for r in ev_recs if r['event'] == 'TRADE_OPEN' and r['ticket'] > 0]
    ev_open_tickets = set(r['ticket'] for r in ev_trade_open)

    # S4 Backend
    st = backend_status()

    # S4b Posicoes abertas (broker, leitura)
    open_positions = broker_open_positions()

    # ==== Análise ====
    dup_exec = []
    per_symbol_in = Counter(d['symbol'] for d in in_deals)
    # Pares duplicados: mesma posição (1 decisão) com >1 entrada no mesmo segundo/preço
    for pos, ds in positions_by_pos.items():
        ents = [d for d in ds if d['entry'] == 0]
        if len(ents) > 1:
            dup_exec.append({
                'position': pos,
                'symbol': ents[0]['symbol'],
                'n_fills': len(ents),
                'times': [d['time_server'] for d in ents],
                'price': ents[0]['price'],
            })

    # F4: cadeia Broker x Audit x Events por ticket
    missing_audit = [d['position'] for d in in_deals if d['position'] not in audit_tickets]
    missing_event = [d['deal'] for d in in_deals if d['deal'] not in ev_open_tickets]
    unknown_event = sorted(ev_open_tickets - set(d['deal'] for d in in_deals))

    summary = {
        'window_start_server': WINDOW_START_SERVER.strftime('%Y.%m.%d %H:%M:%S'),
        'broker': {
            'deals_total': len(deals),
            'entries': len(in_deals),
            'exits': len(out_deals),
            'symbols_entry': dict(per_symbol_in),
            'net_profit_deals': round(sum(d['profit'] for d in deals), 2),
            'positions_open': open_positions,
        },
        'audit': {
            'rows': len(audit),
            'unique_tickets': len(audit_tickets),
        },
        'events': {
            'lines': len(events),
            'trade_approved': len(ev_approved),
            'trade_open_tickets': len(ev_open_tickets),
        },
        'chain_f4': {
            'missing_audit_entry': len(missing_audit),
            'missing_audit_entry_ids': missing_audit[:10],
            'missing_event_entry': len(missing_event),
            'missing_event_entry_ids': missing_event[:10],
            'unknown_event_tickets': unknown_event[:10],
        },
        'backend': st,
        'dup_exec_groups': dup_exec,
        'dup_exec_count': len(dup_exec),
        'dup_exec_positions_same_second': sum(
            1 for g in dup_exec if len(set(g['times'])) <= 1 or (len(set(g['times'])) == 2 and abs(
                datetime.strptime(g['times'][0], '%Y.%m.%d %H:%M:%S') -
                datetime.strptime(g['times'][1], '%Y.%m.%d %H:%M:%S')).total_seconds() <= 2)
        ),
    }

    if as_json:
        sys.stdout.write(json.dumps(summary, ensure_ascii=False, indent=2))
        return

    print('\n[S1 BROKER] deals=%d | entries=%d | exits=%d | net(profit deals)=%.2f'
          % (len(deals), len(in_deals), len(out_deals), sum(d['profit'] for d in deals)))
    print('  Entradas por símbolo:', dict(per_symbol_in))
    if open_positions:
        print('  Posicoes abertas: %d total | %d EA (magic %d) | por simbolo: %s'
              % (open_positions['total'], open_positions['ea_magic'], MAGIC,
                 open_positions['by_symbol']))
    print('[S2 AUDIT] linhas=%d | tickets únicos=%d' % (len(audit), len(audit_tickets)))
    print('[S3 EVENTS] linhas=%d (janela) | TRADE_APPROVED=%d | TRADE_OPEN_tickets=%d'
          % (len(ev_recs), len(ev_approved), len(ev_open_tickets)))
    print('[S4 BACKEND] exists=%s health=%s algo=%s dataset_bytes=%s'
          % (st.get('exists'), st.get('health'), st.get('algo'), st.get('dataset_bytes')))

    # Barra de gate
    print('\n-- CRITÉRIOS 20.8 + F4 (janela limpa) --')
    print('missing AUDIT (entry broker sem linha full_audit [pos id]): %d %s'
          % (len(missing_audit), '' if not missing_audit else missing_audit[:10]))
    print('missing EVENT (entry broker sem TRADE_OPEN): %d %s'
          % (len(missing_event), '' if not missing_event else missing_event[:10]))
    print('evento TRADE_OPEN sem deal no broker: %d %s'
          % (len(unknown_event), unknown_event[:10]))
    print('dup-exec (1 decisão -> >1 fill): %d' % len(dup_exec))
    for g in dup_exec:
        print('  * pos %s %s n_fills=%d times=%s price=%s'
              % (g['position'], g['symbol'], g['n_fills'], g['times'], g['price']))
    print('DIVERGÊNCIA financeira: deals profit soma=%.2f vs conta (ver via MT5)' % sum(d['profit'] for d in deals))

    return summary


if __name__ == '__main__':
    main()