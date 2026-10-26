path = r"C:\Users\Micro\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Files\XAU_AI_PRO\Temp\mapa_engineering.py"
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()
print("Total lines:", len(lines))
for i, line in enumerate(lines):
    if "def main" in line or "__name__" in line:
        print(i + 1, repr(line.strip()))
