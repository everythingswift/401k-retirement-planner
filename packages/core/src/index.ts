// Types
export type {
  FireNumber,
  InflationResult,
  ProjectionInput,
  ProjectionSnapshot,
  WithdrawalAnalysis,
} from "./types.js";

// Inflation utilities
export {
  inflationAdjustedContribution,
  inflationFactor,
  realReturnRate,
  toNominal,
  toReal,
} from "./inflation.js";

// 4% rule / FIRE calculations
export {
  DEFAULT_WITHDRAWAL_RATE,
  fireNumber,
  fireProgress,
  safeWithdrawal,
  yearsOfExpenses,
} from "./fourPercent.js";

// Projection engine
export {
  projectFinalBalance,
  projectPortfolio,
  totalContributions,
  totalGains,
} from "./projection.js";
