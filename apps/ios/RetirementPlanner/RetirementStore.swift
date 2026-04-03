import Foundation
import Observation

@Observable
final class RetirementStore {

    // MARK: - Section 1: Your Retirement
    var retireAge: Int = 65
    var totalPortfolio: Double = 500_000

    // MARK: - Section 2: Living Expenses
    var annualSpend: Double = 65_000

    // MARK: - Section 3: Additional Income
    var rentalIncome: Double = 0
    var socialSecurityAge: Int = 67
    var socialSecurityAmt: Double = 22_000

    // MARK: - Section 4: Investment Assumptions
    var bondAllocation: Double = 40.0   // display %  (40 = 40%)
    var bondReturn: Double = 4.5        // display %  (4.5 = 4.5%)
    var equityReturn: Double = 7.0      // display %
    var inflationRate: Double = 3.0     // display %

    // MARK: - Computed inputs

    var projectionYears: Int { max(1, 100 - retireAge) }

    private var bucketInput: BucketInput {
        BucketInput(
            retireAge: retireAge,
            totalPortfolio: totalPortfolio,
            annualSpend: annualSpend,
            rentalIncome: rentalIncome,
            socialSecurityAge: socialSecurityAge,
            socialSecurityAmt: socialSecurityAmt,
            bondAllocation: bondAllocation / 100,
            bondReturn: bondReturn / 100,
            equityReturn: equityReturn / 100,
            inflationRate: inflationRate / 100,
            projectionYears: projectionYears
        )
    }

    // MARK: - Results

    var snapshots: [BucketSnapshot] { projectBuckets(bucketInput) }
    var initialCash: Double { computeInitialCash(bucketInput) }
    var investable: Double { max(0, totalPortfolio - initialCash) }
    var bondAmt: Double { investable * bondAllocation / 100 }
    var equityAmt: Double { investable * (1 - bondAllocation / 100) }
    var yr1Return: Double { snapshots.first?.totalReturn ?? 0 }
    var snapshotAt5: BucketSnapshot? { snapshots.count > 5 ? snapshots[5] : snapshots.last }
    var snapshotAt20: BucketSnapshot? { snapshots.count > 20 ? snapshots[20] : snapshots.last }
    var finalPortfolio: Double { snapshots.last?.total ?? 0 }
}

// MARK: - Formatting helpers

func fmtCurrency(_ n: Double) -> String {
    if n >= 1_000_000 {
        return String(format: "$%.2fM", n / 1_000_000)
    } else if n >= 1_000 {
        return String(format: "$%.0fK", n / 1_000)
    } else {
        return String(format: "$%.0f", n)
    }
}

func fmtPercent(_ n: Double, decimals: Int = 1) -> String {
    String(format: "%.\(decimals)f%%", n)
}
