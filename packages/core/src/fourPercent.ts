import type { FireNumber, WithdrawalAnalysis } from "./types.js";

/** Default safe withdrawal rate (Bengen 1994 / Trinity study). */
export const DEFAULT_WITHDRAWAL_RATE = 0.04;

/**
 * Calculates how much you can safely withdraw each year (and month) from a
 * given portfolio using the safe withdrawal rate rule.
 *
 * @param portfolioValue   Total portfolio value in dollars.
 * @param withdrawalRate   Annual withdrawal rate as a decimal (default 0.04).
 */
export function safeWithdrawal(
  portfolioValue: number,
  withdrawalRate: number = DEFAULT_WITHDRAWAL_RATE
): WithdrawalAnalysis {
  const annualWithdrawal = portfolioValue * withdrawalRate;
  return {
    portfolioValue,
    annualWithdrawal,
    monthlyWithdrawal: annualWithdrawal / 12,
    withdrawalRate,
  };
}

/**
 * Calculates the portfolio size (FIRE number) needed to sustainably cover a
 * given annual expense level — the inverse of the withdrawal rate rule.
 *
 * Rule of thumb: multiply annual expenses by 25 (at the 4% rate).
 *
 * @param annualExpenses   Desired annual spending in dollars.
 * @param withdrawalRate   Annual withdrawal rate as a decimal (default 0.04).
 */
export function fireNumber(
  annualExpenses: number,
  withdrawalRate: number = DEFAULT_WITHDRAWAL_RATE
): FireNumber {
  return {
    annualExpenses,
    requiredPortfolio: annualExpenses / withdrawalRate,
    withdrawalRate,
  };
}

/**
 * Returns the percentage of the FIRE number already achieved.
 *
 * @param currentPortfolio   Current portfolio value.
 * @param targetPortfolio    Required portfolio (from fireNumber).
 */
export function fireProgress(
  currentPortfolio: number,
  targetPortfolio: number
): number {
  if (targetPortfolio <= 0) return 0;
  return Math.min(currentPortfolio / targetPortfolio, 1);
}

/**
 * Estimates how many years of expenses the current portfolio can sustain at a
 * given withdrawal rate, assuming zero growth (conservative floor).
 */
export function yearsOfExpenses(
  portfolioValue: number,
  annualExpenses: number
): number {
  if (annualExpenses <= 0) return Infinity;
  return portfolioValue / annualExpenses;
}
