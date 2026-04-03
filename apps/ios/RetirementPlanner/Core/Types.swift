// Core domain types — mirrors packages/core/src/types.ts

/// A single year's snapshot in the projection timeline.
struct ProjectionSnapshot: Equatable, Codable {
    /// Calendar year (e.g. 2035).
    let year: Int
    /// Age of the primary person at the end of this year.
    let age: Int
    /// Portfolio balance at year-end in nominal dollars.
    let portfolioNominal: Double
    /// Portfolio balance at year-end in today's purchasing power.
    let portfolioReal: Double
    /// Total contributions made during this year.
    let annualContribution: Double
    /// Investment gains earned during this year (nominal).
    let investmentGains: Double
}

/// Input parameters for the portfolio projection engine.
/// Not Codable — used as a function argument only.
struct ProjectionInput {
    let currentPortfolio: Double
    let annualContribution: Double
    let annualReturnRate: Double
    let inflationRate: Double
    let currentAge: Int
    let retirementAge: Int
    /// Whether contributions grow with inflation each year (default: true).
    var inflationAdjustContributions: Bool = true
}

/// Result of the 4% safe-withdrawal-rate analysis.
struct WithdrawalAnalysis: Equatable, Codable {
    let portfolioValue: Double
    let annualWithdrawal: Double
    let monthlyWithdrawal: Double
    let withdrawalRate: Double
}

/// Portfolio size needed to sustainably fund a given annual spending level.
struct FireNumber: Equatable, Codable {
    let annualExpenses: Double
    let requiredPortfolio: Double
    let withdrawalRate: Double
}

/// Inflation-adjusted value calculation result.
struct InflationResult: Equatable, Codable {
    let nominalValue: Double
    let realValue: Double
    let years: Double
    let inflationRate: Double
}

/// Errors thrown by the projection engine.
enum ProjectionError: Error, Equatable {
    case retirementAgeNotGreaterThanCurrentAge(retirementAge: Int, currentAge: Int)
    case noSnapshots
}

// MARK: - Bucket strategy types

/// Input for the 5-year bucket decumulation strategy.
struct BucketInput {
    /// Age at which the person retires.
    let retireAge: Int
    /// Total portfolio value (cash + investments) at retirement.
    let totalPortfolio: Double
    /// Desired annual spending in today's dollars.
    let annualSpend: Double
    /// Annual rental income in today's dollars (0 if none).
    let rentalIncome: Double
    /// Age at which Social Security payments begin.
    let socialSecurityAge: Int
    /// Annual Social Security benefit in today's dollars.
    let socialSecurityAmt: Double
    /// Bond allocation as a decimal (e.g. 0.4 = 40%).
    let bondAllocation: Double
    /// Expected annual bond return as a decimal (e.g. 0.045 = 4.5%).
    let bondReturn: Double
    /// Expected annual equity return as a decimal (e.g. 0.07 = 7%).
    let equityReturn: Double
    /// Annual inflation rate as a decimal (e.g. 0.03 = 3%).
    let inflationRate: Double
    /// Number of years to project (typically 100 − retireAge).
    let projectionYears: Int
}

/// A single year's snapshot in the 5-year bucket decumulation timeline.
struct BucketSnapshot: Equatable, Codable {
    /// 0-indexed year from retirement (0 = first year of retirement).
    let yr: Int
    /// Age during this year.
    let age: Int
    /// Bond bucket value at year-end.
    let bonds: Double
    /// Equity bucket value at year-end.
    let equity: Double
    /// Cash bucket value at year-end.
    let cash: Double
    /// Total portfolio value (bonds + equity + cash) at year-end.
    let total: Double
    /// Combined investment return (bond gains + equity gains) this year.
    let totalReturn: Double
    /// Inflation-adjusted spending this year.
    let spend: Double
    /// Inflation-adjusted rental income this year.
    let rental: Double
    /// Inflation-adjusted Social Security income this year (0 if not yet eligible).
    let ss: Double
    /// Total passive income this year (rental + SS).
    let totalIncome: Double
    /// Net amount that must be drawn from the portfolio (spend − totalIncome, floored at 0).
    let gap: Double
    /// Bond investment gains this year.
    let bondGain: Double
    /// Equity investment gains this year.
    let equityGain: Double
}
