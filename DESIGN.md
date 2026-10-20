# Wall Tap Design System & Interface Specification

Design specifications, theme tokens, color palette, typography hierarchy, component architecture, and interaction patterns for Wall Tap.

> Reading this as: Utility Android application with OLED-optimized dark interface, dial ENERGY 2 / RHYTHM 2 / MOTION 2.

---

## 1. Design Direction & Aesthetic Foundations

Wall Tap treats wallpaper artwork as the primary visual subject. The interface serves as a dark, minimal frame that displays photography and illustrations without competing for attention.

### Core Principles
1. **OLED Dark Foundation**: Obsidian and charcoal background surfaces (`#0D0E12`, `#16181F`) reduce battery consumption on OLED displays and provide high contrast against wallpaper imagery.
2. **Content-First Composition**: Media cards run edge-to-edge within their grid cells. Active wallpapers remain unbadged and clean. Badges appear only when necessary to show state, such as active device wallpaper or excluded status.
3. **Layered Depth with Frosted Overlays**: Semi-transparent frosted glass overlays (`BackdropFilter` with Gaussian blur $\sigma = 16$) position controls above image layers while preserving legibility.
4. **Tactile Touch Feedback & Haptics**: Interactive cards, buttons, and navigation tabs provide physical feedback through scale compression (`PressableScale` down to 0.96 scale) paired with device haptics (`selectionClick`, `mediumImpact`).
5. **Deterministic Motion**: View transitions, image zooming, and selection modes use short spring and ease-out curves (`Curves.easeOutCubic`, 100ms to 260ms) to ensure interactions feel immediate.

---

## 2. Color System & Design Tokens

Wall Tap uses an OLED dark palette consisting of obsidian backgrounds, structured dividers, a crimson primary accent, and semantic status colors.

### 2.1 Color Token Table

| Token Name | Value | Purpose |
| :--- | :--- | :--- |
| **Scaffold Background** | `#0D0E12` | Root background for all screens and tabs |
| **Surface Card** | `#16181F` | Primary container surface for wallpaper cards and action sheets |
| **Surface Secondary** | `#161822` | Modal sheet backgrounds, dialog containers, and settings cards |
| **Surface Elevated** | `#1B1D26` | Confirmation dialogs and popups |
| **Surface Highest** | `#1F222B` | Hover states and secondary action tiles |
| **Bottom Bar Glass** | `#161824` (80% alpha) | Floating navigation bar with 16px background blur |
| **Border Subtle** | `#242834` | 1.0px structural dividers and card outlines |
| **Border Nav / Header** | `#2B3042` | Navigation bar perimeter border (1.2px) |
| **Border Sheet Top** | `#2A2E3D` | Top border stroke on modal bottom sheets |
| **Primary Accent** | `#FFFF3B30` | Crimson: active tabs, primary CTAs, and active radio indicators |
| **Secondary Warm** | `#FFFF5E3A` | Companion accent for crimson gradients |
| **Accent Glow Shadow** | `rgba(255, 59, 48, 0.4)` | Subtle drop shadow beneath active buttons |
| **Success / Include** | `#34C759` | Emerald green: include actions, success toasts, and healthy battery status |
| **Success Container** | `#1E3A28` / `#1A3826` | Dark emerald container background for include actions |
| **Warning / Alert** | `#FF9F0A` | Amber orange: exclude actions, battery alerts, and warnings |
| **Destructive / Delete** | `#FF453A` | Carmine red: delete icons and destructive confirmation buttons |
| **Destructive Container**| `#2E1B1E` | Muted burgundy background for delete action containers |
| **Destructive Border** | `#4E2429` | Border stroke around delete buttons |
| **Text Primary** | `#FFFFFF` / `#F0F1F5` | High-contrast headings, active labels, and primary values |
| **Text Secondary** | `rgba(255, 255, 255, 0.70)` | Subheadings, card labels, and metadata descriptors |
| **Text Muted** | `rgba(255, 255, 255, 0.38)` | Helper texts, disabled labels, and timestamps |

---

## 3. Typography System

Typography prioritizes legibility with clear hierarchy, tight tracking on headings, and standard line spacing on body text.

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

### 3.2 Usage Rules
- **Screen Titles**: Displayed in pure white (`#FFFFFF`) with -0.5 letter spacing.
- **Section Headers**: Formatted as uppercase category tags (e.g. `BACKGROUND EXECUTION & ALARMS`, `STORAGE`, `WALLPAPER CONFIGURATION`) in muted grey (`Colors.white54` or `#8E95A5`) with `letterSpacing: 1.0`.
- **Badges**: Formatted in uppercase bold (`9.5pt`, `FontWeight.w900`, `letterSpacing: 0.4`) for legibility at small sizes.

---

## 4. Layout, Spacing & Elevation

### 4.1 8-Point Grid System
All spacing, padding, margins, and dimensions follow an 8-point base grid:
- **Base Grid**: 8pt increments (`8`, `16`, `24`, `32`, `40`, `48`).
- **Micro Spacing**: 4pt increments for badge padding, inline icon spacing (`4`, `6`, `12`).
- **Screen Margin**: Standard horizontal padding is `16pt` to `18pt`.
- **Bottom Navigation Clearance**: Scrollable views include bottom padding of `100pt` to `120pt` so the floating navigation bar does not cover content.
- **Scrollbar**: Displayed on the right edge of scroll views with clean thumb styling.

### 4.2 System Bar Integration
- **Status Bar**: Transparent (`Colors.transparent`) with light icons (`Brightness.light`) for edge-to-edge drawing under system indicators.
- **Navigation Bar**: Transparent or dark backing (`#0F1015`) with light system icons, matching Android gesture bar behavior.

---

## 5. Core Components

### 5.1 Floating Glass Bottom Navigation Bar
Anchored above the bottom edge of the screen:
- **Placement**: Anchored in `SafeArea` with `EdgeInsets.fromLTRB(16, 0, 16, 16)`.
- **Dimensions**: `64pt` height, `BorderRadius.circular(32)`. Max width constrained to `540pt` on wide screens and tablets.
- **Materials**: Frosted glass (`BackdropFilter` with `sigmaX: 16, sigmaY: 16`), container color `#161824` with 80% alpha (`0xCC`), border `#2B3042` (1.2px), and ambient shadow (`blurRadius: 20`, offset `y: 8`).
- **Tabs**:
  1. **Studio** (`Icons.shuffle_rounded`): Quick wallpaper shuffle, auto-interval setup, active collection monitor.
  2. **Library** (`Icons.photo_library_rounded`): Wallpaper grid, custom albums, and multi-selection actions.
  3. **Widgets** (`Icons.widgets_rounded`): Launcher widget manager and configuration.
  4. **Settings** (`Icons.tune_rounded`): Background execution, battery optimization, and app information.
- **Selected Tab State**: Animates into an expanded red pill (`#FFFF3B30`, `BorderRadius.circular(24)`), revealing the tab label alongside the icon.

### 5.2 Wallpaper Cards (Library & Albums)
- **Shape**: `BorderRadius.circular(16)`.
- **Image Display**: Cached preview rendering with broken image fallback.
- **Gradient Scrim**: Bottom 60pt linear gradient (`Colors.black.withAlpha(190)` to `transparent`) ensuring text contrast over light photos.
- **Bottom Metadata**: Resolution label (e.g. `1080x2400`) in a semi-transparent black pill (`Colors.black.withAlpha(160)`) on the bottom-left.
- **Bottom Action Button**: Bottom-right circular toggle button wrapped in `PressableScale`:
  - Active: Emerald green circle (`#34C759`) with check icon.
  - Excluded: Dark charcoal circle with minus icon.
- **Status Badges**:
  - `CURRENT` Badge: Top-left solid crimson pill (`#FFFF3B30`). Displayed exclusively when the image matches the active device wallpaper.
  - `EXCLUDED` Badge: Top-left slate dark pill with minus circle icon. Displayed only when the wallpaper is excluded from rotation.
  - Active Wallpapers: Unbadged to keep presentation clean.

### 5.3 Interactive Wallpaper Preview Dialog
Full-resolution viewer opened by tapping any wallpaper card:
- **Transition**: Modal hero route with fade animation and dark backdrop blur (`Colors.black.withAlpha(240)`).
- **Gestures**:
  - Pan and Pinch Zoom: Powered by `InteractiveViewer` with `TransformationController` (scale: 1.0x to 5.0x).
  - Double-Tap Zoom: Animates to 2.5x centered on the tap coordinate via `Matrix4Tween` (`Curves.easeOutCubic`, 260ms duration). Double-tapping again resets to 1.0x.
  - Single Tap: Toggles visibility of top controls and bottom action sheet.
- **Bottom Sheet**:
  - Dark container `#161822` with 28pt top rounded corners.
  - File metadata (file name, resolution, file size).
  - Status toggle (Active vs Excluded).
  - Delete button with confirmation alert.
  - Primary button: "Set as Current Wallpaper" (`#FFFF3B30` with `mediumImpact` haptic feedback).

### 5.4 Multi-Selection Mode
Batch workflow for Library and Album views:
- **Trigger**: Long-press on any card or tap the "Select" button in the header.
- **Visuals**:
  - Selected cards show an active crimson tint overlay (`#FFFF3B30.withAlpha(45)`).
  - Top-right corner checkmark circle (`#FFFF3B30`).
- **Header Actions**:
  - Item counter showing selected count.
  - "Select All" and "Deselect All" toggle.
  - Dynamic Include/Exclude button:
    - All selected items excluded: displays "Include" (Green).
    - All selected items active: displays "Exclude" (Amber).
    - Mixed selection: opens a bottom sheet offering "Include All" or "Exclude All".
  - Delete button:
    - In Library: Prompts permanent deletion confirmation.
    - In Albums: Offers choice between "Remove from Album" and "Delete Permanently".

### 5.5 Home Screen Widgets & Management
1. **Shuffle Widget**:
   - Launcher widget showing upcoming wallpaper preview (300x480 thumbnail) with a red `NEXT` badge.
   - Action button triggers `ACTION_NEXT` to cycle wallpaper and pre-calculate next index.
   - Smooth transition animation when updating widget image.
2. **Album Display Widget**:
   - Photo frame widget displaying photos from a selected album or all photos.
   - Interactive tap-to-reveal controls for advancing photos and opening settings.
   - Smooth transition animation on image rotation.
3. **Placed Widgets Tab UI**:
   - 2-column square grid layout displaying placed widget previews and configuration cards.
   - Interval indicator displaying active rotation schedule (e.g. 1m, 3m, 5m, 10m, 15m, 30m, 45m, 1h, 3h, 6h, 12h, 24h, or Manual).
   - Solid, un-gradiented action buttons.
   - Crimson radio theme for shuffle and order selection.
   - Right-side scrollbar.

### 5.6 Section Cards & Settings
- **Containers**: Grouped cards with 20pt border radius, background `#161822`, and border `#242836`.
- **Switches**: Material 3 switches with crimson active track color (`#FFFF3B30`).
- **Buttons**: Flat solid buttons without unnecessary gradient overlays.

---

## 6. Micro-Interactions, Motion & Haptics

### 6.1 `PressableScale`
Interactive buttons, cards, and list tiles use `PressableScale`:
- **Scale**: Compresses to `0.96` on touch-down.
- **Duration**: `100ms` forward, `100ms` reverse.
- **Curve**: `Curves.easeOutCubic`.

### 6.2 Haptic Feedback Matrix
- Tab Navigation Switch: `HapticFeedback.selectionClick()`
- Toggle Active / Exclude: `HapticFeedback.selectionClick()`
- Enter Multi-Selection Mode: `HapticFeedback.mediumImpact()`
- Select / Deselect Item: `HapticFeedback.selectionClick()`
- Primary Action (Set Wallpaper / Shuffle): `HapticFeedback.mediumImpact()`

### 6.3 SnackBars & Feedback
- Floating SnackBars (`SnackBarBehavior.floating`) with `BorderRadius.circular(12)`.
- Semantic colors: Success `#34C759`, Warning `#FF9F0A`, Error `#FF3B30`.

---

## 7. Iconography

Material Rounded icons (`Icons.*_rounded`) are used consistently:
- Studio: `Icons.shuffle_rounded`
- Library: `Icons.photo_library_rounded`
- Albums: `Icons.folder_rounded`, `Icons.folder_open_rounded`
- Widgets: `Icons.widgets_rounded`
- Settings: `Icons.tune_rounded`
- Include: `Icons.check_circle_rounded`, `Icons.add_circle_outline_rounded`
- Exclude: `Icons.remove_circle_outline_rounded`
- Set Wallpaper: `Icons.wallpaper_rounded`
- Delete: `Icons.delete_outline_rounded`
- Search: `Icons.search_rounded`

---

## 8. Accessibility & Visual Ergonomics

1. **Color Contrast**: Normal and large text meet WCAG AA standards against `#0D0E12` and `#16181F` background surfaces.
2. **Touch Targets**: Interactive controls maintain a minimum touch target of 44x44 pt or expand gesture hitboxes using `HitTestBehavior.opaque`.
3. **Safe Areas**: Padding accounts for system gesture bars, display cutouts, and status bars across Android device profiles.
