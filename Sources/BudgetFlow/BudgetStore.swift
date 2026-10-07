import BudgetCore
import Foundation

@MainActor
final class BudgetStore: ObservableObject {
    @Published private(set) var profile: BudgetProfile?
    @Published private(set) var allocation = AllocationPlan()
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private let repository: BudgetRepository

    init(repository: BudgetRepository) {
        self.repository = repository
        Task { await load() }
    }

    var snapshot: BudgetSnapshot? {
        profile.map(BudgetEngine.snapshot)
    }

    var score: FinancialStabilityScore? {
        profile.map { BudgetEngine.financialStabilityScore(for: $0, allocation: allocation) }
    }

    func completeSetup(with profile: BudgetProfile) {
        self.profile = profile
        allocation = BudgetEngine.suggestedAllocation(for: profile)
        persist()
        publishWidgetSummary()
    }

    func updateProfile(_ profile: BudgetProfile) {
        self.profile = profile
        allocation = BudgetEngine.suggestedAllocation(for: profile)
        persist()
        publishWidgetSummary()
    }

    func updatePlanningPreferences(_ mutation: (inout BudgetPreferences) -> Void) {
        guard var profile else { return }
        mutation(&profile.preferences)
        self.profile = profile
        persist()
        publishWidgetSummary()
    }

    func updateAllocation(_ allocation: AllocationPlan) {
        self.allocation = allocation
        persist()
        publishWidgetSummary()
    }

    func restoreSuggestedAllocation() {
        guard let profile else { return }
        allocation = BudgetEngine.suggestedAllocation(for: profile)
        persist()
        publishWidgetSummary()
    }

    func dismissError() {
        errorMessage = nil
    }

    private func load() async {
        defer { isLoading = false }
        do {
            guard let saved = try await repository.load() else { return }
            profile = saved.profile
            allocation = saved.allocation
            publishWidgetSummary()
        } catch {
            errorMessage = "The saved budget could not be loaded. Your file was not changed."
        }
    }

    private func persist() {
        guard let profile else { return }
        let saved = SavedBudget(profile: profile, allocation: allocation)
        Task {
            do {
                try await repository.save(saved)
            } catch {
                errorMessage = "BudgetFlow could not save the latest changes."
            }
        }
    }

    private func publishWidgetSummary() {
        guard let profile else { return }
        BudgetWidgetPublisher.publish(profile: profile, allocation: allocation)
    }
}
