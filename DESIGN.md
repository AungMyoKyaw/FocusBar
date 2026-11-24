# FocusBar Design System

Surface Mode: **Operate**

## Visual Direction

FocusBar is a native macOS menu bar utility pairing a **Swiss desktop chronograph** aesthetic (precision radial dial ticks, crisp tabular numerals, single active phase accent) with **macOS Tahoe (macOS 26+) Liquid Glass** (`focusGlassCapsule` / `GlassEffectContainer` gated behind `#available(macOS 26, *)`, with semantic material fallbacks on macOS 14–15). Chrome recedes into native materials; only the active timer phase and progress carry color.

### Color Tokens (`FocusBarTheme`)

- **Focus Accent** (`#E8412C` light / `#FF5B45` dark, `AccentColor` asset): Active Pomodoro ring, primary Start/Resume action, focus charts.
- **Short Break Accent** (`Color.green` / `#2E9E5B`): Short break ring and status pill.
- **Long Break Accent** (`Color.blue` / `#3B82F6`): Long break ring, task breakdown chart.
- **Streak Accent** (`Color.orange`): Active streak indicator.
- **Surfaces**: Semantic macOS materials (`.quaternary.opacity(0.45)` + `1pt` `Color.primary.opacity(0.08)` hairline stroke via `focusCardSurface`) and system text colors (`.primary`, `.secondary`). Never stack glass-on-glass; reserve `.glassEffect()` for floating interactive control pods.

### Geometry & Layout

- **Corners**: `cardCornerRadius = 12pt`, `controlCornerRadius = 10pt`, continuous corner style.
- **Chronograph Dial**: `ringSize = 164pt`, `ringLineWidth = 7pt`, 60 radial perimeter ticks.
- **Window Sizing**: Use `.defaultSize(width:height:)` on `Window` scenes and `.frame(minWidth:minHeight:)` on `ScrollView` content so scrollbars always hug the window edge. Never hardcode narrow widths on segmented pickers.

### Typography & Numerics

- **Countdown & Metrics**: System font with `.monospacedDigit()` on all timers, XP counters, stat cards, and chart values so digits never jitter.
- **Hierarchy**: `38pt` medium rounded monospaced countdown inside the dial; `26pt` semibold rounded for dashboard stat cards; `caption` / `caption2` for metadata.

### Iconography

- 100% SF Symbols (`timer`, `cup.and.saucer.fill`, `leaf.fill`, `pause.circle`, `chart.bar`, `trophy`, `gearshape`, `power`). Zero decorative emoji in UI chrome or menu bar labels.

### Motion & Accessibility

- Respect `@Environment(\.accessibilityReduceMotion)`: disable ring stroke animations when Reduce Motion is enabled.
- Every interactive control provides `.accessibilityLabel` and `.accessibilityHint`; composite cards use `.accessibilityElement(children: .combine)`.
