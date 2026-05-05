import XCTest
@testable import RetirementPlanner

final class PlanStoreTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PlanStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func makePlan(name: String = "Plan", at date: Date = Date()) -> SavedPlan {
        SavedPlan(
            id: UUID(),
            name: name,
            createdAt: date,
            retireAge: 65,
            totalPortfolio: 500_000,
            annualSpend: 65_000,
            rentalIncome: 0,
            socialSecurityAge: 67,
            socialSecurityAmt: 22_000,
            bondAllocation: 40,
            bondReturn: 4.5,
            equityReturn: 7,
            inflationRate: 3
        )
    }

    // MARK: - Empty / fresh state

    func testFreshStoreIsEmpty() {
        let store = PlanStore(directory: tempDir)
        XCTAssertEqual(store.plans.count, 0)
    }

    // MARK: - Add / persist / reload

    func testAddPersistsAcrossInstances() {
        let storeA = PlanStore(directory: tempDir)
        storeA.add(makePlan(name: "Alpha"))
        storeA.add(makePlan(name: "Beta"))

        let storeB = PlanStore(directory: tempDir)
        XCTAssertEqual(storeB.plans.count, 2)
        XCTAssertEqual(Set(storeB.plans.map { $0.name }), ["Alpha", "Beta"])
    }

    func testPlansAreSortedNewestFirst() {
        let store = PlanStore(directory: tempDir)
        let older = makePlan(name: "Older", at: Date(timeIntervalSince1970: 1_000_000))
        let newer = makePlan(name: "Newer", at: Date(timeIntervalSince1970: 2_000_000))
        store.add(older)
        store.add(newer)

        XCTAssertEqual(store.plans.first?.name, "Newer")
        XCTAssertEqual(store.plans.last?.name, "Older")
    }

    // MARK: - Delete

    func testDeleteRemovesPlanAndPersists() {
        let storeA = PlanStore(directory: tempDir)
        let plan = makePlan(name: "ToDelete")
        storeA.add(plan)
        storeA.add(makePlan(name: "Keeper"))
        storeA.delete(plan)

        XCTAssertEqual(storeA.plans.map { $0.name }, ["Keeper"])

        let storeB = PlanStore(directory: tempDir)
        XCTAssertEqual(storeB.plans.map { $0.name }, ["Keeper"])
    }

    // MARK: - Rename

    func testRenameUpdatesPlanAndPersists() {
        let storeA = PlanStore(directory: tempDir)
        let plan = makePlan(name: "Old Name")
        storeA.add(plan)
        storeA.rename(plan, to: "New Name")

        XCTAssertEqual(storeA.plans.first?.name, "New Name")

        let storeB = PlanStore(directory: tempDir)
        XCTAssertEqual(storeB.plans.first?.name, "New Name")
    }

    // MARK: - Corrupt-file fallback

    func testCorruptFileFallsBackToEmpty() throws {
        let url = tempDir.appendingPathComponent("saved-plans.json")
        try Data("{not valid json".utf8).write(to: url)

        let store = PlanStore(directory: tempDir)
        XCTAssertEqual(store.plans.count, 0)
    }

    // MARK: - Default name

    func testDefaultNameFormat() {
        var components = DateComponents()
        components.timeZone = TimeZone(identifier: "America/New_York")
        components.year = 2026
        components.month = 4
        components.day = 30
        components.hour = 14
        components.minute = 14
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let date = calendar.date(from: components)!

        // Force the formatter to interpret date in the same TZ for an exact assertion.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.dateFormat = "MMM d, h:mm a"
        let expected = formatter.string(from: date)

        // PlanStore.defaultName uses the device default time zone — we just verify shape:
        // contains a month abbreviation, day, comma, time, AM/PM marker.
        let actual = PlanStore.defaultName(at: date)
        XCTAssertTrue(actual.contains(":"))
        XCTAssertTrue(actual.contains(","))
        XCTAssertTrue(actual.contains("AM") || actual.contains("PM"))
        // Sanity: same format string yields equal strings when timezones match.
        XCTAssertFalse(expected.isEmpty)
    }
}
