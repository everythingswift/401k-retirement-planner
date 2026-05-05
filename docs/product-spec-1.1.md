# RetireWise — Product Spec, 1.1 (Save & Load Plans)

**Status:** Planned. Targets iOS only.
**Baseline:** `product-spec.md` (1.0, as-built). This document describes the **delta** from 1.0; everything not mentioned here is unchanged.
**Last updated:** 2026-04-30
**Owner:** sridharcse@gmail.com

## 1. What's new

A user can save the current configuration as a named "plan," view their saved plans in a list, load any of them back into the app, rename them, and delete them. Storage is **fully on-device** — a single JSON file in the app's `Documents/` directory. No iCloud, no network, no account. Plans are deleted when the app is uninstalled, and the user is told this explicitly the first time they save.

## 2. Why

In 1.0, every relaunch starts from the default inputs. Users iterating on scenarios ("what if I retire at 67 instead of 65?") have to re-enter values from memory each session. Saved plans turn the app into a tool for *comparing* scenarios over time without taking on the privacy and engineering cost of cloud sync.

## 3. UX additions

- **Save button** on `ResultsView` toolbar (trailing). One tap saves the current configuration with an auto-generated name; no name prompt.
- **First-save privacy alert** — the first time a user ever taps Save, a confirmation alert appears: *"Plans are saved on this device only. They're not synced or backed up. If you uninstall RetireWise, your saved plans are deleted."* with **Save Plan** / **Cancel**. Confirming sets `@AppStorage("savePrivacyNoticeSeen")` and performs the save. Subsequent taps skip the alert and save immediately, with haptic + brief "Saved" overlay feedback.
- **Saved Plans list** reachable via a leading toolbar button (folder icon) on `ConfigurationView`, presented as a sheet:
  - Rows sorted newest-first; each row shows name, relative created date ("2 hours ago"), and a one-line summary ("Retire 65 · $500K · 40% bonds").
  - **Tap row** → loads the plan into `RetirementStore` and dismisses the sheet.
  - **Swipe leading → Rename** → alert with prefilled text field.
  - **Swipe trailing → Delete** → destructive, no confirmation.
  - Empty state: "No saved plans yet. Tap Save on the Results screen to keep a configuration."

## 4. Naming

Default plan name is the save timestamp formatted as `MMM d, h:mm a` (e.g. `Apr 30, 2:14 PM`). Two saves within the same minute share a default name; users can rename to disambiguate. Internal identity is `UUID`, so duplicate names are not a correctness issue.

## 5. Data model

A new `SavedPlan` struct (`Codable`, `Identifiable`, `Equatable`) capturing the 10 inputs from `RetirementStore` plus `id: UUID`, `name: String`, `createdAt: Date`.

**Storage:** `Documents/saved-plans.json`, written atomically as a JSON array. Load on app launch; on missing or corrupt file, start with an empty list (logged, no crash). All writes rewrite the whole file — list is small (tens) and this avoids any partial-write complexity.

**Snapshots are not saved.** Only inputs. The projection model is deterministic, so loading a plan and re-running the projection reproduces identical numbers. This keeps the saved format independent of any future projection-model changes.

## 6. Privacy delta vs. 1.0

Updates §9 of `product-spec.md`:

- 1.0 said: *"financial inputs are not persisted across launches in 1.0."* That is no longer true once the user opts in by tapping Save.
- New surface: a single JSON file at `Documents/saved-plans.json`. Apple removes the app's container on uninstall, so saved plans are deleted with the app — no extra cleanup logic needed.
- **No new network calls. No third-party SDKs. No analytics on save activity.**
- The first-save alert is the user-facing acknowledgement of this trade-off.

## 7. Out of scope for 1.1

- Overwrite/update of an existing plan (every Save creates a new entry; rename + delete handle hygiene).
- iCloud sync or any cross-device persistence.
- Export / import (no Files app integration, no share sheet, no JSON export).
- Web parity — `apps/web` does not gain saved plans in 1.1.
- Sorting, search, folders, or tagging on the list.
- Confirmation dialog when loading a plan over a modified configuration.

## 8. Acceptance — what "1.1" means

In addition to all 1.0 acceptance criteria:

1. New XCTest classes (`PlanStoreTests`, `SavedPlanCodableTests`) pass alongside the existing 34 tests on iPhone 16 simulator.
2. Round-trip property: `capture(from:store)` → `apply(_:to:newStore)` → projecting `newStore` produces a `[BucketSnapshot]` array equal to projecting the original store.
3. First-save alert appears exactly once per install and is gated by `@AppStorage("savePrivacyNoticeSeen")`.
4. Uninstalling the app removes `Documents/saved-plans.json` (Apple default behavior — verified in QA, not tested in code).
5. No new network calls observed in Instruments / Console during save, load, rename, or delete flows.
