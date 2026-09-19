#!/usr/bin/env python3
"""Reject selectable locales without complete, placeholder-safe catalogs."""

from collections import Counter
import json
from pathlib import Path
import plistlib
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "Shell/App/ShellConfiguration.swift"
RESOURCES = ROOT / "Shell/Resources"
SOURCE = ROOT / "Localization"

configured = re.findall(r'\.init\(id: "([^"]+)", displayNameKey:', CONFIG.read_text())
locales = [locale for locale in configured if locale != "system"]


def json_catalog(locale: str) -> dict:
    path = SOURCE / f"{locale}.json"
    if not path.is_file():
        sys.exit(f"LOCALIZATION FAILED: selectable locale {locale} has no reviewed JSON catalog")
    return json.loads(path.read_text(encoding="utf-8"))


def strings_catalog(path: Path) -> dict[str, str]:
    found = re.findall(
        r'^\s*"((?:\\.|[^"])*)"\s*=\s*"((?:\\.|[^"])*)"\s*;',
        path.read_text(encoding="utf-8"),
        re.MULTILINE,
    )
    if len(found) != len({key for key, _ in found}):
        sys.exit(f"LOCALIZATION FAILED: duplicate keys in {path.relative_to(ROOT)}")
    return dict(found)


def placeholders(value: str) -> Counter[tuple[str, str]]:
    return Counter(re.findall(r'%(?:\d+\$)?(@|lld|ld|d|f|s)|\{([A-Za-z][A-Za-z0-9_]*)\}', value))


english = json_catalog("en")
expected_strings = set(english["strings"])
expected_plurals = set(english["plurals"])
expected_placeholder_schema = english["placeholders"]

for locale in locales:
    reviewed = json_catalog(locale)
    if set(reviewed["strings"]) != expected_strings:
        sys.exit(f"LOCALIZATION FAILED: {locale} reviewed string-key mismatch")
    if set(reviewed["plurals"]) != expected_plurals:
        sys.exit(f"LOCALIZATION FAILED: {locale} reviewed plural-key mismatch")
    if reviewed["placeholders"] != expected_placeholder_schema:
        sys.exit(f"LOCALIZATION FAILED: {locale} placeholder-schema mismatch")
    for key in expected_strings:
        if placeholders(reviewed["strings"][key]) != placeholders(english["strings"][key]):
            sys.exit(f"LOCALIZATION FAILED: {locale} placeholder mismatch for {key}")

    bundle = RESOURCES / f"{locale}.lproj"
    strings_path = bundle / "Localizable.strings"
    dict_path = bundle / "Localizable.stringsdict"
    info_path = bundle / "InfoPlist.strings"
    if not strings_path.is_file() or not dict_path.is_file() or not info_path.is_file():
        sys.exit(f"LOCALIZATION FAILED: {locale} generated bundle is incomplete")
    generated_strings = strings_catalog(strings_path)
    with dict_path.open("rb") as handle:
        generated_plurals = plistlib.load(handle)
    if set(generated_strings) != expected_strings or set(generated_plurals) != expected_plurals:
        sys.exit(f"LOCALIZATION FAILED: {locale} generated bundle is stale")
    info = strings_catalog(info_path)
    if info.get("CFBundleDisplayName") != reviewed["strings"]["app.short_name"]:
        sys.exit(f"LOCALIZATION FAILED: {locale} display name is stale")

print(
    f"Localization validation passed ({len(locales)} locales, "
    f"{len(expected_strings)} strings, {len(expected_plurals)} plurals)."
)
