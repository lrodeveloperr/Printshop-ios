import Foundation

enum PrintJobStatus: String, Codable, CaseIterable, Sendable {
    case handoff
    case preProduction
    case ready
    case inProduction
    case finalCheck
    case packing
    case readyForRelease
    case complete
    case blocked

    var localizationKey: String {
        switch self {
        case .handoff: "status.job.handoff"
        case .preProduction: "status.job.pre_production"
        case .ready: "status.job.ready"
        case .inProduction: "status.job.in_production"
        case .finalCheck: "status.job.final_qc"
        case .packing: "status.job.packing"
        case .readyForRelease: "status.job.ready_for_release"
        case .complete: "status.job.complete"
        case .blocked: "sample.state.blocked"
        }
    }
}

struct PrintJobIssue: Codable, Hashable, Sendable {
    var replacementQuantity: Int
    var note: String?
}

struct PrintJob: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var reference: String
    var customerName: String
    var customerLocalizationKey: String?
    var itemName: String
    var itemCountLocalizationKey: String?
    var methodLocalizationKey: String?
    var quantity: Int
    var dueDate: Date
    var status: PrintJobStatus
    var progress: Int
    var issue: PrintJobIssue?
    var isSample: Bool
    var createdAt: Date
    var updatedAt: Date

    var isActive: Bool { status != .complete }
}

struct PrintShopEvent: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let jobID: UUID?
    let jobReference: String?
    let titleKey: String
    let detail: String?
    let occurredAt: Date
}

struct PrintShopWorkspace: Codable, Sendable {
    var schemaVersion: Int
    var jobs: [PrintJob]
    var events: [PrintShopEvent]
    var realJobsEverCreated: Int
    var lastBackupAt: Date?
}

struct ImportedJobDraft: Identifiable, Hashable, Sendable {
    let id: UUID
    let reference: String
    let customer: String
    let item: String
    let quantity: Int
    let dueDate: Date
}

struct ImportPreview: Sendable {
    let fileName: String
    let drafts: [ImportedJobDraft]
    let issues: [LocalizedImportIssue]

    var canImport: Bool { !drafts.isEmpty && issues.allSatisfy { !$0.isBlocking } }
}

struct LocalizedImportIssue: Identifiable, Hashable, Sendable {
    let id: UUID
    let key: String
    let row: Int?
    let column: String?
    let isBlocking: Bool
}

enum PrintShopStoreError: Error, Equatable {
    case freeLimitReached
    case invalidBackup
    case unsupportedBackupVersion
    case saveFailed
    case jobNotFound
}
