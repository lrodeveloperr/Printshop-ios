import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class PrintShopFeatureCanvasProvider: FeatureCanvasProviding {
    let store: PrintShopStore

    init(store: PrintShopStore = .shared) { self.store = store }

    func makeCanvas(for destination: ShellDestination, context: FeatureCanvasContext) -> AnyView {
        switch destination.id {
        case "home": AnyView(PrintShopHomeView(store: store, context: context))
        case "jobs": AnyView(PrintShopJobsView(store: store, context: context))
        case "import": AnyView(PrintShopImportView(store: store, context: context))
        case "history": AnyView(PrintShopHistoryView(store: store))
        default: AnyView(ContentUnavailableView("error.unexpected", systemImage: "exclamationmark.triangle"))
        }
    }
}

private struct PrintShopHomeView: View {
    let store: PrintShopStore
    let context: FeatureCanvasContext
    @Environment(\.locale) private var locale
    @State private var alertKey: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                summary
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) { primaryColumn; secondaryColumn }
                    VStack(spacing: 18) { primaryColumn; secondaryColumn }
                }
            }
            .padding()
            .frame(maxWidth: 1_050)
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .alert(alertKey.map { AppLocalization.string($0, locale: locale) } ?? "", isPresented: alertBinding) {
            Button("common.done") { alertKey = nil }
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(get: { alertKey != nil }, set: { if !$0 { alertKey = nil } })
    }

    private var summary: some View {
        HStack(spacing: 0) {
            SummaryMetric(value: "\(store.activeJobs.count)", label: plural("count.active_jobs", store.activeJobs.count))
            Divider().frame(height: 44)
            SummaryMetric(value: "\(store.dueTodayCount)", label: plural("count.due_today", store.dueTodayCount))
            Divider().frame(height: 44)
            SummaryMetric(value: "\(store.blockedJobs.count)", label: plural("count.blocked_jobs", store.blockedJobs.count))
        }
        .padding(.vertical, 16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var primaryColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("home.next_step").font(.title2.bold())
            if let job = store.nextJob {
                NavigationLink {
                    PrintShopJobDetailView(store: store, context: context, jobID: job.id)
                } label: {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(store.displayCustomer(for: job, locale: locale)).font(.headline)
                                Text(job.reference).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            StatusPill(status: job.status)
                        }
                        Text(store.displayItem(for: job, locale: locale)).foregroundStyle(.secondary)
                        ProgressView(value: Double(job.progress), total: 7)
                        Label(LocalizedStringKey(store.nextActionKey(for: job)), systemImage: "arrow.right.circle.fill")
                            .font(.headline).foregroundStyle(.tint)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                ContentUnavailableView("empty.title", systemImage: "checkmark.circle", description: Text("empty.message"))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var secondaryColumn: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("home.needs_attention").font(.headline)
                if let blocked = store.blockedJobs.first {
                    NavigationLink {
                        PrintShopJobDetailView(store: store, context: context, jobID: blocked.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(store.displayCustomer(for: blocked, locale: locale)).font(.headline)
                                Text("sample.attention.replacement_detail").font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Label("replacement.resolved", systemImage: "checkmark.circle.fill").foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("home.jobs_by_stage").font(.headline)
                HStack(spacing: 0) {
                    StageCount(key: "home.stage.prep", count: count(.preProduction) + count(.ready))
                    StageCount(key: "home.stage.production", count: count(.inProduction))
                    StageCount(key: "home.stage.final_check", count: count(.finalCheck))
                    StageCount(key: "home.stage.ready", count: count(.readyForRelease))
                }
                .padding(.vertical, 12)
                .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func count(_ status: PrintJobStatus) -> Int { store.activeJobs.filter { $0.status == status }.count }
    private func plural(_ key: String, _ count: Int) -> String { AppLocalization.string(key, locale: locale, count) }
}

private struct SummaryMetric: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.title2.bold()).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary).lineLimit(2).minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StageCount: View {
    let key: LocalizedStringKey
    let count: Int
    var body: some View {
        VStack(spacing: 4) {
            Text(verbatim: "\(count)").font(.headline).monospacedDigit()
            Text(key).font(.caption).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatusPill: View {
    let status: PrintJobStatus
    private var color: Color { status == .blocked ? .orange : .accentColor }
    var body: some View {
        Text(LocalizedStringKey(status.localizationKey))
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9).padding(.vertical, 5)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }
}

private struct PrintShopJobsView: View {
    let store: PrintShopStore
    let context: FeatureCanvasContext
    @Environment(\.locale) private var locale
    @State private var query = ""

    var filteredJobs: [PrintJob] {
        guard !query.isEmpty else { return store.jobs }
        return store.jobs.filter { job in
            [job.reference, store.displayCustomer(for: job, locale: locale), store.displayItem(for: job, locale: locale)]
                .contains { value in value.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        List(filteredJobs) { job in
            NavigationLink {
                PrintShopJobDetailView(store: store, context: context, jobID: job.id)
            } label: {
                HStack(spacing: 12) {
                    Circle().fill(job.issue == nil ? Color.accentColor : .orange).frame(width: 9, height: 9)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.displayCustomer(for: job, locale: locale)).font(.headline)
                        Text(job.reference + " · " + store.displayItem(for: job, locale: locale))
                            .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(job.dueDate, format: .dateTime.locale(locale).month(.abbreviated).day())
                            .font(.caption).foregroundStyle(.secondary)
                        StatusPill(status: job.status)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .searchable(text: $query, prompt: Text("jobs.search.placeholder"))
        .overlay {
            if filteredJobs.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
    }
}

private struct PrintShopJobDetailView: View {
    let store: PrintShopStore
    let context: FeatureCanvasContext
    let jobID: UUID
    @Environment(\.locale) private var locale
    @State private var errorKey: String?

    var body: some View {
        Group {
            if let job = store.job(id: jobID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(store.displayCustomer(for: job, locale: locale)).font(.largeTitle.bold())
                            Text(job.reference).foregroundStyle(.secondary)
                            Text(store.displayItem(for: job, locale: locale)).font(.title3)
                        }
                        HStack { StatusPill(status: job.status); Spacer(); Text(job.dueDate, format: .dateTime.locale(locale).month(.wide).day().year()) }
                        ProgressView(value: Double(job.progress), total: 7)
                        if let issue = job.issue {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("home.needs_attention", systemImage: "exclamationmark.triangle.fill").font(.headline).foregroundStyle(.orange)
                                Text(AppLocalization.string("count.replacements_needed", locale: locale, issue.replacementQuantity))
                                Button("event.resolve_customer_replacement") { tryAction { try store.resolveReplacement(jobID: jobID) } }
                                    .buttonStyle(.borderedProminent)
                            }
                            .padding().background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                        } else if job.status != .complete {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("home.next_step").font(.headline)
                                Button {
                                    tryAction { _ = try store.advance(jobID: jobID) }
                                } label: {
                                    Label(LocalizedStringKey(store.nextActionKey(for: job)), systemImage: "arrow.right.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent).controlSize(.large)
                            }
                            .padding().background(.background, in: RoundedRectangle(cornerRadius: 16))
                        } else {
                            Label("guided.complete.label", systemImage: "checkmark.seal.fill").font(.title2.bold()).foregroundStyle(.green)
                        }
                    }
                    .padding().frame(maxWidth: 720, alignment: .leading).frame(maxWidth: .infinity)
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationTitle(job.reference)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView("error.unexpected", systemImage: "questionmark.folder")
            }
        }
        .alert(errorKey.map { AppLocalization.string($0, locale: locale) } ?? "", isPresented: errorBinding) {
            Button("common.done") { errorKey = nil }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorKey != nil }, set: { if !$0 { errorKey = nil } })
    }
    private func tryAction(_ action: () throws -> Void) {
        do { try action() } catch { errorKey = "error.unexpected" }
    }
}

private struct PrintShopImportView: View {
    let store: PrintShopStore
    let context: FeatureCanvasContext
    @Environment(\.locale) private var locale
    @State private var isImporterPresented = false
    @State private var preview: ImportPreview?
    @State private var messageKey: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("import.intro").foregroundStyle(.secondary)
                Button("import.choose_csv", systemImage: "doc.badge.plus") { isImporterPresented = true }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                if let preview { previewCard(preview) }
            }
            .padding().frame(maxWidth: 760, alignment: .leading).frame(maxWidth: .infinity)
        }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            do {
                let url = try result.get()
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                preview = PrintShopCSVParser.preview(data: data, fileName: url.lastPathComponent, locale: locale)
            } catch { messageKey = "error.io_failure" }
        }
        .alert(messageKey.map { AppLocalization.string($0, locale: locale) } ?? "", isPresented: messageBinding) {
            Button("common.done") { messageKey = nil }
        }
    }

    private var messageBinding: Binding<Bool> {
        Binding(get: { messageKey != nil }, set: { if !$0 { messageKey = nil } })
    }

    @ViewBuilder
    private func previewCard(_ preview: ImportPreview) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("import.file_selected", systemImage: "doc.text.fill").font(.headline)
            Text(preview.fileName).foregroundStyle(.secondary)
            Text(AppLocalization.string("count.rows_checked", locale: locale, preview.drafts.count))
            if preview.issues.isEmpty {
                Label("import.ready", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            } else {
                Label("import.needs_attention", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                ForEach(preview.issues) { issue in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(issue.key))
                        if let row = issue.row {
                            Text(AppLocalization.string("error.row", locale: locale, row))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Button("import.import_jobs") { commit(preview) }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(!preview.canImport)
        }
        .padding(18).background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private func commit(_ preview: ImportPreview) {
        do {
            try store.importJobs(
                preview.drafts,
                hasPro: context.isProUnlocked(),
                remainingFreeJobs: context.remainingFreeActions(),
                recordSuccessfulCreation: context.recordSuccessfulAction
            )
            messageKey = "event.commit_worksbien_import"
            self.preview = nil
        } catch PrintShopStoreError.freeLimitReached {
            context.requestUpgrade()
        } catch { messageKey = "error.import_internal" }
    }
}

private struct PrintShopHistoryView: View {
    let store: PrintShopStore
    @Environment(\.locale) private var locale

    var body: some View {
        List {
            if store.events.isEmpty {
                ContentUnavailableView("history.empty.title", systemImage: "clock", description: Text("history.empty.detail"))
            } else {
                ForEach(store.events) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(LocalizedStringKey(event.titleKey)).font(.headline)
                            if let reference = event.jobReference { Text(reference).foregroundStyle(.secondary) }
                            Text(event.occurredAt, format: .dateTime.locale(locale).month(.abbreviated).day().hour().minute())
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }
}
