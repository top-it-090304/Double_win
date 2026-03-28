from pathlib import Path

def main() -> None:
    p = Path(__file__).resolve().parents[1] / "casle_minu" / "main" / "castle_main_menu.tscn"
    lines = p.read_text(encoding="utf-8").splitlines()
    out = []
    i = 0
    while i < len(lines):
        if lines[i].startswith('[node name="slot_info"'):
            while i < len(lines) and not lines[i].startswith('[node name="InfoPanel"'):
                i += 1
            continue
        if lines[i].startswith('[node name="InfoPanel"'):
            while i < len(lines) and not lines[i].startswith('[node name="HireSelectPanel"'):
                i += 1
            continue
        out.append(lines[i])
        i += 1
    # Remove info-related connections
    filtered = []
    for line in out:
        if 'slot_info' in line and 'ColumnInfo' in line:
            continue
        if 'InfoPanel/' in line and 'connection signal' in line:
            continue
        filtered.append(line)
    p.write_text("\n".join(filtered) + "\n", encoding="utf-8")
    print("lines", len(lines), "->", len(filtered))


if __name__ == "__main__":
    main()
