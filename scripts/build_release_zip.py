#!/usr/bin/env python3
"""Build a non-publishing, reproducible WoW 3.3.5a addon ZIP.

Run from anywhere: python3 scripts/build_release_zip.py
This script never creates a GitHub tag/release or changes game data.
"""
from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "NaxxLootLottery"
TOC = ADDON / "NaxxLootLottery.toc"
CORE = ADDON / "Core" / "Core.lua"
EXPECTED_VERSION = "0.1.0.29-rc.1-dev3"
EXPECTED_INTERFACE = "30300"


def addon_entries():
    toc = TOC.read_text(encoding="utf-8")
    core = CORE.read_text(encoding="utf-8")
    assert re.search(r"^## Interface: " + EXPECTED_INTERFACE + r"$", toc, re.M), "Not a WoW 3.3.5a addon"
    assert re.search(r"^## Version: " + re.escape(EXPECTED_VERSION) + r"$", toc, re.M), "Incorrect TOC version"
    assert 'NLL.version = "' + EXPECTED_VERSION + '"' in core, "Core version disagrees"
    assert "## SavedVariables: NaxxLootLotteryDB" in toc, "SavedVariables identity changed"

    modules = []
    for line in toc.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        module = line.replace("\\", "/")
        rel = Path(module)
        assert not rel.is_absolute() and ".." not in rel.parts, "Unsafe TOC path"
        assert rel.suffix.lower() == ".lua", "Unexpected TOC dependency"
        assert rel.parts and rel.parts[0] != "NaxxLootLottery", "Nested addon path"
        modules.append(ADDON / rel)
    assert len(modules) == 40, f"Expected 40 Lua modules, found {len(modules)}"
    assert len(set(modules)) == len(modules), "Duplicate TOC dependency"
    for module in modules:
        assert module.is_file() and not module.is_symlink(), f"Missing/unsafe {module}"

    actual_files = {p for p in ADDON.rglob("*") if p.is_file()}
    assert actual_files == set(modules) | {TOC}, (
        "Unexpected addon files, do not package unreviewed files: "
        + str(sorted(str(p.relative_to(ADDON)) for p in
                     actual_files - set(modules) - {TOC}))
    )
    assert not any(p.is_symlink() for p in ADDON.rglob("*")), "Symlink in addon tree"
    return [TOC] + modules


def build(output: Path):
    files = addon_entries()
    output.parent.mkdir(parents=True, exist_ok=True)
    assert not str(output.resolve()).startswith(str(ADDON.resolve()) + "/"), (
        "Output must not be inside the installed addon folder"
    )
    with ZipFile(output, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(files, key=lambda p: p.as_posix()):
            relative = path.relative_to(ROOT).as_posix()
            metadata = ZipInfo(relative, date_time=(2020, 1, 1, 0, 0, 0))
            metadata.compress_type = ZIP_DEFLATED
            metadata.external_attr = 0o100644 << 16
            archive.writestr(metadata, path.read_bytes(), compress_type=ZIP_DEFLATED)
    with ZipFile(output, "r") as archive:
        names = archive.namelist()
        assert archive.testzip() is None, "ZIP CRC validation failed"
        assert len(names) == len(files), "Missing packaged files"
        assert all(n.startswith("NaxxLootLottery/") for n in names), "Extra root folder"
        assert "NaxxLootLottery/NaxxLootLottery.toc" in names
        forbidden = ("savedvariables", "naxxlootlotterydb", ".bak", "wtf/")
        assert not any(token in name.lower()
                       for name in names for token in forbidden), (
                           "Personal data slipped into archive"
                       )
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    print(f"Validated {len(files)-1} modules; package: {output}")
    print(f"SHA256: {digest}")
    return digest


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path,
                        default=ROOT / "dist" /
                        f"Naxxramas-Loot-Ledger-v{EXPECTED_VERSION}.zip")
    args = parser.parse_args()
    build(args.output)
