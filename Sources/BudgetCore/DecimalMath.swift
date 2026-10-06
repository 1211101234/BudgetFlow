import Foundation

extension Decimal {
    static let oneHundred = Decimal(100)

    var nonNegative: Decimal {
        max(self, 0)
    }

    func rounded(scale: Int = 2) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, .bankers)
        return result
    }
}

func safeRatio(_ numerator: Decimal, _ denominator: Decimal) -> Decimal {
    guard denominator > 0 else { return 0 }
    return numerator / denominator
}

func interpolatedScore(
    value: Decimal,
    thresholds: [(minimum: Decimal, score: Int)]
) -> Int {
    for threshold in thresholds.sorted(by: { $0.minimum > $1.minimum }) {
        if value >= threshold.minimum {
            return threshold.score
        }
    }
    return 0
}
