# English Source Audit and Localization Schema Contract

## Verdict

`en.json` is the canonical user-facing source catalog for Print Shop Job Manager. It uses one English master locale, not four English runtime catalogs. Dates, times, numbers, measurements, currency, and StoreKit prices must follow the user's system locale. Narrow regional vocabulary differences belong in a small override table only when a real user-facing difference is proven; import aliases must accept both `color`/`colour` and `traveler`/`traveller`.

The source catalog is complete for the current locked web prototype, native shell, harness, documented engine vocabulary, settings inventory, import diagnostics, subscription copy, and presently specified backup/export surfaces. Catalog content is **PASS**. The native Release path is also **PASS**: its active SwiftUI references have zero missing keys, and generated EN/DE/FR resources exactly match the catalogs. The older web prototype remains a separate integration target.

## Canonical schema contract

Every locale file must use this exact JSON shape:

| Top-level field | Required content |
|---|---|
| `_meta` | `schemaVersion`, `locale`, `sourceLanguage`, `displayName`, `catalogStatus`, `placeholderSyntax`, `pluralCategories`, and `sourceFiles` |
| `strings` | Flat map of stable semantic ID to localized string. Current canonical count: **535**. |
| `placeholders` | Flat map for non-plural formatted strings. Each value maps placeholder name to type. Current canonical count: **12**. |
| `plurals` | Flat map of stable semantic ID to an object containing `placeholders`, `zero`, `one`, and `other`. Current canonical count: **12**. |

Current payload per locale is **547 message IDs**: 535 singular strings plus 12 plural messages. Twelve singular messages have explicit type signatures: two use named `{placeholder}` tokens and ten preserve the native shell’s exact `%lld` or `%@` format tokens.

Example:

```json
{
  "strings": {
    "review.engine_live": "Engine live · {progress}/{maximum}"
  },
  "placeholders": {
    "review.engine_live": {
      "progress": "integer",
      "maximum": "integer"
    }
  },
  "plurals": {
    "count.jobs": {
      "placeholders": { "count": "integer" },
      "zero": "No jobs",
      "one": "One job",
      "other": "{count} jobs"
    }
  }
}
```

Contract rules:

1. Locale files must have exact key parity with `en.json` in `strings`, `placeholders`, and `plurals`.
2. Placeholder names and declared types must be identical across locales. Translators may reorder placeholders but must not add, drop, or rename them.
   Native shell keys and values containing `%lld` or `%@` are an exception to named-brace syntax: those format tokens must remain byte-for-byte identical and in the same count as English.
3. All three plural branches are required. `zero` may use a natural zero phrase without `{count}`; `one` and `other` must preserve the declared signature.
4. Values must not be blank. Engine/store codes such as `PRE_PRODUCTION` or `CSV_UNKNOWN_COLUMN` must never be displayed or used as a translated value.
5. Stable IDs are semantic, not positional. UI code refers to IDs; engine values map to IDs through a closed lookup table.
6. Do not assemble sentences by concatenating translated fragments. Format a complete localized message.
7. StoreKit supplies localized prices. The catalog supplies surrounding copy only; no price string may be hard-coded.
8. Proper names and external identifiers remain unchanged unless the user edits them.

## English source corrections

| Existing or unsafe source | Canonical English | Reason |
|---|---|---|
| Activity | History | Matches an audit trail rather than live social activity. |
| Next safe action | Next step | Shorter and immediately understandable. Safety remains enforced by the engine. |
| Needs job details / HANDOFF | Job setup needed | Explains what the operator must do without exposing workflow jargon. |
| Getting ready / PRE_PRODUCTION | Preparing job | Concrete, active wording. |
| Ready in queue | Queued for production | States what the queue is for. |
| First order garment | First garment from this order | Removes ambiguity about an order's first-ever garment. |
| Supply unknown | Garment supplier not set | Names the missing decision. |
| Vendor | External shop, supplier, or carrier according to role | `Vendor` collapses distinct responsibilities. |
| Release / Released | Ship or pick up / Shipped or picked up | Uses the shop's observable action. |
| Retained outside job | Moved to shop stock | Explains the physical destination. |
| Returned to source | Returned to supplier | Names the receiving party. |
| First article | First piece | More natural shop-floor language; engine code can remain unchanged. |
| Final QC | Final inspection | Plain English for operators and first-time reviewers. |
| Quarantine | Set aside | Prefer on operator-facing screens; retain technical state internally. |
| Commitment date | Due date or in-hands date, selected by meaning | `Commitment` is abstract and the two dates are not interchangeable. |
| Files on this device | Local backups and exports | Describes the contents instead of their location alone. |
| Nothing leaves this device | The file is processed on this device | Avoids an absolute privacy promise that attachments or later exports could contradict. |
| Active operator timeout | Clear active operator after | Describes the setting's effect. |
| Ready to check | Ready to import | Names the next action. |
| Operation instructions advanced | Operation instructions updated | Removes version-control jargon from an operator message. |
| Operation instructions relocked | Updated operation instructions approved | Describes the meaningful business outcome. |
| `titleCase(event.type)` | Closed `event.*` lookup | Mechanical title case leaks implementation language. |
| `error.message` | Closed `error.*` lookup plus safe fields | Raw exceptions are not localized, consistent, or safe. |
| Make the useful thing unlimited | Create unlimited jobs with Pro | Replaces template copy with the actual subscription benefit. |
| Unlimited core actions | Unlimited new jobs | Pro gates only new-job creation. |
| Upgrade to continue using this feature | Five real jobs are free; Pro creates further jobs | Names the actual threshold and gated action. |
| Data remains available according to the derived product’s lapse policy | Existing jobs, completion, backups, and exports remain available | States the locked lapse policy directly. |
| Review advertising consent / Ads remain off until setup succeeds | Review privacy information | The app has no ads, so advertising setup copy is false. |
| Replaceable feature area / replace with feature-specific content | Job summary / job production details | Removes visible shell-template instructions. |

## Source coverage

The source catalog contains:

- all current Home, Jobs, Import, History, Settings, review-shell, sample-workspace, and harness messages;
- all documented job/stage states, decoration methods, supply and ownership states, first-piece choices, production outcomes, artwork/run states, holds, dispositions, entitlement states, account labels, and reason labels;
- labels for all 49 engine command events plus the WorksBIEN import commit and trusted App Store entitlement-observation events;
- 83 error messages, including all 50 defined CSV diagnostics, both native-shell fallback error strings, and the localized CSV row label;
- all 108 original native-shell runtime keys plus the product-screen keys found by the final SwiftUI source scan;
- 12 plural messages and 12 typed non-plural placeholder signatures;
- subscription, restore-purchase, offline-verification, destructive confirmation, backup, export, privacy, terms, and accessibility labels currently specified by the product materials.

## Remaining integration and verification work

| Blocker | Required fix |
|---|---|
| The older web prototype hard-codes English strings. | Route it through the same semantic IDs only if it remains a shipping target. This does not affect the native Release build. |
| `ActivityScreen` renders `titleCase(event.type)`. | Map every event type through the closed `event.*` table. |
| Jobs render raw or mechanically title-cased statuses. | Map job and stage states through `status.job.*` and `status.stage.*`. |
| Toasts display raw `error.message`. | Map typed engine error codes to `error.*`; interpolate only allow-listed, escaped fields. |
| Harness and sample data contain hard-coded sentences. | Store semantic IDs and data, then format at render time. |
| Locale-aware formatting is not wired. | Use Swift `Locale`, `Date.FormatStyle`, `Measurement.FormatStyle`, and plural-capable String Catalog substitutions. |
| `labels.ts` models four English locales with empty override maps. | Replace with the single English catalog and add only proven, narrow overrides. |
| The contract promises semicolon-separated European CSV support while the current parser is comma-only. | Add delimiter detection/selection and validate real German/French Excel exports before localized launch. |
| Generated resources can drift after a canonical copy correction. | Regenerate all supported `.lproj` resources from the JSON catalogs and fail CI on missing keys, value drift, or printf/plural mismatch. |
| Help content, App Store metadata, and screenshot copy are not final source documents. | Localize after their source text is frozen. German and French privacy/terms pages now exist and are selected by locale, but still require legal/native review. |

## Release gate

The native Release catalog/resource gate is closed with zero machine-detected gaps. Before describing the app as fully localized, complete device truncation and VoiceOver checks, German/French CSV and backup round trips, StoreKit purchase-state tests, legal review, and in-context review by qualified German- and French-speaking print-shop users. This audit is research-backed language work, not human-native certification.
