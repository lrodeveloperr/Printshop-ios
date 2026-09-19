#!/usr/bin/env python3
"""Generate Apple .strings/.stringsdict resources from the reviewed JSON catalogs."""

from __future__ import annotations

import json
import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Localization"
RESOURCES = ROOT / "Shell" / "Resources"
LOCALES = {
    "en": "en.json",
    "es-419": "es-419.json",
    "pt-BR": "pt-BR.json",
    "de-DE": "de-DE.json",
    "fr-FR": "fr-FR.json",
}


def quote(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "\\r")
    )


def plural_entry(value: dict) -> dict:
    placeholders = value.get("placeholders", {})
    if len(placeholders) != 1:
        raise ValueError(f"Plural must contain exactly one placeholder: {value}")
    variable, kind = next(iter(placeholders.items()))
    if kind not in {"Int", "Int64"}:
        raise ValueError(f"Unsupported plural placeholder type {kind}")
    rule = {
        "NSStringFormatSpecTypeKey": "NSStringPluralRuleType",
        "NSStringFormatValueTypeKey": "lld",
    }
    for category in ("zero", "one", "two", "few", "many", "other"):
        if category in value:
            rule[category] = value[category].replace("{" + variable + "}", "%lld")
    return {"NSStringLocalizedFormatKey": f"%#@{variable}@", variable: rule}


def printf_value(key: str, value: str, schema: dict[str, dict[str, str]]) -> str:
    placeholders = schema.get(key, {})
    kinds = {"String": "@", "Int": "lld", "Int64": "lld", "Double": "f"}
    for position, (variable, kind) in enumerate(placeholders.items(), start=1):
        if kind not in kinds:
            raise ValueError(f"Unsupported placeholder type {kind} for {key}")
        value = value.replace("{" + variable + "}", f"%{position}${kinds[kind]}")
    return value


for locale, filename in LOCALES.items():
    catalog = json.loads((SOURCE / filename).read_text(encoding="utf-8"))
    target = RESOURCES / f"{locale}.lproj"
    target.mkdir(parents=True, exist_ok=True)

    lines = [
        f'"{quote(key)}" = "{quote(printf_value(key, value, catalog["placeholders"]))}";'
        for key, value in sorted(catalog["strings"].items())
    ]
    (target / "Localizable.strings").write_text("\n".join(lines) + "\n", encoding="utf-8")

    display_name = catalog["strings"]["app.short_name"]
    (target / "InfoPlist.strings").write_text(
        f'"CFBundleDisplayName" = "{quote(display_name)}";\n'
        f'"CFBundleName" = "{quote(display_name)}";\n',
        encoding="utf-8",
    )

    stringsdict = {
        key: plural_entry(value)
        for key, value in sorted(catalog["plurals"].items())
    }
    with (target / "Localizable.stringsdict").open("wb") as handle:
        plistlib.dump(stringsdict, handle, fmt=plistlib.FMT_XML, sort_keys=True)

print(f"Generated {len(LOCALES)} reviewed localization bundles.")
