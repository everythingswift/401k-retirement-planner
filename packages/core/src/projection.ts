import { inflationAdjustedContribution, inflationFactor } from "./inflation.js";
import type { ProjectionInput, ProjectionSnapshot } from "./types.js";

/**
 * Projects portfolio growth year-by-year from today until retirement.
 *
 * Model assumptions:
 * - Contributions are made at the start of each year (beginning-of-year).
 * - Growth is applied to (opening balance + contribution) for the full year.
 * - Nominal dollars are used internally; real values are derived by deflating
 *   by the cumulative inflation factor for that year.
 *
 * @param input   Projection parameters.
 * @returns       Ordered array of yearly snapshots (length = retirementAge − currentAge).
 */
export function projectPortfolio(
  input: ProjectionInput
): ProjectionSnapshot[] {
  const {
    currentPortfolio,
    annualContribution,
    annualReturnRate,
    inflationRate,
    currentAge,
    retirementAge,
    inflationAdjustContributions = true,
  } = input;

  if (retirementAge <= currentAge) {
    throw new RangeError(
      `retirementAge (${retirementAge}) must be greater than currentAge (${currentAge})`
    );
  }

  const years = retirementAge - currentAge;
  const snapshots: ProjectionSnapshot[] = [];
  let balance = currentPortfolio;
  const startYear = new Date().getFullYear();

  for (let i = 0; i < years; i++) {
    const contribution = inflationAdjustContributions
      ? inflationAdjustedContribution(annualContribution, inflationRate, i)
      : annualContribution;

    const openingBalance = balance + contribution;
    const closingBalance = openingBalance * (1 + annualReturnRate);
    const gains = closingBalance - openingBalance;
    const cumulativeInflation = inflationFactor(inflationRate, i + 1);

    snapshots.push({
      year: startYear + i + 1,
      age: currentAge + i + 1,
      portfolioNominal: closingBalance,
      portfolioReal: closingBalance / cumulativeInflation,
      annualContribution: contribution,
      investmentGains: gains,
    });

    balance = closingBalance;
  }

  return snapshots;
}

/**
 * Returns only the final snapshot (portfolio value at retirement).
 * Useful when you only need the end-state rather than the full timeline.
 */
export function projectFinalBalance(
  input: ProjectionInput
): ProjectionSnapshot {
  const snapshots = projectPortfolio(input);
  const last = snapshots[snapshots.length - 1];
  if (last === undefined) {
    throw new RangeError("Projection produced no snapshots — check your ages.");
  }
  return last;
}

/**
 * Calculates the total contributions made over the accumulation period.
 */
export function totalContributions(snapshots: ProjectionSnapshot[]): number {
  return snapshots.reduce((sum, s) => sum + s.annualContribution, 0);
}

/**
 * Calculates the total investment gains over the accumulation period.
 */
export function totalGains(snapshots: ProjectionSnapshot[]): number {
  return snapshots.reduce((sum, s) => sum + s.investmentGains, 0);
}
