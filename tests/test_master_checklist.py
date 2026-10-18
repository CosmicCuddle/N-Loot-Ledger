"""Guard the project-wide NLL master checklist against silent scope loss.

Runs offline and never accesses real user data, GitHub accounts or game files.
This is a snapshot of PRs verified on 18 October 2026; add new PR IDs when
creating future development branches rather than removing older history.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
master = (root / "docs" / "MASTER_DEVELOPMENT_CHECKLIST.md").read_text()
readme = (root / "README.md").read_text()
tracker = (root / "docs" / "DEVELOPMENT_TRACKER.md").read_text()
roadmap = (root / "docs" / "ROADMAP.md").read_text()

assert "MASTER_DEVELOPMENT_CHECKLIST.md" in readme
assert "MASTER_DEVELOPMENT_CHECKLIST.md" in tracker
assert "MASTER_DEVELOPMENT_CHECKLIST.md" in roadmap

expected = {
    2, 3, 6, 8, 9, 10, 12, 13, 14, 15, 16, 17,
    18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
}
missing = [number for number in sorted(expected) if (
    f"PR #{number}" not in master and f"[#{number}]" not in master
)]
assert not missing, f"Never lose older PR work: {missing}"
for term in (
    "604", "38 Playerbots", "469 NEED", "135 GREED",
    "0.1.0.29-rc.1-hf2", "CI", "WoW", "Release",
    "parallel", "18", "19", "20", "21",
    "NEED", "GREED", "OBTAINED", "Playerbot",
    "character filter", "owner", "NaxxLootLottery.lua",
):
    assert term.lower() in master.lower(), f"Missing master section: {term}"

assert master.index("## D. Parallel") > master.index("## C. Main")
assert master.index("## F. Integrated") > master.index("## E. Future")
assert "Owner action today: NONE" in master
assert "Anything you need to do" in master
print("PASS: NLL master checklist retains all historical/parallel PRs and links")
