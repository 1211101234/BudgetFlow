import BudgetCore
import SwiftUI

@main
struct BudgetFlowApp: App {
    @StateObject private var store = BudgetStore(repository: BudgetRepository())

    private var previewColorScheme: ColorScheme? {
        CommandLine.arguments.contains("--preview-light") ? .light : nil
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(previewColorScheme)
                .frame(minWidth: 980, minHeight: 680)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1180, height: 780)
    }
}
