import BudgetCore
import Foundation

struct SavedBudget: Codable, Sendable {
    var profile: BudgetProfile
    var allocation: AllocationPlan
}

actor BudgetRepository {
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = baseURL.appending(path: "BudgetFlow", directoryHint: .isDirectory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appending(path: "budget.json", directoryHint: .notDirectory)
    }

    func load() throws -> SavedBudget? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(SavedBudget.self, from: data)
    }

    func save(_ budget: SavedBudget) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(budget)
        try data.write(to: fileURL, options: .atomic)
    }
}
