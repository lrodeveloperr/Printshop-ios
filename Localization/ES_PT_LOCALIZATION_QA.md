# Print Shop Job Manager — Spanish and Brazilian Portuguese Localization QA

**Catalogs:** `es-419.json`, `pt-BR.json`  
**Review scope:** locked Calm Summary prototype plus the v2.1 engine contract/source  
**Status:** **STRUCTURALLY COMPLETE; RELEASE BLOCKED PENDING NATIVE IN-CONTEXT QA AND UI WIRING**  
**Certification claim:** None. This is a research-backed implementation pass, not human-native certification.

## 1. Locale decision

The app should not carry four duplicated English catalogs. Use one canonical English source and locale-aware Foundation formatting. Add small `en-CA`, `en-GB`, or `en-AU` overrides only where terminology, legal copy, or store metadata genuinely differs.

Launch catalog set remains five languages:

1. English source
2. Latin American Spanish (`es-419`; validate on an `es-MX` device/storefront)
3. Brazilian Portuguese (`pt-BR`)
4. German (`de-DE`, owned by the other localization pass)
5. French (`fr-FR`, owned by the other localization pass)

English regional App Store product pages may still be separate for ASO. They are not separate full in-app translations.

## 2. Authority and extraction scope

Reviewed source:

- `/workspace/sites/print-shop-job-manager-test/app/page.tsx`
- `/workspace/sites/print-shop-job-manager-test/app/layout.tsx`
- `/workspace/sites/print-shop-job-manager-test/app/lib/harness.ts`
- v2.1 `engine/src/labels.ts`, `types.ts`, `engine.ts`, `csv.ts`, and `cli.ts`
- `Print-Shop-Engine-v2-Contract.md`
- `Print-Shop-Job-Manager-Implementation-Pack.md`
- `Print-Shop-Job-Manager-Product-Spec.md`
- `print-shop-gate-manifest.json`

Where documents conflict, the implementation pack and v2.1 source govern. The English product name is locked. Spanish and Portuguese titles remain candidate strings pending native garment-decoration review.

The two catalogs now use the canonical `en.json` schema and exact key set. Each contains **533 static strings, 12 plural messages, and 11 explicit placeholder-signature records**:

| Group | Coverage |
|---|---:|
| Prototype, native shell, navigation, Home, Jobs, import, Activity, Settings, onboarding, commerce, guided sample and accessibility copy | Included |
| Static strings | 533 |
| Explicit plural messages | 12 |
| Explicit placeholder signatures | 11 |
| Legacy compiled-shell keys represented in the canonical catalogs | 108/108 |
| Workflow event labels | 51/51 |
| CSV error-code messages | 50/50 |
| English engine-label authority codes | 50/50 |

Customer names, order numbers, filenames, SKUs, artwork references, and other record identity are data, not translatable copy. Sample descriptions and statuses are localized; sample proper names remain unchanged.

## 3. Catalog contract

Each message has one stable semantic ID. Storage codes remain unchanged and must be resolved through the catalog. The top-level `strings`, `plurals`, and `placeholders` objects and every contained key exactly match `en.json`.

Static entry:

```json
"nav.jobs": "Trabajos"
```

Plural entry:

```json
"count.active_jobs": {
  "placeholders": { "count": "Int" },
  "zero": "No hay trabajos activos",
  "one": "{count} trabajo activo",
  "other": "{count} trabajos activos"
}
```

Placeholder signatures are named and typed. Swift String Catalog conversion must preserve the same names and types. UI code must not concatenate grammar-sensitive fragments.

## 4. Surface checklist

`PASS` means the localized catalog content for the known source is complete and structurally checked. `PROVISIONAL` means credible copy exists but an unresolved product or terminology decision remains. `BLOCKED` means the current app cannot truthfully ship that surface as fully localized.

| Surface | Status | Evidence and remaining work |
|---|---|---|
| App name and subtitle | PROVISIONAL | Uses the implementation pack candidates: **Gestor de Producción Gráfica / Serigrafía, bordado y DTF** and **Gestão de Estamparia / Pedidos, bordado e DTF**. Native trade and live-store review is still mandatory. |
| Prototype metadata and review chrome | PASS | Every current title, description, device selector, caption, reset label, engine-progress string, and compiled shell key has a localized entry. Development-only diagnostics must remain excluded from normal production navigation. |
| Navigation | PASS | Home/Jobs/Import/Activity/Settings and navigation accessibility labels are mapped. Product spec later calls for Board/Jobs/Work/More; source must be reconciled before native build. |
| Calm Summary Home | PASS | Counts, next action, attention, stage summary, actions, toast copy, and accessibility summary are mapped. Plural keys replace the prototype's fixed English fragments. |
| Sample data | PROVISIONAL | Customer names and order IDs correctly remain unchanged. Garment descriptions, quantities, states, due terms, guided actions, and reset copy are mapped. Full engine-generated sample travelers/PDFs do not yet exist in the native source. |
| Jobs list/search | PASS | Search, relative due text, sample descriptions and visible states are mapped. Raw `titleCase(job.status)` must be replaced with status keys. |
| Job workspace | BLOCKED | The authoritative product spec defines the surface, but the locked prototype does not implement its fields, exceptions, or accessibility behavior. Cataloged engine terms are ready for wiring, not proof of a complete screen. |
| Receiving | PROVISIONAL | Supply, receipt, shortage, unmatched-receipt, ownership, receiving-exception, reason and account terms are mapped. No production receiving UI exists to validate order, truncation or operator comprehension. |
| Production operations | PROVISIONAL | All six decoration methods, readiness/stage states, setup, first-piece, rework, vendor and batch event labels are mapped. First-piece and loss/refugo wording requires native in-context confirmation. |
| Quality control | PROVISIONAL | Final QC, pass/reject, rework and external-return states are mapped. UI must consistently spell out quality control rather than expose `QC` to VoiceOver. |
| Packing and release | PROVISIONAL | Package, unseal, partial delivery and final delivery events are mapped. The English source does not reliably distinguish shipping, delivery and pickup; source correction is required. |
| Cancellation and holds | PROVISIONAL | Scope and physical-disposition labels are mapped. Required irreversible confirmations and consequence copy are absent from the prototype. |
| Workflow history/activity | BLOCKED | All 51 authoritative event values now have localized labels, including `trusted-store-entitlement-observation`. The prototype still calls `titleCase(event.type)`, exposing hyphenated English codes. Replace that formatter with catalog lookup before release. |
| Domain errors | BLOCKED | All stable error families have localized messages. The prototype passes raw `error.message` into toasts, so English invariant text can leak. Add a code-to-message adapter with structured details. |
| CSV errors | BLOCKED | All 50 CSV codes plus row/field wrappers are mapped. Current UI shows raw parser messages; it must render localized code copy and separately interpolate row, field, received value and expectation. |
| Confirmations and irreversible actions | BLOCKED | No final localized confirmation inventory exists for cancel, discard, return, unseal, restore or replacement decisions. Use explicit action labels, never generic Yes/No or Sim/Não. |
| Accessibility labels and hints | BLOCKED | Current navigation, Settings, Home summary and search labels are covered. The full native screen inventory, VoiceOver hints/values, rotor order and dynamic-type checks do not exist. |
| Plurals | PASS | Twelve count families contain explicit `zero`, `one` and `other` variants with matching `{count:Int}` signatures. Convert them to String Catalog plural variations; do not keep fixed singular English fragments. |
| Dates, time, numbers and units | BLOCKED | Source currently calls `toLocaleString` but the site document is fixed to `en-US`. Native UI must use `Date.FormatStyle`, `Number.FormatStyle` and explicit shop-unit preferences. Never hand-build dates or decimal separators. |
| CSV import flow | BLOCKED | All present buttons, states, counts and 50 parser-error codes are mapped. Runtime still needs localized header aliases, comma/semicolon/tab detection, UTF-8/BOM testing and removal of raw English errors. Canonical export data should retain ISO 8601 dates and stable machine headers. |
| Exports and PDF traveler | BLOCKED | Contract requires localized travelers and exports, but no rendering source or complete label inventory exists. Must test fonts for ñ/á/ç/ã/õ, wrapping, repeated headers, pagination, status/reason mapping and safe filenames. |
| Backup and restore | BLOCKED | Shell labels, keep/replace conflict choices, local-first notice, and common storage errors are mapped. Restore progress, success, destructive confirmation, and complete corruption/incompatible-version handling still need runtime review. |
| Paywall and subscription | PROVISIONAL | The catalog truthfully states five real jobs free, Pro-only unlimited new-job creation, no ads, no timed trial, monthly/annual App Store pricing, and continued access to existing jobs, completion, backups and exports after expiry. Purchase, restore, pending, verification, billing-retry, grace and expiry copy is mapped. Release still requires StoreKit-sourced prices/cadence and native transaction-state testing. |
| Settings | PROVISIONAL | Every currently visible row is mapped. Language selection, shop units, operator reset, storage use, sample reset, export/archive, subscription and legal subflows are not implemented in the prototype. |
| Help, privacy and terms | BLOCKED | Only the Settings destination is present. Localized legal/help content and locale-correct URLs must ship with the locale; an English-only page fails the 100% localization requirement. |
| Empty states | PROVISIONAL | The compiled shell's Jobs, selection and backup empty states are mapped, as is the Activity empty state. Import history, search-no-results, archived jobs and unavailable-purchase empty states still need a final inventory. |
| Loading/progress/offline states | BLOCKED | Shell loading/error/retry and StoreKit loading/retry copy is mapped. Import, restore and export progress remain incomplete. Local production copy does not imply that internet is required, but the behavior still needs device testing. |
| Notifications | PROVISIONAL | No local notifications are defined in the locked launch source. Do not add them during translation. If reminders are added, title/body/action/accessibility copy needs a new reviewed inventory. |
| Locale switching with existing records | BLOCKED | Stored engine codes are locale-safe, but no native language switch or cross-locale persistence test exists. User-entered data must never be translated or rewritten. |
| Store screenshots and metadata | BLOCKED | App names/subtitles are candidate copy only. Screenshots, description, keywords, privacy answers and subscription disclosures require a separate store-localization pass. |

## 5. Canonical authority additions — resolved

The 29 approved English authority keys are now present in both localized catalogs without adding locale-only keys:

- 11 import-preview labels: classifications, record types and route-target types.
- 2 language-picker labels: Latin American Spanish and Brazilian Portuguese.
- 2 replacement-supply decisions and 3 external-return results.
- 2 revision decisions, 3 actor kinds and 3 receiving buckets.
- 1 trusted-store entitlement event and 2 safe fallback errors.

Machine comparison confirms exact key parity with `en.json`. The targeted v2.1 inventories now cover all 50 presentation-label codes, all 51 authoritative event values, and all 50 CSV error codes. Any future engine code must be added to English and every locale in the same change; the UI must use a safe localized fallback rather than render an unknown raw code.

The subsequent runtime-shell reconciliation added 107 previously absent static keys and 9 placeholder signatures; together with the already shared subscription-management key, this covers all **108/108** keys in the compiled English shell inventory. It also localizes compiled-but-currently-unused onboarding and diagnostic states so a future code path cannot silently fall back to English. The old generic `.strings` values were used only as a key inventory; corrected product-specific values in `en.json` remained the semantic authority.

## 6. Suggested source corrections

These are source-copy corrections, not silent translation choices. The English master should be repaired before native catalogs are generated.

| Current English | Problem | Suggested source |
|---|---|---|
| `Calm Summary` | Internal design-direction name, not a user task | Do not show in the production app. Use `Home` or `Production summary`. |
| `Job` everywhere | Can mean customer order, production order or operation | Lock entity names: `Order` for the customer commitment, `production job` only where truly distinct, `operation` for one process step. |
| `Release package` | Does not state whether the package was shipped, delivered or picked up | Require fulfillment mode, then use `Record shipment`, `Record delivery`, or `Record pickup`. |
| `All four shirts are released` | Software jargon; physical outcome is unclear | `All four shirts were shipped, delivered, or picked up, and all quantities balance.` |
| `Ready for release` | Same ambiguity | `Ready for shipment, delivery, or pickup`, or a mode-specific label. |
| `Released to customer` / `Shipped or picked up` | Omits local delivery and merges different custody events | Use a dynamic outcome label based on the recorded mode. |
| `Returned to source` | Source may be supplier or customer | Use `Returned to supplier` or `Returned to customer` from the recorded owner. |
| `First order garment` | Unnatural English | `First piece from this order`. |
| `Test substrate` → `Test print` | A substrate and a printed test are not always the same physical object | Confirm whether the mode consumes a test material; name the physical object explicitly. |
| `Vendor rejected; shop decision pending` | It is unclear whether the vendor rejected the job or classified returned units as rejected | `Vendor marked returned pieces as rejected; shop decision pending.` |
| `Production` in the sample queue | Could mean ready, running or generally in production | Use the derived state: `Ready to start`, `In progress`, or the current operation name. |
| `QC` in visible or spoken copy | Abbreviation is weak for unfamiliar reviewers and VoiceOver | Display and speak `Quality check`; retain `QC` only where space is proven insufficient. |
| `Create package` | Describes a database record rather than the shop action | `Pack 4 shirts` or `Confirm package` depending on whether packing has physically happened. |
| `Pass final inspection` | `Pass` can describe the object or the action | `Approve final quality check`. |
| `Mark 4 good` | Colloquial and lacks the operation | `Record 4 approved`. |
| `Nothing leaves this device` | Too absolute if StoreKit verification, remote legal pages or user-initiated exports use network/sharing | `This CSV is processed on this device.` Keep the broader privacy promise in reviewed policy copy. |
| `Reset` | Could imply deleting the entire workspace | `Reset sample job`. |
| `Files on this device` | Does not explain export/backup destination or scope | `Stored on this device`; explain export separately. |
| `titleCase(event.type)` and `titleCase(status)` | Produces raw or malformed code labels and cannot localize | Resolve every code through `event.*` and `status.*` catalogs; unknown codes display a safe localized fallback and are logged. |
| Raw `error.message` in toasts | Leaks developer English and may expose internal identifiers | Resolve the stable code to localized copy, then add structured row/field/job context. Never show the raw invariant message by default. |

## 7. Terminology decisions and provisional terms

### Locked for this pass

- `screen printing` → **serigrafía** / **serigrafia**
- `embroidery` → **bordado** / **bordado**
- `heat press` → **prensa térmica** / **prensa térmica**
- `sublimation` → **sublimación** / **sublimação**
- `DTF` and `DTG` remain recognized trade acronyms, expanded on first use and in accessibility copy.
- `artwork` → **diseño/archivo de diseño** in Spanish; **arte/arquivo da arte** in Brazilian Portuguese.
- `rework` → **retrabajo** / **retrabalho**.
- `workstation` → **estación de trabajo** / **posto de trabalho**.
- `due date` is expressed as a delivery deadline, not a literal commitment date.

### Provisional pending native shop-floor review

- Spanish top-level `Trabajo` versus `Pedido` versus `Orden de producción`.
- Portuguese top-level `Ordem` versus `Pedido` versus `Ordem de produção`.
- Portuguese production loss `perda` versus formal `refugo`.
- Spanish `primera pieza` versus `muestra inicial`; Portuguese `primeira peça` versus `amostra inicial`.
- `package`, `batch`, `lot`, `release`, and exact fulfillment-mode language.
- Candidate store names and subtitles.

Do not translate `traveler` as *viajero* or *viajante*. The native surface should use **hoja de producción** in Spanish and **ficha de produção** in Brazilian Portuguese after the PDF contents are finalized.

## 8. Required native runtime gate

Before either locale can be marked release-ready:

1. Convert the JSON entries to the native String Catalog without changing IDs or placeholder signatures.
2. Replace every literal in the SwiftUI production target; development preview chrome must be excluded.
3. Replace `titleCase` and raw `error.message` paths with catalog lookup.
4. Render every key on iPhone SE and iPad in portrait and landscape, with largest supported Dynamic Type.
5. Walk normal, interrupted and exception paths for receiving, first piece, all six methods, vendor work, QC, rework, packing, partial delivery, cancellation, CSV import, export, backup/restore and entitlement expiry.
6. Verify VoiceOver labels, hints, values, focus order and pronunciation of DTF/DTG.
7. Test zero, one, two and large counts for every plural key.
8. Test locale switching with existing records and confirm that identifiers and user-entered text are unchanged.
9. Render every CSV error using structured row/field context and confirm no English message or raw code appears.
10. Obtain fluent in-context review by someone familiar with garment decoration in Latin America and Brazil; fix findings upstream and repeat screenshots/tests.

## 9. Machine-check results

Run against both catalogs after creation:

```text
Localized catalogs checked:              2
Static strings per locale:             533
Plural messages per locale:             12
Explicit placeholder signatures:        11
Static-string key differences vs en:      0
Plural-key differences vs en:             0
Placeholder-key differences vs en:        0
Blank values:                             0
Placeholder signature mismatches:         0
Placeholder token mismatches:             0
Values equal to raw machine codes:         0
Compiled-shell keys covered:          108/108
Commerce-contract keys covered:          9/9
English label-authority codes covered:    50/50
Workflow event labels in catalog:         51
Authoritative event values covered:       51/51
CSV error codes covered:                  50/50
```

Both files parse as valid JSON. This Spanish/Portuguese pass did not edit the German or French catalogs.

## 10. Current verdict

The Spanish and Brazilian Portuguese catalogs are suitable as an implementation baseline and close the known structural vocabulary gaps, including the compiled shell and paywall states. They do **not** yet establish 100% product localization because several native workflows, complete legal/help content, export rendering, runtime catalog wiring, and in-context native QA are still unverified. Release status for both locales remains **BLOCKED** until the runtime gate above passes.
