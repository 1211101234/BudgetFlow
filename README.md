# BudgetFlow

A local-first macOS budgeting and allocation app built with SwiftUI and Swift 6.

The interface includes adaptive light/dark colors, VoiceOver summaries, keyboard-friendly actions, reduced-transparency support, a custom 8-bit macOS app icon, and small and medium desktop widgets.

## Requirements

- macOS 14 or later
- Swift 6.2 or later
- Xcode 16 or later for the macOS app and WidgetKit extension
- An Apple Account added to Xcode for App Group signing and widget discovery

## Build and test

```bash
swift build
swift test
swift run BudgetFlow
```

The native Xcode project is generated from `project.yml`. Regenerate it after
changing targets or build settings with:

```bash
brew install xcodegen
xcodegen generate
```

## Run the app and widget from Xcode

1. Open `BudgetFlow.xcodeproj`.
2. In **Xcode > Settings > Apple Accounts**, sign in to an Apple Account.
3. Select the **BudgetFlow** project, then choose the same Team for the
   **BudgetFlow** and **BudgetFlowWidget** targets under **Signing & Capabilities**.
4. Confirm both targets use the `2796SY86W6.com.zahinadri.BudgetFlow` App Group. Sandboxed macOS group identifiers must begin with the signing Team ID.
5. Select the **BudgetFlow** scheme and **My Mac**, then press **Run**.

The app target embeds the WidgetKit extension automatically. After opening
BudgetFlow once, right-click the desktop, choose **Edit Widgets**, search for
**BudgetFlow**, and add the small or medium **BudgetFlow Overview** widget.
The app publishes only the calculated overview needed by the widget to its
private App Group container; the complete budget remains in Application
Support.

You can verify the native build and tests from Terminal with:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project BudgetFlow.xcodeproj \
  -scheme BudgetFlow -destination 'platform=macOS' build test
```

## Unsigned local fallback

```bash
./Scripts/build_app.sh
open "./Release/BudgetFlow.app"
```

This creates an ad-hoc-signed application bundle for local app development. The
app launches, but the embedded App Group widget is not expected to appear in
the macOS widget gallery because it has no Apple development team or
provisioning profile.

To install the local build and register its widget:

```bash
ditto "./Release/BudgetFlow.app" "/Applications/BudgetFlow.app"
pluginkit -a "/Applications/BudgetFlow.app/Contents/PlugIns/BudgetFlowWidget.appex"
open "/Applications/BudgetFlow.app"
```

The first launch asks for gross income, net income, and the current emergency-fund balance. Saved data is stored locally in the user's Application Support directory.

See [Documentation/PRODUCT.md](Documentation/PRODUCT.md) for the calculation rules, score definition, and roadmap.
See [Documentation/DESIGN.md](Documentation/DESIGN.md) for the visual system and accessibility behavior.
