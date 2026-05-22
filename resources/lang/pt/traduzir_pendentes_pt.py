#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fox GO / 6amMart - Tradutor em lote do arquivo resources/lang/pt/pendentes_traducao.json

Uso dentro da VPS:
  cd /opt/foxgo/admin/resources/lang/pt
  python3 traduzir_pendentes_pt.py

Gera:
  traduzidos_pt.json
  traduzir_pendentes_pt.cache.json
  relatorio_traducao_pt.txt

Observação:
- Não altera o sistema.
- Usa endpoint público do Google Translate via HTTPS.
- Tem cache/resume: se parar, rode novamente.
"""
import json, time, re, sys, urllib.parse, urllib.request, socket
from pathlib import Path

SRC = Path("pendentes_traducao.json")
OUT = Path("traduzidos_pt.json")
CACHE = Path("traduzir_pendentes_pt.cache.json")
REPORT = Path("relatorio_traducao_pt.txt")

SOURCE_LANG = "en"
TARGET_LANG = "pt"
SLEEP_SECONDS = 0.08
TIMEOUT_SECONDS = 20

def load_json(path, default):
    if path.exists():
        with path.open("r", encoding="utf-8") as f:
            return json.load(f)
    return default

def save_json(path, obj):
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
    tmp.replace(path)

def is_nontranslatable(text):
    s = str(text).strip()
    if not s:
        return True
    if re.fullmatch(r"[\d\s:#$%.,/+()_\-–—]+", s):
        return True
    if re.search(r"https?://|firebase\.com|apps\.com|@|\.com\b|\.br\b", s, re.I):
        return True
    if re.search(r"^[A-Z0-9_#:\-/. ]{1,12}$", s):
        return True
    if sum(1 for ch in s if "\u0600" <= ch <= "\u06FF") > 0:
        return True
    return False

def protect_placeholders(text):
    placeholders = []
    def repl(m):
        placeholders.append(m.group(0))
        return f"__FOXPH_{len(placeholders)-1}__"
    # Laravel placeholders (:name), HTML tags, braces, currency-like tokens
    protected = re.sub(r":[A-Za-z_][A-Za-z0-9_]*", repl, text)
    protected = re.sub(r"\{[^{}]{1,80}\}", repl, protected)
    protected = re.sub(r"<[^>]+>", repl, protected)
    return protected, placeholders

def restore_placeholders(text, placeholders):
    for i, ph in enumerate(placeholders):
        text = text.replace(f"__FOXPH_{i}__", ph)
        text = text.replace(f"__ FOXPH_ {i} __", ph)
        text = text.replace(f"__FOXPH {i}__", ph)
    return text

def google_translate(text):
    protected, placeholders = protect_placeholders(str(text))
    params = urllib.parse.urlencode({
        "client": "gtx",
        "sl": SOURCE_LANG,
        "tl": TARGET_LANG,
        "dt": "t",
        "q": protected,
    })
    url = "https://translate.googleapis.com/translate_a/single?" + params
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0 FoxGO Translation Script"
    })
    with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as resp:
        raw = resp.read().decode("utf-8")
    data = json.loads(raw)
    translated = "".join(part[0] for part in data[0] if part and part[0])
    translated = restore_placeholders(translated, placeholders)
    return translated

def main():
    if not SRC.exists():
        print(f"ERRO: não encontrei {SRC.resolve()}")
        sys.exit(1)

    pendentes = load_json(SRC, {})
    cache = load_json(CACHE, {})
    output = load_json(OUT, {})

    total = len(pendentes)
    ok = 0
    pulados = 0
    erros = 0

    print(f"Pendentes carregados: {total}")
    print(f"Cache atual: {len(cache)}")
    print("Iniciando tradução em lote...")

    for idx, (key, original) in enumerate(pendentes.items(), 1):
        original = str(original)

        if key in cache:
            output[key] = cache[key]
            ok += 1
        elif is_nontranslatable(original):
            output[key] = original
            cache[key] = original
            pulados += 1
        else:
            tentativa = 0
            while True:
                tentativa += 1
                try:
                    traduzido = google_translate(original).strip()
                    if not traduzido:
                        traduzido = original
                    output[key] = traduzido
                    cache[key] = traduzido
                    ok += 1
                    time.sleep(SLEEP_SECONDS)
                    break
                except Exception as e:
                    if tentativa >= 3:
                        output[key] = original
                        cache[key] = original
                        erros += 1
                        print(f"[ERRO] {idx}/{total} chave={key!r}: {e}")
                        break
                    time.sleep(1.5 * tentativa)

        if idx % 25 == 0 or idx == total:
            save_json(CACHE, cache)
            save_json(OUT, output)
            print(f"Progresso: {idx}/{total} | OK/cache: {ok} | pulados: {pulados} | erros: {erros}")

    save_json(CACHE, cache)
    save_json(OUT, output)

    changed = sum(1 for k, v in pendentes.items() if str(output.get(k, "")) != str(v))
    with REPORT.open("w", encoding="utf-8") as f:
        f.write("FOX GO / 6amMart - Relatório de tradução PT-BR\n")
        f.write(f"Total pendentes: {total}\n")
        f.write(f"Traduzidos/Cache: {ok}\n")
        f.write(f"Pulados por regra: {pulados}\n")
        f.write(f"Erros mantidos original: {erros}\n")
        f.write(f"Valores alterados em relação ao original: {changed}\n")
        f.write(f"Arquivo gerado: {OUT.resolve()}\n")

    print("Concluído.")
    print(f"Arquivo gerado: {OUT.resolve()}")
    print(f"Relatório: {REPORT.resolve()}")

if __name__ == "__main__":
    socket.setdefaulttimeout(TIMEOUT_SECONDS)
    main()
