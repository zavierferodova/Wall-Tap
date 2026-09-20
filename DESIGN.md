# Wall Tap Design System & UI Specification

Welcome to the **Wall Tap** Design System documentation. This document outlines the visual language, design philosophy, theme tokens, color palette, typography hierarchy, component architecture, and interaction patterns implemented across the Wall Tap mobile application.

---

## 1. Design Philosophy & Aesthetic Pillars

Wall Tap is built around the principle that **wallpapers are the hero art**. The user interface serves as a refined, high-performance canvas designed to showcase photography and digital art without visual friction.

### Core Design Pillars
1. **Dark-First, OLED-Optimized Foundation**:
   - Deep obsidian and charcoal surfaces (`#0D0E12`, `#16181F`) reduce battery consumption on OLED displays while maximizing the vibrancy and perceived contrast of wallpaper artwork.
2. **Content-First Simplicity**:
   - Edge-to-edge media cards eliminate unnecessary borders and heavy frames.
   - Active wallpapers remain completely clean and uncluttered—badges appear only when providing essential context (e.g., currently active device wallpaper or excluded status).
3. **Glassmorphism & Layered Depth**:
   - Translucent frosted glass overlays (`BackdropFilter` with Gaussian blur $\sigma = 16$) elevate controls above media layers, maintaining context while ensuring high legibility.
4. **Tactile Micro-Interactions & Haptics**:
   - Every tap, toggle, and press provides physical feedback via scale physics (`PressableScale` compressing to `0.96` scale) paired with device haptics (`selectionClick`, `mediumImpact`).
5. **Fluid Motion & Spatial Continuity**:
   - Smooth spring and ease-out cubic curves make view transitions, image zooming, and selection modes feel instantaneous yet natural.

---

## 2. Color System & Palette

Wall Tap utilizes a curated dark color palette consisting of dark obsidian backgrounds, crisp boundary strokes, a vibrant crimson primary accent, and purposeful semantic indicators.

### 2.1 Color Token Table

| Token Name | Hex Code | Purpose & Usage |
| :--- | :--- | :--- |
| **Scaffold Background** | `#0D0E12` | Root application background for all screens and tabs |
| **Surface (Card / Sheet)** | `#16181F` | Primary elevated container surface (cards, bottom sheets) |
| **Surface Secondary** | `#161822` | Modal sheet backgrounds, dialog containers, settings cards |
| **Surface High-Elevated**| `#1B1D26` | Confirmation dialogs, elevated popups |
| **Surface Highest** | `#1F222B` | Hover states, secondary action tiles |
| **Bottom Bar Glass** | `#161824` (80% / `0xCC`) | Floating navigation bar with 16px background blur |
| **Border Subtle** | `#242834` | 1.0px structural dividers, card outlines |
| **Border Nav / Header** | `#2B3042` | Navigation bar perimeter border (1.2px) |
| **Border Sheet Top** | `#2A2E3D` | Top border stroke on modal bottom sheets |
| **Primary Accent** | `#FFFF3B30` | Wall Tap Crimson: active tabs, primary CTAs, delete alerts |
| **Secondary Warm** | `#FFFF5E3A` | Gradient transition companion for crimson accents |
| **Accent Glow Shadow** | `rgba(255, 59, 48, 0.4)`| Dynamic drop shadows beneath active buttons and badges |
| **Success / Include** | `#34C759` | Emerald Green: include actions, success toasts, battery good |
| **Success Container** | `#1E3A28` / `#1A3826` | Dark emerald tinted background for include buttons and badges |
| **Warning / Alert** | `#FF9F0A` | Amber Orange: exclude actions, battery alerts, warnings |
| **Destructive / Delete** | `#FF453A` | Carmine Red: delete icons and destructive confirmation buttons |
| **Destructive Tint** | `#2E1B1E` | Muted burgundy background for delete action containers |
| **Destructive Border** | `#4E2429` | Border stroke around delete buttons |
| **Text Primary** | `#FFFFFF` / `#F0F1F5` | High-contrast headings, active labels, primary values |
| **Text Secondary** | `rgba(255, 255, 255, 0.70)`| Subheadings, card labels, metadata descriptors |
| **Text Muted / Hints** | `rgba(255, 255, 255, 0.38)`| Helper texts, disabled labels, timestamps |

---

## 3. Typography System

Wall Tap relies on clean typographic hierarchy with crisp weights, tight tracking on headings, and generous line spacing on body copy.

### 3.1 Typographic Scale

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

### 3.2 Typography Usage Principles
- **Screen & Display Titles**: Rendered in pure white (`#FFFFFF`) with `-0.5` letter spacing to convey an editorial, modern tone.
- **Section Headers**: Formatted as uppercase category tags (e.g., `BACKGROUND EXECUTION & ALARMS`, `STORAGE`, `WALLPAPER CONFIGURATION`) in muted grey (`Colors.white54` or `#8E95A5`) with `letterSpacing: 1.0` to divide functional groups cleanly.
- **Micro-Badges**: Formatted in uppercase bold (`9.5pt`, `FontWeight.w900`, `letterSpacing: 0.4`) for quick recognition at small scales.

---

## 4. Layout, Spacing & Elevation

### 4.1 8-Point Grid System
All spacing, padding, margins, and component dimensions adhere to multiples of 4 and 8:
- **Base Grid**: 8pt increments (`8`, `16`, `24`, `32`, `40`, `48`).
- **Micro Spacing**: 4pt increments for badge padding, inline icon-text spacing (`4`, `6`, `12`).
- **Screen Padding**: Standard horizontal edge margin is `16pt` to `18pt`.
- **Bottom Navigation Offset**: Scrollable views include a bottom inset of `100pt` to `120pt` to prevent floating navigation bars from obstructing content.

### 4.2 System Bar Integration
- **Status Bar**: Transparent (`Colors.transparent`) with light icons (`Brightness.light`) for edge-to-edge immersion under the system clock and battery indicators.
- **Navigation Bar**: Rendered with `#0F1015` or transparent backing with light system icons, preserving Android 10+ gesture bar aesthetics.

---

## 5. Core Components & Visual Architecture

### 5.1 Floating Glassmorphic Bottom Navigation Bar
The main navigation is a floating glass pill suspended above the bottom screen edge:
- **Placement**: Anchored in `SafeArea` with `EdgeInsets.fromLTRB(16, 0, 16, 16)`.
- **Dimensions**: `64pt` height, `BorderRadius.circular(32)`.
- **Materials**: Frosted glass (`BackdropFilter` with `sigmaX: 16, sigmaY: 16`), container color `#161824` with 80% alpha (`0xCC`), stroke `#2B3042` (1.2px), and soft ambient shadow (`blurRadius: 20`, offset `y: 8`).
- **Tabs**:
  1. **Studio** (`Icons.shuffle_rounded`): Quick wallpaper shuffle, auto-interval setup, active collection monitor.
  2. **Gallery** (`Icons.photo_library_rounded`): All wallpapers grid, custom albums, multi-select actions.
  3. **Widgets** (`Icons.widgets_rounded`): Home screen widget manager and preview builder.
  4. **Settings** (`Icons.tune_rounded`): Persistent notification switch, background execution, battery optimization, and storage maintenance.
- **Interactive State**: The selected tab animates smoothly into an expanded red pill (`#FFFF3B30`, `BorderRadius.circular(24)`) with drop shadow glow, revealing the tab label alongside the icon.

### 5.2 Wallpaper Cards (Gallery & Albums)
Wallpaper cards represent images as clean, edge-to-edge elements:
- **Shape**: `BorderRadius.circular(16)`.
- **Image Fitting**: High-performance cached preview rendering with broken image fallback.
- **Gradient Scrim**: Bottom 60pt linear gradient (`Colors.black.withAlpha(190)` to `transparent`) ensures metadata legibility over light-colored photos.
- **Bottom Metadata**: Resolution tag (e.g. `1080x2400`) in a semi-transparent black pill (`Colors.black.withAlpha(160)`) on the bottom-left.
- **Bottom Action Button**: Bottom-right circular toggle button (`PressableScale`):
  - **Active**: Vibrant emerald green circle (`#34C759`) with check icon.
  - **Excluded**: Translucent dark charcoal circle with minus icon.
- **Status Badge Architecture**:
  - **`CURRENT` Badge**: Top-left solid crimson pill (`#FFFF3B30`) with subtle shadow glow. Rendered exclusively when the image matches the device's currently set wallpaper.
  - **`EXCLUDED` Badge**: Top-left slate dark pill with minus circle icon. Rendered only when the wallpaper is disabled from rotation.
  - **Active Wallpapers**: Completely badge-free to maximize aesthetic clarity.

### 5.3 Interactive Wallpaper Preview Dialog & Overlay
Full-resolution viewer displayed when tapping a wallpaper card:
- **Entry & Transition**: Modal hero route with fade animation and deep backdrop blur (`Colors.black.withAlpha(240)`).
- **Gesture Navigation**:
  - **Pan & Pinch Zoom**: Powered by `InteractiveViewer` with `TransformationController` (scale: 1.0x to 5.0x).
  - **Double-Tap Smart Zoom**: Animates directly to 2.5x centered on the tap position via `Matrix4Tween` (`Curves.easeOutCubic`, 260ms duration).
  - **Single Tap**: Toggles visibility of top navigation controls and bottom action sheet for unobstructed viewing.
- **Bottom Action Sheet**:
  - Frosted surface `#161822` with 28pt top rounded corners.
  - File metadata (file name, resolution, file size).
  - Quick status toggle (**Active** vs **Excluded**).
  - Delete shortcut button with confirmation alert.
  - Full-width primary CTA: **"Set as Current Wallpaper"** (`#FFFF3B30` with `mediumImpact` haptic feedback).

### 5.4 Multi-Selection Mode
A batch management workflow available in both Gallery and Album views:
- **Activation**: Triggered via long-press on any card or tapping the "Select" action button in the header.
- **Selection Visuals**:
  - Selected cards display an active crimson tint overlay (`#FFFF3B30.withAlpha(45)`).
  - Top-right corner animated check circle (`#FFFF3B30` with white check icon).
- **Selection Top Bar**:
  - Replaces standard navigation header with dynamic item counter (e.g., `3 selected`).
  - **"Select All" / "Deselect All"** toggle.
  - **Dynamic Include / Exclude Button**:
    - If all selected items are excluded $\rightarrow$ displays **Include** (Green).
    - If all selected items are active $\rightarrow$ displays **Exclude** (Amber).
    - If selection is mixed $\rightarrow$ opens a bottom sheet offering **"Include All"** or **"Exclude All"**.
  - **Delete Button**:
    - In Gallery: Permanent deletion confirmation dialog.
    - In Albums: Bottom sheet allowing user to choose between **"Remove from Album"** or **"Delete Permanently"**.

### 5.5 Section Cards & Settings Rows
- **Containers**: Grouped cards with 20pt border radius, background `#161822`, and stroke border `#242836`.
- **Icon Styling**: 24pt-28pt icons with semantic coloring (e.g., charging battery in emerald `#34C759`, warning battery in orange `#FF9F0A`).
- **Switches**: Custom-styled Material 3 switches featuring crimson active track colors.

---

## 6. Micro-Interactions, Motion & Haptics

### 6.1 `PressableScale`
All interactive buttons, cards, and icon taps are wrapped with `PressableScale`:
- **Scale Factor**: Compresses to `0.96` on touch-down.
- **Duration**: `100ms` forward, `100ms` reverse.
- **Curve**: `Curves.easeOutCubic`.
- **Result**: Provides a physical, springy feel without distracting lag.

### 6.2 Haptic Feedback Matrix
- **Tab Change**: `HapticFeedback.selectionClick()`
- **Toggle Active / Exclude**: `HapticFeedback.selectionClick()`
- **Enter Multi-Selection Mode**: `HapticFeedback.mediumImpact()`
- **Select / Deselect Item**: `HapticFeedback.selectionClick()`
- **Primary CTA (Set Wallpaper / Shuffle)**: `HapticFeedback.mediumImpact()`

### 6.3 Feedback & Notifications
- **Floating SnackBars**:
  - Elevated floating behavior (`SnackBarBehavior.floating`) with `BorderRadius.circular(12)`.
  - Icon on leading edge (`Icons.check_circle` or `Icons.error_outline`).
  - Color-coded: Success `#34C759`, Warning `#FF9F0A`, Error `#FF3B30`.
- **Persistent Android Notification**:
  - Clean system indicator with compact Wall Tap brand icon and status text.
  - Toggleable from the Settings screen for user control.

---

## 7. Iconography & Assets

- **Icon Family**: Exclusively Material Rounded (`Icons.*_rounded`) to harmonize with rounded card geometries (`16pt` - `28pt` radii).
- **Core Glyph Mapping**:
  - Studio / Shuffle: `Icons.shuffle_rounded`
  - Gallery / Library: `Icons.photo_library_rounded`
  - Albums: `Icons.folder_rounded`, `Icons.folder_open_rounded`
  - Widgets: `Icons.widgets_rounded`
  - Settings: `Icons.tune_rounded`
  - Include / Active: `Icons.add_circle_outline_rounded`, `Icons.check_circle_rounded`
  - Exclude: `Icons.remove_circle_outline_rounded`
  - Set Wallpaper: `Icons.wallpaper_rounded`
  - Delete / Destructive: `Icons.delete_outline_rounded`
  - Search & Filter: `Icons.search_rounded`, `Icons.filter_list_rounded`

---

## 8. Accessibility & Visual Ergonomics

1. **High Contrast Compliance**:
   - All body copy meets or exceeds WCAG AA contrast ratio against dark backgrounds (`#0D0E12` and `#16181F`).
2. **Touch Targets**:
   - All interactive icons and buttons meet the minimum touch target requirement of $44 \times 44\text{ pt}$ (or use expanded gesture hitboxes via `HitTestBehavior.opaque`).
3. **Safe Area Discipline**:
   - All screen contents and floating bars respect display cutouts, notch contours, and gesture bars across diverse Android device profiles.
