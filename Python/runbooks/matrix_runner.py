# -*- coding: utf-8 -*-
"""
XAU_AI_PRO — RUNBOOK: matrix_runner.py
Prepara e valida a bateria de backtests da matriz 20.15 (FORA DA JANELA LIMPA).

Funções:
  --list            lista perfis .ini de teste disponíveis em MQL5\Profiles\Tester
  --report          lista relatórios de backtest salvos em Files\Temp\*_report.json
  --check-logs      varre Tester\logs e Logs por '4807'/'CopyBuffer failed'/'error'
  --check-hash      hash do XAU_AI_PRO.ex5 vs esperado (opcional --expect=HEX)

Uso (o lançamento real do tester é feito pelo MetaTrader MCP, com pausa entre jobs
para não derrubar o agente — ver PLANO_20_15 §4):
  py -3 runbooks\matrix_runner.py --list
  py -3 runbooks\matrix_runner.py --report
  py -3 runbooks\matrix_runner.py --check-logs

Segurança: leitura apenas.
"""
import sys, os, glob, json, io, hashlib

BASE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))  # runbooks -> Python -> MQL5
TESTER_DIR = os.path.join(BASE, 'Profiles', 'Tester')
TEMP_DIR = os.path.join(BASE, 'Files', 'Temp')
EX5 = os.path.join(BASE, 'Experts', 'XAU_AI_PRO', 'XAU_AI_PRO.ex5')
TERMINAL_LOGS = os.path.dirname(BASE)  # ...\Terminal\<id>
TESTER_LOGS = os.path.join(TERMINAL_LOGS, 'Tester', 'logs')


def list_inis():
    out = []
    for p in sorted(glob.glob(os.path.join(TESTER_DIR, 'DIAG_*.ini'))):
        name = os.path.basename(p)
        with io.open(p, 'r', encoding='utf-8', errors='replace') as f:
            txt = f.read()
        model = next((l.split('=')[1].strip() for l in txt.splitlines() if l.startswith('Model=')), '?')
        out.append({'ini': name, 'model': model})
    return out


def list_reports():
    out = []
    for p in sorted(glob.glob(os.path.join(TEMP_DIR, '*_report.json'))):
        try:
            with io.open(p, 'r', encoding='utf-8') as f:
                j = json.load(f)
            out.append({'file': os.path.basename(p), 'trades': j.get('trades'), 'profit': j.get('profit'),
                        'deals': j.get('deals')})
        except Exception as e:
            out.append({'file': os.path.basename(p), 'error': str(e)})
    return out


def scan_errors():
    hits = {'4807': 0, 'CopyBuffer failed': 0, 'Position doesn': 0, 'skipped as it changes nothing': 0}
    dirs = [TESTER_LOGS, os.path.join(TERMINAL_LOGS, 'Logs')]
    for base in dirs:
        if not os.path.isdir(base):
            continue
        for p in glob.glob(os.path.join(base, '*.log')):
            try:
                raw = io.open(p, 'rb').read()
                txt = None
                for enc in ('utf-16', 'utf-8', 'cp1252'):
                    try:
                        t = raw.decode(enc)
                        if 'MetaTrader' in t or '4807' in t or 'ERROR' in t or 'Expert' in t:
                            txt = t
                            break
                    except Exception:
                        continue
                if txt is None:
                    continue
                for k in hits:
                    hits[k] += txt.count(k)
            except Exception:
                continue
    return hits


def ex5_hash():
    if not os.path.exists(EX5):
        return None
    h = hashlib.sha256()
    with open(EX5, 'rb') as f:
        h.update(f.read())
    return h.hexdigest()


def main():
    args = sys.argv[1:]
    if '--list' in args:
        for i in list_inis():
            print('%(ini)s  (Model=%(model)s)' % i)
    elif '--report' in args:
        for r in list_reports():
            print(r)
    elif '--check-logs' in args:
        h = scan_errors()
        print(json.dumps(h, ensure_ascii=False))
    elif '--check-hash' in args:
        hx = ex5_hash()
        print('ex5 sha256:', hx)
        if '--expect=' in ' '.join(args):
            exp = [a.split('=', 1)[1] for a in args if a.startswith('--expect=')][0]
            print('esperado   :', exp)
            print('MATCH' if hx == exp else 'DIVERGE')
    else:
        print(__doc__)


if __name__ == '__main__':
    main()