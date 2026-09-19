import Foundation
import Observation

@MainActor
@Observable
final class PrintShopStore {
    static let shared = PrintShopStore()
    static let schemaVersion = 1
    static let freeJobLimit = 5

    private(set) var workspace: PrintShopWorkspace
    private(set) var lastErrorKey: String?
    private let fileManager: FileManager
    private let storageURL: URL

    init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        self.fileManager = fileManager
        let resolvedURL = storageURL ?? Self.defaultStorageURL(fileManager: fileManager)
        self.storageURL = resolvedURL
        if let data = try? Data(contentsOf: resolvedURL),
           let decoded = try? JSONDecoder.printShop.decode(PrintShopWorkspace.self, from: data),
           decoded.schemaVersion == Self.schemaVersion {
            workspace = decoded
        } else {
            workspace = Self.sampleWorkspace()
            try? persist()
        }
    }

    var jobs: [PrintJob] {
        workspace.jobs.sorted {
            if $0.status == .complete && $1.status != .complete { return false }
            if $0.status != .complete && $1.status == .complete { return true }
            return $0.dueDate < $1.dueDate
        }
    }

    var events: [PrintShopEvent] { workspace.events.sorted { $0.occurredAt > $1.occurredAt } }
    var activeJobs: [PrintJob] { jobs.filter(\.isActive) }
    var blockedJobs: [PrintJob] { activeJobs.filter { $0.issue != nil || $0.status == .blocked } }
    var dueTodayCount: Int { activeJobs.filter { Calendar.current.isDateInToday($0.dueDate) }.count }
    var nextJob: PrintJob? { activeJobs.first { $0.issue == nil } ?? activeJobs.first }
    var lastBackupAt: Date? { workspace.lastBackupAt }

    func displayCustomer(for job: PrintJob, locale: Locale) -> String {
        guard let key = job.customerLocalizationKey else { return job.customerName }
        return AppLocalization.string(key, locale: locale)
    }

    func displayItem(for job: PrintJob, locale: Locale) -> String {
        guard let countKey = job.itemCountLocalizationKey else { return job.itemName }
        let count = AppLocalization.string(countKey, locale: locale, job.quantity)
        guard let methodKey = job.methodLocalizationKey else { return count }
        return count + " · " + AppLocalization.string(methodKey, locale: locale)
    }

    func job(id: UUID) -> PrintJob? { workspace.jobs.first { $0.id == id } }

    func nextActionKey(for job: PrintJob) -> String {
        if job.issue != nil { return "event.resolve_customer_replacement" }
        switch job.progress {
        case ...0: "event.receive"
        case 1: "event.start_setup"
        case 2: "event.record_first_article"
        case 3: "event.dispose_stage_quantity"
        case 4: "event.record_final_qc"
        case 5: "event.create_package"
        default: "event.release_package"
        }
    }

    @discardableResult
    func advance(jobID: UUID) throws -> PrintJob {
        guard let index = workspace.jobs.firstIndex(where: { $0.id == jobID }) else { throw PrintShopStoreError.jobNotFound }
        guard workspace.jobs[index].issue == nil else { return workspace.jobs[index] }
        let newProgress = min(7, workspace.jobs[index].progress + 1)
        workspace.jobs[index].progress = newProgress
        workspace.jobs[index].status = Self.status(for: newProgress)
        workspace.jobs[index].updatedAt = Date()
        let updated = workspace.jobs[index]
        workspace.events.append(
            PrintShopEvent(
                id: UUID(), jobID: updated.id, jobReference: updated.reference,
                titleKey: Self.eventKey(for: newProgress), detail: nil, occurredAt: Date()
            )
        )
        try persist()
        return updated
    }

    func resolveReplacement(jobID: UUID) throws {
        guard let index = workspace.jobs.firstIndex(where: { $0.id == jobID }) else { throw PrintShopStoreError.jobNotFound }
        workspace.jobs[index].issue = nil
        if workspace.jobs[index].status == .blocked { workspace.jobs[index].status = .preProduction }
        workspace.jobs[index].updatedAt = Date()
        let job = workspace.jobs[index]
        workspace.events.append(
            PrintShopEvent(id: UUID(), jobID: job.id, jobReference: job.reference,
                           titleKey: "event.resolve_customer_replacement", detail: nil, occurredAt: Date())
        )
        try persist()
    }

    func importJobs(
        _ drafts: [ImportedJobDraft],
        hasPro: Bool,
        remainingFreeJobs: Int?,
        recordSuccessfulCreation: (String) -> UsageRecordingResult
    ) throws {
        let unique = drafts.filter { draft in
            !workspace.jobs.contains { $0.reference.caseInsensitiveCompare(draft.reference) == .orderedSame }
        }
        let durableRemaining = max(0, Self.freeJobLimit - workspace.realJobsEverCreated)
        let effectiveRemaining = min(remainingFreeJobs ?? 0, durableRemaining)
        if !hasPro, unique.count > effectiveRemaining { throw PrintShopStoreError.freeLimitReached }
        let now = Date()
        let newJobs = unique.map {
            PrintJob(id: $0.id, reference: $0.reference, customerName: $0.customer,
                     customerLocalizationKey: nil, itemName: $0.item, itemCountLocalizationKey: nil,
                     methodLocalizationKey: nil, quantity: $0.quantity,
                     dueDate: $0.dueDate, status: .handoff, progress: 0, issue: nil,
                     isSample: false, createdAt: now, updatedAt: now)
        }
        workspace.jobs.append(contentsOf: newJobs)
        workspace.realJobsEverCreated += newJobs.count
        workspace.events.append(contentsOf: newJobs.map {
            PrintShopEvent(id: UUID(), jobID: $0.id, jobReference: $0.reference,
                           titleKey: "event.create_job", detail: nil, occurredAt: now)
        })
        do { try persist() }
        catch {
            workspace.jobs.removeAll { job in newJobs.contains(where: { $0.id == job.id }) }
            workspace.realJobsEverCreated -= newJobs.count
            throw error
        }
        for job in newJobs { _ = recordSuccessfulCreation("real-job:\(job.id.uuidString.lowercased())") }
    }

    func resetSampleWorkspace() {
        let liveJobs = workspace.jobs.filter { !$0.isSample }
        let liveEvents = workspace.events.filter { event in
            guard let jobID = event.jobID else { return true }
            return liveJobs.contains { $0.id == jobID }
        }
        let samples = Self.sampleWorkspace()
        workspace.jobs = liveJobs + samples.jobs
        workspace.events = liveEvents + samples.events
        try? persist()
    }

    func removeSampleWorkspace() {
        let sampleIDs = Set(workspace.jobs.filter(\.isSample).map(\.id))
        workspace.jobs.removeAll(where: \.isSample)
        workspace.events.removeAll { event in event.jobID.map(sampleIDs.contains) ?? false }
        try? persist()
    }

    func exportCSV() -> String {
        var lines = ["order_reference,customer,item,quantity,due_date,status"]
        let formatter = ISO8601DateFormatter()
        for job in jobs where !job.isSample {
            lines.append([
                job.reference, job.customerName, job.itemName, String(job.quantity),
                formatter.string(from: job.dueDate), job.status.rawValue,
            ].map(Self.csvEscape).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    func makeBackupData() throws -> Data {
        var copy = workspace
        copy.lastBackupAt = Date()
        let data = try JSONEncoder.printShop.encode(copy)
        workspace.lastBackupAt = copy.lastBackupAt
        try persist()
        return data
    }

    func restoreBackup(_ data: Data) throws {
        let decoded = try JSONDecoder.printShop.decode(PrintShopWorkspace.self, from: data)
        guard decoded.schemaVersion == Self.schemaVersion else { throw PrintShopStoreError.unsupportedBackupVersion }
        guard Set(decoded.jobs.map(\.id)).count == decoded.jobs.count,
              decoded.jobs.allSatisfy({ $0.quantity > 0 && (0...7).contains($0.progress) }) else {
            throw PrintShopStoreError.invalidBackup
        }
        let original = workspace
        var replacement = decoded
        replacement.realJobsEverCreated = max(original.realJobsEverCreated, decoded.realJobsEverCreated)
        workspace = replacement
        do { try persist() }
        catch { workspace = original; throw error }
    }

    private func persist() throws {
        do {
            try fileManager.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder.printShop.encode(workspace)
            try data.write(to: storageURL, options: [.atomic, .completeFileProtection])
            lastErrorKey = nil
        } catch {
            lastErrorKey = "error.io_failure"
            throw PrintShopStoreError.saveFailed
        }
    }

    private static func defaultStorageURL(fileManager: FileManager) -> URL {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return root.appending(path: "PrintShopJobManager", directoryHint: .isDirectory)
            .appending(path: "workspace-v1.json")
    }

    private static func status(for progress: Int) -> PrintJobStatus {
        switch progress {
        case ...0: .handoff
        case 1: .preProduction
        case 2: .ready
        case 3: .inProduction
        case 4: .finalCheck
        case 5: .packing
        case 6: .readyForRelease
        default: .complete
        }
    }

    private static func eventKey(for progress: Int) -> String {
        switch progress {
        case 1: "event.receive"
        case 2: "event.start_setup"
        case 3: "event.record_first_article"
        case 4: "event.dispose_stage_quantity"
        case 5: "event.record_final_qc"
        case 6: "event.create_package"
        default: "event.release_package"
        }
    }

    private static func csvEscape(_ value: String) -> String {
        let safe = value.first.map { "=+-@\t\r".contains($0) } == true ? "'" + value : value
        guard safe.contains(",") || safe.contains("\"") || safe.contains("\n") else { return safe }
        return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func sampleWorkspace(now: Date = Date()) -> PrintShopWorkspace {
        let calendar = Calendar.current
        func date(_ days: Int, _ hour: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: now)) ?? now
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: base) ?? base
        }
        let jobs = [
            PrintJob(id: UUID(uuidString: "D49F43AE-6BDE-49E2-92DE-A2CBE0B00401")!, reference: "PS-1048",
                     customerName: "River Run Club", customerLocalizationKey: "sample.customer.river_run_club",
                     itemName: "", itemCountLocalizationKey: "count.shirts", methodLocalizationKey: "method.screen_print",
                     quantity: 36, dueDate: date(0, 16),
                     status: .inProduction, progress: 3, issue: nil, isSample: true, createdAt: now, updatedAt: now),
            PrintJob(id: UUID(uuidString: "D49F43AE-6BDE-49E2-92DE-A2CBE0B00402")!, reference: "PS-1049",
                     customerName: "Northside Gym", customerLocalizationKey: "sample.customer.northside_gym",
                     itemName: "", itemCountLocalizationKey: "count.hoodies", methodLocalizationKey: "method.embroidery",
                     quantity: 24, dueDate: date(0, 13),
                     status: .blocked, progress: 2, issue: PrintJobIssue(replacementQuantity: 1, note: nil),
                     isSample: true, createdAt: now, updatedAt: now),
            PrintJob(id: UUID(uuidString: "D49F43AE-6BDE-49E2-92DE-A2CBE0B00403")!, reference: "PS-1050",
                     customerName: "Oak Street Café", customerLocalizationKey: "sample.customer.oak_street_cafe",
                     itemName: "", itemCountLocalizationKey: "count.tote_bags", methodLocalizationKey: "method.dtf",
                     quantity: 18, dueDate: date(1, 11),
                     status: .finalCheck, progress: 4, issue: nil, isSample: true, createdAt: now, updatedAt: now),
            PrintJob(id: UUID(uuidString: "D49F43AE-6BDE-49E2-92DE-A2CBE0B00404")!, reference: "PS-1051",
                     customerName: "West End Dental", customerLocalizationKey: "sample.customer.west_end_dental",
                     itemName: "", itemCountLocalizationKey: "count.polo_shirts", methodLocalizationKey: "method.embroidery",
                     quantity: 12, dueDate: date(1, 15),
                     status: .packing, progress: 5, issue: nil, isSample: true, createdAt: now, updatedAt: now),
        ]
        let events = jobs.map {
            PrintShopEvent(id: UUID(), jobID: $0.id, jobReference: $0.reference,
                           titleKey: "event.create_job", detail: nil, occurredAt: now)
        }
        return PrintShopWorkspace(schemaVersion: schemaVersion, jobs: jobs, events: events,
                                  realJobsEverCreated: 0, lastBackupAt: nil)
    }
}

private extension JSONEncoder {
    static var printShop: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var printShop: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
