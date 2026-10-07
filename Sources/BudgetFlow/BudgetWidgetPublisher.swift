import BudgetCore
import Foundation
import WidgetKit

enum BudgetWidgetPublisher {
    static let widgetKind = "BudgetFlowOverviewWidget"

    static func publish(profile: BudgetProfile, allocation: AllocationPlan) {
        let snapshot = BudgetEngine.snapshot(for: profile)
        let score = BudgetEngine.financialStabilityScore(for: profile, allocation: allocation)
        let cardRecommendations = BudgetEngine.creditCardRecommendations(
            for: profile,
            allocation: allocation
        )
        let summary = BudgetWidgetSummary(
            availableToAllocate: snapshot.availableToAllocate,
            financialScore: score.value,
            plannedCreditCardPayment: cardRecommendations.reduce(0) { $0 + $1.plannedPayment },
            projectedCreditCardBalance: cardRecommendations.reduce(0) {
                $0 + $1.projectedStatementRemainder
            },
            emergencyBalance: profile.emergencyFundBalance + allocation.emergencyFund,
            emergencyTarget: snapshot.emergencyFundTarget
        )

        try? BudgetWidgetSharedStore.save(summary)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
