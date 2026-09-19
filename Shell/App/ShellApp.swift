import SwiftUI

@main
struct ShellApp: App {
    var body: some Scene {
        WindowGroup {
            ShellRootView(featureProvider: PrintShopFeatureCanvasProvider())
                .tint(ShellConfiguration.tint)
        }
    }
}
