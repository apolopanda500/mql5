# -*- coding: utf-8 -*-
"""Bloco de leitura com deteccao de encoding para o heartbeat_watchdog.py"""

import codecs


def detect_encoding(head: bytes) -> str:
    """Detecta encoding a partir dos primeiros bytes (BOM)."""
    if head.startswith(codecs.BOM_UTF16_LE):
        return 'utf-16-le'
    if head.startswith(codecs.BOM_UTF8):
        return 'utf-8-sig'
    if head.startswith(codecs.BOM_UTF16_BE):
        return 'utf-16-be'
    return 'utf-8'


def read_last_lines(path, n=5, chunk=65536):
    """Le as ultimas n linhas de um arquivo texto com encoding detectado.

    Abre com FileShare (o arquivo pode estar sendo escrito pelo EA).
    Se o arquivo nao pode ser aberto, retorna lista vazia.
    """
    import os
    import io

    if not os.path.exists(path):
        return []
    try:
        # le o cabecalho para detectar encoding
        with open(path, 'rb') as f:
            head = f.read(4)
        enc = detect_encoding(head)
        # tenta abrir em modo texto com o encoding
        # (usa io.open com buffering e tentativa simples; se der
        #  PermissionError, tenta via leitura por blocos)
        try:
            with io.open(path, 'r', encoding=enc, errors='replace') as f:
                lines = f.readlines()
                return lines[-n:]
        except PermissionError:
            # fallback: le por blocos no final com os.open (share read/write)
            import ctypes
            GENERIC_READ = 0x80000000
            FILE_SHARE_READ = 0x1
            FILE_SHARE_WRITE = 0x2
            OPEN_EXISTING = 3
            kernel32 = ctypes.windll.kernel32
            size = os.path.getsize(path)
            if size == 0:
                return []
            read = min(size, chunk)
            h = kernel32.CreateFileW(path, GENERIC_READ,
                                     FILE_SHARE_READ | FILE_SHARE_WRITE,
                                     None, OPEN_EXISTING, 0, None)
            if not h or h == -1:
                return []
            try:
                buf = ctypes.create_string_buffer(read)
                got = ctypes.c_ulong(0)
                ok = kernel32.ReadFile(h, buf, read, ctypes.byref(got), None)
                if not ok:
                    return []
                data = buf.raw[:got.value]
            finally:
                kernel32.CloseHandle(h)
            try:
                text = data.decode(enc, errors='replace')
            except LookupError:
                text = data.decode('utf-8', errors='replace')
            lines = text.splitlines()
            return lines[-n:]
    except Exception:
        return []


# ---- atalhos de compatibilidade para o watchdog original ----

def smart_open_lines(path, n=5, chunk=65536):
    return read_last_lines(path, n, chunk)


if __name__ == '__main__':
    import sys
    p = (r'C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal'
         r'\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Files\Data\forward_test_events.csv')
    lines = read_last_lines(p, 5)
    print('ultimas linhas:')
    for l in lines:
        print(' ', l.rstrip()[:120])