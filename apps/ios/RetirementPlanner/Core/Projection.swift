import Foundation

// Portfolio projection engine — mirrors packages/core/src/projection.ts

/// Projects portfolio growth year-by-year from today until retirement.
///
/// Model assumptions:
/// - Contributions are made at the start of each year (beginning-of-year).
/// - Growth is applied to (opening balance + contribution) for the full year.
/// - Nominal dollars are used internally; real values are derived by deflating
///   by the cumulative inflation factor for that year.
///
/// - Parameters:
///   - input: Projection parameters.
///   - startYear: Calendar year to treat as year 0 (defaults to current year;
///     pass an explicit value in tests to keep assertions deterministic).
/// - Returns: Ordered array of yearly snapshots (length = retirementAge − currentAge).
/// - Throws: `ProjectionError.retirementAgeNotGreaterThanCurrentAge` if ages are invalid.
func projectPortfolio(
    _ input: ProjectionInput,
    startYear: Int = Calendar.current.component(.year, from: Date())
) throws -> [ProjectionSnapshot] {
    guard input.retirementAge > input.currentAge else {
        throw ProjectionError.retirementAgeNotGreaterThanCurrentAge(
            retirementAge: input.retirementAge,
            currentAge: input.currentAge
        )
    }

    let years = input.retirementAge - input.currentAge
    var snapshots: [ProjectionSnapshot] = []
    var balance = input.currentPortfolio

    for i in 0 ..< years {
        let contribution = input.inflationAdjustContributions
            ? inflationAdjustedContribution(
                input.annualContribution,
                inflationRate: input.inflationRate,
                yearsElapsed: Double(i)
              )
            : input.annualContribution

        let openingBalance = balance + contribution
        let closingBalance = openingBalance * (1 + input.annualReturnRate)
        let gains = closingBalance - openingBalance
        let cumulativeInflation = inflationFactor(inflationRate: input.inflationRate, years: Double(i + 1))

        snapshots.append(ProjectionSnapshot(
            year: startYear + i + 1,
            age: input.currentAge + i + 1,
            portfolioNominal: closingBalance,
            portfolioReal: closingBalance / cumulativeInflation,
            annualContribution: contribution,
            investmentGains: gains
        ))
        balance = closingBalance
    }

    return snapshots
}

/// Returns only the final snapshot (portfolio value at retirement).
func projectFinalBalance(
    _ input: ProjectionInput,
    startYear: Int = Calendar.current.component(.year, from: Date())
) throws -> ProjectionSnapshot {
    let snapshots = try projectPortfolio(input, startYear: startYear)
    guard let last = snapshots.last else {
        throw ProjectionError.noSnapshots
    }
    return last
}

/// Total contributions made across all snapshots.
func totalContributions(_ snapshots: [ProjectionSnapshot]) -> Double {
    snapshots.reduce(0) { $0 + $1.annualContribution }
}

/// Total investment gains across all snapshots.
func totalGains(_ snapshots: [ProjectionSnapshot]) -> Double {
    snapshots.reduce(0) { $0 + $1.investmentGains }
}
