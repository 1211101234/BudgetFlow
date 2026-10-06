# BudgetFlow visual and accessibility system

## Visual direction

BudgetFlow uses an optimistic-finance palette with indigo as the brand color, teal for positive outcomes, amber for items that need review, coral/red for critical states, and system blue for neutral information. The implementation uses macOS semantic system colors so contrast adapts to light mode, dark mode, and increased-contrast settings.

Cards use a restrained pixel-inspired top accent that connects the interface to the 8-bit app icon without making financial information feel like a game.

## Accessibility behavior

- Meaning is never communicated by color alone. Status cards include a severity label, icon, and complete text.
- Dashboard metrics and financial rows combine their visible content into concise VoiceOver labels.
- The chart exposes a text summary instead of requiring VoiceOver users to navigate individual marks.
- Layouts use adaptive grids and `ViewThatFits` so content can stack when space or text size requires it.
- The background respects Reduce Transparency.
- Editable fields retain explicit accessible names.
- Primary and cancel actions in sheets support the standard Return and Escape keyboard actions.
- The allocation reset action supports Shift-Command-R and includes a tooltip.
- Future-plan rows identify whether each payday came from Calendar or is an estimate, and Calendar access is requested only from an explicit button.

## App icon

The source artwork is `Sources/BudgetFlow/Resources/BudgetFlowIcon.png`. The macOS AppIcon asset catalog contains all required representations from 16×16 to 1024×1024. The icon uses a teal wallet, allocation compartments, a gold coin, and an upward progress arrow in high-contrast 8-bit pixel art.

The icon intentionally contains no text, number, or currency symbol so it remains recognizable across locales and small display sizes.
