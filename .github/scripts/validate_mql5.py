#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
validate_mql5.py - Validacao estatica de codigo fonte MQL5/MQH.

Executado pelo GitHub Actions (CI) para verificar problemas comuns de
alta relevancia sem depender do MetaEditor (compilador proprietario da
MetaQuotes, disponivel apenas em Windows).

  1. Encoding: .mq5/.mqh/.mqproj devem ser UTF-8 valido (detecta
     caracteres quebrados tipo 'm\u00c3\u00b3dulos' que ocorrem quando o
     arquivo e salvo em UTF-8 mas o .mqproj usa "unicode_character_set":"0").
  2. Balanceamento de chaves {} em arquivos fonte.
  3. Referencias a #include locais (aspas) devem existir no repo.
  4. Marcadores de pendencia (TODO/FIXME/...).
  5. Fim de linha CRLF em fontes .mq5/.mqh/.mqproj.

Retorna exit code 1 se houver QUALQUER problema.
"""

import os
import re
import sys

# Raiz do repositorio git (pasta MQL5)
REPO_ROOT = os.path.normpath(os.path.join(
    os.path.dirname(os.path.abspath(__file__)), os.pardir, os.pardir))

# Alvo da validacao: o projeto XAU_AI_PRO (e subpastas).
# Evita varrer exemplos/instalacao do MetaEditor que nao sao do autor.
TARGET = os.path.normpath(os.path.join(
    REPO_ROOT, "Experts", "XAU_AI_PRO"))

# ROOT usado para rel_path() -> mantem relativos dentro do projeto
ROOT = TARGET

SOURCE_EXTS = {".mq5", ".mqh", ".mqproj"}

INCLUDE_RE = re.compile(r'#include\s+"([^"]+)"')

TODO_MARKERS = ["TODO", "FIXME", "HACK", "XXX"]

SKIP_DIRS = {"Data", "logs", "__pycache__", "node_modules"}

problems = []
warnings = []


def rel_path(path):
    """Caminho relativo ao root do repo para logs curtos."""
    try:
        return os.path.relpath(path, ROOT)
    except ValueError:
        return path


def walk_files():
    """Itera sobre arquivos fonte no repo, respeitando diretorios pulados."""
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fname in filenames:
            if os.path.splitext(fname)[1].lower() in SOURCE_EXTS:
                yield os.path.join(dirpath, fname)


def check_encoding(path):
    """Arquivo deve ser UTF-8 valido (ASCII puro e subconjunto UTF-8)."""
    try:
        with open(path, "rb") as f:
            raw = f.read()
        raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        problems.append("[ENCODING] Nao UTF-8: %s (%s)" % (rel_path(path), exc))
        return False
    return True


def _strip_line(line):
    """Remove strings, char literals e comentarios de linha; retorna codigo."""
    out = []
    i = 0
    n = len(line)
    in_str = False
    in_char = False
    while i < n:
        c = line[i]
        nxt = line[i + 1] if i + 1 < n else ""
        if in_str:
            if c == '"':
                in_str = False
            i += 1
            continue
        if in_char:
            if c == "'":
                in_char = False
            i += 1
            continue
        if c == "/" and nxt == "/":
            break
        if c == '"':
            in_str = True
            i += 1
            continue
        if c == "'":
            in_char = True
            i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def check_braces(path):
    """Verifica balanceamento de chaves, ignorando strings/comentarios/char."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            lines = f.read().split("\n")
    except Exception:
        return
    depth = 0
    in_block = False
    first_neg = -1
    for lineno, raw in enumerate(lines, 1):
        # remove block comments /* ... */
        if in_block:
            idx = raw.find("*/")
            if idx >= 0:
                raw = raw[idx + 2:]
                in_block = False
            else:
                continue
        idx = raw.find("/*")
        if idx >= 0:
            raw = raw[:idx]
            in_block = True
        body = _strip_line(raw)
        depth += body.count("{")
        depth -= body.count("}")
        if depth < 0 and first_neg < 0:
            first_neg = lineno
    if first_neg >= 0:
        problems.append("[BRACES] '}' sem '{' em %s (linha %d)"
                        % (rel_path(path), first_neg))
    elif depth != 0:
        problems.append("[BRACES] %d '{' sem fechamento em %s"
                        % (depth, rel_path(path)))


def check_todo(path):
    """Relata como warning marcadores de pendencia."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            for lineno, line in enumerate(f, 1):
                for m in TODO_MARKERS:
                    if m in line.upper():
                        warnings.append("%s:%d %s" % (rel_path(path), lineno, m))
                        break
    except Exception:
        pass


def check_eol(path):
    """Detecta CRLF para informar preferencia de LF."""
    try:
        with open(path, "rb") as f:
            raw = f.read()
        if b"\r\n" in raw:
            warnings.append("[EOL] CRLF em %s" % rel_path(path))
    except Exception:
        pass


def check_includes(path):
    """Confere que cada #include local (aspas) existe no repo.

    Inclui: usa '< >' (biblioteca padrao MT5 fora do repo) -> ignora.
    Inclui com caminho absoluto 'MQL5\\Include\\...' -> ignora.
    """
    try:
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
    except Exception:
        return
    basedir = os.path.dirname(path)
    for m in INCLUDE_RE.finditer(text):
        inc = m.group(1)
        norm = inc.replace("\\\\", "/").replace("\\", "/")
        first = norm.split("/")[0].lower()
        # libs padrao MT5 que ficam fora do repositorio
        if first in ("mql5", "trade", "stdlib"):
            continue
        cand = os.path.normpath(os.path.join(basedir, *inc.split("\\\\")))
        if not os.path.exists(cand):
            # fallback dentro da arvore do proprio projeto (ROOT = XAU_AI_PRO)
            root_inc = os.path.join(ROOT, *norm.split("/"))
            if not os.path.exists(root_inc):
                problems.append("[INCLUDE] faltando '%s' (referido em %s)"
                                % (inc, rel_path(path)))


def main():
    count = 0
    for path in walk_files():
        count += 1
        check_encoding(path)
        ext = os.path.splitext(path)[1].lower()
        if ext in (".mq5", ".mqh"):
            check_braces(path)
            check_includes(path)
            check_todo(path)
            check_eol(path)

    print("==> Validacao estatica MQL5")
    print("==> Raiz: %s" % ROOT)
    print("==> Arquivos fonte varridos: %d\n" % count)

    if warnings:
        print("AVISOS (%d):" % len(warnings))
        for w in warnings:
            print("  [!] %s" % w)
        print()

    if problems:
        print("PROBLEMAS (%d):" % len(problems))
        for p in problems:
            print("  [X] %s" % p)
        print("\n[FALHA] Existem problemas de validacao a corrigir.")
        return 1

    print("[OK] Nenhum problema de validacao encontrado.")
    return 0


if __name__ == "__main__":
    sys.exit(main())