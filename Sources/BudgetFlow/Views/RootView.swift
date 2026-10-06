import BudgetCore
import SwiftUI

private enum AppSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case allocation = "Allocation"
    case futurePlans = "Future plans"
    case budget = "Budget details"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dashboard: "chart.pie"
        case .allocation: "slider.horizontal.3"
        case .futurePlans: "calendar.badge.clock"
        case .budget: "list.bullet.rectangle"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: BudgetStore
    @State private var selection: AppSection? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView("Loading your budget…")
            } else if store.profile == nil {
                SetupView { store.completeSetup(with: $0) }
            } else {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    List(AppSection.allCases, selection: $selection) { section in
                        Label(section.rawValue, systemImage: section.systemImage)
                            .tag(section)
                            .help("Open \(section.rawValue)")
                    }
                    .tint(BudgetTheme.brand)
                    .navigationSplitViewColumnWidth(220)
                    .safeAreaInset(edge: .top) {
                        HStack(spacing: 10) {
                            BrandMark(size: 38)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("BudgetFlow")
                                    .font(.headline)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text("Plan with clarity")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("BudgetFlow, plan with clarity")
                    }
                    .safeAreaInset(edge: .bottom) {
                        Label("Planning guidance only", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .help("The stability score is not a bank or credit-bureau score.")
                    }
                } detail: {
                    detailView
                }
                .navigationSplitViewStyle(.balanced)
            }
        }
        .alert(
            "BudgetFlow",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.dismissError() } }
            )
        ) {
            Button("OK") { store.dismissError() }
                .keyboardShortcut(.defaultAction)
        } message: {
            Text(store.errorMessage ?? "An unexpected error occurred.")
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection ?? .dashboard {
        case .dashboard:
            DashboardView()
        case .allocation:
            AllocationView()
        case .futurePlans:
            FuturePlansView()
        case .budget:
            BudgetDetailsView()
        }
    }
}
