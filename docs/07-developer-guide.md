# 07 - Developer Setup, Build & Troubleshooting Guide

This guide covers local environment setup, running Wall Tap in debug and release modes, building Android binaries, and troubleshooting common platform issues.

---

## 1. Prerequisites & Toolchain

Ensure your development environment meets the following specifications:

- **Flutter SDK**: 3.12.2 or later (Dart 3.12.2+)
- **Java Development Kit (JDK)**: OpenJDK 17 or higher
- **Android SDK Tools**:
  - `compileSdkVersion`: 34 (Android 14)
  - `minSdkVersion`: 21 (Android 5.0 Lollipop)
  - `targetSdkVersion`: 34
  - Android SDK Build-Tools 34.0.0+
- **Recommended IDEs**:
  - VS Code with Flutter and Dart extensions
  - Android Studio with Kotlin plugin for native module work

---

## 2. Getting Started

### 2.1 Clone & Dependency Installation
```bash
# Navigate to project directory
cd wall_tap

# Fetch Flutter dependencies
flutter pub get
```

### 2.2 Verify Environment
```bash
flutter doctor -v
```
Ensure there are no blocking issues with the Android toolchain or Flutter installation.

---

## 3. Running the Application

### 3.1 On Physical Android Device (Recommended)
Because Wall Tap interacts with the physical Android system wallpaper and Home Screen AppWidgets, testing on a physical Android device provides the best validation of haptics, widget resizing, and Doze mode alarms.

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

## 4. Developing & Debugging Native Android Code

When making changes to Kotlin code under `android/app/src/main/kotlin/com/zavierdev/walltap/`:

1. Open the `android/` subfolder in **Android Studio**.
2. Allow Gradle to perform its initial project sync.
3. Use Android Studio's **Logcat** window to filter logs:
   - Filter query: `package:mine` or `tag:WallTap`
4. Set breakpoints inside `MainActivity.kt`, `WallpaperHelper.kt`, `WidgetProvider.kt`, or `Scheduler.kt`.

---

## 5. Building Release Artifacts

### 5.1 Build Release APK
```bash
flutter build apk --release
```
*Outputs to `build/app/outputs/flutter-apk/app-release.apk`.*

### 5.2 Build Release App Bundle (AAB for Google Play)
```bash
flutter build appbundle --release
```
*Outputs to `build/app/outputs/bundle/release/app-release.aab`.*

---

## 6. Common Issues & Troubleshooting

### 6.1 Wallpaper Doesn't Rotate in Background
- **Cause**: Aggressive battery saver or OEM task killer killed the background process.
- **Remedy**:
  1. Open the **Settings** tab in Wall Tap.
  2. Tap **"Request Exemption"** under Battery Optimization.
  3. Turn on the **"Persistent Status Notification"** toggle.
  4. On Xiaomi/Redmi devices (MIUI/HyperOS): Enable **"Autostart"** and set Battery Saver to **"No restrictions"** in Android app settings.

### 6.2 Widget Not Updating or Blank
- **Cause**: No images are enabled in the active playlist, or native permissions were revoked.
- **Remedy**:
  1. Verify the gallery contains at least one enabled image.
  2. In the app, open the **Studio** tab and tap **"Shuffle Next"** once to force a sync to `FlutterSharedPreferences`.
  3. Re-add the widget to the home screen.

### 6.3 Exact Alarm Exceptions on Android 12+ (API 31+)
- **Symptom**: `SecurityException: Caller not allowed to schedule exact alarms`.
- **Handling**: Wall Tap automatically catches this exception in `Scheduler.kt` and falls back to `alarmManager.setAndAllowWhileIdle()`. Users can also grant the **Alarms & Reminders** permission in device settings.

### 6.4 SAF Folder Picker Returns Empty List
- **Cause**: User selected an empty directory or a cloud drive (e.g. Google Drive) where direct file access is restricted.
- **Remedy**: Ensure the folder contains supported local images (`.jpg`, `.jpeg`, `.png`, `.webp`, `.bmp`).
