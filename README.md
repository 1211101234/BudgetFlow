# BudgetFlow

A local-first macOS budgeting and allocation app built with SwiftUI and Swift 6.

The interface includes adaptive light/dark colors, VoiceOver summaries, keyboard-friendly actions, reduced-transparency support, and a custom 8-bit macOS app icon.

## Requirements

- macOS 14 or later
- Swift 6.2 or later
- Xcode is recommended for running and packaging the app

## Build and test

```bash
swift build
swift test
swift run BudgetFlow
```

## Build the macOS application bundle

```bash
./Scripts/build_app.sh
open "./Release/BudgetFlow.app"
```

This creates a signed local development application bundle with the project icon. It is suitable for installation on this Mac but is not Developer ID signed or notarized for public distribution.

The first launch asks for gross income, net income, and the current emergency-fund balance. Saved data is stored locally in the user's Application Support directory.

See [Documentation/PRODUCT.md](Documentation/PRODUCT.md) for the calculation rules, score definition, and roadmap.
See [Documentation/DESIGN.md](Documentation/DESIGN.md) for the visual system and accessibility behavior.
