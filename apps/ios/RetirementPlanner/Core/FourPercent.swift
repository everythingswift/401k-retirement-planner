// 4% rule / FIRE number utilities — mirrors packages/core/src/fourPercent.ts

/// Namespace for the 4% safe-withdrawal-rate rule constant (Bengen 1994 / Trinity study).
enum FourPercentRule {
    static let defaultWithdrawalRate: Double = 0.04
}

/// Annual and monthly safe withdrawal amounts for a given portfolio.
func safeWithdrawal(
    portfolioValue: Double,
    withdrawalRate: Double = FourPercentRule.defaultWithdrawalRate
) -> WithdrawalAnalysis {
    let annual = portfolioValue * withdrawalRate
    return WithdrawalAnalysis(
        portfolioValue: portfolioValue,
        annualWithdrawal: annual,
        monthlyWithdrawal: annual / 12,
        withdrawalRate: withdrawalRate
    )
}

/// Portfolio size (FIRE number) needed to sustainably fund a given annual expense level.
/// Rule of thumb: multiply annual expenses by 25 at the 4% rate.
func fireNumber(
    annualExpenses: Double,
    withdrawalRate: Double = FourPercentRule.defaultWithdrawalRate
) -> FireNumber {
    FireNumber(
        annualExpenses: annualExpenses,
        requiredPortfolio: annualExpenses / withdrawalRate,
        withdrawalRate: withdrawalRate
    )
}

/// Fraction of the FIRE number already achieved, clamped to [0, 1].
func fireProgress(currentPortfolio: Double, targetPortfolio: Double) -> Double {
    guard targetPortfolio > 0 else { return 0 }
    return min(currentPortfolio / targetPortfolio, 1)
}

/// How many years of expenses the portfolio can cover at zero growth (conservative floor).
func yearsOfExpenses(portfolioValue: Double, annualExpenses: Double) -> Double {
    guard annualExpenses > 0 else { return .infinity }
    return portfolioValue / annualExpenses
}
