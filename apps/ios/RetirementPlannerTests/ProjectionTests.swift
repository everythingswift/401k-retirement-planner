import XCTest
@testable import RetirementPlanner

final class ProjectionTests: XCTestCase {
    private var adjusted: ProjectionFixtures!
    private var flat: ProjectionFixtures!
    private var adjSnaps: [ProjectionSnapshot]!
    private var flatSnaps: [ProjectionSnapshot]!

    override func setUpWithError() throws {
        let fixtures = try FixtureLoader.load()
        adjusted = fixtures.projectionAdjusted
        flat = fixtures.projectionFlat
        adjSnaps = try projectPortfolio(adjusted.input.asProjectionInput, startYear: adjusted.input.startYear)
        flatSnaps = try projectPortfolio(flat.input.asProjectionInput, startYear: flat.input.startYear)
    }

    // MARK: Adjusted projection — snapshot count

    func testAdjustedSnapshotCount() {
        XCTAssertEqual(adjSnaps.count, adjusted.snapshots.count)
    }

    // MARK: Adjusted projection — year 1 fields

    func testAdjustedSnapshotYear1() {
        let s = adjSnaps[0]; let f = adjusted.snapshots[0]
        XCTAssertEqual(s.year, f.year)
        XCTAssertEqual(s.age, f.age)
        XCTAssertEqual(s.portfolioNominal, f.portfolioNominal, accuracy: 1e-6)
        XCTAssertEqual(s.portfolioReal, f.portfolioReal, accuracy: 1e-6)
        XCTAssertEqual(s.annualContribution, f.annualContribution, accuracy: 1e-6)
        XCTAssertEqual(s.investmentGains, f.investmentGains, accuracy: 1e-6)
    }

    // MARK: Adjusted projection — year 2 fields

    func testAdjustedSnapshotYear2() {
        let s = adjSnaps[1]; let f = adjusted.snapshots[1]
        XCTAssertEqual(s.year, f.year)
        XCTAssertEqual(s.age, f.age)
        XCTAssertEqual(s.portfolioNominal, f.portfolioNominal, accuracy: 1e-6)
        XCTAssertEqual(s.portfolioReal, f.portfolioReal, accuracy: 1e-6)
        XCTAssertEqual(s.annualContribution, f.annualContribution, accuracy: 1e-6)
        XCTAssertEqual(s.investmentGains, f.investmentGains, accuracy: 1e-6)
    }

    // MARK: Aggregates

    func testAdjustedTotalContributions() {
        XCTAssertEqual(totalContributions(adjSnaps), adjusted.totalContributions, accuracy: 1e-6)
    }

    func testAdjustedTotalGains() {
        XCTAssertEqual(totalGains(adjSnaps), adjusted.totalGains, accuracy: 1e-6)
    }

    // MARK: Flat projection

    func testFlatSnapshotCount() {
        XCTAssertEqual(flatSnaps.count, flat.snapshots.count)
    }

    func testFlatContributionYear2IsFlat() {
        // Flat mode keeps contribution at the base amount — no inflation escalation.
        XCTAssertEqual(flatSnaps[1].annualContribution, flat.input.annualContribution, accuracy: 1e-6)
        XCTAssertEqual(flatSnaps[1].annualContribution, flat.snapshots[1].annualContribution, accuracy: 1e-6)
    }

    func testFlatVsAdjustedPortfolioDiffers() {
        // Adjusted contributions are larger in year 2, so the portfolio should be higher.
        XCTAssertGreaterThan(adjSnaps[1].portfolioNominal, flatSnaps[1].portfolioNominal)
    }

    // MARK: projectFinalBalance

    func testFinalBalanceParity() throws {
        let finalBalance = try projectFinalBalance(adjusted.input.asProjectionInput, startYear: adjusted.input.startYear)
        XCTAssertEqual(finalBalance.portfolioNominal, adjSnaps.last!.portfolioNominal, accuracy: 1e-6)
        XCTAssertEqual(finalBalance.year, adjSnaps.last!.year)
    }

    // MARK: Error handling

    func testThrowsWhenRetirementAgeEqualsCurrentAge() {
        let input = ProjectionInput(
            currentPortfolio: 10_000,
            annualContribution: 1_000,
            annualReturnRate: 0.07,
            inflationRate: 0.03,
            currentAge: 40,
            retirementAge: 40
        )
        XCTAssertThrowsError(try projectPortfolio(input, startYear: 2026)) { error in
            guard case ProjectionError.retirementAgeNotGreaterThanCurrentAge = error else {
                XCTFail("Expected retirementAgeNotGreaterThanCurrentAge, got \(error)")
                return
            }
        }
    }

    func testThrowsWhenRetirementAgeBeforeCurrentAge() {
        let input = ProjectionInput(
            currentPortfolio: 10_000,
            annualContribution: 1_000,
            annualReturnRate: 0.07,
            inflationRate: 0.03,
            currentAge: 50,
            retirementAge: 45
        )
        XCTAssertThrowsError(try projectPortfolio(input, startYear: 2026))
    }

    // MARK: Single-year boundary

    func testSingleYearProjection() throws {
        let input = ProjectionInput(
            currentPortfolio: 100_000,
            annualContribution: 5_000,
            annualReturnRate: 0.07,
            inflationRate: 0.03,
            currentAge: 64,
            retirementAge: 65
        )
        let snapshots = try projectPortfolio(input, startYear: 2026)
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots[0].year, 2027)
        XCTAssertEqual(snapshots[0].age, 65)
        // (100_000 + 5_000) × 1.07 = 112_350
        XCTAssertEqual(snapshots[0].portfolioNominal, 112_350.0, accuracy: 1e-6)
    }

    // MARK: Year / age increment correctness

    func testYearAndAgeIncrementPerSnapshot() throws {
        for (i, snapshot) in adjSnaps.enumerated() {
            XCTAssertEqual(snapshot.year, adjusted.input.startYear + i + 1, "year at index \(i)")
            XCTAssertEqual(snapshot.age, adjusted.input.currentAge + i + 1, "age at index \(i)")
        }
    }

    // MARK: Real < nominal when inflation > 0

    func testRealBalanceLessThanNominalWhenInflationPositive() {
        for snapshot in adjSnaps {
            XCTAssertLessThan(snapshot.portfolioReal, snapshot.portfolioNominal)
        }
    }
}
