# -*- coding: utf-8 -*-
"""Bloco de leitura com deteccao de encoding para o heartbeat_watchdog.py

Regra 20.14 (forward_test_events.csv):
  BOM FF FE -> UTF-16 LE -> csv.DictReader (delimiter ',')
  - NUNCA converter o arquivo nem alterar o EA (o problema e do leitor).
  - Usar codec 'utf-16' quando ha BOM: o Python determina a ordem dos bytes
    pelo BOM e o REMOVE durante a leitura (diferente de 'utf-16-le', que
    deixaria '\ufeff' no inicio da primeira linha).
  - O Event Stream grava linhas com terminator '\r\r\n' em UTF-16LE:
    ler com newline='' e limpar os '\r' antes do DictReader.
"""

import csv
import codecs
import io
import os


def detect_encoding(head: bytes) -> str:
    """Detecta encoding a partir dos primeiros bytes (BOM)."""
    if head.startswith(codecs.BOM_UTF16_LE):
        return 'utf-16-le'
    if head.startswith(codecs.BOM_UTF8):
        return 'utf-8-sig'
    if head.startswith(codecs.BOM_UTF16_BE):
        return 'utf-16-be'
    return 'utf-8'


def decode_codec(enc: str) -> str:
    """Codec de DECODIFICACAO a partir do encoding detectado.

    Mantem a deteccao do watchdog (detect_encoding), mas ao abrir o arquivo
    usa 'utf-16' quando ha BOM UTF-16: o decoder consome o BOM e remove o
    caractere '\ufeff' da primeira linha. Arquivos sem BOM seguem utf-8.
    """
    if enc in ('utf-16-le', 'utf-16-be'):
        return 'utf-16'
    if enc == 'utf-8-sig':
        return 'utf-8-sig'
    return 'utf-8'


def read_last_lines(path, n=5, chunk=65536):
    """Le as ultimas n linhas de um arquivo texto com encoding detectado.

    Abre com FileShare (o arquivo pode estar sendo escrito pelo EA).
    Se o arquivo nao pode ser aberto, retorna lista vazia.
    """
    if not os.path.exists(path):
        return []
    try:
        # le o cabecalho para detectar encoding
        with open(path, 'rb') as f:
            head = f.read(4)
        enc = decode_codec(detect_encoding(head))
        # tenta abrir em modo texto com o encoding
        # (usa io.open com buffering e tentativa simples; se der
        #  PermissionError, tenta via leitura por blocos)
        try:
            with io.open(path, 'r', encoding=enc, errors='replace', newline='') as f:
                lines = f.read().splitlines()
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


def read_rows(path, max_rows=0):
    """Le o CSV de eventos como lista de dicts (colunas do cabecalho).

    Regra 20.14:
      forward_test_events.csv
        -> BOM FF FE detectado -> UTF-16 LE
        -> csv.DictReader (delimiter ',', newline='')
        -> eventos reais (sem BOM, sem '\r' residual) p/ reconciliacao/metricas

    max_rows=0 retorna todas as linhas; >0 limita as ULTIMAS max_rows.
    Nao converte o arquivo e nao altera o EA.
    """
    if not os.path.exists(path):
        return []
    try:
        with open(path, 'rb') as f:
            head = f.read(4)
        enc = decode_codec(detect_encoding(head))
        with io.open(path, 'r', encoding=enc, errors='replace', newline='') as f:
            text = f.read()
        # limpa '\r' residual (terminator \r\r\n do Event Stream)
        text = text.replace('\r', '')
        rows = list(csv.DictReader(io.StringIO(text)))
        if max_rows and len(rows) > max_rows:
            rows = rows[-max_rows:]
        return rows
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
    rows = read_rows(p)
    print('total rows:', len(rows))
    if rows:
        print('colunas:', list(rows[0].keys()))
        for r in rows[-3:]:
            print(' ', {k: v for k, v in r.items() if k not in ('EventId',)})