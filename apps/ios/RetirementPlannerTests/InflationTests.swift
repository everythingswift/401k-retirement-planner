import XCTest
@testable import RetirementPlanner

final class InflationTests: XCTestCase {
    private var fix: InflationFixtures!

    override func setUpWithError() throws {
        fix = try FixtureLoader.load().inflation
    }

    // MARK: inflationFactor

    func testInflationFactorBasic() {
        XCTAssertEqual(
            inflationFactor(inflationRate: fix.factorBasic.inflationRate, years: fix.factorBasic.years),
            fix.factorBasic.expected,
            accuracy: 1e-6
        )
    }

    func testInflationFactorZeroRate() {
        XCTAssertEqual(inflationFactor(inflationRate: 0.0, years: 5), 1.0, accuracy: 1e-9)
    }

    func testInflationFactorZeroYears() {
        XCTAssertEqual(inflationFactor(inflationRate: 0.03, years: 0), 1.0, accuracy: 1e-9)
    }

    // MARK: toNominal

    func testToNominalBasic() {
        let f = fix.toNominalBasic
        XCTAssertEqual(
            toNominal(f.realValue, inflationRate: f.inflationRate, years: f.years),
            f.expected,
            accuracy: 1e-6
        )
    }

    // MARK: toReal

    func testToRealRoundTrip() {
        let f = fix.toRealBasic
        let result = toReal(f.nominalValue, inflationRate: f.inflationRate, years: f.years)
        XCTAssertEqual(result.realValue, f.expectedReal, accuracy: 1e-6)
    }

    func testToRealPreservesInputFields() {
        let f = fix.toRealBasic
        let result = toReal(f.nominalValue, inflationRate: f.inflationRate, years: f.years)
        XCTAssertEqual(result.nominalValue, f.nominalValue, accuracy: 1e-6)
        XCTAssertEqual(result.inflationRate, f.inflationRate, accuracy: 1e-9)
        XCTAssertEqual(result.years, f.years, accuracy: 1e-9)
    }

    // MARK: realReturnRate

    func testRealReturnRateBasic() {
        let f = fix.realReturnBasic
        XCTAssertEqual(
            realReturnRate(nominalRate: f.nominalRate, inflationRate: f.inflationRate),
            f.expected,
            accuracy: 1e-6
        )
    }

    func testRealReturnRateZeroInputs() {
        XCTAssertEqual(realReturnRate(nominalRate: 0.0, inflationRate: 0.0), 0.0, accuracy: 1e-9)
    }

    // MARK: inflationAdjustedContribution

    func testAdjustedContributionBasic() {
        let f = fix.adjustedContributionBasic
        XCTAssertEqual(
            inflationAdjustedContribution(f.baseContribution, inflationRate: f.inflationRate, yearsElapsed: f.yearsElapsed),
            f.expected,
            accuracy: 1e-6
        )
    }

    func testAdjustedContributionYearZero() {
        // At year 0 the factor is 1.03^0 = 1, so the contribution is unchanged.
        XCTAssertEqual(
            inflationAdjustedContribution(1000.0, inflationRate: 0.03, yearsElapsed: 0),
            1000.0,
            accuracy: 1e-9
        )
    }
}
