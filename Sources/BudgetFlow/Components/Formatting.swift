import Foundation

enum AppFormatters {
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_MY")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_MY")
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MYR"
        formatter.locale = Locale(identifier: "en_MY")
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func currency(_ value: Decimal) -> String {
        currency.string(from: NSDecimalNumber(decimal: value)) ?? "RM 0.00"
    }

    static func percent(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value * 100)
        return "\(number.intValue)%"
    }

    static func date(_ value: Date) -> String {
        date.string(from: value)
    }

    static func monthYear(_ value: Date) -> String {
        monthYear.string(from: value)
    }
}
