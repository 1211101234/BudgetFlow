import XCTest
@testable import BudgetCore

final class BudgetEngineTests: XCTestCase {
    func testSnapshotSeparatesEssentialAndFlexibleExpenses() {
        let profile = makeProfile()
        let snapshot = BudgetEngine.snapshot(for: profile)

        XCTAssertEqual(snapshot.totalCommitments, 200)
        XCTAssertEqual(snapshot.essentialExpenses, 900)
        XCTAssertEqual(snapshot.nonEssentialExpenses, 200)
        XCTAssertEqual(snapshot.availableToAllocate, 2_700)
        XCTAssertEqual(snapshot.emergencyFundTarget, 3_300)
    }

    func testSuggestedAllocationUsesExactlyTheAvailableAmount() {
        let profile = makeProfile()
        let snapshot = BudgetEngine.snapshot(for: profile)
        let plan = BudgetEngine.suggestedAllocation(for: profile)

        XCTAssertEqual(plan.total, snapshot.availableToAllocate)
        XCTAssertEqual(plan.cashBuffer, 200)
        XCTAssertGreaterThan(plan.extraDebtPayment, 0)
    }

    func testSuggestionUsesLoanBucketWhenThereIsNoCreditCardDebt() {
        var profile = makeProfile()
        profile.commitments[0].category = .vehicleLoan
        profile.commitments[0].creditCardDetails = nil

        let plan = BudgetEngine.suggestedAllocation(for: profile)

        XCTAssertGreaterThan(plan.extraLoanPayment, 0)
        XCTAssertEqual(plan.creditCardPayment, 0)
    }

    func testNegativeDisposableIncomeProducesCriticalObservation() {
        var profile = makeProfile()
        profile.netIncome = 1_000

        let observations = BudgetEngine.observations(for: profile, allocation: AllocationPlan())

        XCTAssertTrue(observations.contains {
            $0.id == "monthly-deficit" && $0.severity == .critical
        })
    }

    func testManualOverAllocationIsRejectedByAdviceEngine() {
        let profile = makeProfile()
        let plan = AllocationPlan(longTermSavings: 2_000)

        let observations = BudgetEngine.observations(for: profile, allocation: plan)

        XCTAssertTrue(observations.contains { $0.id == "allocation-over-budget" })
    }

    func testFinancialScoreRemainsWithinDocumentedRange() {
        let profile = makeProfile()
        let plan = BudgetEngine.suggestedAllocation(for: profile)

        let score = BudgetEngine.financialStabilityScore(for: profile, allocation: plan)

        XCTAssertNotNil(score.value)
        XCTAssertTrue((0...100).contains(score.value ?? -1))
        XCTAssertEqual(score.components.reduce(0) { $0 + $1.weight }, 100)
    }

    func testFinancialScoreIsWithheldWhenExpensesAreMissing() {
        var profile = makeProfile()
        profile.expenses = []

        let plan = BudgetEngine.suggestedAllocation(for: profile)
        let score = BudgetEngine.financialStabilityScore(for: profile, allocation: plan)

        XCTAssertNil(score.value)
        XCTAssertEqual(score.band, .incomplete)
        XCTAssertTrue(score.observations.contains { $0.id == "incomplete-expenses" })
    }

    func testSuggestedAllocationSeparatesLoansCardsAndNextPaymentReserve() {
        var profile = makeProfile()
        profile.commitments.append(MonthlyCommitment(
            name: "Car loan",
            category: .vehicleLoan,
            monthlyPayment: 500,
            outstandingBalance: 20_000,
            annualRate: 4
        ))

        let plan = BudgetEngine.suggestedAllocation(for: profile)

        XCTAssertGreaterThan(plan.extraLoanPayment, 0)
        XCTAssertGreaterThan(plan.creditCardPayment, 0)
        XCTAssertGreaterThan(plan.creditCardReserve, 0)
        XCTAssertEqual(plan.total, BudgetEngine.snapshot(for: profile).availableToAllocate)
    }

    func testCreditCardRecommendationProtectsMinimumAndCapsAtStatementBalance() {
        let profile = makeProfile()
        let allocation = AllocationPlan(creditCardPayment: 10_000, creditCardReserve: 300)

        let recommendation = BudgetEngine.creditCardRecommendations(
            for: profile,
            allocation: allocation
        ).first

        XCTAssertEqual(recommendation?.minimumPaymentDue, 200)
        XCTAssertEqual(recommendation?.plannedPayment, 1_200)
        XCTAssertEqual(recommendation?.projectedStatementRemainder, 0)
        XCTAssertEqual(recommendation?.nextPaymentReserve, 300)
    }

    func testLegacyCombinedDebtAllocationDecodesIntoCreditCardBucket() throws {
        let data = Data(
            """
            {
              "emergencyFund": 100,
              "extraDebtPayment": 250,
              "longTermSavings": 300,
              "discretionarySpending": 50,
              "cashBuffer": 200
            }
            """.utf8
        )

        let plan = try JSONDecoder().decode(AllocationPlan.self, from: data)

        XCTAssertEqual(plan.extraLoanPayment, 0)
        XCTAssertEqual(plan.creditCardPayment, 250)
        XCTAssertEqual(plan.total, 900)
    }

    func testFuturePlanClearsCardThenFundsEmergencyAndMarchBonusSavings() throws {
        let calendar = Calendar(identifier: .gregorian)
        let november = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 24)))
        let march = try XCTUnwrap(calendar.date(from: DateComponents(year: 2027, month: 3, day: 24)))
        var profile = BudgetProfile(
            grossIncome: 3_500,
            netIncome: 3_065,
            emergencyFundBalance: 1_800,
            commitments: [
                MonthlyCommitment(
                    name: "CIMB",
                    category: .creditCard,
                    monthlyPayment: 201,
                    creditCardDetails: CreditCardDetails(
                        statementBalance: 4_000,
                        minimumPaymentDue: 201,
                        immediatePayment: Decimal(string: "955.87")
                    )
                )
            ],
            preferences: BudgetPreferences(
                priority: .debtReduction,
                minimumMonthlyBuffer: 0,
                emergencyFundTargetMonths: 3,
                emergencyFundMonthlyBaseline: 941,
                starterEmergencyTarget: 1_000,
                bonusMonth: 3,
                bonusIncomeMultiplier: Decimal(string: "2.5")
            )
        )
        profile.expenses = []
        let current = AllocationPlan(emergencyFund: 300, creditCardPayment: 1_623)

        let months = FuturePlanEngine.simulate(
            profile: profile,
            currentAllocation: current,
            paydayDates: [november, march],
            calendar: calendar
        )

        XCTAssertEqual(months[0].creditCardPayment, Decimal(string: "1220.13"))
        XCTAssertEqual(months[0].endingCreditCardBalance, 0)
        XCTAssertEqual(months[0].endingEmergencyBalance, 2_823)
        XCTAssertTrue(months[1].isBonusMonth)
        XCTAssertEqual(months[1].income, Decimal(string: "7662.50"))
        XCTAssertEqual(months[1].longTermSavings, Decimal(string: "6721.50"))
    }

    private func makeProfile() -> BudgetProfile {
        BudgetProfile(
            grossIncome: 5_000,
            netIncome: 4_000,
            emergencyFundBalance: 2_000,
            commitments: [
                MonthlyCommitment(
                    name: "Credit card",
                    category: .creditCard,
                    monthlyPayment: 200,
                    outstandingBalance: 5_000,
                    annualRate: 18,
                    creditCardDetails: CreditCardDetails(
                        statementBalance: 1_200,
                        minimumPaymentDue: 200,
                        statementDate: Date(timeIntervalSince1970: 1_700_000_000),
                        paymentDueDate: Date(timeIntervalSince1970: 1_701_814_400),
                        nextStatementEstimate: 400,
                        creditLimit: 8_000
                    )
                )
            ],
            expenses: [
                MonthlyExpense(name: "Food", category: .food, monthlyAmount: 600),
                MonthlyExpense(name: "Travel", category: .transport, monthlyAmount: 300),
                MonthlyExpense(name: "Leisure", category: .lifestyle, monthlyAmount: 200)
            ]
        )
    }
}
