import BudgetCore
import SwiftUI

struct AllocationView: View {
    @EnvironmentObject private var store: BudgetStore

    var body: some View {
        BudgetCanvas {
            ScrollView {
                if let profile = store.profile, let snapshot = store.snapshot {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .top, spacing: 20) {
                            PageHeader(
                                eyebrow: "Try a scenario",
                                title: "Allocation planner",
                                subtitle: "Change any amount and see the effect before you commit to it.",
                                systemImage: "slider.horizontal.3"
                            )
                            Spacer(minLength: 16)
                            Button("Restore suggestion", systemImage: "arrow.counterclockwise") {
                                store.restoreSuggestedAllocation()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .keyboardShortcut("r", modifiers: [.command, .shift])
                            .help("Restore the recommended allocation (Shift-Command-R)")
                        }

                        HStack(spacing: 14) {
                            Image(systemName: snapshot.availableToAllocate >= 0
                                  ? "checkmark.seal.fill"
                                  : "exclamationmark.octagon.fill")
                                .font(.title2)
                                .foregroundStyle(snapshot.availableToAllocate >= 0
                                                 ? BudgetTheme.positive
                                                 : BudgetTheme.critical)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Available this month")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(AppFormatters.currency(snapshot.availableToAllocate))
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .minimumScaleFactor(0.75)
                            }
                            Spacer()
                            Text(profile.preferences.priority.rawValue)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(BudgetTheme.brand.opacity(0.12), in: Capsule())
                                .foregroundStyle(BudgetTheme.brand)
                        }
                        .budgetPanel(accent: snapshot.availableToAllocate >= 0
                                     ? BudgetTheme.positive
                                     : BudgetTheme.critical)
                        .accessibilityElement(children: .combine)

                        VStack(spacing: 0) {
                            allocationRow(
                                "Emergency fund",
                                systemImage: "shield.lefthalf.filled",
                                tint: BudgetTheme.positive,
                                keyPath: \AllocationPlan.emergencyFund
                            )
                            Divider()
                            allocationRow(
                                "Additional loan payment",
                                systemImage: "building.columns.fill",
                                tint: BudgetTheme.warning,
                                keyPath: \AllocationPlan.extraLoanPayment
                            )
                            Divider()
                            allocationRow(
                                "Additional credit card payment",
                                systemImage: "creditcard.trianglebadge.exclamationmark",
                                tint: BudgetTheme.critical,
                                keyPath: \AllocationPlan.creditCardPayment
                            )
                            Divider()
                            allocationRow(
                                "Next credit card reserve",
                                systemImage: "calendar.badge.clock",
                                tint: BudgetTheme.information,
                                keyPath: \AllocationPlan.creditCardReserve
                            )
                            Divider()
                            allocationRow(
                                "Long-term savings",
                                systemImage: "leaf.fill",
                                tint: BudgetTheme.brand,
                                keyPath: \AllocationPlan.longTermSavings
                            )
                            Divider()
                            allocationRow(
                                "Flexible spending",
                                systemImage: "sparkles",
                                tint: BudgetTheme.information,
                                keyPath: \AllocationPlan.discretionarySpending
                            )
                            Divider()
                            allocationRow(
                                "Cash buffer",
                                systemImage: "banknote.fill",
                                tint: BudgetTheme.positive,
                                keyPath: \AllocationPlan.cashBuffer
                            )
                        }
                        .budgetPanel(accent: BudgetTheme.brand)

                        HStack(spacing: 24) {
                            totalValue(
                                title: "Total allocation",
                                value: store.allocation.total,
                                color: BudgetTheme.brand
                            )
                            Divider()
                            let difference = snapshot.availableToAllocate - store.allocation.total
                            totalValue(
                                title: "Difference",
                                value: difference,
                                color: difference >= 0 ? BudgetTheme.positive : BudgetTheme.critical
                            )
                        }
                        .budgetPanel()

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Recommendation", systemImage: "wand.and.stars")
                                .font(.title2.bold())
                                .foregroundStyle(BudgetTheme.brand)
                            ForEach(BudgetEngine.observations(for: profile, allocation: store.allocation)) {
                                BudgetStatusCard(observation: $0)
                            }
                        }
                    }
                    .padding(28)
                }
            }
        }
        .navigationTitle("Allocation")
    }

    private func allocationRow(
        _ title: String,
        systemImage: String,
        tint: Color,
        keyPath: WritableKeyPath<AllocationPlan, Decimal>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(title)
                .font(.body.weight(.medium))
            Spacer(minLength: 20)
            MoneyField(
                title: "0.00",
                value: Binding(
                    get: { store.allocation[keyPath: keyPath] },
                    set: { newValue in
                        var updated = store.allocation
                        updated[keyPath: keyPath] = max(newValue, 0)
                        store.updateAllocation(updated)
                    }
                )
            )
            .accessibilityLabel(title)
        }
        .padding(.vertical, 12)
    }

    private func totalValue(title: String, value: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(AppFormatters.currency(value))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
