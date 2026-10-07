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

    var subtitle: String {
        switch self {
        case .dashboard: "Monthly position"
        case .allocation: "Adjust this payday"
        case .futurePlans: "Forecast 12 months"
        case .budget: "Income, debts and limits"
        }
    }

    var tint: Color {
        switch self {
        case .dashboard: BudgetTheme.brand
        case .allocation: BudgetTheme.positive
        case .futurePlans: BudgetTheme.information
        case .budget: BudgetTheme.warning
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
                    List(selection: $selection) {
                        Section("Plan") {
                            ForEach([AppSection.dashboard, .allocation, .futurePlans]) {
                                navigationRow($0)
                            }
                        }
                        Section("Manage") {
                            navigationRow(.budget)
                        }
                    }
                    .listStyle(.sidebar)
                    .tint(BudgetTheme.brand)
                    .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 300)
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
                        sidebarSummary
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
        .onOpenURL { url in
            guard url.scheme == "budgetflow", url.host == "dashboard" else { return }
            selection = .dashboard
            columnVisibility = .all
        }
    }

    private func navigationRow(_ section: AppSection) -> some View {
        HStack(spacing: 11) {
            Image(systemName: section.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(section.tint)
                .frame(width: 32, height: 32)
                .background(section.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(section.rawValue)
                    .font(.body.weight(.semibold))
                Text(section.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
        .tag(section)
        .help("Open \(section.rawValue)")
        .accessibilityElement(children: .combine)
    }

    private var sidebarSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("This month", systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BudgetTheme.positive)
                Spacer()
                if let score = store.score?.value {
                    Text("\(score)/100")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            if let available = store.snapshot?.availableToAllocate {
                Text(AppFormatters.currency(available))
                    .font(.title3.bold())
                    .foregroundStyle(BudgetTheme.brand)
                    .monospacedDigit()
                Text("available after required outgoings")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Divider()
            Label("Planning guidance only", systemImage: "info.circle")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .help("The stability score is not a bank or credit-bureau score.")
        }
        .padding(12)
        .background(BudgetTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(BudgetTheme.divider.opacity(0.7), lineWidth: 1)
        }
        .padding(10)
        .accessibilityElement(children: .contain)
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
