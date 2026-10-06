import SwiftUI

struct MoneyField: View {
    let title: String
    @Binding var value: Decimal

    var body: some View {
        TextField(title, value: $value, format: .number.precision(.fractionLength(0...2)))
            .labelsHidden()
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 180)
    }
}
