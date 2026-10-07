# BudgetFlow

A local-first macOS budgeting and allocation app built with SwiftUI and Swift 6.

The interface includes adaptive light/dark colors, VoiceOver summaries, keyboard-friendly actions, reduced-transparency support, a custom 8-bit macOS app icon, and small and medium desktop widgets.

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

This creates a signed local development application bundle with the project icon and an embedded WidgetKit extension. It is suitable for installation on this Mac but is not Developer ID signed or notarized for public distribution.

To install the local build and register its widget:

```bash
ditto "./Release/BudgetFlow.app" "/Applications/BudgetFlow.app"
pluginkit -a "/Applications/BudgetFlow.app/Contents/PlugIns/BudgetFlowWidget.appex"
open "/Applications/BudgetFlow.app"
```

After opening BudgetFlow once, right-click the desktop, choose **Edit Widgets**, search for **BudgetFlow**, and add the small or medium **BudgetFlow Overview** widget. The app publishes only the calculated overview needed by the widget to its private app-group container; the complete budget remains in Application Support.

The first launch asks for gross income, net income, and the current emergency-fund balance. Saved data is stored locally in the user's Application Support directory.

See [Documentation/PRODUCT.md](Documentation/PRODUCT.md) for the calculation rules, score definition, and roadmap.
See [Documentation/DESIGN.md](Documentation/DESIGN.md) for the visual system and accessibility behavior.
