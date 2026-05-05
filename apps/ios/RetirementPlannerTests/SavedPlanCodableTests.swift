import XCTest
@testable import RetirementPlanner

final class SavedPlanCodableTests: XCTestCase {

    func testRoundTripPreservesAllFields() throws {
        let original = SavedPlan(
            id: UUID(),
            name: "My Conservative Plan",
            createdAt: Date(timeIntervalSince1970: 1_714_500_000),
            retireAge: 67,
            totalPortfolio: 750_000,
            annualSpend: 80_000,
            rentalIncome: 12_000,
            socialSecurityAge: 70,
            socialSecurityAmt: 28_000,
            bondAllocation: 50,
            bondReturn: 4.0,
            equityReturn: 6.5,
            inflationRate: 2.75
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SavedPlan.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testCaptureFromStoreCopiesAllInputs() {
        let store = RetirementStore()
        store.retireAge = 62
        store.totalPortfolio = 1_200_000
        store.annualSpend = 95_000
        store.rentalIncome = 24_000
        store.socialSecurityAge = 67
        store.socialSecurityAmt = 32_000
        store.bondAllocation = 35
        store.bondReturn = 4.25
        store.equityReturn = 8.0
        store.inflationRate = 3.25

        let plan = SavedPlan(capturing: store, name: "Test")

        XCTAssertEqual(plan.retireAge, 62)
        XCTAssertEqual(plan.totalPortfolio, 1_200_000)
        XCTAssertEqual(plan.annualSpend, 95_000)
        XCTAssertEqual(plan.rentalIncome, 24_000)
        XCTAssertEqual(plan.socialSecurityAge, 67)
        XCTAssertEqual(plan.socialSecurityAmt, 32_000)
        XCTAssertEqual(plan.bondAllocation, 35)
        XCTAssertEqual(plan.bondReturn, 4.25)
        XCTAssertEqual(plan.equityReturn, 8.0)
        XCTAssertEqual(plan.inflationRate, 3.25)
        XCTAssertEqual(plan.name, "Test")
    }

    func testApplyOnStoreOverwritesAllInputs() {
        let store = RetirementStore() // defaults
        let plan = SavedPlan(
            id: UUID(),
            name: "Override",
            createdAt: Date(),
            retireAge: 70,
            totalPortfolio: 2_000_000,
            annualSpend: 120_000,
            rentalIncome: 36_000,
            socialSecurityAge: 70,
            socialSecurityAmt: 40_000,
            bondAllocation: 60,
            bondReturn: 3.5,
            equityReturn: 7.5,
            inflationRate: 2.5
        )

        store.apply(plan)

        XCTAssertEqual(store.retireAge, 70)
        XCTAssertEqual(store.totalPortfolio, 2_000_000)
        XCTAssertEqual(store.annualSpend, 120_000)
        XCTAssertEqual(store.rentalIncome, 36_000)
        XCTAssertEqual(store.socialSecurityAge, 70)
        XCTAssertEqual(store.socialSecurityAmt, 40_000)
        XCTAssertEqual(store.bondAllocation, 60)
        XCTAssertEqual(store.bondReturn, 3.5)
        XCTAssertEqual(store.equityReturn, 7.5)
        XCTAssertEqual(store.inflationRate, 2.5)
    }

    func testCaptureThenApplyReproducesSnapshots() {
        let original = RetirementStore()
        original.retireAge = 64
        original.totalPortfolio = 600_000
        original.annualSpend = 55_000
        original.bondAllocation = 45
        original.equityReturn = 6.0
        let originalSnapshots = original.snapshots

        let plan = SavedPlan(capturing: original, name: "Snapshot")
        let restored = RetirementStore()
        restored.apply(plan)

        XCTAssertEqual(restored.snapshots, originalSnapshots)
    }
}
