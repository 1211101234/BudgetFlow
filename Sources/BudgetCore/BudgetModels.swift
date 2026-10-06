import Foundation

public struct CreditCardDetails: Codable, Hashable, Sendable {
    public var statementBalance: Decimal
    public var minimumPaymentDue: Decimal?
    public var statementDate: Date?
    public var paymentDueDate: Date?
    public var immediatePayment: Decimal?
    public var nextStatementEstimate: Decimal
    public var creditLimit: Decimal?
    public var freezeNewSpending: Bool?

    public init(
        statementBalance: Decimal,
        minimumPaymentDue: Decimal? = nil,
        statementDate: Date? = nil,
        paymentDueDate: Date? = nil,
        immediatePayment: Decimal? = nil,
        nextStatementEstimate: Decimal = 0,
        creditLimit: Decimal? = nil,
        freezeNewSpending: Bool? = nil
    ) {
        self.statementBalance = statementBalance
        self.minimumPaymentDue = minimumPaymentDue
        self.statementDate = statementDate
        self.paymentDueDate = paymentDueDate
        self.immediatePayment = immediatePayment
        self.nextStatementEstimate = nextStatementEstimate
        self.creditLimit = creditLimit
        self.freezeNewSpending = freezeNewSpending
    }
}

public struct MonthlyCommitment: Identifiable, Codable, Hashable, Sendable {
    public enum Category: String, Codable, CaseIterable, Identifiable, Sendable {
        case housingLoan = "Housing loan"
        case vehicleLoan = "Vehicle loan"
        case personalLoan = "Personal loan"
        case creditCard = "Credit card"
        case buyNowPayLater = "BNPL"
        case insurance = "Insurance"
        case other = "Other"

        public var id: String { rawValue }

        public var isConsumerCredit: Bool {
            self == .creditCard || self == .buyNowPayLater
        }

        public var isLoan: Bool {
            switch self {
            case .housingLoan, .vehicleLoan, .personalLoan:
                true
            case .creditCard, .buyNowPayLater, .insurance, .other:
                false
            }
        }
    }

    public let id: UUID
    public var name: String
    public var category: Category
    public var monthlyPayment: Decimal
    public var outstandingBalance: Decimal?
    public var annualRate: Decimal?
    public var creditCardDetails: CreditCardDetails?

    public init(
        id: UUID = UUID(),
        name: String,
        category: Category,
        monthlyPayment: Decimal,
        outstandingBalance: Decimal? = nil,
        annualRate: Decimal? = nil,
        creditCardDetails: CreditCardDetails? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.monthlyPayment = monthlyPayment
        self.outstandingBalance = outstandingBalance
        self.annualRate = annualRate
        self.creditCardDetails = creditCardDetails
    }
}

public struct MonthlyExpense: Identifiable, Codable, Hashable, Sendable {
    public enum Category: String, Codable, CaseIterable, Identifiable, Sendable {
        case food = "Food"
        case transport = "Transport"
        case utilities = "Utilities"
        case household = "Household"
        case healthcare = "Healthcare"
        case dependants = "Dependants"
        case lifestyle = "Lifestyle"
        case other = "Other"

        public var id: String { rawValue }

        public var isEssential: Bool {
            switch self {
            case .food, .transport, .utilities, .household, .healthcare, .dependants:
                true
            case .lifestyle, .other:
                false
            }
        }
    }

    public let id: UUID
    public var name: String
    public var category: Category
    public var monthlyAmount: Decimal
    public var weeklyLimit: Decimal?

    public init(
        id: UUID = UUID(),
        name: String,
        category: Category,
        monthlyAmount: Decimal,
        weeklyLimit: Decimal? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.monthlyAmount = monthlyAmount
        self.weeklyLimit = weeklyLimit
    }
}

public enum AllocationPriority: String, Codable, CaseIterable, Identifiable, Sendable {
    case balanced = "Balanced"
    case debtReduction = "Reduce debt"
    case buildEmergencyFund = "Build emergency fund"
    case growSavings = "Grow savings"

    public var id: String { rawValue }
}

public struct BudgetPreferences: Codable, Hashable, Sendable {
    public var priority: AllocationPriority
    public var minimumMonthlyBuffer: Decimal
    public var emergencyFundTargetMonths: Int
    public var emergencyFundMonthlyBaseline: Decimal?
    public var starterEmergencyTarget: Decimal?
    public var bonusMonth: Int?
    public var bonusIncomeMultiplier: Decimal?

    public init(
        priority: AllocationPriority = .balanced,
        minimumMonthlyBuffer: Decimal = 200,
        emergencyFundTargetMonths: Int = 3,
        emergencyFundMonthlyBaseline: Decimal? = nil,
        starterEmergencyTarget: Decimal? = nil,
        bonusMonth: Int? = nil,
        bonusIncomeMultiplier: Decimal? = nil
    ) {
        self.priority = priority
        self.minimumMonthlyBuffer = minimumMonthlyBuffer
        self.emergencyFundTargetMonths = emergencyFundTargetMonths
        self.emergencyFundMonthlyBaseline = emergencyFundMonthlyBaseline
        self.starterEmergencyTarget = starterEmergencyTarget
        self.bonusMonth = bonusMonth
        self.bonusIncomeMultiplier = bonusIncomeMultiplier
    }
}

public struct BudgetProfile: Codable, Hashable, Sendable {
    public var grossIncome: Decimal
    public var netIncome: Decimal
    public var emergencyFundBalance: Decimal
    public var commitments: [MonthlyCommitment]
    public var expenses: [MonthlyExpense]
    public var preferences: BudgetPreferences

    public init(
        grossIncome: Decimal,
        netIncome: Decimal,
        emergencyFundBalance: Decimal = 0,
        commitments: [MonthlyCommitment] = [],
        expenses: [MonthlyExpense] = [],
        preferences: BudgetPreferences = BudgetPreferences()
    ) {
        self.grossIncome = grossIncome
        self.netIncome = netIncome
        self.emergencyFundBalance = emergencyFundBalance
        self.commitments = commitments
        self.expenses = expenses
        self.preferences = preferences
    }
}

public struct AllocationPlan: Codable, Equatable, Sendable {
    public var emergencyFund: Decimal
    public var extraLoanPayment: Decimal
    public var creditCardPayment: Decimal
    public var creditCardReserve: Decimal
    public var longTermSavings: Decimal
    public var discretionarySpending: Decimal
    public var cashBuffer: Decimal

    public init(
        emergencyFund: Decimal = 0,
        extraLoanPayment: Decimal = 0,
        creditCardPayment: Decimal = 0,
        creditCardReserve: Decimal = 0,
        longTermSavings: Decimal = 0,
        discretionarySpending: Decimal = 0,
        cashBuffer: Decimal = 0
    ) {
        self.emergencyFund = emergencyFund
        self.extraLoanPayment = extraLoanPayment
        self.creditCardPayment = creditCardPayment
        self.creditCardReserve = creditCardReserve
        self.longTermSavings = longTermSavings
        self.discretionarySpending = discretionarySpending
        self.cashBuffer = cashBuffer
    }

    public var total: Decimal {
        emergencyFund + extraLoanPayment + creditCardPayment + creditCardReserve
            + longTermSavings + discretionarySpending + cashBuffer
    }

    /// Compatibility bridge for callers and saved plans that used one combined debt bucket.
    public var extraDebtPayment: Decimal {
        get { extraLoanPayment + creditCardPayment }
        set {
            extraLoanPayment = 0
            creditCardPayment = newValue
        }
    }

    private enum CodingKeys: String, CodingKey {
        case emergencyFund
        case extraLoanPayment
        case creditCardPayment
        case creditCardReserve
        case extraDebtPayment
        case longTermSavings
        case discretionarySpending
        case cashBuffer
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        emergencyFund = try values.decodeIfPresent(Decimal.self, forKey: .emergencyFund) ?? 0
        extraLoanPayment = try values.decodeIfPresent(Decimal.self, forKey: .extraLoanPayment) ?? 0
        creditCardPayment = try values.decodeIfPresent(Decimal.self, forKey: .creditCardPayment)
            ?? values.decodeIfPresent(Decimal.self, forKey: .extraDebtPayment)
            ?? 0
        creditCardReserve = try values.decodeIfPresent(Decimal.self, forKey: .creditCardReserve) ?? 0
        longTermSavings = try values.decodeIfPresent(Decimal.self, forKey: .longTermSavings) ?? 0
        discretionarySpending = try values.decodeIfPresent(Decimal.self, forKey: .discretionarySpending) ?? 0
        cashBuffer = try values.decodeIfPresent(Decimal.self, forKey: .cashBuffer) ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(emergencyFund, forKey: .emergencyFund)
        try values.encode(extraLoanPayment, forKey: .extraLoanPayment)
        try values.encode(creditCardPayment, forKey: .creditCardPayment)
        try values.encode(creditCardReserve, forKey: .creditCardReserve)
        try values.encode(longTermSavings, forKey: .longTermSavings)
        try values.encode(discretionarySpending, forKey: .discretionarySpending)
        try values.encode(cashBuffer, forKey: .cashBuffer)
    }
}

public struct BudgetSnapshot: Equatable, Sendable {
    public let totalCommitments: Decimal
    public let loanPayments: Decimal
    public let creditCardPayments: Decimal
    public let essentialExpenses: Decimal
    public let nonEssentialExpenses: Decimal
    public let availableToAllocate: Decimal
    public let emergencyFundTarget: Decimal
    public let emergencyFundCoverageMonths: Decimal

    public var totalExpenses: Decimal { essentialExpenses + nonEssentialExpenses }
}

public struct CreditCardPaymentRecommendation: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let cardName: String
    public let statementBalance: Decimal
    public let minimumPaymentDue: Decimal?
    public let immediatePayment: Decimal
    public let balanceAfterImmediatePayment: Decimal
    public let plannedPayment: Decimal
    public let nextPaymentReserve: Decimal
    public let projectedStatementRemainder: Decimal
    public let paymentDueDate: Date?
    public let annualRate: Decimal?
    public let explanation: String
}

public enum ScoreBand: String, Sendable {
    case incomplete = "Complete your budget"
    case strong = "Strong"
    case stable = "Stable"
    case cautious = "Cautiously stable"
    case vulnerable = "Vulnerable"
    case critical = "Needs attention"
}

public struct ScoreComponent: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let score: Int
    public let weight: Int
    public let explanation: String
}

public struct FinancialStabilityScore: Equatable, Sendable {
    public let value: Int?
    public let band: ScoreBand
    public let components: [ScoreComponent]
    public let observations: [BudgetObservation]
}

public struct BudgetObservation: Identifiable, Equatable, Sendable {
    public enum Severity: Int, Sendable {
        case positive
        case information
        case warning
        case critical
    }

    public let id: String
    public let severity: Severity
    public let message: String

    public init(id: String, severity: Severity, message: String) {
        self.id = id
        self.severity = severity
        self.message = message
    }
}
