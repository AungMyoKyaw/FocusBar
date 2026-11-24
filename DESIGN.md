# FocusBar Design System

Surface Mode: **Operate**

## Visual Direction

FocusBar is a native macOS menu bar utility built for quiet, uninterrupted focus sessions. Chrome recedes into semantic macOS materials; only active timer state and progress carry color.

### Color Tokens (`FocusBarTheme`)

- **Focus Accent** (`#E8412C` light / `#FF5B45` dark, `AccentColor` asset): Active Pomodoro ring, primary Start/Resume action, focus charts.
- **Short Break Accent** (`Color.green` / `#2E9E5B`): Short break ring and status pill.
- **Long Break Accent** (`Color.blue` / `#3B82F6`): Long break ring, task breakdown chart.
- **Streak Accent** (`Color.orange`): Active streak indicator.
- **Surfaces**: Semantic macOS materials (`.quaternary`, `.ultraThinMaterial`) and system text colors (`.primary`, `.secondary`). No hardcoded light/dark backgrounds.

### Typography & Numerics

- **Countdown & Metrics**: System font with `.monospacedDigit()` on all timers, XP counters, stat cards, and chart values so digits never jitter.
- **Hierarchy**: `34pt` light monospaced countdown inside the ring; `title3` bold for stat cards; `caption` for metadata.

### Iconography

- 100% SF Symbols (`timer`, `cup.and.saucer.fill`, `leaf.fill`, `pause.circle`, `chart.bar`, `trophy`, `gearshape`, `power`). Zero decorative emoji in UI chrome or menu bar labels.

### Motion & Accessibility

- Respect `@Environment(\.accessibilityReduceMotion)`: disable ring stroke animations when Reduce Motion is enabled.
- Every interactive control provides `.accessibilityLabel` and `.accessibilityHint`; composite cards use `.accessibilityElement(children: .combine)`.
