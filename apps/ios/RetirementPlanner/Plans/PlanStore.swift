import Foundation
import Observation
import os

/// On-device persistence for saved plans.
///
/// Storage: a single JSON file at `Documents/saved-plans.json`. The list is
/// small (tens at most), so every mutation rewrites the whole file atomically.
/// Apple removes the app's container on uninstall, so saved plans are deleted
/// with the app — no extra cleanup logic needed.
@Observable
final class PlanStore {

    /// Plans sorted newest-first.
    private(set) var plans: [SavedPlan] = []

    private let fileURL: URL
    private let logger = Logger(subsystem: "com.everythingswift.RetireWise", category: "PlanStore")

    /// - Parameter directory: Directory to store the JSON file in. Defaults to the
    ///   app's Documents directory; tests inject a temp dir.
    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
        self.fileURL = dir.appendingPathComponent("saved-plans.json")
        load()
    }

    // MARK: - Public API

    func add(_ plan: SavedPlan) {
        plans.insert(plan, at: 0)
        sortInPlace()
        persist()
    }

    func delete(_ plan: SavedPlan) {
        plans.removeAll { $0.id == plan.id }
        persist()
    }

    func rename(_ plan: SavedPlan, to newName: String) {
        guard let idx = plans.firstIndex(where: { $0.id == plan.id }) else { return }
        plans[idx].name = newName
        persist()
    }

    /// Default name for a plan saved at `date`, e.g. "Apr 30, 2:14 PM".
    static func defaultName(at date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            plans = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            plans = try decoder.decode([SavedPlan].self, from: data)
            sortInPlace()
        } catch {
            logger.error("Failed to load saved plans, starting with empty list: \(error.localizedDescription, privacy: .public)")
            plans = []
        }
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(plans)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            logger.error("Failed to persist saved plans: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func sortInPlace() {
        plans.sort { $0.createdAt > $1.createdAt }
    }
}
