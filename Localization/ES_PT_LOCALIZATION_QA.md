# Print Shop Job Manager — Spanish and Brazilian Portuguese Localization QA

**Catalogs:** `es-419.json`, `pt-BR.json`  
**Review scope:** native SwiftUI TestFlight app, generated Apple resources, locked Calm Summary prototype, and v2.1 engine contract/source  
**Status:** **NATIVE CATALOG GATE PASS; DEVICE AND HUMAN IN-CONTEXT REVIEW STILL REQUIRED**  
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

- Native `Shell/Product`, `Shell/Features`, `Shell/App`, and `Shell/Services` Swift sources
- Generated `Shell/Resources/{es-419,pt-BR}.lproj` `.strings` and `.stringsdict` files
- `PRIVACY.md`, `TERMS.md`, and the four controlled ES-419/PT-BR legal localizations
- `/workspace/sites/print-shop-job-manager-test/app/page.tsx`
- `/workspace/sites/print-shop-job-manager-test/app/layout.tsx`
- `/workspace/sites/print-shop-job-manager-test/app/lib/harness.ts`
- v2.1 `engine/src/labels.ts`, `types.ts`, `engine.ts`, `csv.ts`, and `cli.ts`
- `Print-Shop-Engine-v2-Contract.md`
- `Print-Shop-Job-Manager-Implementation-Pack.md`
- `Print-Shop-Job-Manager-Product-Spec.md`
- `print-shop-gate-manifest.json`

Where documents conflict, the implementation pack and v2.1 source govern. The English product name is locked. Spanish and Portuguese titles remain candidate strings pending native garment-decoration review.

The two catalogs now use the canonical `en.json` schema and exact key set. Each contains **535 static strings, 12 plural messages, and 12 explicit placeholder-signature records**:

| Group | Coverage |
|---|---:|
| Prototype, native shell, navigation, Home, Jobs, import, Activity, Settings, onboarding, commerce, guided sample and accessibility copy | Included |
| Static strings | 535 |
| Explicit plural messages | 12 |
| Explicit placeholder signatures | 12 |
| Generated Apple static-string resources | 535/535 per locale |
| Generated Apple plural dictionaries | 12/12 per locale |
| Current Swift catalog references | 199/199 |
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
| Navigation | PASS | Home, Jobs, Import, History, Settings, language selection, and navigation accessibility labels resolve through the generated locale resources. |
| Calm Summary Home | PASS | Counts, next action, attention, stage summary, empty state, actions, and accessibility summary are mapped. Plural keys replace fixed count fragments. |
| Sample data | PASS | Customer names and order IDs correctly remain unchanged. Garment descriptions, quantities, states, due terms, actions, reset, and removal copy are localized in the native app. |
| Jobs list/search | PASS | Search, locale-formatted due dates, sample descriptions, status pills, and visible states use catalog keys or user data. No raw status code is rendered. |
| Job workspace | PASS | Every user-visible string in the current simplified native job-detail screen resolves through the catalog. This does not claim that every future v2.1 workflow screen has been implemented. |
| Receiving | PROVISIONAL | Supply, receipt, shortage, unmatched-receipt, ownership, receiving-exception, reason and account terms are mapped. No production receiving UI exists to validate order, truncation or operator comprehension. |
| Production operations | PROVISIONAL | All six decoration methods, readiness/stage states, setup, first-piece, rework, vendor and batch event labels are mapped. First-piece and loss/refugo wording requires native in-context confirmation. |
| Quality control | PROVISIONAL | Final QC, pass/reject, rework and external-return states are mapped. UI must consistently spell out quality control rather than expose `QC` to VoiceOver. |
| Packing and release | PROVISIONAL | Package, unseal, partial delivery and final delivery events are mapped. The English source does not reliably distinguish shipping, delivery and pickup; source correction is required. |
| Cancellation and holds | PROVISIONAL | Scope and physical-disposition labels are mapped. Required irreversible confirmations and consequence copy are absent from the prototype. |
| Workflow history/activity | PASS | All 51 authoritative engine events and every event emitted by the native product store resolve through catalog keys. The previously missing replacement-history key was removed from the native path. |
| Domain errors | PASS | Active startup, product, file, import, and StoreKit error paths now resolve to localized safe messages. Disabled future backup/advertising providers must be re-audited if enabled. |
| CSV errors | PASS | All 50 canonical CSV messages are present. The native parser's active subset resolves through localized keys and uses the typed `error.row` printf label rather than a bare row number. |
| Confirmations and irreversible actions | PROVISIONAL | Current native actions use explicit localized labels. Future full-engine cancel, discard, return and unseal confirmations need a separate inventory when those screens are implemented; never use generic Yes/No or Sim/Não. |
| Accessibility labels and hints | PROVISIONAL | Current navigation, Settings, Home summary, paywall, legal actions and search labels are localized. VoiceOver focus order, pronunciation and largest Dynamic Type still require device testing. |
| Plurals | PASS | Twelve count families contain explicit `zero`, `one` and `other` variants with matching `{count:Int}` signatures. Convert them to String Catalog plural variations; do not keep fixed singular English fragments. |
| Dates, time, numbers and units | PASS | Native dates and subscription dates use locale-aware Foundation format styles. Canonical CSV export correctly retains machine-safe ISO dates. |
| CSV import flow | PASS | Buttons, states, counts, active parser errors and row labels are localized. The parser accepts comma, semicolon, tab and pipe delimiters plus UTF-8/UTF-16 BOM input; stable machine headers and user data remain untranslated. |
| Exports and PDF traveler | PROVISIONAL | Current CSV export uses stable machine headers and preserves user data. The future full-engine PDF traveler has no rendering source yet and will require font, wrapping, pagination, status/reason and filename QA. |
| Backup and restore | PASS | The current local export/backup/restore rows and safe errors are localized. The misleading add-or-replace subtitle was removed from the direct file-restore path; the optional provider-based conflict screen remains disabled. |
| Paywall and subscription | PROVISIONAL | The catalog truthfully states five real jobs free, Pro-only unlimited new-job creation, no ads, no timed trial, monthly/annual App Store pricing, and continued access to existing jobs, completion, backups and exports after expiry. Purchase, restore, pending, verification, billing-retry, grace and expiry copy is mapped. Release still requires StoreKit-sourced prices/cadence and native transaction-state testing. |
| Settings | PASS | Every currently visible row, subtitle, subscription status, language option, sample action, local export/backup action, and legal destination is mapped. Debug-only Shell Lab text is excluded from release builds. |
| Help, privacy and terms | PASS | Faithful ES-419 and PT-BR privacy policies and terms exist, and `LegalView` selects locale-specific URLs with English fallback. The four files must be pushed in the same commit as the configured URLs. |
| Empty states | PASS | Home, Jobs/search, History, selection and backup empty states resolve through appropriate localized keys. The Home screen no longer reuses History copy. |
| Loading/progress/offline states | PASS | Current shell, import, safe file-error, StoreKit loading/retry and offline-verification copy is mapped. Local production copy does not imply that internet is required. |
| Notifications | PROVISIONAL | No local notifications are defined in the locked launch source. Do not add them during translation. If reminders are added, title/body/action/accessibility copy needs a new reviewed inventory. |
| Locale switching with existing records | PROVISIONAL | The native selector exposes the five complete catalogs plus System and persists the choice. Stored codes and user data remain unchanged; cross-locale persistence still needs device testing. |
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

The final native pass added the typed `error.row` message and the localized SwiftUI separator key, bringing the authority to **535 static strings and 12 placeholder signatures**. It also verified every current Swift reference, corrected the device-processing, empty-state, final-inspection, package-release, replacement-history and App Store price-loading wording, and generated matching Apple resources. Current native key gap: **0**.

## 6. Open full-engine source corrections

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
| `Reset` | Could imply deleting the entire workspace | `Reset sample job`. |
| `Files on this device` | Does not explain export/backup destination or scope | `Stored on this device`; explain export separately. |

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

Before either locale can be marked fully release-certified:

1. **PASS —** Generate native `.strings` and `.stringsdict` resources without changing IDs or typed placeholder signatures.
2. **PASS —** Scan the production Swift target: all 199 current catalog references resolve, with no active English literal or raw code path found.
3. **PASS —** Route startup, product, file, import and StoreKit failures through localized safe messages.
4. Render every screen on compact iPhone and iPad layouts, in portrait and landscape where supported, with the largest supported Dynamic Type.
5. Walk every implemented normal, interrupted and exception path for sample jobs, CSV import, replacement handling, production progress, final inspection, packing, release, local export/backup/restore and entitlement expiry.
6. Verify VoiceOver labels, hints, values, focus order and pronunciation of DTF/DTG on devices.
7. Test zero, one, two and large counts for all 12 plural keys; structural plural validation already passes.
8. Test locale switching with existing records and confirm that identifiers and user-entered text remain unchanged.
9. Trigger every active CSV error with structured row context and confirm no English message or raw code appears; structural key and printf validation already passes.
10. Obtain fluent in-context review by garment-decoration users in Latin America and Brazil; fix findings upstream and repeat screenshots/tests.

## 9. Machine-check results

Run against both catalogs after creation:

```text
Localized catalogs checked:              2
Static strings per locale:             535
Plural messages per locale:             12
Explicit placeholder signatures:        12
Static-string key differences vs en:      0
Plural-key differences vs en:             0
Placeholder-key differences vs en:        0
Blank values:                             0
Placeholder signature mismatches:         0
Placeholder token mismatches:             0
Values equal to raw machine codes:         0
Current Swift catalog refs covered:   199/199
Missing current Swift keys:                 0
Generated static resources:           535/535 per locale
Generated plural dictionaries:          12/12 per locale
Generated value/printf mismatches:           0
Generated plural-rule mismatches:            0
Commerce-contract keys covered:          9/9
English label-authority codes covered:    50/50
Workflow event labels in catalog:         51
Authoritative event values covered:       51/51
CSV error codes covered:                  50/50
Localized legal documents:                  4/4
Localized legal URL routes:                  4/4
```

Both files parse as valid JSON. This Spanish/Portuguese pass did not edit the German or French catalogs.

## 10. Current verdict

**Final native catalog verdict: PASS with zero active key, generated-resource, placeholder, plural or legal-routing gaps for ES-419 and PT-BR.** The current SwiftUI product surfaces, Settings, language selector, paywall, active errors and localized legal pages are fully represented in both generated bundles.

This is not a claim of human-native certification or complete future v2.1 engine localization. Device layout, VoiceOver, end-to-end exception-path testing, legal-page publication in the release commit, and fluent garment-decoration user review remain release-process gates.
