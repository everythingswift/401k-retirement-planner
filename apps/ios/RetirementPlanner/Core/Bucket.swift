import Foundation

// 5-year bucket decumulation strategy — mirrors bucket logic in RetirementPlanner.tsx

/// Computes the initial 5-year net cash reserve at retirement.
///
/// This is the sum of net portfolio withdrawals needed for years 0–4,
/// where net withdrawal = max(0, annualSpend − rental − SS), inflation-adjusted.
///
/// - Parameter input: Bucket strategy parameters.
/// - Returns: Cash amount to set aside at retirement.
func computeInitialCash(_ input: BucketInput) -> Double {
    let infR = input.inflationRate
    var total = 0.0
    for i in 0 ..< 5 {
        let inflFactor = pow(1 + infR, Double(i))
        let age = input.retireAge + i
        let ss = age >= input.socialSecurityAge ? input.socialSecurityAmt * inflFactor : 0.0
        let rental = input.rentalIncome * inflFactor
        total += max(0, input.annualSpend * inflFactor - rental - ss)
    }
    return total
}

/// Projects the bucket portfolio year-by-year from retirement to the end of
/// `input.projectionYears`.
///
/// Model:
/// - **Year 0:** Set aside 5 years of net expenses as cash; the rest goes to bonds + equity
///   per `bondAllocation`.
/// - **Each year:** Apply investment returns to bonds and equity, then withdraw net spending
///   from the cash bucket.
/// - **Every 5 years** (end of year 5, 10, 15, …): Refill cash for the next 5 years by
///   withdrawing from bonds and equity proportionally to their current weights.
///
/// All income and spending values use nominal (inflation-adjusted) dollars internally.
///
/// - Parameter input: Bucket strategy parameters.
/// - Returns: Ordered array of yearly snapshots (length = `input.projectionYears`).
func projectBuckets(_ input: BucketInput) -> [BucketSnapshot] {
    let infR = input.inflationRate
    let bondR = input.bondReturn
    let eqR   = input.equityReturn

    // Initial 5-year cash reserve; remainder invested in bonds + equity.
    var cash   = computeInitialCash(input)
    let inv    = max(0, input.totalPortfolio - cash)
    var bonds  = inv * input.bondAllocation
    var equity = inv * (1 - input.bondAllocation)

    var snapshots: [BucketSnapshot] = []

    for yr in 0 ..< input.projectionYears {
        let inflFactor    = pow(1 + infR, Double(yr))
        let age           = input.retireAge + yr
        let spend         = input.annualSpend * inflFactor
        let rental        = input.rentalIncome * inflFactor
        let ss            = age >= input.socialSecurityAge ? input.socialSecurityAmt * inflFactor : 0.0
        let netWithdrawal = max(0, spend - rental - ss)

        // Apply investment returns.
        let bondGain   = bonds * bondR
        let equityGain = equity * eqR
        bonds  += bondGain
        equity += equityGain

        // Withdraw net spending from cash.
        cash = max(0, cash - netWithdrawal)

        // Every 5 years, refill cash for the next 5 years from bonds + equity.
        if (yr + 1) % 5 == 0 && yr < input.projectionYears - 1 {
            var nextCashNeeded = 0.0
            for j in 1 ... 5 {
                let futureInflFactor = pow(1 + infR, Double(yr + j))
                let futureAge        = input.retireAge + yr + j
                let futureSS         = futureAge >= input.socialSecurityAge
                    ? input.socialSecurityAmt * futureInflFactor : 0.0
                let futureRental     = input.rentalIncome * futureInflFactor
                nextCashNeeded += max(0, input.annualSpend * futureInflFactor - futureRental - futureSS)
            }

            let totalInvest = bonds + equity
            if totalInvest > 0 && nextCashNeeded > 0 {
                let withdraw   = min(nextCashNeeded, totalInvest)
                let bondShare  = bonds / totalInvest
                bonds  = max(0, bonds  - withdraw * bondShare)
                equity = max(0, equity - withdraw * (1 - bondShare))
                cash  += withdraw
            }
        }

        snapshots.append(BucketSnapshot(
            yr:          yr,
            age:         age,
            bonds:       max(0, bonds),
            equity:      max(0, equity),
            cash:        max(0, cash),
            total:       max(0, bonds + equity + cash),
            totalReturn: bondGain + equityGain,
            spend:       spend,
            rental:      rental,
            ss:          ss,
            totalIncome: rental + ss,
            gap:         max(0, spend - rental - ss),
            bondGain:    bondGain,
            equityGain:  equityGain
        ))
    }

    return snapshots
}
