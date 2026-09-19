# German and French Localization QA

## Scope and status

Reviewed locales: `de-DE` and `fr-FR`, both translated from the locked `en.json` master. The catalogs use natural trade vocabulary for garment decoration and keep machine identifiers untranslated. Catalog and generated-resource integration are release-ready, but neither locale is certified by a human native reviewer. Device testing, legal review, and real-world import/export fixtures remain release gates.

Status meanings:

- **PASS** — completed in the catalogs and machine-verified.
- **PROVISIONAL** — translated with a defensible term, but requires in-context or trade-user confirmation.
- **BLOCKED** — the required source, feature, fixture, or UI implementation is not available.
- **N/A** — the current product deliberately has no such surface.

## Completed surface checklist

| Surface | de-DE | fr-FR | Finding / release condition |
|---|---:|---:|---|
| Catalog schema and semantic IDs | PASS | PASS | Exact parity with `en.json`: 535 singular strings, 12 plurals, and 12 typed singular placeholder signatures; no positional or screen-index keys. |
| Native release runtime keys | PASS | PASS | Final release-source scan found no missing EN/DE/FR catalog key. The product-specific CSV row label and paywall separator are covered; all `%lld` and `%@` tokens are preserved exactly. |
| Navigation and primary actions | PASS | PASS | Home, Jobs, Import, History, Settings, Done, Reset, See all, and View jobs are localized. |
| Calm Summary home | PASS | PASS | Next step, attention, stage summary, and dashboard labels are concise. |
| Jobs, search, and queue states | PASS | PASS | Native job and stage labels use closed mappings. The older web prototype still title-cases raw values but is outside this native Release gate. |
| Sample customers, dates, and job states | PASS | PASS | Proper names remain unchanged; relative-date rendering must be generated at runtime. |
| Guided sample workflow | PASS | PASS | Setup, first piece, production, final inspection, packing, handoff, completion, and reset are covered. |
| Receiving and supply ownership | PASS | PASS | Shop-supplied, customer-supplied, unknown supplier, damaged/wrong/set-aside receiving buckets, receipts, shortages, and ownership outcomes are covered. |
| Decoration methods | PASS | PASS | Screen printing, embroidery, DTF, DTG, heat press, and sublimation use established trade terms. |
| Operations, setup, first piece, and rework | PASS | PROVISIONAL | German `Nacharbeit` is stable. French `reprise` is used; confirm against `retouche` with target shops in screen context. |
| Artwork and production approval | PASS | PASS | User labels avoid exposing internal lock/revision jargon. French `BAT` is not used generically; reserve it for an actual proof approval. |
| QC, packing, shipment/pickup | PASS | PASS | Operator-facing terms use `Endkontrolle` / `contrôle final`, `Verpacken` / `conditionnement`, and explicit shipment/pickup wording. |
| Holds, spoilage, replacements, cancellation | PASS | PASS | `Ausschuss` / `rebut`, replacement obligations, decisions, and dispositions are covered. |
| External shop, supplier, carrier roles | PASS | PASS | One generic `vendor` translation is avoided; each role is named by responsibility. |
| Engine statuses and enums | PASS | PASS | Visible values map through stable semantic IDs; engine/store codes remain unchanged internally. |
| Event/history labels | PASS | PASS | All 49 engine commands plus import commit and trusted App Store entitlement observation have labels: 51 total. Native product screens use closed keys; the older web prototype still contains `titleCase(event.type)`. |
| Error messages and recovery actions | PASS | PASS | 83 messages, including all 50 CSV diagnostics, both native-shell fallback errors, and `Row %lld`, are localized. Native product screens use typed keys. |
| Confirmations and destructive actions | PASS | PASS | Workspace erasure and sample reset/remove copy is explicit. Destructive-action UI behavior still needs device testing. |
| Empty and loading states | PASS | PASS | Native-shell loading, empty, selection, and retry states are translated with product-specific copy rather than template instructions. |
| Accessibility labels and hints | PROVISIONAL | PROVISIONAL | Known shell controls are covered. VoiceOver order, Dynamic Type, rotor, and control-label behavior still require device testing in the SwiftUI build. |
| Plurals | PASS | PASS | 12 plural messages contain required zero/one/other branches with matching typed placeholders. |
| Non-plural placeholders | PASS | PASS | Twelve signatures match English exactly: two named-brace messages and ten native `%lld`/`%@` messages. |
| Dates, times, numbers, quantities, and units | PROVISIONAL | PROVISIONAL | Native display uses system `Locale` and Swift format styles. Device output and imported numeric/date variants still require locale-specific fixtures. |
| CSV import guidance and diagnostics | PROVISIONAL | PROVISIONAL | Copy and all known errors are covered. BLOCKED on comma/semicolon detection and real Excel fixtures from Germany and France. |
| Export, PDF, and traveler | PROVISIONAL | PROVISIONAL | Use `Laufkarte/Auftragsbegleitschein` and `fiche suiveuse`. BLOCKED until representative PDFs/exports can be rendered and inspected. |
| Backup and restore | PROVISIONAL | PROVISIONAL | Actions and warnings are covered. BLOCKED on localized filenames, filesystem dialogs, round-trip restore, and corruption testing. |
| Paywall, subscription, restore purchases | PASS | PASS | Copy states five real jobs free, unlimited new-job creation with Pro, no ads, no timed trial, monthly/annual StoreKit pricing, and continued access to existing jobs/completion/backups/exports after expiry. BLOCKED on StoreKit price/period rendering and purchase-state device tests. |
| Compiled onboarding copy | PASS | PASS | Onboarding is disabled, but all retained keys are naturally translated and product-specific if a legal gate invokes them. |
| Settings inventory | PASS | PASS | All currently specified settings, destructive actions, diagnostics, and version/help row are covered. |
| Help content | BLOCKED | BLOCKED | No final help source exists. |
| Privacy policy and terms | PROVISIONAL | PROVISIONAL | `PRIVACY.de-DE.md`, `TERMS.de-DE.md`, `PRIVACY.fr-FR.md`, and `TERMS.fr-FR.md` faithfully preserve the English product facts, dates, email, Apple terms, and EULA link. Legal/native review remains required; this is not legal certification. |
| Notifications | N/A | N/A | No notification surface is specified. If added, foreground/background/action copy requires a new extraction. |
| App Store metadata and screenshot text | BLOCKED | BLOCKED | Requires final ASO title/subtitle/keywords and separate storefront review. Runtime translations do not certify store metadata. |
| iPhone/iPad truncation and layout | BLOCKED | BLOCKED | Requires the implemented SwiftUI app, Dynamic Type sizes, landscape, split view, and smallest supported devices. |
| Debug-only Shell Lab | BLOCKED | BLOCKED | The Release app excludes this view. A DEBUG build still contains 14 English `LocalizedStringKey` literals plus verbatim enum/state values; localizing it requires Swift changes and is not a TestFlight release blocker. |
| Human trade-language review | BLOCKED | BLOCKED | At least one qualified native speaker per locale who understands garment decoration must review the app in context. |

## Final machine-gate results

| Check | Result |
|---|---:|
| JSON catalog parsing | PASS — 3/3 |
| Catalog parity | PASS — 535 strings, 12 signatures, and 12 plurals per locale |
| Active Release SwiftUI references | PASS — 188 unique references, 0 missing |
| Generated `.strings` parity | PASS — 535/535 per locale, 0 missing, 0 extra, 0 value drift |
| Generated `.stringsdict` parity | PASS — 12/12 per locale, 0 missing, 0 extra, 0 value or structural drift |
| Printf compatibility | PASS — all `%lld`, `%@`, and positional specifiers match their signatures |
| Engine event labels | PASS — 49/49 commands plus 2 system/import events |
| CSV diagnostics | PASS — 50/50 |
| Legal translation structure and fixed identifiers | PASS — 4/4 documents |
| Localized legal URL routing | PASS — de-DE and fr-FR privacy and terms routes |
| Total machine failures | **0** |

## Canonical trade glossary

| Concept | English master | de-DE | fr-FR | Note |
|---|---|---|---|---|
| Screen printing | Screen printing | Siebdruck | sérigraphie | Natural established trade term. |
| Embroidery | Embroidery | Stickerei | broderie | Use for the decoration method. |
| Direct to film | DTF printing | DTF-Druck | impression DTF | Retain the industry acronym. |
| Direct to garment | DTG printing | DTG-Druck | impression DTG | Retain the industry acronym. |
| Heat press | Heat press | Transferpresse | presse à chaud | Prefer the machine/process term over a literal press verb. |
| Sublimation | Sublimation | Sublimationsdruck | sublimation | Established process wording. |
| Job traveler | Traveler | Laufkarte / Auftragsbegleitschein | fiche suiveuse | Use the longer German form where first-time clarity matters. |
| First piece | First piece | erstes Teil / Musterstück | première pièce | Do not translate literally as article. |
| First-piece approval | Approve first piece | Erstes Teil freigeben | valider la première pièce | `BAT` only when approving an actual proof. |
| Final inspection | Final inspection | Endkontrolle | contrôle final | More operator-friendly than exposing `QC`. |
| Rework | Needs rework | Nacharbeit erforderlich | reprise nécessaire | French term remains field-test provisional. |
| Spoilage | Spoiled | Ausschuss | rebut | Refers to unusable production output. |
| External decorator | External shop | externer Veredler | sous-traitant | Do not collapse into supplier. |
| Supplier | Supplier | Lieferant | fournisseur | Garment/material source. |
| Workstation | Workstation | Arbeitsplatz | poste de travail | Production station, not a computer. |
| Packing | Packing | Verpacken | conditionnement | `Emballage` may mean the package material rather than the operation. |
| Set aside | Set aside | zurückgestellt | mis de côté | Prefer on operator screens over quarantine jargon. |
| Ship or pick up | Ship or pick up | versenden oder abholen | expédier ou remettre au client | Explicit physical outcome. |

## Literal or unsafe translations to reject

| Do not use | Why | Preferred handling |
|---|---|---|
| German `Bildschirmdruck` for screen printing | Literal and wrong in this trade context. | `Siebdruck` |
| French `impression écran` for screen printing | Literal calque. | `sérigraphie` |
| German `erster Artikel` or French `premier article` | Sounds like a publication or catalog item. | `erstes Teil/Musterstück`; `première pièce` |
| German `Freigabe` or French `libération` for customer handoff | Abstract/legal or mechanically literal. | Name `versenden/abholen`; `expédier/remettre au client`. |
| One translation of `vendor` everywhere | Supplier, decorator, and carrier are different roles. | Translate by role. |
| French `emballage` everywhere for packing | Can denote packaging material rather than the work step. | `conditionnement` for the operation. |
| Raw codes such as `PARTLY_RELEASED` | Internal representation, inaccessible to operators. | Closed lookup to a localized label. |
| Machine-translated error exceptions | May reveal internals and omit a recovery step. | Typed localized error plus row/field context. |
| Hard-coded price, date, decimal, or unit punctuation | Incorrect across regions and storefronts. | System formatters and StoreKit values. |

## Evidence used for terminology

- German manufacturing traveler usage: [L-mobile — Digitale Laufkarte](https://l-mobile.com/wiki/digitale-laufkarte/)
- German textile-decoration framing: [Holfelder — Textile Veredelung](https://holfeldergmbh.de/leistungen/textile-veredelung/)
- German embroidery vocabulary: [Stickin — Stickerei](https://www.stickin.de/stickerei)
- German quality and rework vocabulary: [Quality Miners — Qualität produzieren](https://quality-miners.de/qualitaet-produzieren/)
- French production traveler usage: [Flexio — Fiche suiveuse numérique](https://www.flexio.fr/)
- French inspection vocabulary: [Atelier Grare — Contrôle qualité](https://ateliergrare.fr/blog/controle-qualite-pieces-usinees-metrologie-dimensionnelle/)
- French rework vocabulary: [Tulip — Réduire les reprises](https://tulip.co/fr/blog/manufacturers-guide-to-reducing-rework/)
- French screen-printing vocabulary: [Printful — Sérigraphie textile](https://www.printful.com/fr/blog/serigraphie-textile)
- Apple localization model: [Apple — Localizing and varying text with a string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)

## Final release gate

The JSON catalogs can now drive implementation. Release remains blocked until: the SwiftUI build contains no visible hard-coded English; typed engine mappings replace raw codes/errors; German and French Excel CSV fixtures pass; PDF/export/backup round trips pass; StoreKit pricing formats correctly; VoiceOver and truncation tests pass on iPhone and iPad; legal and storefront sources are finalized; and qualified native trade users sign off in context. This document does not claim human-native certification.
