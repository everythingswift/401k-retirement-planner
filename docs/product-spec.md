# RetireWise — Product Spec, 1.0

**Status:** Live (iOS App Store, 1.0). Web companion live on GitHub Pages.
**Last updated:** 2026-04-30
**Owner:** sridharcse@gmail.com

This is an as-built spec describing what shipped in 1.0 — the source of truth for current behavior and the baseline for future versions.

## 1. Overview

RetireWise is an offline retirement-drawdown planner built around the **5-year bucket strategy**. The user enters a small set of assumptions (age, portfolio, spending, income, return/inflation) and sees a year-by-year projection of a portfolio split into Cash, Bonds, and Equity from retirement through age 99.

Two surfaces, one financial model:

- **iOS** (`apps/ios`) — SwiftUI, iPhone, dark mode. The shipped App Store binary.
- **Web** (`apps/web`) — Vite + React + TypeScript. Companion at GitHub Pages.

Financial logic lives in `packages/core` (TypeScript) and is mirrored function-for-function in `apps/ios/RetirementPlanner/Core` (Swift). A shared JSON fixture (`tests/fixtures/core-fixtures.json`) keeps the two implementations numerically identical.

## 2. Target user

A US-based pre-retiree or new retiree (roughly age 50–70) who wants a quick, no-account way to sanity-check whether their nest egg covers planned spending to 99, see how SS timing and rental income shift the picture, and apply the bucket strategy to their own numbers.

Not the target: someone needing tax planning, RMDs, Monte Carlo, or couple/spousal SS coordination.

## 3. Goals and non-goals

**Goals**

- Make the bucket strategy concrete and personal in under two minutes of input.
- Show the consequences across three views: portfolio growth, income vs. spending, year-by-year.
- Stay 100% on-device. No account, no network, no analytics, no IAP.

**Non-goals (1.0):** taxes (cap gains, income, RMDs, state); healthcare or one-time large expenses; couples / spousal SS; Monte Carlo or sequence-of-returns risk; multi-scenario save/compare; cloud sync, accounts, sharing.

## 4. Surfaces

### 4.1 iOS (shipped 1.0)

Bundle "RetireWise" (renamed from "Retirement Bucket Planner" pre-launch). iPhone, SwiftUI, dark mode forced. Single `NavigationStack` rooted at `ConfigurationView` with a first-launch `fullScreenCover` disclaimer. State held in `@Observable RetirementStore` (in-memory; not persisted). Only persisted bit is `@AppStorage("disclaimerSeen")`. `ITSAppUsesNonExemptEncryption = NO` (OS TLS only).

### 4.2 Web

Same financial model as iOS; single component `apps/web/src/components/RetirementPlanner.tsx`; hosted alongside `docs/` on GitHub Pages.

## 5. UX flow (iOS)

1. **First launch — `DisclaimerView`** (full-screen, dismissible only via "I Understand"). Persists `disclaimerSeen`. Shows the bucket-strategy explainer (Year 0 → 1–5 → End of Yr 5 → Repeat) and five disclaimers (not advice, returns not guaranteed, unexpected expenses excluded, taxes excluded, projections are estimates).
2. **Configuration (`ConfigurationView`)** — inset-grouped list, sticky "Show Results" CTA, four sections plus a live summary banner.
3. **Edit value (`EditValueView`)** — pushed editor with slider/stepper bounded by per-field min/max/step; format-aware (currency / percent / age / allocation).
4. **Results (`ResultsView`)** — horizontal stat strip + segmented picker for **Growth**, **Income**, **Table**.

## 6. Inputs

All inputs have defaults and hard min/max/step enforced by `EditValueView`.

| Field | Default | Min | Max | Step | Format |
|---|---|---|---|---|---|
| Retirement Age | 65 | 45 | 80 | 1 | age |
| Portfolio at Retirement | $500,000 | $50,000 | $10,000,000 | $10,000 | currency |
| Annual Spending (today's $) | $65,000 | $20,000 | $400,000 | $1,000 | currency |
| Rental Income (today's $/yr) | $0 | $0 | $200,000 | $1,000 | currency |
| Social Security Start Age | 67 | 62 | 70 | 1 | age |
| SS Annual Benefit (today's $) | $22,000 | $0 | $60,000 | $500 | currency |
| Bond Allocation | 40% | 0% | 100% | 5% | allocation |
| Bond Return (nominal) | 4.5% | 1.0% | 8.0% | 0.25% | percent |
| Equity Return (nominal) | 7.0% | 2.0% | 15.0% | 0.5% | percent |
| Inflation Rate | 3.0% | 1.0% | 7.0% | 0.25% | percent |

Equity allocation is implicit: `1 − bondAllocation`.

## 7. Outputs

- **Live summary banner (Configuration):** four chips recomputing on every input — Cash Reserve (initial 5-yr bucket), Investment Pot (`totalPortfolio − cashReserve`), Yr 1 Growth (bond + equity gain in year 1), To Age 100 (final-snapshot total).
- **Results — Growth tab:** multi-series line chart (Total, Equity, Bonds, Cash) over ages `retireAge…99`, plus three milestone cards at `retireAge+5`, `+20`, and final, each showing total and delta vs. starting portfolio (green up / red down).
- **Results — Income tab:** multi-series line chart (Spending red, Investment Return green, Rental gold dashed, SS purple dashed) with a vertical rule at SS start age, plus a "Year 1 Breakdown" card (bond gains, equity gains, rental, SS or "Not yet", vs. annual spend).
- **Results — Table tab:** year-by-year table to age 99 with columns Age, Bonds, Equity, Cash, Total, Spend. Refill years (every 5th, end of year) highlighted green; Total cell green/red vs. starting portfolio.

## 8. Financial model (the contract)

Implemented in `packages/core/src/` (TS) and mirrored in `apps/ios/RetirementPlanner/Core/` (Swift). Numerical equivalence enforced by shared fixtures.

### 8.1 Initial cash bucket

```
cash₀ = Σ (i = 0..4) max(0, annualSpend·(1+inf)ⁱ − rental·(1+inf)ⁱ − ss_i)
```

where `ss_i = socialSecurityAmt·(1+inf)ⁱ` if `retireAge + i ≥ socialSecurityAge`, else 0. Remainder splits: `bonds = invest · bondAllocation`, `equity = invest · (1 − bondAllocation)`.

### 8.2 Annual loop (year `yr` from 0 to `projectionYears − 1`)

1. Inflate spending, rental, and SS by `(1 + inflation)ʸʳ` (SS only if eligible).
2. Apply nominal returns: `bonds += bonds · bondReturn`; `equity += equity · equityReturn`.
3. Withdraw `netWithdrawal = max(0, spend − rental − ss)` from cash, floored at 0.
4. **Refill** — at end of year `yr` where `(yr + 1) mod 5 == 0` and not the final year: sum the next 5 years of `netWithdrawal` (inflation-adjusted), withdraw that amount (capped at `bonds + equity`) from bonds and equity *proportional to current weights*, and add it to cash.

### 8.3 Conventions

All internal values are **nominal dollars** (real-dollar core function exists; not exposed in 1.0 UI). Rates are decimals throughout core; the iOS UI stores them as display percentages and divides by 100 at the boundary. `projectionYears = 100 − retireAge`, so snapshots cover ages `retireAge … 99` inclusive. Inputs are not mutated; all core functions are pure.

### 8.4 Known simplifications (intentional in 1.0)

Deterministic returns (no volatility / sequence risk); no taxes, fees, RMDs, or Roth/traditional distinction; single inflation rate applies uniformly to spending, rental, and SS; net withdrawal floored at 0 (surplus income not reinvested); refill draws proportionally rather than rebalancing to target. Surfaced via the disclaimer screen and App Store description.

## 9. Privacy and data

No account, no sign-in, no telemetry, no analytics, no crash reporting beyond Apple defaults. No network calls in the financial path — fully usable offline. Only persisted state is `disclaimerSeen` (a `Bool` in `UserDefaults`); financial inputs are not persisted across launches in 1.0. Privacy policy: `docs/privacy-policy.html` (linked from App Store listing).

## 10. Accessibility, platform, distribution

Native SwiftUI; respects Dynamic Type for body text; uses Apple's `Charts` framework; forced dark mode (no light theme). English only; USD with K/M abbreviations (`$65K`, `$1.20M`). iPhone only (no iPad layout, no Catalyst). Distributed Free on the App Store (no IAP, content rating 4+) and via GitHub Pages for the web build; public GitHub repo, issues used for support.

## 11. Acceptance — what "1.0" means

A build is 1.0-acceptable when:

1. iOS unit tests in `RetirementPlannerTests` pass on iPhone 16 simulator (currently 34 tests).
2. Swift bucket projection matches the TS one on `tests/fixtures/core-fixtures.json` (parity gate).
3. First-launch disclaimer shows and "Show Results" reaches all three result tabs without crash.
4. Default inputs produce a non-empty, non-NaN projection ending at age 99.
5. Export-compliance flag is set (`ITSAppUsesNonExemptEncryption = NO`).

## 12. Deferred past 1.0

Not commitments — live list:

- Persist inputs across launches (gated on iCloud decision).
- Real-dollar toggle on the Growth chart.
- Couples mode (two SS streams, two start ages).
- Sensitivity view (±1% return / inflation).
- Light mode; iPad layout.
