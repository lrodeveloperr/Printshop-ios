import SafariServices
import SwiftUI

enum LegalDocument: String, Identifiable {
    case privacy, terms
    var id: Self { self }

    func url(for locale: Locale) -> URL {
        self == .privacy
            ? ShellConfiguration.legal.privacyURL(for: locale)
            : ShellConfiguration.legal.termsURL(for: locale)
    }
}

/// Always shows the published source of truth instead of duplicating legal copy
/// that can become stale or ship as a template placeholder.
struct LegalView: UIViewControllerRepresentable {
    let document: LegalDocument
    @Environment(\.locale) private var locale

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: document.url(for: locale))
        controller.preferredControlTintColor = UIColor(ShellConfiguration.tint)
        controller.dismissButtonStyle = .done
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
