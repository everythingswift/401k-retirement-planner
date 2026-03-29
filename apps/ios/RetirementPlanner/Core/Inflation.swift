import Foundation

// Inflation utilities — mirrors packages/core/src/inflation.ts

/// Cumulative inflation factor for `years` at `inflationRate`.
/// e.g. inflationFactor(inflationRate: 0.03, years: 10) ≈ 1.3439
func inflationFactor(inflationRate: Double, years: Double) -> Double {
    pow(1 + inflationRate, years)
}

/// Converts a present-day (real) value to its future nominal equivalent.
func toNominal(_ realValue: Double, inflationRate: Double, years: Double) -> Double {
    realValue * inflationFactor(inflationRate: inflationRate, years: years)
}

/// Converts a future nominal value back to today's purchasing power.
func toReal(_ nominalValue: Double, inflationRate: Double, years: Double) -> InflationResult {
    let realValue = nominalValue / inflationFactor(inflationRate: inflationRate, years: years)
    return InflationResult(nominalValue: nominalValue, realValue: realValue, years: years, inflationRate: inflationRate)
}

/// Real (inflation-adjusted) return rate via the Fisher equation.
/// Fisher: (1 + nominal) / (1 + inflation) − 1
func realReturnRate(nominalRate: Double, inflationRate: Double) -> Double {
    (1 + nominalRate) / (1 + inflationRate) - 1
}

/// Adjusts a base contribution for `yearsElapsed` years of inflation,
/// keeping its real purchasing power constant.
func inflationAdjustedContribution(_ baseContribution: Double, inflationRate: Double, yearsElapsed: Double) -> Double {
    baseContribution * inflationFactor(inflationRate: inflationRate, years: yearsElapsed)
}
