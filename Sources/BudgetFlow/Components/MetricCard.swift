import SwiftUI

struct MetricCard: View {
    let systemImage: String
    let title: String
    let value: String
    let detail: String
    var tint: Color = BudgetTheme.brand

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .budgetPanel(accent: tint)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value). \(detail)")
    }
}
