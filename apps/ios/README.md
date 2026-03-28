# Retirement Planner (iOS)

Native SwiftUI app for the 401(k) / retirement calculator. Domain logic will be ported from `@retirement/core` (TypeScript) into Swift with shared numeric fixtures.

## Requirements

- Xcode 15+ (iOS 17 SDK)
- Apple Developer account for device / TestFlight / App Store

## Open the project

```bash
open apps/ios/RetirementPlanner.xcodeproj
```

Select the **RetirementPlanner** scheme, pick a simulator or device, then Run.

## Layout

| Path | Purpose |
|------|---------|
| `RetirementPlanner/` | SwiftUI app sources and asset catalog |
| `RetirementPlanner.xcodeproj/` | Xcode project |

Update **Signing & Capabilities** in Xcode: set your **Team** and adjust **Bundle Identifier** (`com.retirementplanner.RetirementPlanner` by default) if needed.
