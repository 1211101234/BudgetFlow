import BudgetCore
import Charts
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: BudgetStore

    var body: some View {
        BudgetCanvas {
            ScrollView {
                if let profile = store.profile,
                   let snapshot = store.snapshot,
                   let score = store.score {
                    VStack(alignment: .leading, spacing: 24) {
                        PageHeader(
                            eyebrow: "Monthly overview",
                            title: "Your money, with a plan",
                            subtitle: "A clear view of income, commitments, expenses, and the choices available next.",
                            systemImage: "sparkles"
                        )

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 230), spacing: 14)],
                            spacing: 14
                        ) {
                            MetricCard(
                                systemImage: "banknote.fill",
                                title: "Net income",
                                value: AppFormatters.currency(profile.netIncome),
                                detail: "Available after payroll deductions"
                            )
                            MetricCard(
                                systemImage: "creditcard.fill",
                                title: "Committed",
                                value: AppFormatters.currency(snapshot.totalCommitments),
                                detail: "Loans, credit, BNPL and fixed commitments",
                                tint: BudgetTheme.warning
                            )
                            MetricCard(
                                systemImage: snapshot.availableToAllocate >= 0
                                    ? "arrow.up.right.circle.fill"
                                    : "arrow.down.right.circle.fill",
                                title: "Available to allocate",
                                value: AppFormatters.currency(snapshot.availableToAllocate),
                                detail: "After commitments and planned expenses",
                                tint: snapshot.availableToAllocate >= 0
                                    ? BudgetTheme.positive
                                    : BudgetTheme.critical
                            )
                        }

                        let weeklyExpenses = profile.expenses.filter { $0.weeklyLimit != nil }
                        if !weeklyExpenses.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Weekly spending limits", systemImage: "calendar.badge.checkmark")
                                    .font(.title2.bold())
                                    .foregroundStyle(BudgetTheme.information)
                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: 210), spacing: 14)],
                                    spacing: 14
                                ) {
                                    ForEach(weeklyExpenses) { expense in
                                        MetricCard(
                                            systemImage: expense.category == .transport
                                                ? "fuelpump.fill"
                                                : "wallet.bifold.fill",
                                            title: expense.name,
                                            value: AppFormatters.currency(expense.weeklyLimit ?? 0),
                                            detail: "Per week · \(AppFormatters.currency(expense.monthlyAmount)) monthly",
                                            tint: BudgetTheme.information
                                        )
                                    }
                                }
                            }
                        }

                        if let emergencyBaseline = profile.preferences.emergencyFundMonthlyBaseline {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Emergency targets", systemImage: "shield.checkered")
                                    .font(.title2.bold())
                                    .foregroundStyle(BudgetTheme.positive)
                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: 210), spacing: 14)],
                                    spacing: 14
                                ) {
                                    MetricCard(
                                        systemImage: "1.circle.fill",
                                        title: "Starter reserve",
                                        value: AppFormatters.currency(
                                            profile.preferences.starterEmergencyTarget ?? emergencyBaseline
                                        ),
                                        detail: "Keep this amount untouched",
                                        tint: BudgetTheme.positive
                                    )
                                    MetricCard(
                                        systemImage: "3.circle.fill",
                                        title: "Three-month target",
                                        value: AppFormatters.currency(emergencyBaseline * 3),
                                        detail: "Based on the monthly baseline",
                                        tint: BudgetTheme.positive
                                    )
                                    MetricCard(
                                        systemImage: "6.circle.fill",
                                        title: "Six-month target",
                                        value: AppFormatters.currency(emergencyBaseline * 6),
                                        detail: "Longer-term resilience",
                                        tint: BudgetTheme.brand
                                    )
                                }
                            }
                        }

                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: 18) {
                                allocationChart(snapshot: snapshot)
                                    .frame(maxWidth: .infinity)
                                scoreCard(score)
                                    .frame(width: 370)
                            }
                            VStack(spacing: 18) {
                                allocationChart(snapshot: snapshot)
                                scoreCard(score)
                            }
                        }

                        let cardRecommendations = BudgetEngine.creditCardRecommendations(
                            for: profile,
                            allocation: store.allocation
                        )
                        if !cardRecommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Credit card payment plan", systemImage: "creditcard.and.123")
                                    .font(.title2.bold())
                                    .foregroundStyle(BudgetTheme.critical)
                                Text("Statement-level guidance using your due dates, minimums, available cash, and chosen buffer.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: 360), spacing: 14)],
                                    spacing: 14
                                ) {
                                    ForEach(cardRecommendations) { recommendation in
                                        creditCardPlanCard(recommendation)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Label("What your plan is telling you", systemImage: "lightbulb.max.fill")
                                .font(.title2.bold())
                                .foregroundStyle(BudgetTheme.brand)
                            ForEach(score.observations) { observation in
                                BudgetStatusCard(observation: observation)
                            }
                        }
                    }
                    .padding(28)
                }
            }
        }
        .navigationTitle("Dashboard")
    }

    private func allocationChart(snapshot: BudgetSnapshot) -> some View {
        let otherCommitments = max(
            snapshot.totalCommitments - snapshot.loanPayments - snapshot.creditCardPayments,
            0
        )
        let values: [(String, Decimal)] = [
            ("Loans", snapshot.loanPayments),
            ("Credit cards", snapshot.creditCardPayments),
            ("Other commitments", otherCommitments),
            ("Essential", snapshot.essentialExpenses),
            ("Flexible", snapshot.nonEssentialExpenses),
            ("Available", snapshot.availableToAllocate.nonNegativeForDisplay)
        ]

        return VStack(alignment: .leading, spacing: 14) {
            Label("Where net income goes", systemImage: "chart.bar.xaxis")
                .font(.title2.bold())
                .foregroundStyle(BudgetTheme.brand)
            Chart(values, id: \.0) { item in
                BarMark(
                    x: .value("Amount", NSDecimalNumber(decimal: item.1).doubleValue),
                    y: .value("Category", item.0)
                )
                .foregroundStyle(by: .value("Category", item.0))
                .cornerRadius(4)
            }
            .chartLegend(.hidden)
            .frame(height: 230)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Monthly income distribution")
            .accessibilityValue(chartAccessibilitySummary(snapshot))
        }
        .budgetPanel(accent: BudgetTheme.brand)
    }

    private func creditCardPlanCard(
        _ recommendation: CreditCardPaymentRecommendation
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(recommendation.cardName)
                    .font(.headline)
                Spacer()
                Label(
                    recommendation.paymentDueDate.map { "Due \(AppFormatters.date($0))" }
                        ?? "Due date pending",
                    systemImage: "calendar"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(BudgetTheme.warning)
            }

            if let card = store.profile?.commitments.first(where: { $0.id == recommendation.id }),
               card.creditCardDetails?.freezeNewSpending == true {
                Label("No new spending planned on this card", systemImage: "hand.raised.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BudgetTheme.critical)
            }

            Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 8) {
                cardValueRow("Statement balance", recommendation.statementBalance)
                if recommendation.immediatePayment > 0 {
                    cardValueRow("Pay now", recommendation.immediatePayment, emphasized: true)
                    cardValueRow("Balance after pay-now", recommendation.balanceAfterImmediatePayment)
                }
                if let minimumDue = recommendation.minimumPaymentDue {
                    cardValueRow("Minimum due", minimumDue)
                } else {
                    GridRow {
                        Text("Minimum due")
                            .foregroundStyle(.secondary)
                        Text("Pending latest statement")
                            .fontWeight(.semibold)
                            .foregroundStyle(BudgetTheme.warning)
                    }
                }
                cardValueRow("Recommended payment", recommendation.plannedPayment, emphasized: true)
                cardValueRow("Save for next payment", recommendation.nextPaymentReserve, emphasized: true)
                cardValueRow("Projected remainder", recommendation.projectedStatementRemainder)
            }

            ProgressView(
                value: NSDecimalNumber(decimal: recommendation.plannedPayment).doubleValue,
                total: max(NSDecimalNumber(decimal: recommendation.statementBalance).doubleValue, 1)
            )
            .tint(recommendation.projectedStatementRemainder == 0
                  ? BudgetTheme.positive
                  : BudgetTheme.warning)

            Text(recommendation.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .budgetPanel(accent: recommendation.projectedStatementRemainder == 0
                     ? BudgetTheme.positive
                     : BudgetTheme.warning)
        .accessibilityElement(children: .contain)
    }

    private func cardValueRow(
        _ title: String,
        _ value: Decimal,
        emphasized: Bool = false
    ) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)
            Text(AppFormatters.currency(value))
                .fontWeight(emphasized ? .bold : .regular)
                .foregroundStyle(emphasized ? BudgetTheme.brand : .primary)
                .monospacedDigit()
        }
    }

    private func scoreCard(_ score: FinancialStabilityScore) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Financial stability", systemImage: "gauge.with.dots.needle.50percent")
                .font(.title2.bold())
                .foregroundStyle(BudgetTheme.positive)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(score.value.map(String.init) ?? "—")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                Text("/ 100")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Text(score.band.rawValue)
                .font(.headline)
            Divider()
            if score.value == nil {
                Text("Add monthly expenses to calculate a meaningful score.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(score.components) { component in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(component.title)
                            Spacer()
                            Text("\(component.score) of 100")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: Double(component.score), total: 100)
                            .tint(component.score >= 65 ? BudgetTheme.positive : BudgetTheme.warning)
                    }
                    .font(.caption)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(component.title), \(component.score) of 100")
                }
            }
            Text("This is an internal planning indicator, not a bank or credit-bureau score.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .budgetPanel(accent: BudgetTheme.positive)
        .accessibilityElement(children: .contain)
    }

    private func chartAccessibilitySummary(_ snapshot: BudgetSnapshot) -> String {
        "Commitments \(AppFormatters.currency(snapshot.totalCommitments)); " +
            "essential expenses \(AppFormatters.currency(snapshot.essentialExpenses)); " +
            "flexible expenses \(AppFormatters.currency(snapshot.nonEssentialExpenses)); " +
            "available \(AppFormatters.currency(snapshot.availableToAllocate))."
    }
}

private extension Decimal {
    var nonNegativeForDisplay: Decimal { max(self, 0) }
}
