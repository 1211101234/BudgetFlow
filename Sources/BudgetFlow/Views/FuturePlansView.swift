import BudgetCore
import SwiftUI

struct FuturePlansView: View {
    @EnvironmentObject private var store: BudgetStore
    @StateObject private var calendarService = PaydayCalendarService()

    private let planningMonthCount = 12

    var body: some View {
        BudgetCanvas {
            ScrollView {
                if let profile = store.profile {
                    let dates = planDates
                    let months = FuturePlanEngine.simulate(
                        profile: profile,
                        currentAllocation: store.allocation,
                        paydayDates: dates
                    )

                    VStack(alignment: .leading, spacing: 22) {
                        PageHeader(
                            eyebrow: "Next 12 paydays",
                            title: "Future plans",
                            subtitle: "Follow the Payday events in Calendar, clear CIMB first, then build reserves and savings.",
                            systemImage: "calendar.badge.clock"
                        )

                        controls(profile: profile)

                        if months.isEmpty {
                            ContentUnavailableView(
                                "No Payday events found",
                                systemImage: "calendar.badge.exclamationmark",
                                description: Text(
                                    "Add upcoming Calendar events titled Payday, then sync again."
                                )
                            )
                            .frame(maxWidth: .infinity, minHeight: 280)
                            .budgetPanel(accent: BudgetTheme.warning)
                        } else {
                            summary(months: months, profile: profile)

                            LazyVStack(spacing: 14) {
                                ForEach(months) { month in
                                    monthCard(month)
                                }
                            }
                        }
                    }
                    .padding(28)
                }
            }
        }
        .navigationTitle("Future plans")
        .task {
            await calendarService.refreshIfAuthorized(monthCount: planningMonthCount)
        }
    }

    private var planDates: [Date] {
        estimatedPaydays.map { estimatedDate in
            calendarService.paydayDates.first {
                Calendar.current.isDate($0, equalTo: estimatedDate, toGranularity: .month)
            } ?? estimatedDate
        }
    }

    private var estimatedPaydays: [Date] {
        let calendar = Calendar.current
        guard let nextMonth = calendar.dateInterval(of: .month, for: Date())?.end else { return [] }
        return (0..<planningMonthCount).compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: offset, to: nextMonth) else {
                return nil
            }
            var components = calendar.dateComponents([.year, .month], from: month)
            components.day = 24
            return calendar.date(from: components)
        }
    }

    private func controls(profile: BudgetProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(calendarStatusTitle, systemImage: calendarStatusImage)
                        .font(.headline)
                    Text(calendarStatusDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(calendarButtonTitle, systemImage: "arrow.triangle.2.circlepath") {
                    Task { await calendarService.connect(monthCount: planningMonthCount) }
                }
                .buttonStyle(.borderedProminent)
                .tint(BudgetTheme.brand)
                .disabled(calendarService.status == .loading)
            }

            Divider()

            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("March bonus income")
                        .font(.headline)
                    Text("Apply the multiplier to net income on March's Payday.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("March bonus multiplier", selection: bonusMultiplierBinding(profile)) {
                    Text("2.5× income").tag(Decimal(string: "2.5")!)
                    Text("3× income").tag(Decimal(3))
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
            }
        }
        .budgetPanel(accent: BudgetTheme.brand)
    }

    private func summary(months: [FuturePlanMonth], profile: BudgetProfile) -> some View {
        let cardClearMonth = months.first { $0.endingCreditCardBalance == 0 }
        let target = (profile.preferences.emergencyFundMonthlyBaseline ?? 0)
            * Decimal(profile.preferences.emergencyFundTargetMonths)
        let emergencyTargetMonth = months.first { $0.endingEmergencyBalance >= target }
        let projectedSavings = months.reduce(Decimal.zero) { $0 + $1.longTermSavings }

        return LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 230), spacing: 14)],
            spacing: 14
        ) {
            MetricCard(
                systemImage: "creditcard.trianglebadge.exclamationmark",
                title: "CIMB projected clear",
                value: cardClearMonth.map { AppFormatters.monthYear($0.payday) } ?? "Beyond forecast",
                detail: "No new card spending assumed",
                tint: BudgetTheme.critical
            )
            MetricCard(
                systemImage: "shield.checkered",
                title: "Three-month reserve",
                value: emergencyTargetMonth.map { AppFormatters.monthYear($0.payday) } ?? "Beyond forecast",
                detail: AppFormatters.currency(target),
                tint: BudgetTheme.positive
            )
            MetricCard(
                systemImage: "leaf.fill",
                title: "Projected new savings",
                value: AppFormatters.currency(projectedSavings),
                detail: "Across the displayed paydays",
                tint: BudgetTheme.brand
            )
        }
    }

    private func monthCard(_ month: FuturePlanMonth) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(AppFormatters.monthYear(month.payday))
                        .font(.title2.bold())
                    Text(
                        "\(isCalendarPayday(month.payday) ? "Calendar Payday" : "Estimated payday") · " +
                        AppFormatters.date(month.payday)
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if month.isBonusMonth {
                    Label("Bonus month", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(BudgetTheme.brand.opacity(0.14), in: Capsule())
                        .foregroundStyle(BudgetTheme.brand)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 8) {
                planRow("Income", month.income, emphasized: month.isBonusMonth)
                planRow("Monthly baseline", month.baselineSpending)
                planRow("CIMB payment", month.creditCardPayment)
                planRow("Emergency fund", month.emergencyContribution)
                planRow("Long-term savings", month.longTermSavings, emphasized: true)
                Divider()
                planRow("CIMB balance after payday", month.endingCreditCardBalance)
                planRow("Emergency balance", month.endingEmergencyBalance)
            }
        }
        .budgetPanel(accent: month.isBonusMonth ? BudgetTheme.brand : BudgetTheme.positive)
        .accessibilityElement(children: .contain)
    }

    private func planRow(_ title: String, _ value: Decimal, emphasized: Bool = false) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)
            Text(AppFormatters.currency(value))
                .fontWeight(emphasized ? .bold : .regular)
                .foregroundStyle(emphasized ? BudgetTheme.brand : .primary)
                .monospacedDigit()
        }
    }

    private func bonusMultiplierBinding(_ profile: BudgetProfile) -> Binding<Decimal> {
        Binding(
            get: { profile.preferences.bonusIncomeMultiplier ?? Decimal(string: "2.5")! },
            set: { value in
                store.updatePlanningPreferences {
                    $0.bonusMonth = 3
                    $0.bonusIncomeMultiplier = value
                }
            }
        )
    }

    private func isCalendarPayday(_ date: Date) -> Bool {
        calendarService.paydayDates.contains {
            Calendar.current.isDate($0, inSameDayAs: date)
        }
    }

    private var calendarStatusTitle: String {
        switch calendarService.status {
        case .notConnected: "Calendar not connected"
        case .loading: "Checking Calendar…"
        case let .connected(count): "Calendar connected · \(count) Payday events"
        case .denied: "Calendar access unavailable"
        case .failed: "Calendar sync needs attention"
        }
    }

    private var calendarStatusDetail: String {
        switch calendarService.status {
        case .notConnected:
            "Showing estimated dates on the 24th until Calendar access is allowed."
        case .loading:
            "Looking only for events whose title is Payday."
        case let .connected(count) where count > 0:
            "Using \(count) Calendar dates; months without an event are estimated on the 24th."
        case .connected:
            "No upcoming events titled Payday were found."
        case .denied:
            "Allow BudgetFlow calendar access in System Settings to use Payday events."
        case let .failed(message):
            message
        }
    }

    private var calendarStatusImage: String {
        switch calendarService.status {
        case .connected: "calendar.badge.checkmark"
        case .denied, .failed: "calendar.badge.exclamationmark"
        case .notConnected, .loading: "calendar"
        }
    }

    private var calendarButtonTitle: String {
        switch calendarService.status {
        case .connected: "Sync Payday events"
        case .loading: "Connecting…"
        case .notConnected, .denied, .failed: "Connect Calendar"
        }
    }
}
