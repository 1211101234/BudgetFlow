import Foundation

public struct FuturePlanMonth: Identifiable, Equatable, Sendable {
    public let id: Date
    public let payday: Date
    public let income: Decimal
    public let baselineSpending: Decimal
    public let creditCardPayment: Decimal
    public let emergencyContribution: Decimal
    public let longTermSavings: Decimal
    public let endingCreditCardBalance: Decimal
    public let endingEmergencyBalance: Decimal
    public let isBonusMonth: Bool
}

public enum FuturePlanEngine {
    public static func simulate(
        profile: BudgetProfile,
        currentAllocation: AllocationPlan,
        paydayDates: [Date],
        calendar: Calendar = .current
    ) -> [FuturePlanMonth] {
        let baseline = profile.preferences.emergencyFundMonthlyBaseline
            ?? fallbackBaseline(for: profile)
        let emergencyTarget = baseline * Decimal(profile.preferences.emergencyFundTargetMonths)
        let bonusMonth = profile.preferences.bonusMonth ?? 3
        let bonusMultiplier = max(profile.preferences.bonusIncomeMultiplier ?? Decimal(string: "2.5")!, 1)

        var creditCardBalance = BudgetEngine.creditCardRecommendations(
            for: profile,
            allocation: currentAllocation
        ).reduce(Decimal.zero) { $0 + $1.projectedStatementRemainder }
        var emergencyBalance = profile.emergencyFundBalance + currentAllocation.emergencyFund

        return paydayDates.sorted().map { payday in
            let isBonusMonth = calendar.component(.month, from: payday) == bonusMonth
            let income = (profile.netIncome * (isBonusMonth ? bonusMultiplier : 1)).rounded()
            var available = (income - baseline).nonNegative.rounded()

            let cardPayment = min(creditCardBalance, available).rounded()
            creditCardBalance = (creditCardBalance - cardPayment).nonNegative.rounded()
            available -= cardPayment

            let emergencyGap = (emergencyTarget - emergencyBalance).nonNegative
            let emergencyContribution = min(emergencyGap, available).rounded()
            emergencyBalance = (emergencyBalance + emergencyContribution).rounded()
            available -= emergencyContribution

            return FuturePlanMonth(
                id: payday,
                payday: payday,
                income: income,
                baselineSpending: baseline.rounded(),
                creditCardPayment: cardPayment,
                emergencyContribution: emergencyContribution,
                longTermSavings: available.nonNegative.rounded(),
                endingCreditCardBalance: creditCardBalance,
                endingEmergencyBalance: emergencyBalance,
                isBonusMonth: isBonusMonth
            )
        }
    }

    private static func fallbackBaseline(for profile: BudgetProfile) -> Decimal {
        let nonCardCommitments = profile.commitments
            .filter { $0.category != .creditCard }
            .reduce(Decimal.zero) { $0 + $1.monthlyPayment }
        let expenses = profile.expenses.reduce(Decimal.zero) { $0 + $1.monthlyAmount }
        return (nonCardCommitments + expenses).rounded()
    }
}
