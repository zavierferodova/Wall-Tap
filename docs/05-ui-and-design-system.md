# 05 - UI Architecture & Design System

Visual design tokens, typography specifications, component architecture, and tactile interactions in Wall Tap.

---

## 1. Aesthetic Foundations

Wall Tap uses a dark, minimal aesthetic to focus attention on wallpaper artwork.

### Core Principles
1. **OLED Optimization**: Dark obsidian surfaces (`#0D0E12`, `#16181F`) conserve battery life on mobile OLED displays while providing high contrast against images.
2. **Content-First Simplicity**: Edge-to-edge media cards eliminate heavy frames. Active wallpapers remain unbadged and clean.
3. **Layered Depth with Frosted Overlays**: Semi-transparent frosted glass overlays (`BackdropFilter` with Gaussian blur $\sigma = 16$) position navigation and controls above content layers.
4. **Tactile Touch Feedback**: Interactive cards, buttons, and tabs provide physical feedback through scale compression (`PressableScale`) paired with device haptics.

---

## 2. Color System & Tokens

### 2.1 Color Palette Table

| Token Name | Hex Value | Purpose |
| :--- | :--- | :--- |
| **Scaffold Background** | `#0D0E12` | Root application canvas for all tabs and screens. |
| **Surface Card** | `#16181F` | Primary container surface (wallpaper cards, action sheets). |
| **Surface Secondary** | `#161822` | Modal sheets, dialog containers, settings cards. |
| **Surface Elevated** | `#1B1D26` | Confirmation dialogs and popups. |
| **Surface Highest** | `#1F222B` | Hover states and interactive selection tiles. |
| **Bottom Bar Glass** | `#161824` (80% / `0xCC`) | Floating navigation bar container with 16px background blur. |
| **Border Subtle** | `#242834` | 1.0px structural dividers and card outlines. |
| **Border Nav / Header** | `#2B3042` | Navigation bar perimeter stroke (1.2px). |
| **Primary Crimson** | `#FFFF3B30` | Active tabs, primary CTAs, delete alerts, glowing pills. |
| **Secondary Warm** | `#FFFF5E3A` | Warm companion accent for primary accents. |
| **Success / Include** | `#34C759` | Emerald green: include actions, success toasts, battery healthy. |
| **Warning / Alert** | `#FF9F0A` | Amber orange: exclude actions, battery alerts, warnings. |
| **Destructive Carmine**| `#FF453A` | Destructive confirmation buttons and delete icons. |
| **Text Primary** | `#FFFFFF` / `#F0F1F5` | High-contrast headings and primary labels. |
| **Text Secondary** | `rgba(255, 255, 255, 0.70)`| Subheadings, card labels, metadata descriptors. |
| **Text Muted** | `rgba(255, 255, 255, 0.38)`| Helper texts, disabled labels, timestamps. |

---

## 3. Typography Hierarchy

```
Display Titles        24pt / 1.2   Weight: 800 (ExtraBold)   Tracking: -0.5px
AppBar / Screen Title 22pt / 1.2   Weight: 800 (ExtraBold)   Tracking: -0.5px
Modal Sheet Header    18pt / 1.3   Weight: 700 (Bold)        Tracking: -0.2px
Section Header        13pt / 1.0   Weight: 700 (Bold)        Tracking: +1.0px (UPPERCASE)
List Tile Title       16pt / 1.3   Weight: 600 (SemiBold)    Tracking: 0.0px
Body Regular          14pt / 1.4   Weight: 400 (Regular)     Tracking: 0.0px
Subtitles / Captions  12pt / 1.3   Weight: 400 - 500         Tracking: 0.0px
Badge / Pill Tags     9.5pt / 1.0  Weight: 800 - 900 (Black) Tracking: +0.4px (UPPERCASE)
Metadata / Spec       10.5pt / 1.0 Weight: 600 - 700         Tracking: 0.0px
```

---

## 4. Component Specifications

### 4.1 Floating Glass Bottom Navigation Bar
Implemented in `MainScreen` (`lib/views/main_screen.dart`):
- **Container**: Suspended inside `SafeArea` with `EdgeInsets.fromLTRB(16, 0, 16, 16)`.
- **Dimensions**: `64pt` height, `BorderRadius.circular(32)`. Max width constrained to `540pt`.
- **Material Backdrop**: `BackdropFilter` with `sigmaX: 16, sigmaY: 16` over `Color(0xCC161824)`.
- **Border**: `Border.all(color: Color(0xFF2B3042), width: 1.2)`.
- **Tabs**: Studio, Library, Widgets, Settings.
- **Active State**: Selected tab expands into a red pill (`#FFFF3B30`, `BorderRadius.circular(24)`), displaying the tab label alongside the icon.

### 4.2 Wallpaper Card Architecture
- **Shape**: `BorderRadius.circular(16)`.
- **Gradient Scrim**: Bottom 60pt linear gradient (`Colors.black.withAlpha(190)` to `transparent`) ensures text contrast over light imagery.
- **Bottom-Left Pill**: Displays resolution (e.g. `1080x2400`) in a semi-transparent black pill (`Colors.black.withAlpha(160)`).
- **Bottom-Right Toggle**: Circular button wrapped in `PressableScale`:
  - Active: Emerald green circle (`#34C759`) with checkmark.
  - Excluded: Slate charcoal circle with minus icon.
- **Status Badges**:
  - `CURRENT`: Top-left crimson badge (`#FFFF3B30`) shown only when the item matches the active device wallpaper.
  - `EXCLUDED`: Top-left slate dark badge shown only when the wallpaper is excluded from rotation.
  - Active Items: Unbadged.

### 4.3 Placed Widgets Grid & Controls
- **Layout**: 2-column square grid layout displaying placed widget previews and configuration cards.
- **Interval Indicators**: Displays active rotation schedule (e.g. 1m, 3m, 5m, 10m, 15m, 30m, 45m, 1h, 3h, 6h, 12h, 24h, or Manual).
- **Buttons**: Solid, flat buttons without gradient overlays.
- **Order Selection**: Crimson radio theme for shuffle and order selection.
- **Scrollbar**: Displayed on the right edge of the screen.

---

## 5. Micro-Interactions, Motion & Haptics

### 5.1 `PressableScale`
Interactive cards, buttons, and tab tiles are wrapped in `PressableScale` (`lib/views/widgets/pressable_scale.dart`):
- **Scale Factor**: Compresses to `0.96` on touch-down.
- **Duration**: `100ms` forward, `100ms` reverse.
- **Curve**: `Curves.easeOutCubic`.

### 5.2 Haptic Feedback Matrix
- Tab Navigation Switch: `HapticFeedback.selectionClick()`
- Toggle Active / Exclude: `HapticFeedback.selectionClick()`
- Enter Multi-Selection Mode: `HapticFeedback.mediumImpact()`
- Select / Deselect Item: `HapticFeedback.selectionClick()`
- Primary Action (Shuffle / Set): `HapticFeedback.mediumImpact()`

---

## 6. Layout & Spacing Rules

1. **8-Point Grid**: Margins, padding, and spacing adhere to multiples of 8 (`8`, `16`, `24`, `32`, `40`, `48`) or micro-increments of 4 (`4`, `12`).
2. **Edge Margins**: Standard horizontal padding across views is `16pt` to `18pt`.
3. **Bottom Navigation Clearance**: Scrollable views include bottom padding of `100pt` to `120pt` so the floating navigation bar does not cover content.
4. **Minimum Touch Targets**: All interactive controls maintain a minimum touch target of 44x44 pt or expand their hitbox via `HitTestBehavior.opaque`.
