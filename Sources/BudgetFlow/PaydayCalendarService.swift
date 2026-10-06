import EventKit
import Foundation

@MainActor
final class PaydayCalendarService: ObservableObject {
    enum Status: Equatable {
        case notConnected
        case loading
        case connected(eventCount: Int)
        case denied
        case failed(String)
    }

    @Published private(set) var paydayDates: [Date] = []
    @Published private(set) var status: Status = .notConnected

    private let eventStore = EKEventStore()
    private let calendar = Calendar.current

    func refreshIfAuthorized(monthCount: Int = 12) async {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized:
            loadPaydays(monthCount: monthCount)
        case .denied, .restricted, .writeOnly:
            status = .denied
        case .notDetermined:
            status = .notConnected
        @unknown default:
            status = .notConnected
        }
    }

    func connect(monthCount: Int = 12) async {
        status = .loading
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await withCheckedThrowingContinuation { continuation in
                    eventStore.requestAccess(to: .event) { allowed, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: allowed)
                        }
                    }
                }
            }
            guard granted else {
                status = .denied
                return
            }
            loadPaydays(monthCount: monthCount)
        } catch {
            status = .failed("Calendar access could not be completed.")
        }
    }

    private func loadPaydays(monthCount: Int) {
        guard let start = calendar.dateInterval(of: .month, for: Date())?.end,
              let end = calendar.date(byAdding: .month, value: monthCount, to: start) else {
            status = .failed("The planning date range could not be created.")
            return
        }

        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let matchingEvents = eventStore.events(matching: predicate)
            .filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare("Payday") == .orderedSame }
            .sorted { $0.startDate < $1.startDate }

        var seenMonths: Set<DateComponents> = []
        paydayDates = matchingEvents.compactMap { event in
            let month = calendar.dateComponents([.year, .month], from: event.startDate)
            guard seenMonths.insert(month).inserted else { return nil }
            return event.startDate
        }
        status = .connected(eventCount: paydayDates.count)
    }
}
