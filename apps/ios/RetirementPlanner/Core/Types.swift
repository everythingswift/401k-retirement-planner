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
