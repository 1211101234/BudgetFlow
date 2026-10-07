import BudgetCore
import SwiftUI
import WidgetKit

private let widgetKind = "BudgetFlowOverviewWidget"

private struct BudgetFlowWidgetEntry: TimelineEntry {
    let date: Date
    let summary: BudgetWidgetSummary
}

private struct BudgetFlowWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetFlowWidgetEntry {
        BudgetFlowWidgetEntry(date: Date(), summary: .placeholder)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (BudgetFlowWidgetEntry) -> Void
    ) {
        completion(BudgetFlowWidgetEntry(
            date: Date(),
            summary: BudgetWidgetSharedStore.load() ?? .placeholder
        ))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<BudgetFlowWidgetEntry>) -> Void
    ) {
        let entry = BudgetFlowWidgetEntry(
            date: Date(),
            summary: BudgetWidgetSharedStore.load() ?? .placeholder
        )
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            ?? Date().addingTimeInterval(1_800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

private struct BudgetFlowWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BudgetFlowWidgetEntry

    var body: some View {
        Group {
            if family == .systemMedium {
                mediumContent
            } else {
                smallContent
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.indigo.opacity(0.32), Color.teal.opacity(0.16), Color.black.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .widgetURL(URL(string: "budgetflow://dashboard"))
    }

    private var smallContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            brandHeader
            Spacer(minLength: 0)
            Text("AVAILABLE")
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(.secondary)
            Text(currency(entry.summary.availableToAllocate))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .privacySensitive()
            Divider()
            HStack {
                Label("CIMB", systemImage: "creditcard.fill")
                Spacer()
                Text(currency(entry.summary.projectedCreditCardBalance))
                    .monospacedDigit()
                    .privacySensitive()
            }
            .font(.caption.weight(.semibold))
        }
    }

    private var mediumContent: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                brandHeader
                Spacer(minLength: 0)
                Text("AVAILABLE TO ALLOCATE")
                    .font(.caption2.weight(.bold))
                    .tracking(0.9)
                    .foregroundStyle(.secondary)
                Text(currency(entry.summary.availableToAllocate))
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .privacySensitive()
                if let score = entry.summary.financialScore {
                    Label("Stability \(score)/100", systemImage: "gauge.with.dots.needle.50percent")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.teal)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                widgetMetric(
                    title: "CIMB payment",
                    value: entry.summary.plannedCreditCardPayment,
                    systemImage: "creditcard.trianglebadge.exclamationmark",
                    color: .orange
                )
                widgetMetric(
                    title: "Balance after plan",
                    value: entry.summary.projectedCreditCardBalance,
                    systemImage: "arrow.down.right.circle.fill",
                    color: .red
                )
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Label("Emergency", systemImage: "shield.fill")
                        Spacer()
                        Text(currency(entry.summary.emergencyBalance))
                            .monospacedDigit()
                            .privacySensitive()
                    }
                    .font(.caption.weight(.semibold))
                    ProgressView(
                        value: decimalDouble(entry.summary.emergencyBalance),
                        total: max(decimalDouble(entry.summary.emergencyTarget), 1)
                    )
                    .tint(.teal)
                }
            }
        }
    }

    private var brandHeader: some View {
        HStack(spacing: 7) {
            Image(systemName: "wallet.bifold.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Color.indigo.gradient, in: RoundedRectangle(cornerRadius: 8))
            Text("BudgetFlow")
                .font(.headline)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    private func widgetMetric(
        title: String,
        value: Decimal,
        systemImage: String,
        color: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(currency(value))
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .privacySensitive()
            }
            Spacer(minLength: 0)
        }
    }

    private func currency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MYR"
        formatter.locale = Locale(identifier: "en_MY")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "RM 0.00"
    }

    private func decimalDouble(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}

private struct BudgetFlowOverviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: BudgetFlowWidgetProvider()) { entry in
            BudgetFlowWidgetView(entry: entry)
        }
        .configurationDisplayName("BudgetFlow Overview")
        .description("See available money, CIMB progress, and emergency savings at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

@main
struct BudgetFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        BudgetFlowOverviewWidget()
    }
}
