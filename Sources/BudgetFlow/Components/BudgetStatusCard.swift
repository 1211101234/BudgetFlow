import BudgetCore
import SwiftUI

struct BudgetStatusCard: View {
    let observation: BudgetObservation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                Text(observation.message)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(color.opacity(0.24), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(observation.message)")
    }

    private var label: String {
        switch observation.severity {
        case .positive: "On track"
        case .information: "Information"
        case .warning: "Review"
        case .critical: "Action needed"
        }
    }

    private var symbol: String {
        switch observation.severity {
        case .positive: "checkmark.circle.fill"
        case .information: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .critical: "xmark.octagon.fill"
        }
    }

    private var color: Color {
        switch observation.severity {
        case .positive: BudgetTheme.positive
        case .information: BudgetTheme.information
        case .warning: BudgetTheme.warning
        case .critical: BudgetTheme.critical
        }
    }
}
