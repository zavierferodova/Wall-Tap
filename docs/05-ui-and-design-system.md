# 05 - UI Architecture & Design System

This document outlines the visual language, design system tokens, typography rules, component architecture, and tactile micro-interactions in Wall Tap. It is based on the application's primary design document (`DESIGN.md`).

---

## 1. Aesthetic Philosophy

Wall Tap treats **wallpapers as hero artwork**. The user interface acts as a refined, high-performance frame designed to showcase digital art and photography without visual clutter.

### Core Principles
1. **Dark-First, OLED Optimization**: Obsidian and charcoal surfaces (`#0D0E12`, `#16181F`) reduce battery draw on mobile OLED screens while maximizing perceived contrast and color punch of wallpaper imagery.
2. **Content-First Simplicity**: Edge-to-edge media cards eliminate heavy frames. Active wallpapers remain completely clean and unbadged.
3. **Glassmorphism & Layered Depth**: Translucent frosted glass overlays (`BackdropFilter` with Gaussian blur $\sigma = 16$) elevate navigation and controls above content layers.
4. **Tactile Scale Physics & Haptics**: Every interactive card, button, and tab provides physical tactile feedback via scale compression (`PressableScale`) paired with native device haptics.

---

## 2. Color System & Design Tokens

### 2.1 Color Palette Table

| Token Name | Hex Value | Purpose |
| :--- | :--- | :--- |
| **Scaffold Background** | `#0D0E12` | Root application canvas for all tabs and screens. |
| **Surface Card** | `#16181F` | Primary container surface (wallpaper cards, action sheets). |
| **Surface Secondary** | `#161822` | Modal sheets, dialog containers, settings cards. |
| **Surface Elevated** | `#1B1D26` | Confirmation dialogs and elevated popups. |
| **Surface Highest** | `#1F222B` | Hover states and interactive selection tiles. |
| **Bottom Bar Glass** | `#161824` (80% / `0xCC`) | Floating navigation bar container with 16px background blur. |
| **Border Subtle** | `#242834` | 1.0px structural dividers and card outlines. |
| **Border Nav / Header** | `#2B3042` | Navigation bar perimeter stroke (1.2px). |
| **Primary Crimson** | `#FFFF3B30` | Active tabs, primary CTAs, delete alerts, glowing pills. |
| **Secondary Warm** | `#FFFF5E3A` | Warm gradient companion for primary accents. |
| **Success / Include** | `#34C759` | Emerald Green: include actions, success toasts, battery good. |
| **Warning / Alert** | `#FF9F0A` | Amber Orange: exclude actions, battery alerts, warnings. |
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

## 4. Key Component Architecture

### 4.1 Floating Glassmorphic Bottom Navigation Bar
Implemented in `MainScreen` (`lib/views/main_screen.dart`):
- **Container**: Suspended inside `SafeArea` with `EdgeInsets.fromLTRB(16, 0, 16, 16)`.
- **Dimensions**: `64pt` height, `BorderRadius.circular(32)`.
- **Material Backdrop**: `BackdropFilter` with `sigmaX: 16, sigmaY: 16` over `Color(0xCC161824)`.
- **Border**: `Border.all(color: Color(0xFF2B3042), width: 1.2)`.
- **Interactive State**: The selected tab animates smoothly into an expanded crimson pill (`#FFFF3B30`, `BorderRadius.circular(24)`) with drop shadow glow, revealing the label alongside the icon.

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(32),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
    child: Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xCC161824),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF2B3042), width: 1.2),
      ),
      // ...
    ),
  ),
)
```

### 4.2 Wallpaper Card Architecture
- **Shape**: `BorderRadius.circular(16)`.
- **Gradient Scrim**: Bottom 60pt linear gradient (`Colors.black.withAlpha(190)` to `transparent`) ensures text readability over light-colored imagery.
- **Bottom-Left Pill**: Displays resolution (e.g. `1080x2400`) in a semi-transparent black pill (`Colors.black.withAlpha(160)`).
- **Bottom-Right Toggle**: Circular button (`PressableScale`):
  - Active: Emerald green circle (`#34C759`) with checkmark.
  - Excluded: Slate charcoal circle with minus icon.
- **Status Badges**:
  - **`CURRENT`**: Top-left crimson badge (`#FFFF3B30`) shown **only** if the item matches the current device wallpaper.
  - **`EXCLUDED`**: Top-left slate dark badge shown **only** if the wallpaper is excluded from rotation.
  - **Active Items**: Clean and badge-free.

---

## 5. Micro-Interactions, Motion & Haptics

### 5.1 `PressableScale` Physics Widget
All interactive cards, buttons, and tab tiles are wrapped in `PressableScale` (`lib/views/widgets/pressable_scale.dart`):
- **Down Scale**: Compresses to `0.96` scale upon touch-down.
- **Duration**: `100ms` forward, `100ms` reverse.
- **Curve**: `Curves.easeOutCubic`.
- Provides an immediate, tactile response without sluggish spring lag.

### 5.2 Haptic Feedback Matrix
Haptic feedback is triggered intentionally for specific user actions:

| Action | Haptic Event | Purpose |
| :--- | :--- | :--- |
| **Tab Navigation Switch** | `HapticFeedback.selectionClick()` | Lightweight tick when changing tabs. |
| **Toggle Active / Exclude** | `HapticFeedback.selectionClick()` | Tactile feedback for toggling status. |
| **Enter Multi-Selection Mode** | `HapticFeedback.mediumImpact()` | Distinctive bump when initiating multi-select. |
| **Select / Deselect Item** | `HapticFeedback.selectionClick()` | Crisp click when toggling item in selection list. |
| **Primary CTA (Shuffle / Set)** | `HapticFeedback.mediumImpact()` | Solid impact confirming immediate wallpaper change. |

---

## 6. Layout & Spacing Rules

1. **8-Point Grid System**: All margins, padding, and spacing increments adhere to multiples of 8 (`8`, `16`, `24`, `32`, `40`, `48`) or micro-increments of 4 (`4`, `12`).
2. **Edge Margins**: Standard horizontal padding across views is `16pt` to `18pt`.
3. **Bottom Navigation Inset**: Scrollable views (`ListView`, `GridView`, `SingleChildScrollView`) include a bottom padding of `100pt` to `120pt` to prevent content from being covered by the floating navigation bar.
4. **Minimum Touch Targets**: All interactive buttons meet the $44 \times 44\text{ pt}$ accessibility requirement or expand their hitbox via `HitTestBehavior.opaque`.
