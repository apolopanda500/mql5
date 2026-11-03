parts = [
    "mapa_engineering.py",
    "mapa_main_part1.py",
    "mapa_main_part2.py",
    "mapa_part3.py",
    "mapa_part3b.py",
    "mapa_part4.py",
    "mapa_part5.py",
    "mapa_part6.py",
]
output = []
main_added = False
for p in parts:
    raw2 = (base / p).read_bytes()
    t = raw2.decode("utf-8").replace("\ufeff", "")
    for line in t.splitlines(keepends=True):
        s = line.strip()
        if s == "def main():\\n":
            continue
        if s == "def main():" and not main_added:
            main_added = True
            continue
        if s.startswith("if __name__"):
            continue
        output.append(line)
output.append("\nif __name__ == \"__main__\":\n    main()\n")
(base / "mapa_engineering_final.py").write_text("".join(output), encoding="utf-8")
print("regenerated final:", len(output), "lines")
text_final = "".join(output)
ast.parse(text_final)
print("SYNTAX OK")
print("BOM:", text_final.count("\ufeff"))
for i, line in enumerate(text_final.splitlines()):
    s = line.strip()
    if "7. tokens" in s or "def main" in s or "__name__" in s:
        print(i+1, s[:70])
p6 = base / "mapa_part6.py"
raw = p6.read_bytes()
text = raw.decode("utf-8")
CORRUPT = '                   "7. tokens, senhas, DSNs e .env NUNCA no reposit"4. Gate de producao: DEMO -> forward -> endurance -> autorizacao explicita"],'
if CORRUPT in text:
    text = text.replace(CORRUPT, '                   "7. tokens, senhas, DSNs e .env NUNCA no reposit\xf3rio)",')
    p6.write_text(text, encoding="utf-8")
    print("fixed mapa_part6.py")
else:
    print("mapa_part6.py OK (no corrupt)")
