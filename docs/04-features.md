# 04 - Application Features & User Flows

Feature specifications, navigation flows, tab architectures, and interactive dialogs across Wall Tap.

---

## 1. Studio Tab (Wallpaper Control & Rotation Settings)

The Studio tab provides controls for manual wallpaper changes, active rotation monitoring, and schedule configuration.

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
|  [ 15 min ]  [ Modal Picker ]            |
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

### 1.1 Capabilities
- **Current Wallpaper Preview**: Displays the currently active wallpaper with file resolution tag (`1080x2400`) and active status.
- **Shuffle Next Wallpaper**: Tapping triggers `controller.shuffleNext()`. Executes `mediumImpact` haptic feedback, calculates the next index based on sequential or random order, calls native `setWallpaper()`, and updates launcher widgets immediately.
- **Interval Cadence Selector**:
  - Options: Manual (0 min), 1 min, 3 min, 5 min, 10 min, 15 min, 30 min, 45 min, 1 hour, 3 hours, 6 hours, 12 hours, 24 hours (daily).
  - Selecting an interval immediately restarts or cancels Android `AlarmManager` wakeup alarms via `updateSchedule()`.
- **Target Screen Selection**:
  - Sets whether rotations apply to the Home Screen, Lock Screen, or Both.
  - Updates native configuration and immediately re-applies the current wallpaper to the selected screen(s).
- **Scale Mode Selection**:
  - Options: **Center Crop** (aspect ratio preserved, excess cropped), **Fit Image** (aspect ratio preserved with letterbox black bars), or **Full Image** (stretched to screen bounds).
  - Changing scale mode immediately refreshes the active device wallpaper with the selected scaling without changing the image.

---

## 2. Library & Albums Tab

The Library tab manages the wallpaper collection and custom albums.

### 2.1 Tab Segment Control
A segmented control at the top switches between:
- **All Wallpapers**: Displays all imported wallpapers in a responsive grid.
- **Albums**: Displays user-created album collections.

### 2.2 Wallpaper Cards & Status Badges
Each card in the wallpaper grid displays:
- Edge-to-edge image preview.
- **Bottom-left**: Semi-transparent resolution badge (e.g. `1440x3120`).
- **Bottom-right**: Circular inclusion toggle (`PressableScale`). Tapping toggles whether the wallpaper is included in the active rotation (`isEnabled`).
- **Top-left Badges**:
  - `CURRENT` (Crimson): Displayed exclusively when the image matches the device's currently set wallpaper.
  - `EXCLUDED` (Slate Dark): Displayed when the wallpaper is disabled from rotation.
  - Active Items: Unbadged to preserve clean artwork presentation.

### 2.3 Multi-Selection Mode
Enables batch operations across multiple wallpapers:
- **Activation**: Long-press on any wallpaper card or tap "Select" in the top bar.
- **Visuals**: Selected cards show an active crimson tint overlay and an animated check circle in the top right corner.
- **Action Bar**:
  - Selection counter (e.g. `5 selected`).
  - "Select All" and "Deselect All" button.
  - Dynamic Include/Exclude button:
    - All selected wallpapers excluded: displays "Include" (Green).
    - All selected wallpapers active: displays "Exclude" (Amber).
    - Mixed selection: opens a bottom sheet offering "Include All" or "Exclude All".
  - Batch Delete: Prompts a permanent deletion confirmation dialog.

### 2.4 Album Management
- **Album Creation**: Create named albums (e.g. "Minimalist", "OLED Dark", "Landscapes").
- **Album Detail Screen (`AlbumDetailScreen`)**:
  - Filter wallpapers assigned to this album.
  - Add existing photos from library into the album.
  - Import new photos directly into the album.
  - Multi-select operations inside the album: choose between removing from album and permanently deleting from device.
  - Set the album as the active Studio rotation playlist.

---

## 3. Album Widgets Tab (Launcher Widgets)

The Widgets tab allows users to monitor and configure Wall Tap widgets placed on their Android launcher.

### 3.1 Placed Widget Manager
- Lists all active `AlbumWidgetProvider` instances placed on the user's home screen.
- Rendered in a responsive 2-column square grid layout.
- Displays thumbnail preview, target album name, image count, and rotation cadence.
- **Interval Indicator**: Displays the active schedule (including 3m, 5m, 10m, 45m, and custom intervals).
- **Shuffle Button**: Manually advances that specific widget on the home screen without altering the device wallpaper.
- **Cadence & Order Toggles**: Change interval or random/sequential order from within the app using crimson radio indicators.
- **Buttons**: Styled as solid, flat buttons without gradient overlays.
- **Scrollbar**: Anchored on the right edge of the screen.

### 3.2 Widget Setup Guide (`WidgetGuideDialog`)
Provides instructions for adding Wall Tap widgets on Android launchers:
- **Step 1**: Long-press empty space on your home screen.
- **Step 2**: Select "Widgets" from the launcher menu.
- **Step 3**: Locate "Wall Tap" and choose between **Wall Tap Shuffle** (quick wallpaper change button) or **Album Display** (photo frame).
- **Step 4**: Place the widget and choose your album.

---

## 4. Interactive Wallpaper Preview Dialog

Tapping any wallpaper card in the Library or Album view opens `WallpaperPreviewDialog`:

```
+------------------------------------------+
|  [<- Back]                 [Exclude] [*] |
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

### 4.1 Zoom Mechanics
- **Pan & Pinch**: Powered by `InteractiveViewer` with `minScale: 1.0` and `maxScale: 5.0`.
- **Double-Tap Zoom**: Double-tapping the image animates directly to `2.5x` scale centered on the tap position via `Matrix4Tween` (`Curves.easeOutCubic`, 260ms duration). Double-tapping again resets to `1.0x`.
- **Single Tap**: Toggles visibility of the top header and bottom action sheet for unobstructed viewing.

### 4.2 Actions
- **"Set as Current Wallpaper"**: Crimson CTA that applies the wallpaper to the device immediately and dismisses the dialog.
- **Status Toggle**: Toggles item between Active and Excluded.
- **Delete**: Prompts confirmation dialog to delete image file and database entry.

---

## 5. Settings Tab

The Settings tab provides diagnostic controls to ensure background rotations function reliably, alongside application attribution.

### 5.1 Background Execution & Alarms
- **Battery Optimization Status**:
  - Displays green "Unrestricted" badge if Wall Tap is whitelisted from OEM battery restrictions.
  - If restricted, displays an amber warning card with a button to request exemption (`Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`).

### 5.2 Application Information
- Displays application version, developer attribution, and links to documentation.
