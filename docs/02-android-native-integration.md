# 02 - Android Native Integration & Kotlin Architecture

This document provides a comprehensive deep dive into the native Android layer of Wall Tap. It details the Kotlin codebase located at `android/app/src/main/kotlin/com/zavierdev/walltap/`, Android Manifest permissions, system wallpaper interactions, AppWidgets, alarm schedulers, and memory-safe image processing.

---

## 1. Native Component Overview

The Android native implementation is organized into dedicated helper objects, broadcast receivers, widget providers, and activities:

| Component | Type | Responsibility |
| :--- | :--- | :--- |
| `MainActivity.kt` | `FlutterActivity` | Host activity, engine caching, `MethodChannel` dispatch, and SAF folder picker result handling. |
| `WallpaperHelper.kt` | Singleton Object | Display dimension detection, sampled bitmap decoding, aspect ratio scaling (`crop`/`fit`/`full`), and `WallpaperManager` invocation. |
| `WidgetProvider.kt` | `AppWidgetProvider` | Main Wall Tap Shuffle widget provider (`walltap_widget.xml`) managing next wallpaper preview and quick action buttons. |
| `AlbumWidgetProvider.kt` | `AppWidgetProvider` | Album Display widget provider (`album_widget.xml`) with dynamic controls overlay for manual photo flipping and settings. |
| `AlbumWidgetConfigureActivity.kt` | `Activity` | Native configuration activity launched when placing an Album Widget to select target album and rotation cadence. |
| `Scheduler.kt` | Singleton Object | Exact alarm scheduler for global wallpaper rotation via `AlarmManager`. |
| `AlbumWidgetScheduler.kt` | Singleton Object | Exact alarm scheduler for individual Album Widgets. |
| `AlarmReceiver.kt` | `BroadcastReceiver` | Receives global rotation alarm ticks, advances wallpaper, and schedules the next tick. |
| `AlbumWidgetReceiver.kt` | `BroadcastReceiver` | Receives individual album widget alarm ticks and advances the widget image. |
| `BootReceiver.kt` | `BroadcastReceiver` | Restores alarms and widget schedules after device restarts (`BOOT_COMPLETED`). |

---

## 2. System Wallpaper Management (`WallpaperHelper.kt`)

Setting wallpapers on Android requires direct interaction with `android.app.WallpaperManager`.

### 2.1 Multi-Screen Flag Resolution
Wall Tap supports targeting the Home screen, Lock screen, or both simultaneously:

```kotlin
val flags = when (targetScreen.lowercase()) {
    "home", "homescreen" -> WallpaperManager.FLAG_SYSTEM
    "lock", "lockscreen" -> WallpaperManager.FLAG_LOCK
    else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
}
wallpaperManager.setBitmap(scaledBitmap, null, true, flags)
```

> [!NOTE]
> `WallpaperManager.FLAG_LOCK` was introduced in Android 7.0 (API 24). On devices prior to API 24 or ROMs where lock screen setting is restricted by OEM security policies, the call applies globally to the system wallpaper.

### 2.2 Accurate Display Metrics Detection
To scale wallpapers accurately without unwanted cropping, `WallpaperHelper.getDisplayDimensions` handles API level variations:
- **Android 11+ (API 30+)**: Uses `WindowManager.currentWindowMetrics.bounds` to retrieve physical display boundaries.
- **Legacy Android**: Falls back to `DisplayMetrics.getRealMetrics` to include navigation and status bar cutouts.

### 2.3 Memory-Safe Sampled Bitmap Decoding
Loading 4K or 8K wallpaper images directly into memory can cause an `OutOfMemoryError` (OOM). Wall Tap uses `decodeSampledBitmapFromFile` to compute an optimal `inSampleSize` before allocating full pixel buffers:

```kotlin
fun decodeSampledBitmapFromFile(
    path: String,
    reqWidth: Int,
    reqHeight: Int,
    config: Bitmap.Config = Bitmap.Config.ARGB_8888
): Bitmap? {
    val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(path, options)

    var inSampleSize = 1
    val height = options.outHeight
    val width = options.outWidth

    if (height > reqHeight || width > reqWidth) {
        val halfHeight = height / 2
        val halfWidth = width / 2
        while ((halfHeight / inSampleSize) >= reqHeight && (halfWidth / inSampleSize) >= reqWidth) {
            inSampleSize *= 2
        }
    }

    val decodeOptions = BitmapFactory.Options().apply {
        this.inSampleSize = inSampleSize
        inPreferredConfig = config
    }
    return BitmapFactory.decodeFile(path, decodeOptions)
}
```

### 2.4 Scaling Algorithms
`scaleBitmap` supports three distinct user-selectable scale modes:
1. **`crop` / Center Crop**: Preserves image aspect ratio by scaling until both width and height cover the screen, then centers and crops the overflow.
2. **`fit` / Fit with Letterbox**: Scales the image so its entire frame is visible within the screen bounds, drawing letterbox black bars on a blank canvas (`Color.BLACK`) above and below (or on sides).
3. **`full` / Full Stretch**: Stretches the image to exactly match the screen width and height (`Bitmap.createScaledBitmap`).

All intermediate and source bitmaps are explicitly recycled (`bitmap.recycle()`) to free native graphics memory immediately.

---

## 3. Home Screen AppWidgets

Wall Tap provides two distinct home screen widgets defined in `res/xml/` and `res/layout/`:

### 3.1 Wall Tap Shuffle Widget (`WidgetProvider.kt`)
- **Layout**: `res/layout/walltap_widget.xml`
- **Metadata**: `res/xml/walltap_widget_info.xml`
- **Features**:
  - Displays a 300x480 thumbnail preview of the **upcoming** wallpaper.
  - Displays a red `NEXT` badge over the preview.
  - **Settings Button (`R.id.btn_widget_settings`)**: Launches `MainActivity` directly to the app.
  - **Next / Shuffle Button (`R.id.btn_widget_next`)**: Fires `ACTION_NEXT` broadcast to apply the previewed upcoming wallpaper to the device, then pre-calculates the next upcoming wallpaper based on ordered or random shuffle settings.

### 3.2 Album Display Widget (`AlbumWidgetProvider.kt`)
- **Layout**: `res/layout/album_widget.xml`
- **Metadata**: `res/xml/album_widget_info.xml`
- **Features**:
  - Displays high-resolution active photos currently selected from a specific chosen album or "All Photos" (displays the active photo from randomize or ordered section).
  - **Interactive Controls Overlay (`R.id.widget_album_controls_container`)**: Tapping the widget image toggles the visibility of on-screen controls (`ACTION_TOGGLE_CONTROLS`).
  - **Settings Button (`R.id.btn_album_widget_settings`)**: Opens `AlbumWidgetConfigureActivity`.
  - **Next / Shuffle Button (`R.id.btn_album_widget_next`)**: Fires `ACTION_NEXT_ALBUM_IMAGE` broadcast to advance or shuffle to the next photo in the configured album based on the widget's random or ordered setting.
  - **Empty State**: If an album has no photos, displays an empty container with a prompt to tap and reconfigure.

### 3.3 Widget Configuration Activity (`AlbumWidgetConfigureActivity.kt`)
When a user adds an Album Display Widget to their home screen:
1. Android launches `AlbumWidgetConfigureActivity` with `AppWidgetManager.EXTRA_APPWIDGET_ID`.
2. The activity loads available albums from `FlutterSharedPreferences` (`flutter.walltap_albums`).
3. The user selects:
   - Target Album (dropdown spinner)
   - Rotation Interval (1 min, 5 min, 15 min, 30 min, 1 hr, 3 hr, 6 hr, 12 hr, 24 hr, or Manual)
   - Order (Random shuffle or Sequential)
4. Tapping "Save & Add Widget" writes configuration keys (`flutter.album_widget_<id>_*`), starts `AlbumWidgetScheduler`, calls `updateWidget()`, and finishes with `RESULT_OK`.

---

## 4. Background Execution & Alarm Scheduling

Standard Android `WorkManager` cannot guarantee exact execution intervals below 15 minutes and is subject to Doze mode batching. Wall Tap utilizes `AlarmManager` with exact wakeup alarms for predictable cadence.

### 4.1 Exact Alarms (`Scheduler.kt`)
```kotlin
val triggerAtMillis = System.currentTimeMillis() + (intervalMinutes * 60 * 1000L)

if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    try {
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerAtMillis,
            pendingIntent
        )
    } catch (e: SecurityException) {
        // Fallback for Android 12+ if exact alarm permission is denied
        alarmManager.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerAtMillis,
            pendingIntent
        )
    }
}
```

### 4.2 Boot Recovery (`BootReceiver.kt`)
Because alarms scheduled with `AlarmManager` are cleared when a device shuts down or reboots, `BootReceiver` listens for:
- `android.intent.action.BOOT_COMPLETED`
- `android.intent.action.QUICKBOOT_POWERON`

On reboot, it inspects saved preferences for active wallpaper slideshows and album widgets, immediately restoring their scheduled alarms.

---

## 5. Storage Access Framework (SAF) Folder Picker

To import directories of wallpapers without requiring invasive broad external storage permissions on Android 11+ (API 30+), `MainActivity` implements `ACTION_OPEN_DOCUMENT_TREE`:

1. `pickFolderAndGetImages` triggers `Intent.ACTION_OPEN_DOCUMENT_TREE`.
2. User selects a folder in Android's system document picker.
3. `MainActivity.onActivityResult` receives the directory `treeUri`.
4. Persistable permission is taken:
   ```kotlin
   contentResolver.takePersistableUriPermission(treeUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
   ```
5. A background thread scans the selected `DocumentFile` without recursion (top-level images only) and copies matching images (`.jpg`, `.jpeg`, `.png`, `.webp`, `.bmp`) to the internal cache directory (`picked_folder_images/`).
6. Copied file paths are returned to Flutter via `pendingFolderResult.success(copiedPaths)`.

---

## 6. Permissions & Manifest Declarations

Wall Tap declares the following permissions in `AndroidManifest.xml`:

| Permission | Purpose |
| :--- | :--- |
| `SET_WALLPAPER` | Required to set the device wallpaper via `WallpaperManager`. |
| `READ_MEDIA_IMAGES` | Granular media image access on Android 13+ (API 33+). |
| `READ_EXTERNAL_STORAGE` | Storage access for Android 12 and below (`maxSdkVersion="32"`). |
| `RECEIVE_BOOT_COMPLETED` | Allows `BootReceiver` to restore wallpaper and widget alarms after device reboot. |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`| Allows prompting user to disable battery restrictions for uninterrupted rotation. |
| `SCHEDULE_EXACT_ALARM` | Permits setting exact wake-up alarms on Android 12+ (API 31+). |
