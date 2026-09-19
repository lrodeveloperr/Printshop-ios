import SwiftUI

enum ShellConfiguration {
    static let appName = "Print Shop Job Manager"
    static let tint = Color(red: 0.02, green: 0.27, blue: 0.38)
    static let supportEmail = "support@worksbienstudios.com"

    static let legal = LegalConfiguration(
        version: "2026-09-19",
        privacyURL: URL(string: "https://github.com/lrodeveloperr/Printshop-ios/blob/main/PRIVACY.md")!,
        termsURL: URL(string: "https://github.com/lrodeveloperr/Printshop-ios/blob/main/TERMS.md")!,
        localizedPrivacyURLs: [
            "es-419": URL(string: "https://github.com/lrodeveloperr/Printshop-ios/blob/main/PRIVACY.es-419.md")!,
            "pt-BR": URL(string: "https://github.com/lrodeveloperr/Printshop-ios/blob/main/PRIVACY.pt-BR.md")!,
            "de-DE": URL(string: "https://github.com/lrodeveloperr/Printshop-ios/blob/main/PRIVACY.de-DE.md")!,
            "fr-FR": URL(string: "https://github.com/lrodeveloperr/Printshop-ios/blob/main/PRIVACY.fr-FR.md")!,
        ],
        localizedTermsURLs: [
            "es-419": URL(string: "https://github.com/lrodeveloperr/Printshop-ios/blob/main/TERMS.es-419.md")!,
            "pt-BR": URL(string: "https://github.com/lrodeveloperr/Printshop-ios/blob/main/TERMS.pt-BR.md")!,
            "de-DE": URL(string: "https://github.com/lrodeveloperr/Printshop-ios/blob/main/TERMS.de-DE.md")!,
            "fr-FR": URL(string: "https://github.com/lrodeveloperr/Printshop-ios/blob/main/TERMS.fr-FR.md")!,
        ]
    )

    /// Set to nil when the product does not have a genuine onboarding need.
    /// Published legal links alone do not require a blocking acceptance screen.
    static let onboarding: OnboardingProfile? = nil

    static let monetization = MonetizationConfiguration(
        mode: .creationCapWithSubscription,
        freeSuccessfulActions: 5,
        lifetimeProductID: "com.worksbienstudios.printshopjobmanager.pro.lifetime",
        subscriptionProductID: "com.worksbienstudios.printshopjobmanager.pro.monthly",
        annualSubscriptionProductID: "com.worksbienstudios.printshopjobmanager.pro.annual"
    )

    static let advertising = AdvertisingConfiguration(
        bannerUnitID: "ca-app-pub-3940256099942544/2435281174"
    )

    /// Cloud is absent by default. A derived app must enable this and inject an
    /// app-owned provider only after privacy, entitlements and conflict UX review.
    static let backup = BackupConfiguration(enabled: false)

    /// New installs record the current contract. Derived apps add an explicit,
    /// ordered step here before adopting a breaking shell contract.
    static let migrations: [ShellMigration] = []

    static let destinations: [ShellDestination] = [
        .init(id: "home", titleKey: "nav.home", symbol: "house"),
        .init(id: "jobs", titleKey: "nav.jobs", symbol: "tray.full"),
        .init(id: "import", titleKey: "nav.import", symbol: "square.and.arrow.down"),
        .init(id: "history", titleKey: "nav.history", symbol: "clock.arrow.circlepath"),
    ]

    /// Only locales with complete app text belong here. The 31-locale shared
    /// terminology baseline is tracked separately in LocalizationBaseline.swift.
    static let supportedLanguages: [AppLanguage] = [
        .init(id: "system", displayNameKey: "settings.language.system"),
        .init(id: "en", displayNameKey: "settings.language.english"),
        .init(id: "es-419", displayNameKey: "language.es_419"),
        .init(id: "pt-BR", displayNameKey: "language.pt_br"),
        .init(id: "de-DE", displayNameKey: "settings.language.german"),
        .init(id: "fr-FR", displayNameKey: "settings.language.french"),
    ]
}

struct LegalConfiguration: Sendable {
    let version: String
    let privacyURL: URL
    let termsURL: URL
    let localizedPrivacyURLs: [String: URL]
    let localizedTermsURLs: [String: URL]

    func privacyURL(for locale: Locale) -> URL {
        localizedPrivacyURLs[SupportedLocaleResolver.closestSupported(to: locale.identifier)] ?? privacyURL
    }

    func termsURL(for locale: Locale) -> URL {
        localizedTermsURLs[SupportedLocaleResolver.closestSupported(to: locale.identifier)] ?? termsURL
    }
}

enum OnboardingProfile: Equatable, Sendable {
    case legalOnly
    case singleScreen
    case guidedTour
}

struct AdvertisingConfiguration: Sendable {
    let bannerUnitID: String
}

struct BackupConfiguration: Sendable {
    let enabled: Bool
}

struct MonetizationConfiguration: Sendable {
    let mode: MonetizationMode
    let freeSuccessfulActions: Int
    let lifetimeProductID: String
    let subscriptionProductID: String
    let annualSubscriptionProductID: String

    var subscriptionProductIDs: Set<String> {
        [subscriptionProductID, annualSubscriptionProductID]
    }

    var productIDs: Set<String> {
        switch mode {
        case .adsWithRemovePurchase, .oneTimeUnlock, .usageCapWithOneTimeUnlock:
            [lifetimeProductID]
        case .adsWithSubscription, .subscription, .usageCapWithSubscription, .creationCapWithSubscription:
            subscriptionProductIDs
        case .free, .ads:
            []
        }
    }

    var includesAdvertising: Bool { mode == .ads || mode == .adsWithRemovePurchase || mode == .adsWithSubscription }
    var includesPurchase: Bool { !productIDs.isEmpty }
    var includesSubscription: Bool {
        mode == .adsWithSubscription || mode == .subscription || mode == .usageCapWithSubscription || mode == .creationCapWithSubscription
    }
}

struct ShellDestination: Hashable, Identifiable, Sendable {
    let id: String
    let titleKey: String
    let symbol: String

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct AppLanguage: Identifiable, Hashable, Sendable {
    let id: String
    let displayNameKey: String
}

enum MonetizationMode: String, CaseIterable, Identifiable, Sendable {
    case free
    case ads
    case adsWithRemovePurchase
    case adsWithSubscription
    case oneTimeUnlock
    case subscription
    case usageCapWithOneTimeUnlock
    case usageCapWithSubscription
    /// Keeps the product usable while limiting only creation of new records.
    case creationCapWithSubscription

    var id: Self { self }
    var title: String {
        switch self {
        case .free: "Free"
        case .ads: "Ads"
        case .adsWithRemovePurchase: "Ads + remove purchase"
        case .adsWithSubscription: "Ads + subscription"
        case .oneTimeUnlock: "One-time unlock"
        case .subscription: "Subscription"
        case .usageCapWithOneTimeUnlock: "Usage cap + one-time unlock"
        case .usageCapWithSubscription: "Usage cap + subscription"
        case .creationCapWithSubscription: "Creation cap + subscription"
        }
    }
}

enum SampleContentState: String, CaseIterable, Identifiable, Sendable {
    case populated, empty, loading, error
    var id: Self { self }
    var title: String { rawValue.capitalized }
}
