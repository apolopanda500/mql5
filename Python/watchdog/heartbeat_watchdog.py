#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
XAU_AI_PRO - HEARTBEAT WATCHDOG (ETAPA 20.14 - Endurance)
===========================================================
Monitora a "vida" do pipeline sem tocar no EA:
  - system_status.json   (backend/heartbeat do EA)
  - forward_test_events.csv (Event Stream)
  - full_audit.csv       (AuditLog por-deal, opcional)

Se um arquivo parar de ser atualizado além do limite (idle), gera alerta
via Slack webhook e/ou Pushover. Também valida o estado do system_status
(HEALTHY/SAFE, AI READY/STALE) e aponta picos de trades/erros.

USO (regime passivo - nada altera no EA):
  python heartbeat_watchdog.py --once                # verifica uma vez e sai
  python heartbeat_watchdog.py --daemon              # loop a cada N segundos
  python heartbeat_watchdog.py --daemon --interval 300
  python heartbeat_watchdog.py --checkpoint          # modo consolidacao p/ 24h

Config via ambiente (ou --env-file):
  STATUS_PATH   (default: Terminal/MQL5/Files/Data/system_status.json)
  EVENTS_PATH   (default: Terminal/MQL5/Files/Data/forward_test_events.csv)
  AUDIT_PATH    (default: Terminal/MQL5/Files/Data/full_audit.csv)
  MAX_IDLE_SEC  (default: 900 = 15 min sem atualizacao)
  SLACK_WEBHOOK_URL  (opcional; alerta)
  PUSHOVER_TOKEN / PUSHOVER_USER (opcional; alerta)
  ALERT_THROTTLE_SEC (default: 3600 - 1 alerta por tipo por hora)
"""

import argparse
import json
import os
import re
import sys
import time
import datetime as dt
from pathlib import Path

try:
    import urllib.request
except Exception:  # pragma: no cover
    urllib = None

# leitura com detecção de encoding (UTF-16 LE no Event Stream)
import smart_read


# ---------------------------------------------------------------- caminhos
def detect_terminal_root():
    """Descobre a raiz do terminal (onde fica MQL5/Files/Data)."""
    here = Path(__file__).resolve()
    # sobe ate encontrar 'MQL5'
    for parent in here.parents:
        if parent.name == 'MQL5':
            return parent.parent
    # fallback: relativo ao script
    return here.parent.parent.parent


TERMINAL_ROOT = detect_terminal_root()
DEFAULT_STATUS = TERMINAL_ROOT / 'MQL5' / 'Files' / 'Data' / 'system_status.json'
DEFAULT_EVENTS = TERMINAL_ROOT / 'MQL5' / 'Files' / 'Data' / 'forward_test_events.csv'
DEFAULT_AUDIT = TERMINAL_ROOT / 'MQL5' / 'Files' / 'Data' / 'full_audit.csv'


def env_path(name, default):
    v = os.getenv(name)
    if v:
        return Path(v)
    return Path(default)


# ---------------------------------------------------------------- alertas
def send_slack(webhook, text):
    """Envia mensagem simples ao Slack via Incoming Webhook."""
    if not webhook or urllib is None:
        return False
    payload = json.dumps({'text': text}).encode('utf-8')
    req = urllib.request.Request(
        webhook, data=payload,
        headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.status == 200
    except Exception:
        return False


def send_pushover(token, user, title, message):
    if not token or not user or urllib is None:
        return False
    data = ('token=' + urllib.parse.quote(token) +
            '&user=' + urllib.parse.quote(user) +
            '&title=' + urllib.parse.quote(title) +
            '&message=' + urllib.parse.quote(message))
    req = urllib.request.Request(
        'https://api.pushover.net/1/messages.json', data=data.encode('utf-8'),
        headers={'Content-Type': 'application/x-www-form-urlencoded'})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.status == 200
    except Exception:
        return False


# ---------------------------------------------------------------- funcoes
def file_age_seconds(path):
    """Idade (em segundos) desde a ultima modificacao do arquivo."""
    try:
        mtime = path.stat().st_mtime
        return time.time() - mtime
    except FileNotFoundError:
        return float('inf')


def parse_status(path):
    """Le system_status.json e devolve dict (ou None se invalido)."""
    try:
        with open(path, 'r', encoding='utf-8-sig') as f:
            data = json.load(f)
        return data
    except Exception:
        return None


def count_events_today(path, hours=24):
    """Conta eventos gravados nas ultimas N horas no Event Stream."""
    try:
        cutoff = time.time() - hours * 3600
        count = 0
        lines = smart_read.read_last_lines(path, n=2_000_000, chunk=8_000_000)
        if not lines:
            return 0
        for line in lines:
            m = re.match(r'^(\d{4})\.(\d{2})\.(\d{2})[ T](\d{2}):(\d{2}):(\d{2})', line)
            if not m:
                continue
            y, mo, d, h, mi, s = map(int, m.groups())
            ts = time.mktime((y, mo, d, h, mi, s, 0, 0, -1))
            if ts >= cutoff:
                count += 1
        return count
    except Exception:
        return -1


def last_event_time(path):
    """Timestamp da ultima linha do Event Stream (datetime ou None)."""
    try:
        lines = smart_read.read_last_lines(path, n=1)
        if not lines:
            return None
        last_line = lines[-1]
        m = re.match(r'^(\d{4})\.(\d{2})\.(\d{2})[ T](\d{2}):(\d{2}):(\d{2})', last_line)
        if m:
            return dt.datetime(*map(int, m.groups()))
        return None
    except Exception:
        return None


def check_once(conf, verbose=True):
    """Executa uma verificacao e retorna lista de problemas."""
    problems = []
    now = dt.datetime.now()
    max_idle = conf['max_idle']

    # 1) system_status
    status_path = conf['status']
    age = file_age_seconds(status_path)
    if age == float('inf'):
        problems.append('system_status.json NAO EXISTE')
    elif age > max_idle:
        problems.append(f'system_status.json PARADO há {age/60:.0f} min (limite {max_idle/60:.0f} min)')
    st = parse_status(status_path)
    if st:
        health = (st.get('health') or {}).get('state', '?')
        ai = (st.get('ai') or {}).get('signal', '?')
        ai_stale = (st.get('ai') or {}).get('stale')
        dd = (st.get('risk') or {}).get('drawdown_pct')
        if health not in ('HEALTHY', 'SAFE'):
            problems.append(f'health.state = {health} (esperado HEALTHY/SAFE)')
        if ai_stale:
            if verbose:
                print(f'  [info] AI STALE (fim de semana/awaiting) - nao e alerta')
        if verbose:
            print(f'  status: health={health} ai={ai} stale={ai_stale} dd={dd}% age={age/60:.1f}min')

    # 2) event stream
    events_path = conf['events']
    eage = file_age_seconds(events_path)
    last_ev = last_event_time(events_path)
    if eage == float('inf'):
        problems.append('forward_test_events.csv NAO EXISTE')
    elif eage > max_idle:
        problems.append(f'forward_test_events.csv PARADO há {eage/60:.0f} min')
    if last_ev:
        # delta usa o mtime do arquivo (timezone-independent, confiavel)
        if verbose:
            print(f'  events: last={last_ev} file_age={eage/60:.1f}min (delta de relogio nao usado)')
    n = count_events_today(events_path, 24)
    if verbose:
        print(f'  events 24h: {n}')

    # 3) audit (opcional) - atualiza SOMENTE por trade; limite generoso
    audit_path = conf['audit']
    aage = file_age_seconds(audit_path)
    audit_max = conf.get('audit_max_idle', 172800)  # 24h sem trade = ok
    if aage == float('inf'):
        if verbose:
            print('  audit: nao encontrado (opcional)')
    elif aage > audit_max:
        problems.append(f'full_audit.csv PARADO há {aage/3600:.1f} h (limite {audit_max/3600:.0f} h)')
    elif verbose:
        print(f'  audit: age={aage/60:.0f}min (atualiza por trade - ok)')

    return problems


def send_alerts(conf, problems):
    texts = ['[XAU_AI_PRO watchdog] ' + p for p in problems]
    slack = os.getenv('SLACK_WEBHOOK_URL')
    po_token = os.getenv('PUSHOVER_TOKEN')
    po_user = os.getenv('PUSHOVER_USER')
    throttle = conf['throttle']
    now = time.time()
    key = ';'.join(sorted(problems))
    last = conf.get('last_alert')
    if last and (now - last) < throttle:
        return False
    conf['last_alert'] = now
    for t in texts:
        if slack:
            ok = send_slack(slack, t)
            print(f'  [slack] {t} -> {"ok" if ok else "falhou"}')
        if po_token and po_user:
            ok = send_pushover(po_token, po_user, 'XAU_AI_PRO watchdog', t)
            print(f'  [pushover] {t} -> {"ok" if ok else "falhou"}')
    return True


def event_breakdown(path, hours=24):
    """Conta eventos por tipo nas ultimas N horas (coluna Time do stream).

    Usa smart_read.read_rows (encoding detectado, BOM removido, '\r' limpo).
    """
    cutoff = time.time() - hours * 3600
    stats = {}
    total = 0
    for row in smart_read.read_rows(path):
        t = (row.get('Time') or '').strip()
        m = re.match(r'^(\d{4})\.(\d{2})\.(\d{2})[ T](\d{2}):(\d{2}):(\d{2})', t)
        if not m:
            continue
        y, mo, d, h, mi, s = map(int, m.groups())
        ts = time.mktime((y, mo, d, h, mi, s, 0, 0, -1))
        if ts >= cutoff:
            total += 1
            ev = (row.get('Event') or '?').strip()
            stats[ev] = stats.get(ev, 0) + 1
    return total, stats


def consolidate(conf, verbose=True):
    """Modo checkpoint: imprime consolidacao p/ 24h/72h/7d (sem alterar nada)."""
    print('=== CHECKPOINT XAU_AI_PRO (reconciliacao observacional) ===')
    status_path = conf['status']
    events_path = conf['events']
    audit_path = conf['audit']
    st = parse_status(status_path)
    if st:
        print(json.dumps(st, indent=2, ensure_ascii=False))
    n24 = count_events_today(events_path, 24)
    n72 = count_events_today(events_path, 72)
    n7d = count_events_today(events_path, 168)
    print(f'Eventos stream: 24h={n24} 72h={n72} 7d={n7d}')
    total_ev, stats = event_breakdown(events_path, 24)
    print(f'Eventos por tipo (24h, coluna Event): total={total_ev}')
    for ev, c in sorted(stats.items(), key=lambda kv: -kv[1]):
        print(f'  {c:6d}  {ev}')
    print(f'Status: {status_path}')
    print(f'Events: {events_path}')
    print(f'Audit : {audit_path}')


def main():
    ap = argparse.ArgumentParser(description='Heartbeat watchdog XAU_AI_PRO')
    ap.add_argument('--once', action='store_true', help='verifica uma vez e sai')
    ap.add_argument('--daemon', action='store_true', help='loop contínuo')
    ap.add_argument('--interval', type=int, default=300,
                    help='intervalo em segundos (default 300)')
    ap.add_argument('--checkpoint', action='store_true',
                    help='modo consolidacao (nao alerta)')
    ap.add_argument('--env-file', default=None,
                    help='arquivo .env opcional (chave=valor)')
    args = ap.parse_args()

    if args.env_file:
        ep = Path(args.env_file)
        if ep.exists():
            for line in ep.read_text(encoding='utf-8').splitlines():
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    os.environ.setdefault(k.strip(), v.strip())

    conf = {
        'status': env_path('STATUS_PATH', DEFAULT_STATUS),
        'events': env_path('EVENTS_PATH', DEFAULT_EVENTS),
        'audit': env_path('AUDIT_PATH', DEFAULT_AUDIT),
        'max_idle': int(os.getenv('MAX_IDLE_SEC', '900')),
        'throttle': int(os.getenv('ALERT_THROTTLE_SEC', '3600')),
        'audit_max_idle': int(os.getenv('AUDIT_MAX_IDLE_SEC', '172800')),
        'last_alert': 0,
    }

    if args.checkpoint:
        consolidate(conf)
        return 0

    if args.once:
        problems = check_once(conf)
        if problems:
            print('PROBLEMAS:')
            for p in problems:
                print('  -', p)
            if os.getenv('SLACK_WEBHOOK_URL') or os.getenv('PUSHOVER_TOKEN'):
                send_alerts(conf, problems)
        else:
            print('OK - tudo saudavel')
        return 0

    if args.daemon:
        print(f'Watchdog ativo: verifica a cada {args.interval}s '
              f'(limite {conf["max_idle"]/60:.0f} min). Ctrl+C para parar.')
        try:
            while True:
                try:
                    problems = check_once(conf, verbose=False)
                    if problems:
                        send_alerts(conf, problems)
                except Exception as e:
                    print(f'ERRO watchdog: {e}')
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print('\nWatchdog parado.')
        return 0

    ap.print_help()
    return 1


if __name__ == '__main__':
    sys.exit(main())