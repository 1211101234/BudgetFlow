import Foundation

public enum BudgetEngine {
    public static func validate(_ profile: BudgetProfile) -> [BudgetObservation] {
        var observations: [BudgetObservation] = []

        if profile.grossIncome <= 0 {
            observations.append(.init(
                id: "invalid-gross-income",
                severity: .critical,
                message: "Gross income must be greater than zero."
            ))
        }
        if profile.netIncome <= 0 {
            observations.append(.init(
                id: "invalid-net-income",
                severity: .critical,
                message: "Net income must be greater than zero."
            ))
        }
        if profile.netIncome > profile.grossIncome, profile.grossIncome > 0 {
            observations.append(.init(
                id: "net-exceeds-gross",
                severity: .warning,
                message: "Net income is higher than gross income. Check that both values use the same monthly period."
            ))
        }
        if profile.commitments.contains(where: { $0.monthlyPayment < 0 }) ||
            profile.expenses.contains(where: { $0.monthlyAmount < 0 }) {
            observations.append(.init(
                id: "negative-outgoing",
                severity: .critical,
                message: "Commitments and expenses cannot contain negative amounts."
            ))
        }
        for card in profile.commitments where card.category == .creditCard {
            guard let details = card.creditCardDetails else {
                observations.append(.init(
                    id: "missing-card-details-\(card.id)",
                    severity: .warning,
                    message: "Add statement and due-date details for \(card.name) to calculate its payment plan."
                ))
                continue
            }
            let minimumDue = details.minimumPaymentDue ?? 0
            if details.statementBalance < 0 || minimumDue < 0 ||
                minimumDue > details.statementBalance {
                observations.append(.init(
                    id: "invalid-card-statement-\(card.id)",
                    severity: .critical,
                    message: "\(card.name) has invalid statement or minimum-payment values."
                ))
            }
            if let paymentDueDate = details.paymentDueDate,
               let statementDate = details.statementDate,
               paymentDueDate < statementDate {
                observations.append(.init(
                    id: "invalid-card-dates-\(card.id)",
                    severity: .critical,
                    message: "\(card.name)'s payment due date must be after its statement date."
                ))
            }
        }
        return observations
    }

    public static func snapshot(for profile: BudgetProfile) -> BudgetSnapshot {
        let commitments = profile.commitments.reduce(Decimal.zero) { $0 + $1.monthlyPayment }
        let loanPayments = profile.commitments
            .filter(\.category.isLoan)
            .reduce(Decimal.zero) { $0 + $1.monthlyPayment }
        let creditCardPayments = profile.commitments
            .filter { $0.category == .creditCard }
            .reduce(Decimal.zero) { $0 + $1.monthlyPayment }
        let essential = profile.expenses
            .filter(\.category.isEssential)
            .reduce(Decimal.zero) { $0 + $1.monthlyAmount }
        let nonEssential = profile.expenses
            .filter { !$0.category.isEssential }
            .reduce(Decimal.zero) { $0 + $1.monthlyAmount }
        let requiredMonthlySpending = commitments + essential
        let emergencyBaseline = profile.preferences.emergencyFundMonthlyBaseline
            ?? requiredMonthlySpending
        let target = emergencyBaseline * Decimal(profile.preferences.emergencyFundTargetMonths)
        let coverage = safeRatio(profile.emergencyFundBalance, emergencyBaseline)

        return BudgetSnapshot(
            totalCommitments: commitments.rounded(),
            loanPayments: loanPayments.rounded(),
            creditCardPayments: creditCardPayments.rounded(),
            essentialExpenses: essential.rounded(),
            nonEssentialExpenses: nonEssential.rounded(),
            availableToAllocate: (profile.netIncome - commitments - essential - nonEssential).rounded(),
            emergencyFundTarget: target.rounded(),
            emergencyFundCoverageMonths: coverage.rounded()
        )
    }

    public static func suggestedAllocation(for profile: BudgetProfile) -> AllocationPlan {
        let snapshot = snapshot(for: profile)
        let available = snapshot.availableToAllocate.nonNegative
        guard available > 0 else { return AllocationPlan() }

        let requestedBuffer = min(profile.preferences.minimumMonthlyBuffer.nonNegative, available)
        let allocatable = available - requestedBuffer
        let cards = profile.commitments.filter {
            $0.category == .creditCard && ($0.creditCardDetails?.statementBalance ?? 0) > 0
        }
        let hasCreditCardDebt = !cards.isEmpty
        let hasLoanDebt = profile.commitments.contains {
            $0.category.isLoan && ($0.outstandingBalance ?? 0) > 0
        }
        let needsEmergencyFund = profile.emergencyFundBalance < snapshot.emergencyFundTarget

        let nextStatementGoal = cards.reduce(Decimal.zero) {
            $0 + ($1.creditCardDetails?.nextStatementEstimate ?? 0).nonNegative
        }
        let reserveRate: Decimal = profile.preferences.priority == .debtReduction ? 0.10 : 0.20
        let creditCardReserve = min(nextStatementGoal, allocatable * reserveRate).rounded()
        let weightedAmount = allocatable - creditCardReserve

        var weights = weights(for: profile.preferences.priority)
        if !hasCreditCardDebt && !hasLoanDebt {
            weights.savings += weights.debt
            weights.debt = 0
        }
        if !needsEmergencyFund {
            weights.savings += weights.emergency
            weights.emergency = 0
        }

        let debtAmount = (weightedAmount * weights.debt).rounded()
        let creditCardShare: Decimal
        if hasCreditCardDebt && hasLoanDebt {
            creditCardShare = debtAmount * 0.75
        } else if hasCreditCardDebt {
            creditCardShare = debtAmount
        } else {
            creditCardShare = 0
        }

        return AllocationPlan(
            emergencyFund: (weightedAmount * weights.emergency).rounded(),
            extraLoanPayment: (debtAmount - creditCardShare).rounded(),
            creditCardPayment: creditCardShare.rounded(),
            creditCardReserve: creditCardReserve,
            longTermSavings: (weightedAmount * weights.savings).rounded(),
            discretionarySpending: (weightedAmount * weights.discretionary).rounded(),
            cashBuffer: requestedBuffer.rounded()
        ).reconciled(to: available)
    }

    public static func creditCardRecommendations(
        for profile: BudgetProfile,
        allocation: AllocationPlan
    ) -> [CreditCardPaymentRecommendation] {
        let cards = profile.commitments
            .filter { $0.category == .creditCard && $0.creditCardDetails != nil }
            .sorted {
                guard let left = $0.creditCardDetails, let right = $1.creditCardDetails else {
                    return $0.name < $1.name
                }
                if left.paymentDueDate != right.paymentDueDate {
                    switch (left.paymentDueDate, right.paymentDueDate) {
                    case let (leftDate?, rightDate?): return leftDate < rightDate
                    case (_?, nil): return true
                    case (nil, _?): return false
                    case (nil, nil): break
                    }
                }
                return ($0.annualRate ?? 0) > ($1.annualRate ?? 0)
            }

        var extraPaymentBudget = allocation.creditCardPayment.nonNegative
        var reserveBudget = allocation.creditCardReserve.nonNegative

        return cards.compactMap { card in
            guard let details = card.creditCardDetails else { return nil }
            let statementBalance = details.statementBalance.nonNegative
            let immediatePayment = min(
                (details.immediatePayment ?? 0).nonNegative,
                statementBalance
            )
            let balanceAfterImmediatePayment = (statementBalance - immediatePayment).nonNegative
            let minimumDue = min(
                balanceAfterImmediatePayment,
                max((details.minimumPaymentDue ?? 0).nonNegative, card.monthlyPayment.nonNegative)
            )
            let extraNeeded = (balanceAfterImmediatePayment - minimumDue).nonNegative
            let assignedExtra = min(extraPaymentBudget, extraNeeded)
            extraPaymentBudget -= assignedExtra
            let plannedPayment = (minimumDue + assignedExtra).rounded()
            let reserve = min(reserveBudget, details.nextStatementEstimate.nonNegative).rounded()
            reserveBudget -= reserve
            let remainder = (balanceAfterImmediatePayment - plannedPayment).nonNegative.rounded()

            let explanation: String
            if remainder == 0 {
                explanation = "Pays the statement in full while preserving the configured cash buffer."
            } else if plannedPayment > minimumDue {
                explanation = "Covers the minimum and adds a cash-safe extra payment; the remaining balance stays visible."
            } else {
                explanation = "Protects the minimum due and cash buffer first; increase the card allocation when affordable."
            }

            return CreditCardPaymentRecommendation(
                id: card.id,
                cardName: card.name,
                statementBalance: statementBalance,
                minimumPaymentDue: details.minimumPaymentDue,
                immediatePayment: immediatePayment.rounded(),
                balanceAfterImmediatePayment: balanceAfterImmediatePayment.rounded(),
                plannedPayment: plannedPayment,
                nextPaymentReserve: reserve,
                projectedStatementRemainder: remainder,
                paymentDueDate: details.paymentDueDate,
                annualRate: card.annualRate,
                explanation: explanation
            )
        }
    }

    public static func observations(
        for profile: BudgetProfile,
        allocation: AllocationPlan
    ) -> [BudgetObservation] {
        var results = validate(profile)
        let snapshot = snapshot(for: profile)
        let difference = snapshot.availableToAllocate - allocation.total

        if snapshot.availableToAllocate < 0 {
            results.append(.init(
                id: "monthly-deficit",
                severity: .critical,
                message: "Planned commitments and expenses exceed net income by \((-snapshot.availableToAllocate).rounded())."
            ))
        } else if difference < 0 {
            results.append(.init(
                id: "allocation-over-budget",
                severity: .critical,
                message: "This allocation exceeds the available amount by \((-difference).rounded())."
            ))
        } else if difference > 0 {
            results.append(.init(
                id: "unallocated-money",
                severity: .information,
                message: "There is \(difference.rounded()) left unallocated. Assign it intentionally or keep it as additional buffer."
            ))
        } else {
            results.append(.init(
                id: "fully-allocated",
                severity: .positive,
                message: "The available monthly amount is fully allocated."
            ))
        }

        let commitmentRatio = safeRatio(snapshot.totalCommitments, profile.netIncome)
        if commitmentRatio > Decimal(string: "0.50")! {
            results.append(.init(
                id: "high-commitment-ratio",
                severity: .warning,
                message: "More than half of net income is committed before ordinary living expenses."
            ))
        }

        if snapshot.emergencyFundCoverageMonths < 1 {
            results.append(.init(
                id: "low-emergency-coverage",
                severity: .warning,
                message: "The emergency fund covers less than one month of commitments and essential expenses."
            ))
        }

        if allocation.cashBuffer < profile.preferences.minimumMonthlyBuffer,
           snapshot.availableToAllocate >= profile.preferences.minimumMonthlyBuffer {
            results.append(.init(
                id: "buffer-below-preference",
                severity: .warning,
                message: "The cash buffer is below the minimum set in preferences."
            ))
        }
        for recommendation in creditCardRecommendations(for: profile, allocation: allocation)
        where recommendation.projectedStatementRemainder > 0 {
            results.append(.init(
                id: "card-balance-remains-\(recommendation.id)",
                severity: .warning,
                message: "\(recommendation.cardName) will retain \(recommendation.projectedStatementRemainder) after the planned payment."
            ))
        }
        return results
    }

    public static func financialStabilityScore(
        for profile: BudgetProfile,
        allocation: AllocationPlan
    ) -> FinancialStabilityScore {
        let snapshot = snapshot(for: profile)
        let commitmentRatio = safeRatio(snapshot.totalCommitments, profile.netIncome)
        let surplusRatio = safeRatio(snapshot.availableToAllocate, profile.netIncome)
        let savingsRatio = safeRatio(allocation.emergencyFund + allocation.longTermSavings, profile.netIncome)
        let consumerCreditPayments = profile.commitments
            .filter(\.category.isConsumerCredit)
            .reduce(Decimal.zero) { $0 + $1.monthlyPayment }
        let consumerCreditRatio = safeRatio(consumerCreditPayments, profile.netIncome)

        let commitmentScore = reverseScore(
            value: commitmentRatio,
            thresholds: [(0.60, 10), (0.50, 35), (0.40, 60), (0.30, 80)],
            best: 100
        )
        let surplusScore = interpolatedScore(
            value: surplusRatio,
            thresholds: [(0.20, 100), (0.10, 75), (0.001, 50), (0, 25)]
        )
        let emergencyScore = interpolatedScore(
            value: snapshot.emergencyFundCoverageMonths,
            thresholds: [(6, 100), (3, 80), (1, 45), (0.01, 20)]
        )
        let savingsScore = interpolatedScore(
            value: savingsRatio,
            thresholds: [(0.20, 100), (0.10, 70), (0.05, 40), (0.001, 20)]
        )
        let creditScore = reverseScore(
            value: consumerCreditRatio,
            thresholds: [(0.20, 10), (0.10, 40), (0.05, 70), (0.001, 85)],
            best: 100
        )

        let components = [
            ScoreComponent(
                id: "commitments",
                title: "Commitment load",
                score: commitmentScore,
                weight: 30,
                explanation: "Monthly commitments compared with net income."
            ),
            ScoreComponent(
                id: "surplus",
                title: "Monthly surplus",
                score: surplusScore,
                weight: 25,
                explanation: "Money remaining after planned commitments and expenses."
            ),
            ScoreComponent(
                id: "emergency",
                title: "Emergency coverage",
                score: emergencyScore,
                weight: 20,
                explanation: "Months of commitments and essential expenses covered by reserves."
            ),
            ScoreComponent(
                id: "savings",
                title: "Savings allocation",
                score: savingsScore,
                weight: 15,
                explanation: "The portion of net income directed to reserves and long-term savings."
            ),
            ScoreComponent(
                id: "consumer-credit",
                title: "Consumer-credit reliance",
                score: creditScore,
                weight: 10,
                explanation: "Credit-card and BNPL payments compared with net income."
            )
        ]
        let computedValue = components.reduce(0) { $0 + ($1.score * $1.weight) } / 100
        let hasMinimumData = !profile.expenses.isEmpty
        var scoreObservations = observations(for: profile, allocation: allocation)
        if !hasMinimumData {
            scoreObservations.insert(.init(
                id: "incomplete-expenses",
                severity: .warning,
                message: "Add at least one monthly expense before relying on the Financial Stability Score."
            ), at: 0)
        }

        return FinancialStabilityScore(
            value: hasMinimumData ? computedValue : nil,
            band: hasMinimumData ? band(for: computedValue) : .incomplete,
            components: components,
            observations: scoreObservations
        )
    }

    private static func weights(for priority: AllocationPriority) -> AllocationWeights {
        switch priority {
        case .balanced:
            AllocationWeights(emergency: 0.30, debt: 0.25, savings: 0.25, discretionary: 0.20)
        case .debtReduction:
            AllocationWeights(emergency: 0.20, debt: 0.50, savings: 0.20, discretionary: 0.10)
        case .buildEmergencyFund:
            AllocationWeights(emergency: 0.55, debt: 0.20, savings: 0.15, discretionary: 0.10)
        case .growSavings:
            AllocationWeights(emergency: 0.25, debt: 0.15, savings: 0.50, discretionary: 0.10)
        }
    }

    private static func reverseScore(
        value: Decimal,
        thresholds: [(minimum: Decimal, score: Int)],
        best: Int
    ) -> Int {
        for threshold in thresholds.sorted(by: { $0.minimum > $1.minimum }) {
            if value >= threshold.minimum {
                return threshold.score
            }
        }
        return best
    }

    private static func band(for value: Int) -> ScoreBand {
        switch value {
        case 80...100: .strong
        case 65..<80: .stable
        case 50..<65: .cautious
        case 35..<50: .vulnerable
        default: .critical
        }
    }
}

private struct AllocationWeights {
    var emergency: Decimal
    var debt: Decimal
    var savings: Decimal
    var discretionary: Decimal
}

private extension AllocationPlan {
    func reconciled(to available: Decimal) -> AllocationPlan {
        var result = self
        result.longTermSavings += available - total
        result.longTermSavings = result.longTermSavings.nonNegative.rounded()
        return result
    }
}
