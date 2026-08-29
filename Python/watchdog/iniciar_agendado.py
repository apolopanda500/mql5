#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
XAU_AI_PRO - INICIAR WATCHDOG AGENDADO (instancia unica)
========================================================
Chamado pelo Windows Task Scheduler a cada 5 minutos:
  - se o daemon do watchdog ja estiver rodando  -> sai (nao duplica);
  - se o daemon morreu (crash/reboot)           -> reinicia e grava novo PID.

Nao altera o EA nem os dados (regime passivo); apenas garante observacao continua
com throttle de alertas preservado (o daemon mantem o estado em memoria).

USO:
  python iniciar_agendado.py
"""
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PYTHON = sys.executable
DAEMON = HERE / 'heartbeat_watchdog.py'
DAEMON_NAME = 'heartbeat_watchdog.py'
LOCK = Path(os.environ.get('TEMP', str(HERE))) / 'xau_ai_pro_watchdog.pid'
LOG = HERE / 'daemon.log'
ERR = HERE / 'daemon_err.log'
INTERVALO = os.getenv('WATCHDOG_INTERVAL_SEC', '300')


def pid_vivo(pid):
    """True se existe um processo com este PID (Windows)."""
    try:
        out = subprocess.run(
            ['tasklist', '/FI', 'PID eq %d' % pid, '/NH'],
            capture_output=True, text=True, timeout=15).stdout
        return str(pid) in (out or '')
    except Exception:
        return True  # em duvida, assume vivo (conservador)


def pid_e_daemon(pid):
    """Confirma que o PID corresponde ao nosso daemon (evita PID reusado apos reboot)."""
    try:
        out = subprocess.run(
            ['powershell', '-NoProfile', '-Command',
             "(Get-CimInstance Win32_Process -Filter 'ProcessId=%d').CommandLine" % pid],
            capture_output=True, text=True, timeout=20).stdout or ''
        return DAEMON_NAME in out
    except Exception:
        return True  # se faltar ferramenta, confia no check de PID


def main():
    # --- pre-flight: lock existente ---
    if LOCK.exists():
        old = None
        try:
            old = int(LOCK.read_text(encoding='ascii').strip())
        except (ValueError, OSError):
            pass
        if old and pid_vivo(old) and pid_e_daemon(old):
            print('[XAU_AI_PRO] Watchdog ja ativo (PID %d). Nada a fazer.' % old)
            return 0
        print('[XAU_AI_PRO] Lock orfao (daemon morto/reboot); reiniciando watchdog.')
        try:
            LOCK.unlink()
        except OSError:
            pass

    # --- inicia daemon destacado, com logs em arquivo ---
    cmd = [PYTHON, '-u', str(DAEMON), '--daemon', '--interval', INTERVALO]
    try:
        with open(LOG, 'a', encoding='utf-8') as lo, \
             open(ERR, 'a', encoding='utf-8') as er:
            proc = subprocess.Popen(
                cmd, stdout=lo, stderr=er,
                creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
    except OSError as e:
        print('[XAU_AI_PRO] ERRO ao iniciar watchdog: %s' % e)
        return 1

    try:
        LOCK.write_text(str(proc.pid), encoding='ascii')
    except OSError:
        pass
    print('[XAU_AI_PRO] Watchdog iniciado (PID %d).' % proc.pid)
    return 0


if __name__ == '__main__':
    sys.exit(main())