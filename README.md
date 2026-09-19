# Print Shop Job Manager for iPhone and iPad

Native Swift 6 and SwiftUI app for tracking decorated-apparel jobs from CSV handoff through receiving, setup, production, final check, packing, and release.

## Product rules

- Local-first: no account or cloud service is required.
- Four-tab Calm Summary interface for iPhone and iPad.
- CSV files are parsed on-device; backups and exports are user-controlled files.
- Five real jobs can be created free. Pro unlocks unlimited new-job creation.
- Existing jobs, completion, backups, and exports remain available without Pro.
- No ads and no timed trial.
- Localized in English, Latin American Spanish, Brazilian Portuguese, German, and French.

## Build

The project is generated with XcodeGen and targets iOS 18 or later.

```sh
brew install xcodegen
python3 scripts/generate-localizations.py
scripts/validate-shell.sh --release
xcodegen generate
xcodebuild -project Shell.xcodeproj -scheme Shell -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

The TestFlight workflow is intentionally manual and requires the exact confirmation phrase shown in the workflow-dispatch form.

## StoreKit products

- `com.worksbienstudios.printshopjobmanager.pro.monthly`
- `com.worksbienstudios.printshopjobmanager.pro.annual`

Prices are always loaded from StoreKit for the current App Store storefront.
