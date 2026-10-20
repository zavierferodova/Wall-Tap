# 07 - Developer Setup, Build & Troubleshooting Guide

Development environment setup, local execution, release builds, and troubleshooting steps for Wall Tap.

---

## 1. Prerequisites & Toolchain

The development environment requires:

- **Flutter SDK**: 3.12.2 or higher (Dart 3.12.2+)
- **Java Development Kit (JDK)**: OpenJDK 17 or higher
- **Android SDK Tools**:
  - `compileSdkVersion`: 34 (Android 14)
  - `minSdkVersion`: 21 (Android 5.0)
  - `targetSdkVersion`: 34
  - Android SDK Build-Tools 34.0.0+
- **Recommended Tools**:
  - VS Code with Flutter and Dart extensions
  - Android Studio with Kotlin plugin for Android native modules

---

## 2. Setup

### 2.1 Dependencies
```bash
# Navigate to project directory
cd wall_tap

# Install Flutter dependencies
flutter pub get
```

### 2.2 Verify Environment
```bash
flutter doctor -v
```
Confirm the Flutter SDK and Android toolchain report no errors.

---

## 3. Running the Application

### 3.1 On Physical Android Device (Recommended)
Testing on a physical Android device validates hardware features including real system wallpaper changes, home screen widget placement, touch haptics, and Doze mode alarms.

1. Enable **Developer Options** and **USB Debugging** on your device.
2. Connect your device via USB.
3. Run:
   ```bash
   flutter run
   ```

### 3.2 On Android Emulator
If using an emulator, create an Android Virtual Device (AVD) running **API 33 or 34** with Google Play Services.
```bash
flutter emulators --launch <emulator_name>
flutter run
```

---

## 4. Native Android Development

When editing Kotlin code in `android/app/src/main/kotlin/com/zavierdev/walltap/`:

1. Open the `android/` subfolder in Android Studio.
2. Allow Gradle to complete its initial project sync.
3. Filter logs in Android Studio's **Logcat** window:
   - Filter query: `package:mine` or `tag:WallTap`
4. Set breakpoints inside `MainActivity.kt`, `WallpaperHelper.kt`, `WidgetProvider.kt`, `AlbumWidgetProvider.kt`, or `Scheduler.kt`.

---

## 5. Building Release Artifacts

### 5.1 Build Release APK
```bash
flutter build apk --release
```
Outputs to `build/app/outputs/flutter-apk/app-release.apk`.

### 5.2 Build Release App Bundle (AAB for Google Play)
```bash
flutter build appbundle --release
```
Outputs to `build/app/outputs/bundle/release/app-release.aab`.

---

## 6. Troubleshooting

### 6.1 Wallpaper Does Not Rotate in Background
- **Cause**: Battery optimizations or OEM power managers suspended background tasks.
- **Resolution**:
  1. Open the **Settings** tab in Wall Tap.
  2. Select **"Allow Unrestricted Background Execution"** under Battery Optimization.
  3. On Xiaomi/Redmi devices (MIUI/HyperOS): Enable **"Autostart"** and set Battery Saver to **"No restrictions"** in Android app settings.

### 6.2 Widget Not Updating or Blank
- **Cause**: No images are enabled in the active playlist, or permissions were revoked.
- **Resolution**:
  1. Confirm the library contains at least one enabled image.
  2. In the app, open the **Studio** tab and tap **"Shuffle Next"** once to sync data to `FlutterSharedPreferences`.
  3. Re-add the widget to the launcher.

### 6.3 Exact Alarm Exceptions on Android 12+ (API 31+)
- **Symptom**: `SecurityException: Caller not allowed to schedule exact alarms`.
- **Handling**: Wall Tap catches this exception in `Scheduler.kt` and falls back to `alarmManager.setAndAllowWhileIdle()`. Users can also grant the **Alarms & Reminders** permission in device settings.

### 6.4 SAF Folder Picker Returns Empty List
- **Cause**: Selected folder is empty or located on a cloud drive (e.g. Google Drive) that restricts direct file access.
- **Resolution**: Select a local directory containing supported image formats (`.jpg`, `.jpeg`, `.png`, `.webp`, `.bmp`).
