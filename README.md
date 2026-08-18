# Freedom Year

An iOS app that answers one question: **when can you stop working?**

Three numbers — what life costs each month, what you have invested, what you add each month
— and it returns the year your investments start covering your life instead of your salary.
No bank login, no month of collecting receipts before the app says anything.

- **Home screen widget** with the year on it
- **What-if slider** — what another $100 a month is worth in years
- **Life events** — children moving out or a mortgage ending changes what life costs, and
  therefore the year. Modelling spending as flat for thirty years is the biggest lie in most
  FIRE calculators
- **156 currencies**, and an honest warning when a 7% return assumption does not fit the one
  you picked
- **Offline-first.** No amount you type leaves the phone — see [PRIVACY.md](PRIVACY.md)

## Build

Requires Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen), and two sibling
packages checked out next to this repo (`shared/superduperai-auth`,
`shared/superduperai-analytics`).

```sh
xcodegen generate
xcodebuild -project SuperFinans.xcodeproj -scheme SuperFinans \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Layout

```
SuperFinans/Models/FreedomPlan.swift    the three numbers and the arithmetic
SuperFinans/Views/Freedom/              setup, the answer, life events, currency picker
SuperFinansWidget/                      home screen widget (App Group shared)
SuperFinans/Services/                   accounts, transactions, rates, notifications
```

The maths has no dependency on the service layer — the widget links the model file alone.

## Licence

Source is published for inspection. All rights reserved.
