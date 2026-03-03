// ── Core domain types ────────────────────────────────────────────────────────

/** A single year's snapshot in the projection timeline. */
export interface ProjectionSnapshot {
  /** Calendar year (e.g. 2035). */
  year: number;
  /** Age of the primary person at the end of this year. */
  age: number;
  /** Portfolio balance at year-end in nominal dollars. */
  portfolioNominal: number;
  /** Portfolio balance at year-end in today's purchasing power. */
  portfolioReal: number;
  /** Total contributions made during this year. */
  annualContribution: number;
  /** Investment gains earned during this year (nominal). */
  investmentGains: number;
}

/** Input parameters for the portfolio projection engine. */
export interface ProjectionInput {
  /** Current portfolio value in today's dollars. */
  currentPortfolio: number;
  /** Annual contribution amount in today's dollars. */
  annualContribution: number;
  /** Expected nominal annual return rate as a decimal (e.g. 0.07 for 7%). */
  annualReturnRate: number;
  /** Expected annual inflation rate as a decimal (e.g. 0.03 for 3%). */
  inflationRate: number;
  /** Current age of the primary person. */
  currentAge: number;
  /** Target retirement age. */
  retirementAge: number;
  /**
   * Whether contributions grow with inflation each year.
   * Defaults to true (contributions keep real purchasing power).
   */
  inflationAdjustContributions?: boolean;
}

/** Result of the 4% (safe withdrawal rate) analysis. */
export interface WithdrawalAnalysis {
  /** The portfolio value that was analysed. */
  portfolioValue: number;
  /** Annual safe withdrawal amount (portfolioValue × withdrawalRate). */
  annualWithdrawal: number;
  /** Monthly safe withdrawal amount. */
  monthlyWithdrawal: number;
  /** Withdrawal rate used (default 0.04). */
  withdrawalRate: number;
}

/** How much portfolio is needed to fund a given spending level. */
export interface FireNumber {
  /** Desired annual expenses in today's dollars. */
  annualExpenses: number;
  /** Required portfolio size (annualExpenses / withdrawalRate). */
  requiredPortfolio: number;
  /** Withdrawal rate used (default 0.04). */
  withdrawalRate: number;
}

/** Inflation-adjusted value calculation result. */
export interface InflationResult {
  /** Original nominal value. */
  nominalValue: number;
  /** Value expressed in today's purchasing power. */
  realValue: number;
  /** Number of years used in the adjustment. */
  years: number;
  /** Inflation rate used as a decimal. */
  inflationRate: number;
}
