# Retirement Planner — Agent Rules

## Repository layout

```
retirement-planner/               ← pnpm workspace root
├── apps/
│   ├── web/                      ← Vite + React + TypeScript UI
│   │   └── src/
│   │       ├── components/       ← React components (RetirementPlanner.tsx, etc.)
│   │       ├── App.tsx
│   │       └── main.tsx
│   └── ios/                      ← SwiftUI iOS app (Xcode project)
│       ├── RetirementPlanner/
│       └── RetirementPlanner.xcodeproj/
├── packages/
│   └── core/                     ← Pure TS financial logic (@retirement/core)
│       └── src/
│           ├── types.ts          ← Domain types (ProjectionInput, etc.)
│           ├── inflation.ts      ← Inflation utilities
│           ├── fourPercent.ts    ← 4% rule / FIRE number
│           ├── projection.ts     ← Year-by-year projection engine
│           └── index.ts          ← Barrel export
├── tsconfig.base.json            ← Shared TypeScript settings
├── pnpm-workspace.yaml
└── package.json                  ← Workspace root
```

## Package manager

**Always use `pnpm`** — never `npm` or `yarn`.

```bash
pnpm install                      # install all workspaces
pnpm dev                          # start apps/web dev server
pnpm build                        # build core then web
pnpm typecheck                    # typecheck all packages
pnpm --filter @retirement/core <cmd>   # target a specific workspace
pnpm --filter @retirement/web  <cmd>
```

## Core principles

- **packages/core contains zero React** — only pure TypeScript functions and types.
- **apps/ios** is Swift/SwiftUI only; financial behavior should mirror `packages/core` (ported Swift, not embedded JS).
- **Financial logic belongs in packages/core**, never inside a component.
- Components import from `@retirement/core`; never import relative paths that cross package boundaries.
- All monetary values inside core are plain `number` (dollars). Formatting happens in the UI layer only.
- Rates are stored as **decimals** (0.07 = 7%), never percentages.

## Adding new financial calculations

1. Add the function to the appropriate module in `packages/core/src/`.
2. Export it from `packages/core/src/index.ts`.
3. Add the type to `types.ts` if new types are needed.
4. Import in the component via `import { myFn } from "@retirement/core"`.
5. Never mutate input objects — all functions are pure and return new values.

## Adding new UI components

- Place components in `apps/web/src/components/`.
- Keep components focused on display and user input; delegate calculations to `@retirement/core`.
- Use inline styles or a CSS-in-JS approach consistent with existing components (no CSS framework assumed).

## TypeScript rules

- `strict: true` and `exactOptionalPropertyTypes: true` are enabled — do not loosen them.
- `noUncheckedIndexedAccess: true` is on — always guard array accesses (`arr[i] ?? fallback`).
- Prefer `type` imports (`import type { Foo }`) for type-only symbols.
- Do not use `any`. Use `unknown` and narrow with type guards.

## Financial domain notes

- **4% rule** (Bengen 1994 / Trinity study): withdraw 4% of portfolio annually → ~30-year sustainability.
- **25× rule**: required portfolio = annual expenses ÷ 0.04 = expenses × 25.
- **Fisher equation**: real return = (1 + nominal) / (1 + inflation) − 1.
- **Projection model**: contributions at start of year, growth applied to (balance + contribution).
- All projections use nominal dollars internally; real (inflation-adjusted) values are derived.

## Do not

- Do not commit `node_modules/`, `dist/`, or `.env` files.
- Do not add UI frameworks (Tailwind, MUI, etc.) without discussing first.
- Do not bypass TypeScript errors with `// @ts-ignore` or `as any`.
- Do not add side effects to `packages/core` — it must remain a pure utility package.
