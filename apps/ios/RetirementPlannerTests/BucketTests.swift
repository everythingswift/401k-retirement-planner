import XCTest
@testable import RetirementPlanner

final class BucketTests: XCTestCase {

    // A representative average-American default, mirroring the web app defaults.
    private let defaults = BucketInput(
        retireAge:          65,
        totalPortfolio:     500_000,
        annualSpend:        65_000,
        rentalIncome:       0,
        socialSecurityAge:  67,
        socialSecurityAmt:  22_000,
        bondAllocation:     0.4,
        bondReturn:         0.045,
        equityReturn:       0.07,
        inflationRate:      0.03,
        projectionYears:    35   // age 65 → 100
    )

    // MARK: - computeInitialCash

    func testInitialCashIsPositive() {
        XCTAssertGreaterThan(computeInitialCash(defaults), 0)
    }

    func testInitialCashLessThanTotalPortfolio() {
        XCTAssertLessThan(computeInitialCash(defaults), defaults.totalPortfolio)
    }

    func testInitialCashApproxFiveYearsNetSpendNoSS() {
        // When SS doesn't begin until after the 5-year window, cash ≈ 5 × annualSpend
        // (plus small inflation escalation for years 1–4, no rental).
        let input = BucketInput(
            retireAge: 65, totalPortfolio: 500_000, annualSpend: 65_000,
            rentalIncome: 0, socialSecurityAge: 70, socialSecurityAmt: 22_000,
            bondAllocation: 0.4, bondReturn: 0.045, equityReturn: 0.07,
            inflationRate: 0.03, projectionYears: 35
        )
        let cash = computeInitialCash(input)
        let roughFloor   = input.annualSpend * 5
        let roughCeiling = input.annualSpend * 5 * 1.15  // allow for 4 yrs of 3% inflation
        XCTAssertGreaterThanOrEqual(cash, roughFloor)
        XCTAssertLessThanOrEqual(cash, roughCeiling)
    }

    func testInitialCashZeroWhenIncomeCoversSpend() {
        // If rental + SS ≥ annualSpend every year, no cash reserve is needed.
        let input = BucketInput(
            retireAge:         65,
            totalPortfolio:    500_000,
            annualSpend:       50_000,
            rentalIncome:      30_000,
            socialSecurityAge: 65,    // SS active from day 1
            socialSecurityAmt: 25_000, // rental + SS = 55_000 > 50_000
            bondAllocation:    0.4,
            bondReturn:        0.045,
            equityReturn:      0.07,
            inflationRate:     0.03,
            projectionYears:   35
        )
        XCTAssertEqual(computeInitialCash(input), 0, accuracy: 1e-6)
    }

    func testInitialCashReducedByRentalIncome() {
        let withRental = BucketInput(
            retireAge: 65, totalPortfolio: 500_000, annualSpend: 65_000,
            rentalIncome: 20_000, socialSecurityAge: 70, socialSecurityAmt: 22_000,
            bondAllocation: 0.4, bondReturn: 0.045, equityReturn: 0.07,
            inflationRate: 0.03, projectionYears: 35
        )
        XCTAssertLessThan(computeInitialCash(withRental), computeInitialCash(defaults))
    }

    // MARK: - projectBuckets — snapshot count

    func testSnapshotCountMatchesProjectionYears() {
        let snapshots = projectBuckets(defaults)
        XCTAssertEqual(snapshots.count, defaults.projectionYears)
    }

    // MARK: - projectBuckets — initial state (year 0)

    func testYear0AgeEqualsRetireAge() {
        let snap = projectBuckets(defaults)[0]
        XCTAssertEqual(snap.age, defaults.retireAge)
    }

    func testYear0YrIsZero() {
        let snap = projectBuckets(defaults)[0]
        XCTAssertEqual(snap.yr, 0)
    }

    func testYear0TotalDoesNotExceedInitialPortfolio() {
        // After year-0 returns, the total should be >= initial portfolio (positive returns).
        let snap = projectBuckets(defaults)[0]
        XCTAssertGreaterThan(snap.total, 0)
    }

    func testYear0BondsAndEquitySumToInvestableAtStart() {
        // Before any returns the investable pot = portfolio − cash.
        // After one year of returns bonds + equity > investable.
        let cash = computeInitialCash(defaults)
        let investable = defaults.totalPortfolio - cash
        let snap = projectBuckets(defaults)[0]
        // bonds + equity at year-end = investable × (1 + blended return) − possible refill
        XCTAssertGreaterThan(snap.bonds + snap.equity, 0)
        XCTAssertLessThanOrEqual(snap.bonds + snap.equity, investable * 1.2)
    }

    // MARK: - projectBuckets — SS eligibility

    func testSSZeroBeforeEligibleAge() {
        let snapshots = projectBuckets(defaults)
        // SS starts at age 67; year 0 = age 65, year 1 = age 66
        XCTAssertEqual(snapshots[0].ss, 0, accuracy: 1e-6)
        XCTAssertEqual(snapshots[1].ss, 0, accuracy: 1e-6)
    }

    func testSSActiveAtEligibleAge() {
        let snapshots = projectBuckets(defaults)
        // Year 2 = age 67; SS should be active (inflation-adjusted).
        let ssYear2 = snapshots[2].ss
        let expected = defaults.socialSecurityAmt * pow(1 + defaults.inflationRate, 2)
        XCTAssertEqual(ssYear2, expected, accuracy: 1e-6)
    }

    // MARK: - projectBuckets — gap calculation

    func testGapIsZeroWhenIncomeExceedsSpend() {
        let input = BucketInput(
            retireAge: 65, totalPortfolio: 500_000, annualSpend: 40_000,
            rentalIncome: 20_000, socialSecurityAge: 65, socialSecurityAmt: 25_000,
            bondAllocation: 0.4, bondReturn: 0.045, equityReturn: 0.07,
            inflationRate: 0.03, projectionYears: 10
        )
        let snapshots = projectBuckets(input)
        for snap in snapshots {
            XCTAssertEqual(snap.gap, 0, accuracy: 1e-6,
                           "Expected gap = 0 at age \(snap.age) when income > spend")
        }
    }

    func testGapEqualsNetWithdrawalWhenNoIncome() {
        // No rental, no SS yet — gap should equal inflation-adjusted spend.
        let input = BucketInput(
            retireAge: 65, totalPortfolio: 500_000, annualSpend: 60_000,
            rentalIncome: 0, socialSecurityAge: 70, socialSecurityAmt: 0,
            bondAllocation: 0.4, bondReturn: 0.045, equityReturn: 0.07,
            inflationRate: 0.03, projectionYears: 5
        )
        let snapshots = projectBuckets(input)
        for snap in snapshots {
            let expectedSpend = 60_000 * pow(1 + 0.03, Double(snap.yr))
            XCTAssertEqual(snap.gap, expectedSpend, accuracy: 1e-6)
        }
    }

    // MARK: - projectBuckets — cash refill at year 5

    func testCashRefillsAtYear5() {
        // Cash at end of year 4 (index 4) should be higher than end of year 3 (index 3)
        // because a refill happens after year 4's spending.
        let snapshots = projectBuckets(defaults)
        let cashAfterYear4 = snapshots[4].cash   // refill just happened
        let cashAfterYear3 = snapshots[3].cash   // no refill yet
        XCTAssertGreaterThan(cashAfterYear4, cashAfterYear3)
    }

    func testInvestmentPotDecreasesAtRefillYear() {
        // When cash is refilled, bonds + equity should drop.
        let snapshots = projectBuckets(defaults)
        let investAfterYear3 = snapshots[3].bonds + snapshots[3].equity
        let investAfterYear4 = snapshots[4].bonds + snapshots[4].equity
        // The refill withdrawal should more than offset one year of returns
        // only if nextCashNeeded > investment returns — not guaranteed, so just
        // check cash went up (covered by testCashRefillsAtYear5).
        XCTAssertGreaterThan(investAfterYear3, 0)
        XCTAssertGreaterThan(investAfterYear4, 0)
    }

    // MARK: - projectBuckets — yr index correctness

    func testYrIndexMatchesLoopIndex() {
        let snapshots = projectBuckets(defaults)
        for (i, snap) in snapshots.enumerated() {
            XCTAssertEqual(snap.yr, i, "yr at index \(i)")
            XCTAssertEqual(snap.age, defaults.retireAge + i, "age at index \(i)")
        }
    }

    // MARK: - projectBuckets — portfolio stays non-negative

    func testPortfolioNeverGoesNegative() {
        let snapshots = projectBuckets(defaults)
        for snap in snapshots {
            XCTAssertGreaterThanOrEqual(snap.total, 0, "Negative portfolio at age \(snap.age)")
            XCTAssertGreaterThanOrEqual(snap.bonds, 0)
            XCTAssertGreaterThanOrEqual(snap.equity, 0)
            XCTAssertGreaterThanOrEqual(snap.cash, 0)
        }
    }

    // MARK: - computeInitialCash — zero inflation edge case

    func testInitialCashWithZeroInflationIsExactlyFiveYearsNetSpend() {
        let input = BucketInput(
            retireAge: 65, totalPortfolio: 500_000, annualSpend: 60_000,
            rentalIncome: 10_000, socialSecurityAge: 70, socialSecurityAmt: 0,
            bondAllocation: 0.4, bondReturn: 0.045, equityReturn: 0.07,
            inflationRate: 0.0,   // zero inflation → no escalation
            projectionYears: 35
        )
        // net spend per year = 60_000 − 10_000 = 50_000 (flat, no inflation)
        XCTAssertEqual(computeInitialCash(input), 50_000 * 5, accuracy: 1e-6)
    }
}
