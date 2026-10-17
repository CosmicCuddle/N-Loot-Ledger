"""Read-only v0.1.0.29-rc.1-dev4 candidate packaging and opt-in safety checks."""
from __future__ import annotations

import hashlib
import importlib.util
import tempfile
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
script = ROOT / "scripts" / "build_release_zip.py"
spec = importlib.util.spec_from_file_location("nll_zip", script)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

assert module.EXPECTED_VERSION == "0.1.0.29-rc.1-dev4"
assert module.EXPECTED_INTERFACE == "30300"

with tempfile.TemporaryDirectory() as tmp:
    path = Path(tmp) / "Naxxramas-Loot-Ledger-v0.1.0.29-rc.1-dev4.zip"
    digest = module.build(path)
    assert path.is_file() and len(digest) == 64
    assert hashlib.sha256(path.read_bytes()).hexdigest() == digest
    with ZipFile(path) as archive:
        toc = archive.read("NaxxLootLottery/NaxxLootLottery.toc").decode()
        core = archive.read("NaxxLootLottery/Core/Core.lua").decode()
        db = archive.read("NaxxLootLottery/Storage/Database.lua").decode()
        award_settings = archive.read(
            "NaxxLootLottery/UI/AwardSettingsFrame.lua"
        ).decode()
        assert "## Interface: 30300" in toc
        assert "## SavedVariables: NaxxLootLotteryDB" in toc
        assert "## Version: 0.1.0.29-rc.1-dev4" in toc
        assert 'NLL.version = "0.1.0.29-rc.1-dev4"' in core
        assert "db.settings.directMasterLootEnabled = false" in db
        assert "Live Loot Awards (Experimental)" in award_settings
        assert "GiveMasterLoot" not in award_settings.split("heading:SetText")[0]
        assert len(archive.namelist()) == 41
    # Two successive builds have identical ZIP bytes for the same source.
    second = Path(tmp) / "again.zip"
    assert module.build(second) == digest, "ZIP is not deterministic"

print("PASS: 0.1.0.29-rc.1-dev4 ZIP format, versions, offline-direct default, reproducibility")
