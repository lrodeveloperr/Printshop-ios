import XCTest
@testable import Shell

@MainActor
final class ShellTests: XCTestCase {
    func testAllMonetizationModesResolveAccess() {
        for mode in [MonetizationMode.free, .ads, .adsWithRemovePurchase, .adsWithSubscription, .creationCapWithSubscription] {
            XCTAssertEqual(resolve(mode, entitled: false, checking: true, free: false), .allowed)
        }
        for mode in [MonetizationMode.oneTimeUnlock, .subscription] {
            XCTAssertEqual(resolve(mode, entitled: true, checking: false, free: false), .allowed)
            XCTAssertEqual(resolve(mode, entitled: false, checking: true, free: false), .checkingEntitlement)
            XCTAssertEqual(resolve(mode, entitled: false, checking: false, free: false), .purchaseRequired)
        }
        for mode in [MonetizationMode.usageCapWithOneTimeUnlock, .usageCapWithSubscription] {
            XCTAssertEqual(resolve(mode, entitled: false, checking: true, free: true), .allowed)
            XCTAssertEqual(resolve(mode, entitled: true, checking: false, free: false), .allowed)
            XCTAssertEqual(resolve(mode, entitled: false, checking: true, free: false), .checkingEntitlement)
            XCTAssertEqual(resolve(mode, entitled: false, checking: false, free: false), .usageLimitReached)
        }
    }

    func testAdVisibilityNeverLeaksBeforeRemoveAdsEntitlementCheck() {
        XCTAssertTrue(AccessController.resolveAdVisibility(mode: .ads, isEntitled: false, isChecking: true))
        XCTAssertFalse(AccessController.resolveAdVisibility(mode: .adsWithRemovePurchase, isEntitled: false, isChecking: true))
        XCTAssertTrue(AccessController.resolveAdVisibility(mode: .adsWithRemovePurchase, isEntitled: false, isChecking: false))
        XCTAssertFalse(AccessController.resolveAdVisibility(mode: .adsWithRemovePurchase, isEntitled: true, isChecking: false))
        XCTAssertFalse(AccessController.resolveAdVisibility(mode: .adsWithSubscription, isEntitled: false, isChecking: true))
        XCTAssertTrue(AccessController.resolveAdVisibility(mode: .adsWithSubscription, isEntitled: false, isChecking: false))
        XCTAssertFalse(AccessController.resolveAdVisibility(mode: .adsWithSubscription, isEntitled: true, isChecking: false))
        XCTAssertFalse(AccessController.resolveAdVisibility(mode: .subscription, isEntitled: false, isChecking: false))
    }

    func testSuccessfulUsageIsPersistentAndDeduplicated() {
        let defaults = makeDefaults()
        let store = UserDefaultsUsageStore(defaults: defaults, key: "usage")
        let first = UsageLedger(limit: 2, store: store)
        XCTAssertEqual(first.recordSuccessfulAction(id: "operation-1"), .recorded(remaining: 1))
        XCTAssertEqual(first.recordSuccessfulAction(id: "operation-1"), .duplicate(remaining: 1))
        XCTAssertEqual(first.recordSuccessfulAction(id: "  "), .invalidIdentifier)
        XCTAssertEqual(first.recordSuccessfulAction(id: String(repeating: "a", count: 129)), .invalidIdentifier)
        let relaunched = UsageLedger(limit: 2, store: store)
        XCTAssertEqual(relaunched.successfulActionCount, 1)
        XCTAssertEqual(relaunched.recordSuccessfulAction(id: "operation-2"), .recorded(remaining: 0))
        XCTAssertFalse(relaunched.hasFreeActionRemaining)
        XCTAssertEqual(relaunched.recordSuccessfulAction(id: "operation-3"), .limitReached)
    }

    func testLegalAcceptanceIsVersionedAndForcesReconsent() {
        let defaults = makeDefaults()
        let first = LegalConsentStore(defaults: defaults, requiredVersion: "2026-09")
        XCTAssertTrue(first.requiresPresentation)
        XCTAssertFalse(first.isReconsent)
        first.acceptCurrentLegalVersion()
        XCTAssertFalse(first.requiresPresentation)
        XCTAssertFalse(LegalConsentStore(defaults: defaults, requiredVersion: "2026-09").requiresPresentation)
        let revised = LegalConsentStore(defaults: defaults, requiredVersion: "2026-10")
        XCTAssertTrue(revised.requiresPresentation)
        XCTAssertTrue(revised.isReconsent)
    }

    func testSubscriptionCacheExpiresButLifetimeCacheDoesNot() {
        let now = Date(timeIntervalSince1970: 1_000)
        let snapshot = EntitlementSnapshot(
            entitledProductIDs: ["lifetime", "monthly"],
            subscriptionExpiryByProductID: ["monthly": now.addingTimeInterval(60)],
            verifiedAt: now
        )
        XCTAssertTrue(snapshot.isEntitled(to: ["monthly"], at: now))
        XCTAssertFalse(snapshot.isEntitled(to: ["monthly"], at: now.addingTimeInterval(61)))
        XCTAssertTrue(snapshot.isEntitled(to: ["lifetime"], at: now.addingTimeInterval(1_000_000)))
        XCTAssertFalse(snapshot.isEntitled(to: ["unknown"], at: now))
    }

    func testCancelledAutoRenewalKeepsAccessUntilPaidExpiration() {
        let now = Date(timeIntervalSince1970: 1_000)
        let expiration = now.addingTimeInterval(60)
        let condition = SubscriptionCondition.subscribed(willAutoRenew: false, expirationDate: expiration)
        XCTAssertTrue(SubscriptionAccessEvaluation.resolve(condition: condition, at: now).grantsAccess)
        XCTAssertFalse(SubscriptionAccessEvaluation.resolve(condition: condition, at: expiration).grantsAccess)
    }

    func testGracePeriodIsEntitledButBillingRetryExpiryAndRevocationAreNot() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertTrue(SubscriptionAccessEvaluation.resolve(condition: .gracePeriod(expirationDate: now.addingTimeInterval(60)), at: now).grantsAccess)
        XCTAssertFalse(SubscriptionAccessEvaluation.resolve(condition: .billingRetry, at: now).grantsAccess)
        XCTAssertFalse(SubscriptionAccessEvaluation.resolve(condition: .expired, at: now).grantsAccess)
        XCTAssertFalse(SubscriptionAccessEvaluation.resolve(condition: .revoked, at: now).grantsAccess)
    }

    func testSettingsOnlyOffersSubscriptionManagementForRelevantStoreStates() {
        XCTAssertNil(SubscriptionSettingsPresentation.resolve(.notApplicable))
        XCTAssertNil(SubscriptionSettingsPresentation.resolve(.expired))
        XCTAssertNil(SubscriptionSettingsPresentation.resolve(.revoked))

        let checking = SubscriptionSettingsPresentation.resolve(.checking)
        XCTAssertEqual(checking?.showsManagement, false)
        XCTAssertEqual(checking?.symbol, "hourglass")

        let expiration = Date(timeIntervalSince1970: 2_000)
        XCTAssertEqual(
            SubscriptionSettingsPresentation.resolve(.subscribed(willAutoRenew: true, expirationDate: expiration))?.showsManagement,
            true
        )
        XCTAssertEqual(
            SubscriptionSettingsPresentation.resolve(.subscribed(willAutoRenew: false, expirationDate: expiration))?.showsManagement,
            true
        )
        XCTAssertEqual(SubscriptionSettingsPresentation.resolve(.gracePeriod(expirationDate: expiration))?.showsManagement, true)
        XCTAssertEqual(SubscriptionSettingsPresentation.resolve(.billingRetry)?.showsManagement, true)
        XCTAssertEqual(SubscriptionSettingsPresentation.resolve(.offlineCached(expirationDate: expiration))?.showsManagement, true)
    }

    func testProductIdentifiersAreSelectedByProfile() {
        XCTAssertEqual(configuration(.free).productIDs, [])
        XCTAssertEqual(configuration(.ads).productIDs, [])
        XCTAssertEqual(configuration(.adsWithRemovePurchase).productIDs, ["lifetime"])
        XCTAssertEqual(configuration(.adsWithSubscription).productIDs, ["monthly", "annual"])
        XCTAssertEqual(configuration(.oneTimeUnlock).productIDs, ["lifetime"])
        XCTAssertEqual(configuration(.subscription).productIDs, ["monthly", "annual"])
        XCTAssertEqual(configuration(.usageCapWithOneTimeUnlock).productIDs, ["lifetime"])
        XCTAssertEqual(configuration(.usageCapWithSubscription).productIDs, ["monthly", "annual"])
        XCTAssertEqual(configuration(.creationCapWithSubscription).productIDs, ["monthly", "annual"])
        XCTAssertFalse(configuration(.oneTimeUnlock).includesSubscription)
        XCTAssertTrue(configuration(.subscription).includesSubscription)
        XCTAssertTrue(configuration(.adsWithSubscription).includesSubscription)
    }

    func testTemplateNavigationAndLanguagesAreBounded() {
        XCTAssertFalse(ShellConfiguration.destinations.isEmpty)
        XCTAssertLessThanOrEqual(ShellConfiguration.destinations.count, 5)
        XCTAssertEqual(Set(ShellConfiguration.destinations.map(\.id)).count, ShellConfiguration.destinations.count)
        XCTAssertTrue(ShellConfiguration.supportedLanguages.contains { $0.id == "system" })
        XCTAssertTrue(ShellConfiguration.supportedLanguages.contains { $0.id == "en" })
    }

    func testLanguageSelectionRejectsStaleUnsupportedValues() {
        let defaults = makeDefaults()
        defaults.set("fr", forKey: "shell.language")
        let language = LanguageController(defaults: defaults, preferredLanguages: ["es-MX"])
        XCTAssertEqual(language.selection, "system")
        XCTAssertEqual(LanguageController.closestSupported(to: "es-MX"), "es-419")
        XCTAssertEqual(LanguageController.closestSupported(to: "fr-CA"), "fr-FR")
        XCTAssertTrue(SupportedLocaleResolver.isRightToLeft("ar-SA"))
        XCTAssertTrue(SupportedLocaleResolver.isRightToLeft("ur_PK"))
        XCTAssertFalse(SupportedLocaleResolver.isRightToLeft("en-US"))
    }

    func testSafeTemplateDefaultsAndSharedLocalizationContract() {
        XCTAssertFalse(ShellConfiguration.backup.enabled)
        XCTAssertEqual(LocalizationBaseline.localeIdentifiers.count, 31)
        XCTAssertEqual(LocalizationBaseline.sharedKeys.count, 18)
        XCTAssertEqual(ShellContract.currentVersion.split(separator: ".").count, 3)
    }

    func testLegalDestinationsUseDistinctSecureURLs() {
        let urls = [ShellConfiguration.legal.privacyURL, ShellConfiguration.legal.termsURL]
        XCTAssertEqual(Set(urls).count, urls.count)
        for url in urls {
            XCTAssertEqual(url.scheme, "https")
            XCTAssertNotNil(url.host)
        }
    }

    func testCSVImportAcceptsShopExportsAndRejectsMalformedRows() {
        let valid = Data("order_reference;customer;item;quantity;due_date\nPS-42;Café Norte;Camisetas;12;2026-10-15\n".utf8)
        let preview = PrintShopCSVParser.preview(data: valid, fileName: "jobs.csv", locale: Locale(identifier: "es-419"))
        XCTAssertTrue(preview.canImport)
        XCTAssertEqual(preview.drafts.first?.reference, "PS-42")
        XCTAssertEqual(preview.drafts.first?.quantity, 12)

        let invalid = Data("order_reference,customer,item,quantity\nPS-42,Café Norte,,4.0\n".utf8)
        let rejected = PrintShopCSVParser.preview(data: invalid, fileName: "bad.csv", locale: Locale(identifier: "en"))
        XCTAssertFalse(rejected.canImport)
        XCTAssertEqual(rejected.issues.first?.key, "error.csv.required_value")
    }

    func testFiveJobLimitAppliesOnlyToCreation() throws {
        let store = PrintShopStore(storageURL: temporaryWorkspaceURL())
        store.removeSampleWorkspace()
        let drafts = (1...5).map { index in
            ImportedJobDraft(
                id: UUID(), reference: "PS-\(index)", customer: "Customer \(index)", item: "Shirts",
                quantity: 10, dueDate: Date().addingTimeInterval(86_400)
            )
        }
        var recorded = 0
        try store.importJobs(drafts, hasPro: false, remainingFreeJobs: 5) { _ in
            recorded += 1
            return .recorded(remaining: max(0, 5 - recorded))
        }
        XCTAssertEqual(recorded, 5)
        XCTAssertEqual(store.jobs.count, 5)
        XCTAssertNoThrow(try store.advance(jobID: store.jobs[0].id))

        let sixth = ImportedJobDraft(
            id: UUID(), reference: "PS-6", customer: "Sixth", item: "Hoodies",
            quantity: 2, dueDate: Date().addingTimeInterval(86_400)
        )
        XCTAssertThrowsError(
            try store.importJobs([sixth], hasPro: false, remainingFreeJobs: 0) { _ in .limitReached }
        )
    }

    func testJobReachesCompleteAndBackupRoundTrips() throws {
        let url = temporaryWorkspaceURL()
        let store = PrintShopStore(storageURL: url)
        guard let job = store.jobs.first(where: { $0.issue == nil }) else { return XCTFail("Missing sample job") }
        while store.job(id: job.id)?.status != .complete {
            _ = try store.advance(jobID: job.id)
        }
        XCTAssertEqual(store.job(id: job.id)?.status, .complete)

        let backup = try store.makeBackupData()
        let restored = PrintShopStore(storageURL: temporaryWorkspaceURL())
        try restored.restoreBackup(backup)
        XCTAssertEqual(restored.job(id: job.id)?.status, .complete)
    }

    func testBackupPreservesFreeCreationCountEvenIfUsageLedgerIsReset() throws {
        let store = PrintShopStore(storageURL: temporaryWorkspaceURL())
        store.removeSampleWorkspace()
        let drafts = (1...5).map { index in
            ImportedJobDraft(
                id: UUID(), reference: "B-\(index)", customer: "Customer", item: "Shirt",
                quantity: 1, dueDate: Date().addingTimeInterval(86_400)
            )
        }
        try store.importJobs(drafts, hasPro: false, remainingFreeJobs: 5) { _ in .recorded(remaining: 0) }
        let restored = PrintShopStore(storageURL: temporaryWorkspaceURL())
        try restored.restoreBackup(try store.makeBackupData())

        let next = ImportedJobDraft(
            id: UUID(), reference: "B-6", customer: "Customer", item: "Shirt",
            quantity: 1, dueDate: Date().addingTimeInterval(86_400)
        )
        XCTAssertThrowsError(
            try restored.importJobs([next], hasPro: false, remainingFreeJobs: 5) { _ in .recorded(remaining: 4) }
        )
    }

    private func resolve(_ mode: MonetizationMode, entitled: Bool, checking: Bool, free: Bool) -> AccessDecision {
        AccessController.resolveDecision(mode: mode, isEntitled: entitled, isChecking: checking, hasFreeActionRemaining: free)
    }

    private func configuration(_ mode: MonetizationMode) -> MonetizationConfiguration {
        MonetizationConfiguration(
            mode: mode,
            freeSuccessfulActions: 3,
            lifetimeProductID: "lifetime",
            subscriptionProductID: "monthly",
            annualSubscriptionProductID: "annual"
        )
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ShellTests.\(UUID().uuidString)")!
    }

    private func temporaryWorkspaceURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "PrintShopTests-\(UUID().uuidString)", directoryHint: .isDirectory)
            .appending(path: "workspace.json")
    }
}
