# 02 - Android Native Integration & Kotlin Architecture

Implementation details for the Android native layer of Wall Tap, located in `android/app/src/main/kotlin/com/zavierdev/walltap/`.

---

## 1. Native Component Overview

The Android native implementation consists of helper objects, broadcast receivers, widget providers, and activities:

| Component | Type | Responsibility |
| :--- | :--- | :--- |
| `MainActivity.kt` | `FlutterActivity` | Host activity, Flutter engine caching, `MethodChannel` dispatch, and SAF folder picker result handling. |
| `WallpaperHelper.kt` | Singleton Object | Display dimension detection, sampled bitmap decoding, aspect ratio scaling (`crop`/`fit`/`full`), and `WallpaperManager` invocation. |
| `WidgetProvider.kt` | `AppWidgetProvider` | Main Wall Tap Shuffle widget provider (`walltap_widget.xml`) managing upcoming wallpaper previews and quick action buttons. |
| `AlbumWidgetProvider.kt` | `AppWidgetProvider` | Album Display widget provider (`album_widget.xml`) with dynamic controls overlay for manual photo flipping and settings. |
| `AlbumWidgetConfigureActivity.kt` | `Activity` | Native configuration activity launched when placing an Album Widget to select target album, rotation interval, and order. |
| `Scheduler.kt` | Singleton Object | Exact alarm scheduler for global wallpaper rotation via `AlarmManager`. |
| `AlbumWidgetScheduler.kt` | Singleton Object | Exact alarm scheduler for individual Album Widgets. |
| `AlarmReceiver.kt` | `BroadcastReceiver` | Receives global rotation alarm ticks, advances wallpaper, and schedules the next tick. |
| `AlbumWidgetReceiver.kt` | `BroadcastReceiver` | Receives individual album widget alarm ticks and advances the widget image. |
| `BootReceiver.kt` | `BroadcastReceiver` | Restores alarms and widget schedules after device restarts (`BOOT_COMPLETED`). |

---

## 2. System Wallpaper Management (`WallpaperHelper.kt`)

Setting wallpapers on Android requires direct interaction with `android.app.WallpaperManager`.

### 2.1 Multi-Screen Flag Resolution
Wall Tap targets the Home screen, Lock screen, or both simultaneously:

```kotlin
val flags = when (targetScreen.lowercase()) {
    "home", "homescreen" -> WallpaperManager.FLAG_SYSTEM
    "lock", "lockscreen" -> WallpaperManager.FLAG_LOCK
    else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
}
wallpaperManager.setBitmap(scaledBitmap, null, true, flags)
```

> [!NOTE]
> `WallpaperManager.FLAG_LOCK` was introduced in Android 7.0 (API 24). On older versions or ROMs where lock screen setting is restricted by OEM policies, calls apply globally to the system wallpaper.

### 2.2 Display Metrics Detection
To scale wallpapers accurately without clipping, `WallpaperHelper.getDisplayDimensions` handles API level differences:
- **Android 11+ (API 30+)**: Uses `WindowManager.currentWindowMetrics.bounds` to retrieve physical display boundaries.
- **Legacy Android**: Uses `DisplayMetrics.getRealMetrics` to include navigation and status bar dimensions.

### 2.3 Sampled Bitmap Decoding
Loading 4K or 8K images into memory can trigger an `OutOfMemoryError` (OOM). Wall Tap uses `decodeSampledBitmapFromFile` to compute an optimal `inSampleSize` before allocating full pixel buffers:

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
`scaleBitmap` supports three user-selected scale modes:
1. **`crop` (Center Crop)**: Preserves image aspect ratio by scaling until both width and height cover the screen, centering the result and cropping excess edges.
2. **`fit` (Fit with Letterbox)**: Scales the image so its entire frame is visible within the screen bounds, drawing black letterbox bars on a blank canvas (`Color.BLACK`) where necessary.
3. **`full` (Full Stretch)**: Stretches the image to match screen width and height directly (`Bitmap.createScaledBitmap`).

Source and intermediate bitmaps are explicitly recycled (`bitmap.recycle()`) to free native memory.

---

## 3. Home Screen AppWidgets

Wall Tap provides two home screen widgets defined in `res/xml/` and `res/layout/`:

### 3.1 Wall Tap Shuffle Widget (`WidgetProvider.kt`)
- **Layout**: `res/layout/walltap_widget.xml`
- **Metadata**: `res/xml/walltap_widget_info.xml`
- **Features**:
  - Displays a 300x480 thumbnail preview of the upcoming wallpaper.
  - Displays a red `NEXT` badge over the preview.
  - **Settings Button (`R.id.btn_widget_settings`)**: Opens `MainActivity`.
  - **Next / Shuffle Button (`R.id.btn_widget_next`)**: Sends `ACTION_NEXT` broadcast to apply the previewed wallpaper to the device and calculate the subsequent index.
  - Executes image transition animations during updates.

### 3.2 Album Display Widget (`AlbumWidgetProvider.kt`)
- **Layout**: `res/layout/album_widget.xml`
- **Metadata**: `res/xml/album_widget_info.xml`
- **Features**:
  - Displays high-resolution photos selected from a specific album or all photos.
  - **Interactive Controls (`R.id.widget_album_controls_container`)**: Tapping the widget image toggles visibility of on-widget controls (`ACTION_TOGGLE_CONTROLS`).
  - **Settings Button (`R.id.btn_album_widget_settings`)**: Opens `AlbumWidgetConfigureActivity`.
  - **Next / Shuffle Button (`R.id.btn_album_widget_next`)**: Sends `ACTION_NEXT_ALBUM_IMAGE` broadcast to advance to the next photo in the configured album based on sequential or random order settings.
  - Executes transition animations on image change.
  - **Empty State**: Displays an empty placeholder prompting the user to tap and configure when an album has no photos.

### 3.3 Widget Configuration Activity (`AlbumWidgetConfigureActivity.kt`)
When adding an Album Display Widget to the launcher:
1. Android starts `AlbumWidgetConfigureActivity` with `AppWidgetManager.EXTRA_APPWIDGET_ID`.
2. The activity reads available albums from `FlutterSharedPreferences` (`flutter.walltap_albums`).
3. The user configures:
   - Target Album (dropdown selection)
   - Rotation Interval (1m, 3m, 5m, 10m, 15m, 30m, 45m, 1h, 3h, 6h, 12h, 24h, or Manual)
   - Order (Random shuffle or Sequential)
4. Tapping "Save & Add Widget" writes configuration keys (`flutter.album_widget_<id>_*`), starts `AlbumWidgetScheduler`, calls `updateWidget()`, and finishes with `RESULT_OK`.

---

## 4. Background Execution & Alarm Scheduling

Standard `WorkManager` tasks cannot execute on exact intervals under 15 minutes and batch jobs during Doze mode. Wall Tap uses `AlarmManager` with exact wakeup alarms to maintain exact timing.

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
        // Fallback for Android 12+ if exact alarm permission is not granted
        alarmManager.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerAtMillis,
            pendingIntent
        )
    }
}
```

### 4.2 Reboot Recovery (`BootReceiver.kt`)
Alarms scheduled with `AlarmManager` reset when a device restarts. `BootReceiver` listens for:
- `android.intent.action.BOOT_COMPLETED`
- `android.intent.action.QUICKBOOT_POWERON`

On reboot, it reads saved preferences for active wallpaper slideshows and album widgets, rescheduling their timers.

---

## 5. Storage Access Framework (SAF) Folder Picker

To import directories of wallpapers without requesting broad external storage permissions on Android 11+ (API 30+), `MainActivity` uses `ACTION_OPEN_DOCUMENT_TREE`:

1. `pickFolderAndGetImages` fires `Intent.ACTION_OPEN_DOCUMENT_TREE`.
2. User chooses a folder in Android's document picker.
3. `MainActivity.onActivityResult` receives the directory `treeUri`.
4. Persistable permission is acquired:
   ```kotlin
   contentResolver.takePersistableUriPermission(treeUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
   ```
5. A background worker inspects the `DocumentFile` without recursion and copies matching images (`.jpg`, `.jpeg`, `.png`, `.webp`, `.bmp`) to the cache folder (`picked_folder_images/`).
6. Copied paths return to Flutter via `pendingFolderResult.success(copiedPaths)`.

---

## 6. Permissions & Manifest Declarations

Permissions declared in `AndroidManifest.xml`:

| Permission | Purpose |
| :--- | :--- |
| `SET_WALLPAPER` | Required to apply device wallpapers via `WallpaperManager`. |
| `READ_MEDIA_IMAGES` | Media image access on Android 13+ (API 33+). |
| `READ_EXTERNAL_STORAGE` | Storage access for Android 12 and lower (`maxSdkVersion="32"`). |
| `RECEIVE_BOOT_COMPLETED` | Allows `BootReceiver` to restore alarms after device restart. |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Prompts user to disable battery restrictions for background rotations. |
| `SCHEDULE_EXACT_ALARM` | Permits scheduling exact wake-up alarms on Android 12+ (API 31+). |
