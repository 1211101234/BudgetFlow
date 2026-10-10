import Foundation

public struct BudgetWidgetSummary: Codable, Equatable, Sendable {
    public let availableToAllocate: Decimal
    public let financialScore: Int?
    public let plannedCreditCardPayment: Decimal
    public let projectedCreditCardBalance: Decimal
    public let emergencyBalance: Decimal
    public let emergencyTarget: Decimal
    public let updatedAt: Date

    public init(
        availableToAllocate: Decimal,
        financialScore: Int?,
        plannedCreditCardPayment: Decimal,
        projectedCreditCardBalance: Decimal,
        emergencyBalance: Decimal,
        emergencyTarget: Decimal,
        updatedAt: Date = Date()
    ) {
        self.availableToAllocate = availableToAllocate
        self.financialScore = financialScore
        self.plannedCreditCardPayment = plannedCreditCardPayment
        self.projectedCreditCardBalance = projectedCreditCardBalance
        self.emergencyBalance = emergencyBalance
        self.emergencyTarget = emergencyTarget
        self.updatedAt = updatedAt
    }

    public static let placeholder = BudgetWidgetSummary(
        availableToAllocate: 1_923,
        financialScore: 77,
        plannedCreditCardPayment: 1_824,
        projectedCreditCardBalance: Decimal(string: "1220.13")!,
        emergencyBalance: 2_100,
        emergencyTarget: 2_823
    )
}

public enum BudgetWidgetSharedStore {
    // Sandboxed macOS app groups must be prefixed with the signing Team ID.
    public static let appGroupIdentifier = "2796SY86W6.com.zahinadri.BudgetFlow"
    private static let summaryKey = "budget-widget-summary-v1"

    public static func save(_ summary: BudgetWidgetSummary) throws {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            throw SharedStoreError.unavailable
        }
        let data = try JSONEncoder().encode(summary)
        defaults.set(data, forKey: summaryKey)
    }

    public static func load() -> BudgetWidgetSummary? {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: summaryKey) else {
            return nil
        }
        return try? JSONDecoder().decode(BudgetWidgetSummary.self, from: data)
    }

    private enum SharedStoreError: Error {
        case unavailable
    }
}
