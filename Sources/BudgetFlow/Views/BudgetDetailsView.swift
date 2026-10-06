import BudgetCore
import SwiftUI

struct BudgetDetailsView: View {
    @EnvironmentObject private var store: BudgetStore
    @State private var showingCommitmentEditor = false
    @State private var showingExpenseEditor = false

    var body: some View {
        if let profile = store.profile {
            BudgetCanvas {
                GeometryReader { proxy in
                    VStack(alignment: .leading, spacing: 12) {
                        PageHeader(
                            eyebrow: "Your inputs",
                            title: "Budget details",
                            subtitle: "Keep these values current so recommendations reflect your real monthly position.",
                            systemImage: "list.bullet.rectangle.portrait.fill"
                        )
                        .padding(.horizontal, 28)
                        .padding(.top, 24)

                        Form {
                            Section("Income and reserves") {
                                moneyRow("Gross monthly income", value: profile.grossIncome) { newValue in
                                    updateProfile { $0.grossIncome = newValue }
                                }
                                moneyRow("Net monthly income", value: profile.netIncome) { newValue in
                                    updateProfile { $0.netIncome = newValue }
                                }
                                moneyRow("Emergency fund balance", value: profile.emergencyFundBalance) { newValue in
                                    updateProfile { $0.emergencyFundBalance = newValue }
                                }
                            }

                            Section("Preferences") {
                                Picker("Primary priority", selection: priorityBinding) {
                                    ForEach(AllocationPriority.allCases) { priority in
                                        Text(priority.rawValue).tag(priority)
                                    }
                                }
                                moneyRow("Minimum monthly buffer", value: profile.preferences.minimumMonthlyBuffer) { newValue in
                                    updateProfile { $0.preferences.minimumMonthlyBuffer = newValue }
                                }
                                moneyRow(
                                    "Emergency monthly baseline",
                                    value: profile.preferences.emergencyFundMonthlyBaseline ?? 0
                                ) { newValue in
                                    updateProfile {
                                        $0.preferences.emergencyFundMonthlyBaseline = newValue > 0 ? newValue : nil
                                    }
                                }
                                moneyRow(
                                    "Starter emergency target",
                                    value: profile.preferences.starterEmergencyTarget ?? 0
                                ) { newValue in
                                    updateProfile {
                                        $0.preferences.starterEmergencyTarget = newValue > 0 ? newValue : nil
                                    }
                                }
                                Stepper(
                                    "Emergency fund target: \(profile.preferences.emergencyFundTargetMonths) months",
                                    value: emergencyMonthsBinding,
                                    in: 1...12
                                )
                                .accessibilityValue("\(profile.preferences.emergencyFundTargetMonths) months")
                            }

                            Section("Commitments") {
                                if profile.commitments.isEmpty {
                                    Label("No commitments added yet", systemImage: "creditcard")
                                        .foregroundStyle(.secondary)
                                }
                                ForEach(profile.commitments) { commitment in
                                    HStack(spacing: 12) {
                                        Image(systemName: "creditcard.fill")
                                            .foregroundStyle(BudgetTheme.warning)
                                            .accessibilityHidden(true)
                                        VStack(alignment: .leading) {
                                            Text(commitment.name)
                                            Text(commitment.category.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            if let card = commitment.creditCardDetails {
                                                Text(
                                                    "Statement \(AppFormatters.currency(card.statementBalance)) · " +
                                                    (card.paymentDueDate.map {
                                                        "due \(AppFormatters.date($0))"
                                                    } ?? "statement details pending")
                                                )
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Text(AppFormatters.currency(commitment.monthlyPayment))
                                            .font(.body.monospacedDigit())
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel(
                                        "\(commitment.name), \(commitment.category.rawValue), " +
                                        "\(AppFormatters.currency(commitment.monthlyPayment)) monthly"
                                    )
                                }
                                .onDelete(perform: deleteCommitments)
                                Button("Add commitment", systemImage: "plus.circle.fill") {
                                    showingCommitmentEditor = true
                                }
                                .tint(BudgetTheme.warning)
                            }

                            Section("Monthly expenses") {
                                if profile.expenses.isEmpty {
                                    Label("No expenses added yet", systemImage: "cart")
                                        .foregroundStyle(.secondary)
                                }
                                ForEach(profile.expenses) { expense in
                                    HStack(spacing: 12) {
                                        Image(systemName: expense.category.isEssential ? "house.fill" : "sparkles")
                                            .foregroundStyle(expense.category.isEssential
                                                             ? BudgetTheme.positive
                                                             : BudgetTheme.information)
                                            .accessibilityHidden(true)
                                        VStack(alignment: .leading) {
                                            Text(expense.name)
                                            Text(expense.category.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            if let weeklyLimit = expense.weeklyLimit {
                                                Text("Weekly limit \(AppFormatters.currency(weeklyLimit))")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Text(AppFormatters.currency(expense.monthlyAmount))
                                            .font(.body.monospacedDigit())
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel(
                                        "\(expense.name), \(expense.category.rawValue), " +
                                        "\(AppFormatters.currency(expense.monthlyAmount)) monthly"
                                    )
                                }
                                .onDelete(perform: deleteExpenses)
                                Button("Add expense", systemImage: "plus.circle.fill") {
                                    showingExpenseEditor = true
                                }
                                .tint(BudgetTheme.positive)
                            }
                        }
                        .formStyle(.grouped)
                        .scrollContentBackground(.hidden)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height,
                        alignment: .topLeading
                    )
                }
            }
            .navigationTitle("Budget details")
            .sheet(isPresented: $showingCommitmentEditor) {
                CommitmentEditor { commitment in
                    updateProfile { $0.commitments.append(commitment) }
                }
            }
            .sheet(isPresented: $showingExpenseEditor) {
                ExpenseEditor { expense in
                    updateProfile { $0.expenses.append(expense) }
                }
            }
        }
    }

    private var priorityBinding: Binding<AllocationPriority> {
        Binding(
            get: { store.profile?.preferences.priority ?? .balanced },
            set: { value in updateProfile { $0.preferences.priority = value } }
        )
    }

    private var emergencyMonthsBinding: Binding<Int> {
        Binding(
            get: { store.profile?.preferences.emergencyFundTargetMonths ?? 3 },
            set: { value in updateProfile { $0.preferences.emergencyFundTargetMonths = value } }
        )
    }

    private func moneyRow(
        _ title: String,
        value: Decimal,
        update: @escaping (Decimal) -> Void
    ) -> some View {
        LabeledContent(title) {
            MoneyField(
                title: "0.00",
                value: Binding(get: { value }, set: { update(max($0, 0)) })
            )
        }
    }

    private func updateProfile(_ mutation: (inout BudgetProfile) -> Void) {
        guard var profile = store.profile else { return }
        mutation(&profile)
        store.updateProfile(profile)
    }

    private func deleteCommitments(at offsets: IndexSet) {
        updateProfile { $0.commitments.remove(atOffsets: offsets) }
    }

    private func deleteExpenses(at offsets: IndexSet) {
        updateProfile { $0.expenses.remove(atOffsets: offsets) }
    }
}

private struct CommitmentEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category: MonthlyCommitment.Category = .housingLoan
    @State private var payment: Decimal = 0
    @State private var balance: Decimal = 0
    @State private var annualRate: Decimal = 0
    @State private var statementBalance: Decimal = 0
    @State private var minimumPayment: Decimal = 0
    @State private var immediatePayment: Decimal = 0
    @State private var datesConfirmed = false
    @State private var statementDate = Date()
    @State private var paymentDueDate = Calendar.current.date(
        byAdding: .day,
        value: 21,
        to: Date()
    ) ?? Date()
    @State private var nextStatementEstimate: Decimal = 0
    @State private var creditLimit: Decimal = 0
    @State private var freezeNewSpending = false

    let onSave: (MonthlyCommitment) -> Void

    private var isValid: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if category == .creditCard {
            let minimumIsValid = minimumPayment >= 0 && minimumPayment <= statementBalance
            let datesAreValid = !datesConfirmed || paymentDueDate >= statementDate
            return hasName && statementBalance > 0 && minimumIsValid && datesAreValid
        }
        return hasName && payment > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Add commitment")
                .font(.title.bold())
            Form {
                TextField("Name", text: $name)
                Picker("Category", selection: $category) {
                    ForEach(MonthlyCommitment.Category.allCases) { Text($0.rawValue).tag($0) }
                }
                if category == .creditCard {
                    Section("Current statement") {
                        LabeledContent("Statement balance") {
                            MoneyField(title: "0.00", value: $statementBalance)
                        }
                        LabeledContent("Minimum payment due") {
                            MoneyField(title: "Pending statement", value: $minimumPayment)
                        }
                        LabeledContent("Payment before salary day") {
                            MoneyField(title: "Optional", value: $immediatePayment)
                        }
                        Toggle("Statement and due dates confirmed", isOn: $datesConfirmed)
                        if datesConfirmed {
                            DatePicker("Statement date", selection: $statementDate, displayedComponents: .date)
                            DatePicker("Payment due date", selection: $paymentDueDate, displayedComponents: .date)
                        }
                    }
                    Section("Planning details") {
                        LabeledContent("Expected next statement") {
                            MoneyField(title: "Optional", value: $nextStatementEstimate)
                        }
                        LabeledContent("Current outstanding balance") {
                            MoneyField(title: "Optional", value: $balance)
                        }
                        LabeledContent("Credit limit") {
                            MoneyField(title: "Optional", value: $creditLimit)
                        }
                        Toggle("Pause new spending on this card", isOn: $freezeNewSpending)
                    }
                } else {
                    LabeledContent("Monthly payment") { MoneyField(title: "0.00", value: $payment) }
                    LabeledContent("Outstanding balance") { MoneyField(title: "Optional", value: $balance) }
                }
                LabeledContent("Annual rate (%)") { MoneyField(title: "Optional", value: $annualRate) }
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") {
                    let cardDetails: CreditCardDetails? = category == .creditCard
                        ? CreditCardDetails(
                            statementBalance: statementBalance,
                            minimumPaymentDue: minimumPayment > 0 ? minimumPayment : nil,
                            statementDate: datesConfirmed ? statementDate : nil,
                            paymentDueDate: datesConfirmed ? paymentDueDate : nil,
                            immediatePayment: immediatePayment > 0 ? immediatePayment : nil,
                            nextStatementEstimate: nextStatementEstimate,
                            creditLimit: creditLimit > 0 ? creditLimit : nil,
                            freezeNewSpending: freezeNewSpending
                        )
                        : nil
                    onSave(MonthlyCommitment(
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        category: category,
                        monthlyPayment: category == .creditCard ? minimumPayment : payment,
                        outstandingBalance: balance > 0 ? balance : nil,
                        annualRate: annualRate > 0 ? annualRate : nil,
                        creditCardDetails: cardDetails
                    ))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(BudgetTheme.brand)
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 600, height: category == .creditCard ? 680 : 470)
    }
}

private struct ExpenseEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category: MonthlyExpense.Category = .food
    @State private var amount: Decimal = 0
    @State private var weeklyLimit: Decimal = 0

    let onSave: (MonthlyExpense) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Add monthly expense")
                .font(.title.bold())
            Form {
                TextField("Name", text: $name)
                Picker("Category", selection: $category) {
                    ForEach(MonthlyExpense.Category.allCases) { Text($0.rawValue).tag($0) }
                }
                LabeledContent("Monthly amount") { MoneyField(title: "0.00", value: $amount) }
                LabeledContent("Weekly limit") { MoneyField(title: "Optional", value: $weeklyLimit) }
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") {
                    onSave(MonthlyExpense(
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        category: category,
                        monthlyAmount: amount,
                        weeklyLimit: weeklyLimit > 0 ? weeklyLimit : nil
                    ))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(BudgetTheme.brand)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amount <= 0)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}
