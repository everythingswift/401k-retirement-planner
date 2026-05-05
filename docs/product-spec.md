# RetireWise — Product Spec

**Status:** Live (iOS App Store). Web companion live on GitHub Pages.
**Last updated:** 2026-05-04
**Owner:** sridharcse@gmail.com

As-built spec describing current shipped behavior. Source of truth for the financial model and the iOS UX.

## 1. Overview

RetireWise is an offline retirement-drawdown planner built around the **5-year bucket strategy**. The user enters a small set of assumptions (age, portfolio, spending, income, return/inflation) and sees a year-by-year projection of a portfolio split into Cash, Bonds, and Equity from retirement through age 99. Plans can be saved on-device and reloaded later.

Two surfaces, one financial model:

- **iOS** (`apps/ios`) — SwiftUI, iPhone, dark mode. Shipped App Store binary.
- **Web** (`apps/web`) — Vite + React + TypeScript. Companion at GitHub Pages.

Financial logic lives in `packages/core` (TypeScript) and is mirrored function-for-function in `apps/ios/RetirementPlanner/Core` (Swift). A shared JSON fixture (`tests/fixtures/core-fixtures.json`) keeps the two implementations numerically identical.

## 2. Target user

A US-based pre-retiree or new retiree (roughly age 50–70) who wants a quick, no-account way to sanity-check whether their nest egg covers planned spending to 99, see how SS timing and rental income shift the picture, and apply the bucket strategy to their own numbers. Not the target: tax planning, RMDs, Monte Carlo, or couple/spousal SS coordination.

## 3. UX flow (iOS)

1. **First launch — `DisclaimerView`** (full-screen, dismissible only via "I Understand"). Persists `disclaimerSeen`. Shows the bucket-strategy explainer (Year 0 → 1–5 → End of Yr 5 → Repeat) and the five disclaimers (not advice, returns not guaranteed, unexpected expenses excluded, taxes excluded, projections are estimates).
2. **Configuration (`ConfigurationView`)** — inset-grouped list, sticky "Show Results" CTA, four sections plus a live summary banner. Toolbar exposes the Saved Plans list.
3. **Edit value (`EditValueView`)** — pushed editor with slider/stepper bounded by per-field min/max/step; format-aware (currency / percent / age / allocation).
4. **Results (`ResultsView`)** — horizontal stat strip + segmented picker for **Growth**, **Income**, **Table**. Toolbar exposes Save.

## 4. Inputs

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

## 5. Outputs

- **Live summary banner (Configuration):** Cash Reserve (initial 5-yr bucket), Investment Pot (`totalPortfolio − cashReserve`), Yr 1 Growth, To Age 100 (final-snapshot total).
- **Growth tab:** multi-series line chart (Total, Equity, Bonds, Cash) over ages `retireAge…99`, plus three milestone cards at `retireAge+5`, `+20`, and final, each showing total and delta vs. starting portfolio.
- **Income tab:** multi-series line chart (Spending, Investment Return, Rental, SS) with vertical rule at SS start age, plus a "Year 1 Breakdown" card.
- **Table tab:** year-by-year table to age 99 (Age, Bonds, Equity, Cash, Total, Spend). Refill years (every 5th, end of year) highlighted; Total cell green/red vs. starting portfolio.

## 6. Financial model (the contract)

Implemented in `packages/core/src/` (TS) and mirrored in `apps/ios/RetirementPlanner/Core/` (Swift). Numerical equivalence enforced by shared fixtures.

**Initial cash bucket**

```
cash₀ = Σ (i = 0..4) max(0, annualSpend·(1+inf)ⁱ − rental·(1+inf)ⁱ − ss_i)
```

where `ss_i = socialSecurityAmt·(1+inf)ⁱ` if `retireAge + i ≥ socialSecurityAge`, else 0. Remainder splits: `bonds = invest · bondAllocation`, `equity = invest · (1 − bondAllocation)`.

**Annual loop** (year `yr` from 0 to `projectionYears − 1`)

1. Inflate spending, rental, and SS by `(1 + inflation)ʸʳ` (SS only if eligible).
2. Apply nominal returns: `bonds += bonds · bondReturn`; `equity += equity · equityReturn`.
3. Withdraw `netWithdrawal = max(0, spend − rental − ss)` from cash, floored at 0.
4. **Refill** — at end of year `yr` where `(yr + 1) mod 5 == 0` and not the final year: sum the next 5 years of `netWithdrawal` (inflation-adjusted), withdraw that amount (capped at `bonds + equity`) from bonds and equity *proportional to current weights*, and add it to cash.

**Conventions.** All internal values are nominal dollars. Rates are decimals in core; the iOS UI stores display percentages and divides by 100 at the boundary. `projectionYears = 100 − retireAge`. Inputs are not mutated; all core functions are pure.

**Known simplifications.** Deterministic returns (no volatility / sequence risk); no taxes, fees, RMDs, or Roth/traditional distinction; single inflation rate applied uniformly; net withdrawal floored at 0; refill draws proportionally rather than rebalancing to target. Surfaced via the disclaimer screen and App Store description.

## 7. Saved plans (iOS)

A user can save the current configuration as a named plan, view saved plans in a list, load one back, rename, or delete. Storage is fully on-device.

- **Save** (Results toolbar) — saves the current configuration with an auto-generated name (`MMM d, h:mm a`). No name prompt. The first-ever save shows a one-time alert: *"Plans are saved on this device only. They're not synced or backed up. If you uninstall RetireWise, your saved plans are deleted."* Gated by `@AppStorage("savePrivacyNoticeSeen")`. Subsequent saves are silent (haptic + brief "Saved" overlay).
- **Saved Plans list** (Configuration toolbar) — sheet, rows sorted newest-first, each row showing name, relative created date, and a one-line summary. Tap row → load into `RetirementStore` and dismiss. Swipe leading → Rename (alert with prefilled field). Swipe trailing → Delete (destructive, no confirmation). Empty state directs to the Save button.
- **Data model.** `SavedPlan` (`Codable`, `Identifiable`, `Equatable`) holds the 10 inputs plus `id: UUID`, `name: String`, `createdAt: Date`.
- **Storage.** `Documents/saved-plans.json`, written atomically as a JSON array. Load on launch; missing or corrupt file → empty list (logged, no crash). Every mutation rewrites the whole file; list is small (tens).
- **Snapshots are not saved.** Only inputs. The projection is deterministic, so reload reproduces identical numbers and the saved format is independent of future model changes.

## 8. Privacy and data

No account, no sign-in, no telemetry, no analytics, no crash reporting beyond Apple defaults. No network calls in the financial path — fully usable offline. Persisted state is limited to two keys in `UserDefaults` (`disclaimerSeen`, `savePrivacyNoticeSeen`) plus `Documents/saved-plans.json` for opt-in saved plans. Apple removes the app's container on uninstall, so saved plans are deleted with the app. Privacy policy: `docs/privacy-policy.html` (linked from App Store listing). `ITSAppUsesNonExemptEncryption = NO` (OS TLS only).

## 9. Accessibility, platform, distribution

Native SwiftUI; respects Dynamic Type for body text; Apple `Charts` framework; forced dark mode. English only; USD with K/M abbreviations (`$65K`, `$1.20M`). iPhone only (no iPad layout, no Catalyst). Free on the App Store (no IAP, content rating 4+) and via GitHub Pages for the web build; public GitHub repo, issues used for support.

## 10. Acceptance

A build is shippable when:

1. iOS unit tests in `RetirementPlannerTests` pass on iPhone 16 simulator (currently 65 tests, including `PlanStoreTests` and `SavedPlanCodableTests`).
2. Swift bucket projection matches the TS one on `tests/fixtures/core-fixtures.json` (parity gate).
3. First-launch disclaimer shows; "Show Results" reaches all three result tabs without crash.
4. Default inputs produce a non-empty, non-NaN projection ending at age 99.
5. Saved-plan round-trip: capturing inputs → applying them to a fresh store → projecting, equals projecting the original store.
6. First-save privacy alert appears exactly once per install.
7. No new network calls observed during save / load / rename / delete.
8. Export-compliance flag is set (`ITSAppUsesNonExemptEncryption = NO`).

## 11. Out of scope

Not commitments — live list of things deliberately deferred:

- Overwrite/update of an existing plan (every Save creates a new entry; rename + delete handle hygiene).
- iCloud sync or any cross-device persistence.
- Export / import (no Files app integration, no share sheet, no JSON export).
- Web parity for saved plans (`apps/web` is configuration-only).
- Real-dollar toggle on the Growth chart.
- Couples mode (two SS streams, two start ages).
- Sensitivity view (±1% return / inflation).
- Light mode; iPad layout.
- Taxes (cap gains, income, RMDs, state); healthcare or one-time large expenses; Monte Carlo / sequence-of-returns risk.
