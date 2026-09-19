#!/usr/bin/env python3
"""Ensure literal SwiftUI localization keys exist in the reviewed source catalog."""

import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = json.loads((ROOT / "Localization/en.json").read_text(encoding="utf-8"))
KEYS = set(CATALOG["strings"]) | set(CATALOG["plurals"])
PATTERNS = [
    r'\bText\("([^"]+)"',
    r'\bButton\("([^"]+)"',
    r'\bLabel\("([^"]+)"',
    r'\bProgressView\("([^"]+)"',
    r'\bSection\("([^"]+)"',
    r'\.navigationTitle\("([^"]+)"',
    r'ContentUnavailableView\("([^"]+)"',
    r'SettingsLabel\("([^"]+)"',
]

missing: list[str] = []
for path in (ROOT / "Shell").rglob("*.swift"):
    if path.name == "ShellLabView.swift":
        continue
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        for pattern in PATTERNS:
            match = re.search(pattern, line)
            if not match:
                continue
            key = re.sub(r'\\\([^)]*\)', "%lld", match.group(1))
            if key not in KEYS:
                missing.append(f"{path.relative_to(ROOT)}:{line_number}: {key}")

if missing:
    sys.exit("UI LOCALIZATION FAILED:\n" + "\n".join(missing))

print(f"UI localization validation passed ({len(KEYS)} reviewed keys).")
