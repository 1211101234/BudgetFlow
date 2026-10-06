import BudgetCore
import SwiftUI

struct SetupView: View {
    @State private var grossIncome: Decimal = 0
    @State private var netIncome: Decimal = 0
    @State private var emergencyFund: Decimal = 0

    let onComplete: (BudgetProfile) -> Void

    private var isValid: Bool {
        grossIncome > 0 && netIncome > 0 && netIncome <= grossIncome && emergencyFund >= 0
    }

    var body: some View {
        BudgetCanvas {
            ScrollView {
                VStack(spacing: 24) {
                    BrandMark(size: 104)
                        .shadow(color: BudgetTheme.brand.opacity(0.22), radius: 18, y: 8)
                    VStack(spacing: 8) {
                        Text("Build a clearer monthly plan")
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        Text("Start with income and current emergency savings. You can add commitments and expenses next.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 520)
                    }
                    .accessibilityElement(children: .combine)

                    Form {
                        Section("Your starting point") {
                            LabeledContent("Gross monthly income") {
                                MoneyField(title: "0.00", value: $grossIncome)
                            }
                            LabeledContent("Net monthly income") {
                                MoneyField(title: "0.00", value: $netIncome)
                            }
                            LabeledContent("Current emergency fund") {
                                MoneyField(title: "0.00", value: $emergencyFund)
                            }
                        }
                    }
                    .formStyle(.grouped)
                    .frame(maxWidth: 580)
                    .budgetPanel(accent: BudgetTheme.brand)

                    Button("Create my budget", systemImage: "arrow.right.circle.fill") {
                        onComplete(BudgetProfile(
                            grossIncome: grossIncome,
                            netIncome: netIncome,
                            emergencyFundBalance: emergencyFund
                        ))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BudgetTheme.brand)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
                    .help(isValid ? "Create the budget" : "Enter valid gross and net income first")

                    if netIncome > grossIncome, grossIncome > 0 {
                        Label(
                            "Net income cannot be greater than gross income.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.callout.weight(.medium))
                        .foregroundStyle(BudgetTheme.critical)
                        .accessibilityLabel("Error: Net income cannot be greater than gross income.")
                    }
                }
                .frame(maxWidth: 760)
                .padding(48)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
