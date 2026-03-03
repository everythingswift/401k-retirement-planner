import type { InflationResult } from "./types.js";

/**
 * Returns the cumulative inflation factor for `years` at `inflationRate`.
 * e.g. factor(0.03, 10) ≈ 1.3439
 */
export function inflationFactor(inflationRate: number, years: number): number {
  return Math.pow(1 + inflationRate, years);
}

/**
 * Converts a present-day (real) value to its future nominal equivalent.
 *
 * @param realValue        Amount in today's dollars.
 * @param inflationRate    Annual inflation rate as a decimal (e.g. 0.03).
 * @param years            Number of years into the future.
 */
export function toNominal(
  realValue: number,
  inflationRate: number,
  years: number
): number {
  return realValue * inflationFactor(inflationRate, years);
}

/**
 * Converts a future nominal value back to today's purchasing power.
 *
 * @param nominalValue     Amount in future (nominal) dollars.
 * @param inflationRate    Annual inflation rate as a decimal (e.g. 0.03).
 * @param years            Number of years in the future.
 */
export function toReal(
  nominalValue: number,
  inflationRate: number,
  years: number
): InflationResult {
  const realValue = nominalValue / inflationFactor(inflationRate, years);
  return { nominalValue, realValue, years, inflationRate };
}

/**
 * Computes the real (inflation-adjusted) return rate from nominal components.
 * Uses the Fisher equation: (1 + nominal) / (1 + inflation) − 1
 *
 * @param nominalRate   Nominal annual return rate as a decimal.
 * @param inflationRate Annual inflation rate as a decimal.
 */
export function realReturnRate(
  nominalRate: number,
  inflationRate: number
): number {
  return (1 + nominalRate) / (1 + inflationRate) - 1;
}

/**
 * Adjusts an annual contribution amount upward for the given number of years
 * of inflation — keeping the real value constant.
 *
 * @param baseContribution   Contribution in today's dollars.
 * @param inflationRate      Annual inflation rate as a decimal.
 * @param yearsElapsed       How many full years have passed.
 */
export function inflationAdjustedContribution(
  baseContribution: number,
  inflationRate: number,
  yearsElapsed: number
): number {
  return baseContribution * inflationFactor(inflationRate, yearsElapsed);
}
