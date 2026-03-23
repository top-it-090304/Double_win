"""Generate full SpriteFrames .tres for lancer/pawn from ally/.../art/black PNG strips."""
from __future__ import annotations

import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Пешка и воин в паке — полосы 192px; копейщик — клетки 320×320 (см. Lancer_Idle 3840→12 кадров).
PAWN_FRAME_W = 192
LANCER_FRAME_W = 320

LANCER_UID = "uid://c2l4ncr0frms1"
PAWN_UID = "uid://p4wnblk0fram1"

LANCER_ART = ROOT / "ally/lancer/art/black"
PAWN_ART = ROOT / "ally/pawn/art/black"


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as f:
        if f.read(8) != b"\x89PNG\r\n\x1a\n":
            raise ValueError(f"Not a PNG: {path}")
        while True:
            raw = f.read(8)
            if len(raw) < 8:
                raise ValueError(f"IHDR missing: {path}")
            length = struct.unpack(">I", raw[:4])[0]
            ctype = raw[4:8]
            data = f.read(length)
            f.read(4)
            if ctype == b"IHDR":
                return struct.unpack(">II", data[:8])


def frames_in_strip(w: int, h: int, frame_w: int) -> tuple[int, int, int]:
    if w % frame_w != 0:
        raise ValueError(f"Width {w} not divisible by frame width {frame_w}")
    n = w // frame_w
    return n, frame_w, h


def gen_lancer() -> str:
    # Скорости: меньше FPS на длинных циклах, атаки 3 кадра — умеренный темп.
    specs: list[tuple[str, str, bool, float]] = [
        ("Lancer_Idle.png", "idle", True, 8.0),
        ("Lancer_Run.png", "run", True, 9.0),
        ("Lancer_Down_Attack.png", "down_attack", False, 7.0),
        ("Lancer_Down_Defence.png", "down_defence", True, 6.0),
        ("Lancer_DownRight_Attack.png", "down_right_attack", False, 7.0),
        ("Lancer_DownRight_Defence.png", "down_right_defence", True, 6.0),
        ("Lancer_Right_Attack.png", "right_attack", False, 7.0),
        ("Lancer_Right_Defence.png", "right_defence", True, 6.0),
        ("Lancer_Up_Attack.png", "up_attack", False, 7.0),
        ("Lancer_Up_Defence.png", "up_defence", True, 6.0),
        ("Lancer_UpRight_Attack.png", "up_right_attack", False, 7.0),
        ("Lancer_UpRight_Defence.png", "up_right_defence", True, 6.0),
    ]
    ext_ids: list[tuple[str, str]] = []
    lines: list[str] = []
    sub_ids: list[str] = []
    sub_counter = 0

    for fname, _anim, _loop, _spd in specs:
        p = LANCER_ART / fname
        w, h = png_size(p)
        n, fw, fh = frames_in_strip(w, h, LANCER_FRAME_W)
        if fh != 320 or fw != 320:
            raise ValueError(f"Unexpected lancer frame size {fw}x{fh} in {fname}")
        rid = f"tex_{fname.replace('.png', '').replace(' ', '_')}"
        ext_ids.append((rid, f"res://ally/lancer/art/black/{fname}"))
        for i in range(n):
            sid = f"AtlasTexture_l{sub_counter:04d}"
            sub_counter += 1
            sub_ids.append(sid)
            lines.append(f'[sub_resource type="AtlasTexture" id="{sid}"]')
            lines.append(f'atlas = ExtResource("{rid}")')
            lines.append(f"region = Rect2({i * fw}, 0, {fw}, {fh})")
            lines.append("")

    load_steps = len(ext_ids) + len(sub_ids) + 1
    header = [
        f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3 uid="{LANCER_UID}"]',
        "",
    ]
    for rid, rpath in ext_ids:
        header.append(f'[ext_resource type="Texture2D" path="{rpath}" id="{rid}"]')
    header.append("")
    body = "\n".join(lines)

    # Build animations: map anim name to slice of sub_ids
    anim_blocks: list[str] = []
    idx = 0
    for fname, anim, loop, speed in specs:
        p = LANCER_ART / fname
        w, h = png_size(p)
        n, _, _ = frames_in_strip(w, h, LANCER_FRAME_W)
        chunk = sub_ids[idx : idx + n]
        idx += n
        parts = ", ".join(
            [f'{{"duration": 1.0, "texture": SubResource("{s}")}}' for s in chunk]
        )
        loop_s = "true" if loop else "false"
        anim_blocks.append(
            "".join(
                [
                    "{\n",
                    f'"frames": [{parts}],\n',
                    f'"loop": {loop_s},\n',
                    f'"name": &"{anim}",\n',
                    f'"speed": {speed}\n',
                    "}",
                ]
            )
        )

    animations_inner = ", ".join(anim_blocks)
    footer = f"[resource]\nanimations = [{animations_inner}]\n"
    out = "\n".join(header) + body + footer
    return out


def gen_pawn() -> str:
    specs: list[tuple[str, str, bool, float]] = [
        ("Pawn_Idle.png", "idle", True, 10.0),
        ("Pawn_Run.png", "run", True, 10.0),
        ("Pawn_Idle Axe.png", "idle_axe", True, 10.0),
        ("Pawn_Idle Gold.png", "idle_gold", True, 10.0),
        ("Pawn_Idle Hammer.png", "idle_hammer", True, 10.0),
        ("Pawn_Idle Knife.png", "idle_knife", True, 10.0),
        ("Pawn_Idle Meat.png", "idle_meat", True, 10.0),
        ("Pawn_Idle Pickaxe.png", "idle_pickaxe", True, 10.0),
        ("Pawn_Idle Wood.png", "idle_wood", True, 10.0),
        ("Pawn_Run Axe.png", "run_axe", True, 10.0),
        ("Pawn_Run Gold.png", "run_gold", True, 10.0),
        ("Pawn_Run Hammer.png", "run_hammer", True, 10.0),
        ("Pawn_Run Knife.png", "run_knife", True, 10.0),
        ("Pawn_Run Meat.png", "run_meat", True, 10.0),
        ("Pawn_Run Pickaxe.png", "run_pickaxe", True, 10.0),
        ("Pawn_Run Wood.png", "run_wood", True, 10.0),
        ("Pawn_Interact Axe.png", "interact_axe", False, 10.0),
        ("Pawn_Interact Hammer.png", "interact_hammer", False, 10.0),
        ("Pawn_Interact Knife.png", "interact_knife", False, 10.0),
        ("Pawn_Interact Pickaxe.png", "interact_pickaxe", False, 10.0),
    ]
    ext_ids: list[tuple[str, str]] = []
    lines: list[str] = []
    sub_ids: list[str] = []
    sub_counter = 0

    for fname, _anim, _loop, _spd in specs:
        p = PAWN_ART / fname
        w, h = png_size(p)
        n, fw, fh = frames_in_strip(w, h, PAWN_FRAME_W)
        if fh != 192:
            raise ValueError(f"Unexpected pawn frame height {fh} in {fname}")
        rid = f"tex_{fname.replace('.png', '').replace(' ', '_')}"
        ext_ids.append((rid, f"res://ally/pawn/art/black/{fname}"))
        for i in range(n):
            sid = f"AtlasTexture_p{sub_counter:04d}"
            sub_counter += 1
            sub_ids.append(sid)
            lines.append(f'[sub_resource type="AtlasTexture" id="{sid}"]')
            lines.append(f'atlas = ExtResource("{rid}")')
            lines.append(f"region = Rect2({i * fw}, 0, {fw}, {fh})")
            lines.append("")

    load_steps = len(ext_ids) + len(sub_ids) + 1
    header = [
        f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3 uid="{PAWN_UID}"]',
        "",
    ]
    for rid, rpath in ext_ids:
        header.append(f'[ext_resource type="Texture2D" path="{rpath}" id="{rid}"]')
    header.append("")
    body = "\n".join(lines)

    anim_blocks: list[str] = []
    idx = 0
    for fname, anim, loop, speed in specs:
        p = PAWN_ART / fname
        w, h = png_size(p)
        n, _, _ = frames_in_strip(w, h, PAWN_FRAME_W)
        chunk = sub_ids[idx : idx + n]
        idx += n
        parts = ", ".join(
            [f'{{"duration": 1.0, "texture": SubResource("{s}")}}' for s in chunk]
        )
        loop_s = "true" if loop else "false"
        anim_blocks.append(
            "".join(
                [
                    "{\n",
                    f'"frames": [{parts}],\n',
                    f'"loop": {loop_s},\n',
                    f'"name": &"{anim}",\n',
                    f'"speed": {speed}\n',
                    "}",
                ]
            )
        )

    animations_inner = ", ".join(anim_blocks)
    footer = f"[resource]\nanimations = [{animations_inner}]\n"
    return "\n".join(header) + body + footer


def main() -> None:
    lancer_out = ROOT / "ally/lancer/resources/black_lancer_frames.tres"
    pawn_out = ROOT / "ally/pawn/resources/black_pawn_frames.tres"
    lancer_out.write_text(gen_lancer(), encoding="utf-8")
    pawn_out.write_text(gen_pawn(), encoding="utf-8")
    print("Wrote", lancer_out)
    print("Wrote", pawn_out)


if __name__ == "__main__":
    main()
