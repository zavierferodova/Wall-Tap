# 04 - Application Features & User Flows

This document provides a comprehensive guide to all functional features, user journeys, tabs, and interactive dialogs within Wall Tap.

---

## 1. Studio Tab (Quick Wallpaper Shuffle & Settings)

The **Studio** tab serves as the primary control center for immediate wallpaper actions and rotation settings.

```
+------------------------------------------+
|  STUDIO                         [Import] |
|                                          |
|  +------------------------------------+  |
|  | [CURRENT BADGE]                    |  |
|  |                                    |  |
|  |       Hero Wallpaper Image         |  |
|  |                                    |  |
|  | [1080x2400]           [Active Dot] |  |
|  +------------------------------------+  |
|                                          |
|  [         SHUFFLE NEXT WALLPAPER     ]  |
|                                          |
|  SLIDESHOW INTERVAL                      |
|  [ 15 min ]  [ Slider: 1m - 24h / Off ]  |
|                                          |
|  ROTATION ORDER                          |
|  [ Random Shuffle             (Toggle) ] |
|                                          |
|  TARGET SCREEN                           |
|  [ Both Screen | Home Screen | Lock ]    |
|                                          |
|  SCALING MODE                            |
|  [ Center Crop | Fit Image | Full ]      |
+------------------------------------------+
```

### 1.1 Key Capabilities
- **Hero Artwork Preview**: Shows the currently active wallpaper with file resolution tag (`1080x2400`) and active status.
- **Shuffle Next Wallpaper**: Tapping triggers `controller.shuffleNext()`. Vibrates with `mediumImpact` haptic feedback, calculates next index (respecting sequential or random order), invokes native `setWallpaper()`, and updates home screen widgets immediately.
- **Interval Cadence Selector**:
  - Options: Manual (0 min), 1 min, 5 min, 15 min, 30 min, 1 hour, 3 hours, 6 hours, 12 hours, 24 hours (daily).
  - Changing the interval immediately restarts or cancels Android `AlarmManager` via `updateSchedule()`.
- **Target Screen Configuration**:
  - Sets whether rotations apply to the Home Screen, Lock Screen, or Both.
  - Updates native configuration and immediately re-applies the current wallpaper to the selected screen(s).
- **Scale Mode Configuration**:
  - Options: **Full Image** (stretched to screen bounds), **Center Crop** (aspect ratio preserved, excess cropped), or **Fit Image** (aspect ratio preserved with letterbox black bars).
  - Toggling scale mode immediately refreshes the active device wallpaper with the new scaling without changing the photo.

---

## 2. Gallery & Albums Tab

The **Gallery** tab manages your complete library of wallpapers and custom curated albums.

### 2.1 Tab Segment Switch
A segmented control at the top switches between:
- **All Wallpapers**: Displays every wallpaper stored in the app in a responsive, two-column grid.
- **Albums**: Displays user-created album collections.

### 2.2 Wallpaper Cards & Status Badges
Each card in the wallpaper grid displays:
- Edge-to-edge high-resolution image preview.
- **Bottom-left**: Semi-transparent resolution pill (e.g. `1440x3120`).
- **Bottom-right**: Circular inclusion toggle (`PressableScale`). Tapping toggles whether the wallpaper is included in the active rotation (`isEnabled`).
- **Top-left Badges**:
  - **`CURRENT`** (Vibrant Crimson): Rendered exclusively when the image matches the device's currently set wallpaper.
  - **`EXCLUDED`** (Slate Dark): Rendered when the wallpaper is disabled from rotation.
  - **Active Items**: Completely badge-free for clean aesthetics.

### 2.3 Multi-Selection Mode
Designed for fast batch operations across many wallpapers:
- **Activation**: Triggered by long-pressing any wallpaper card or tapping "Select" in the top bar.
- **Visual Feedback**: Selected cards display a crimson tint overlay and an animated check circle in the top right corner.
- **Action Bar**:
  - **Selection Counter**: Displays count (e.g., `5 selected`).
  - **Select All / Deselect All**: Toggles whole collection with one tap.
  - **Dynamic Include / Exclude Button**:
    - If all selected wallpapers are excluded $\rightarrow$ displays **Include** (Green).
    - If all selected wallpapers are active $\rightarrow$ displays **Exclude** (Amber).
    - If mixed $\rightarrow$ opens bottom sheet offering "Include All" or "Exclude All".
  - **Batch Delete**: Prompts a permanent deletion confirmation dialog.

### 2.4 Album Management
- **Album Creation**: Create custom albums (e.g., "Minimalist", "OLED Dark", "Nature") with custom names.
- **Album Detail Screen (`AlbumDetailScreen`)**:
  - Filter wallpapers assigned to this album.
  - Add existing photos from library into album.
  - Import new photos directly into album.
  - Multi-select operations inside album: batch remove from album vs permanently delete from device.
  - Set as active Studio rotation playlist.

---

## 3. Album Widgets Tab (Home Screen Widgets)

The **Widgets** tab allows users to monitor and configure Wall Tap widgets placed on their Android launcher.

### 3.1 Placed Widget Manager
- Lists all active `AlbumWidgetProvider` instances placed on the user's home screen.
- Shows current thumbnail preview, target album name, photo count, and auto-rotation cadence.
- **Shuffle Button**: Tapping manually rotates that specific widget on the home screen without altering the device wallpaper.
- **Cadence & Order Toggles**: Change interval or random/sequential mode from within the app.

### 3.2 Widget Setup Guide (`WidgetGuideDialog`)
Provides visual, step-by-step instructions for adding Wall Tap widgets on popular launchers:
- **Step 1**: Long-press any empty space on your home screen.
- **Step 2**: Tap "Widgets" from the menu.
- **Step 3**: Locate "Wall Tap" and choose between **Wall Tap Shuffle** (quick wallpaper change button) or **Album Display** (photo frame).
- **Step 4**: Place the widget and choose your album.

---

## 4. Interactive Wallpaper Preview Dialog

Tapping any wallpaper card in the Gallery or Album view opens `WallpaperPreviewDialog`:

```
+------------------------------------------+
|  [<- Back]                 [Exclude] [*] |
|                                          |
|                                          |
|                                          |
|            InteractiveViewer             |
|            (Pinch / Pan Zoom)            |
|                                          |
|                                          |
+------------------------------------------+
|  cyberpunk_city.png                      |
|  1440x3120  •  4.2 MB  •  Active         |
|  [SET AS CURRENT WALLPAPER]              |
|  [Toggle Exclude]      [Delete Wallpaper]|
+------------------------------------------+
```

### 4.1 Advanced Zoom Physics
- **Pan & Pinch**: Powered by `InteractiveViewer` with `minScale: 1.0` and `maxScale: 5.0`.
- **Double-Tap Smart Zoom**: Double-tapping the image animates smoothly to `2.5x` scale centered on the tap coordinate using `Matrix4Tween` and `Curves.easeOutCubic`. Double-tapping again resets to `1.0x`.
- **Single Tap Immersion**: Tapping once toggles visibility of the top header and bottom action sheet for an unobstructed fullscreen view.

### 4.2 Actions
- **"Set as Current Wallpaper"**: Full-width crimson CTA that applies the wallpaper to the device immediately and dismisses the dialog.
- **Status Toggle**: Toggles item between Active and Excluded.
- **Delete**: Prompts destructive confirmation dialog to delete image file and database entry.

---

## 5. Settings & Reliability Tab

The **Settings** tab provides diagnostic controls and options to ensure background wallpaper rotations are never killed by Android power managers, alongside application attribution.

### 5.1 Background Execution & Alarms
- **Battery Optimization Whitelist**:
  - Displays green "Unrestricted" badge if Wall Tap is whitelisted from OEM battery restrictions.
  - If restricted, displays an amber warning card with a one-tap button to request exemption (`Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`).

### 5.2 About Wall Tap
- Displays application version, developer attribution, and architectural summary.
