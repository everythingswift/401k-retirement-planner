import XCTest
@testable import RetirementPlanner

final class FourPercentTests: XCTestCase {
    private var fix: FourPercentFixtures!

    override func setUpWithError() throws {
        fix = try FixtureLoader.load().fourPercent
    }

    // MARK: safeWithdrawal

    func testSafeWithdrawalDefault() {
        let f = fix.safeWithdrawalDefault
        let result = safeWithdrawal(portfolioValue: f.portfolioValue)
        XCTAssertEqual(result.portfolioValue, f.portfolioValue, accuracy: 1e-6)
        XCTAssertEqual(result.annualWithdrawal, f.expectedAnnual, accuracy: 1e-6)
        XCTAssertEqual(result.monthlyWithdrawal, f.expectedMonthly, accuracy: 1e-6)
        XCTAssertEqual(result.withdrawalRate, FourPercentRule.defaultWithdrawalRate, accuracy: 1e-9)
    }

    func testSafeWithdrawalZeroPortfolio() {
        let result = safeWithdrawal(portfolioValue: 0)
        XCTAssertEqual(result.annualWithdrawal, 0.0, accuracy: 1e-9)
        XCTAssertEqual(result.monthlyWithdrawal, 0.0, accuracy: 1e-9)
    }

    func testSafeWithdrawalCustomRate() {
        let f = fix.safeWithdrawalCustom
        let result = safeWithdrawal(portfolioValue: f.portfolioValue, withdrawalRate: f.withdrawalRate!)
        XCTAssertEqual(result.annualWithdrawal, f.expectedAnnual, accuracy: 1e-6)
        XCTAssertEqual(result.monthlyWithdrawal, f.expectedMonthly, accuracy: 1e-6)
    }

    // MARK: fireNumber

    func testFireNumberDefault() {
        let f = fix.fireNumberDefault
        let result = fireNumber(annualExpenses: f.annualExpenses)
        XCTAssertEqual(result.requiredPortfolio, f.expectedPortfolio, accuracy: 1e-6)
        XCTAssertEqual(result.annualExpenses, f.annualExpenses, accuracy: 1e-6)
        XCTAssertEqual(result.withdrawalRate, FourPercentRule.defaultWithdrawalRate, accuracy: 1e-9)
    }

    func testFireNumberInverseRoundTrip() {
        // safeWithdrawal on the FIRE number should equal original expenses
        let expenses = fix.fireNumberDefault.annualExpenses
        let fn = fireNumber(annualExpenses: expenses)
        let sw = safeWithdrawal(portfolioValue: fn.requiredPortfolio)
        XCTAssertEqual(sw.annualWithdrawal, expenses, accuracy: 1e-6)
    }

    // MARK: fireProgress

    func testFireProgressPartial() {
        let f = fix.fireProgressPartial
        XCTAssertEqual(
            fireProgress(currentPortfolio: f.currentPortfolio, targetPortfolio: f.targetPortfolio),
            f.expected,
            accuracy: 1e-9
        )
    }

    func testFireProgressClampedAbove100() {
        let f = fix.fireProgressClamped
        XCTAssertEqual(
            fireProgress(currentPortfolio: f.currentPortfolio, targetPortfolio: f.targetPortfolio),
            f.expected,
            accuracy: 1e-9
        )
    }

    func testFireProgressZeroTarget() {
        XCTAssertEqual(fireProgress(currentPortfolio: 100_000, targetPortfolio: 0), 0.0, accuracy: 1e-9)
    }

    // MARK: yearsOfExpenses

    func testYearsOfExpensesNormal() {
        let f = fix.yearsOfExpensesNormal
        XCTAssertEqual(
            yearsOfExpenses(portfolioValue: f.portfolioValue, annualExpenses: f.annualExpenses),
            f.expected,
            accuracy: 1e-6
        )
    }

    func testYearsOfExpensesZeroExpenses() {
        // Fixture uses "Infinity" string sentinel; expected result is Double.infinity.
        let f = fix.yearsOfExpensesZero
        XCTAssertEqual(
            yearsOfExpenses(portfolioValue: f.portfolioValue, annualExpenses: f.annualExpenses),
            f.expectedDouble
        )
    }

    func testYearsOfExpensesNegativeExpenses() {
        // Negative expenses also treated as <= 0 → infinity.
        XCTAssertEqual(yearsOfExpenses(portfolioValue: 500_000, annualExpenses: -1), .infinity)
    }
}
