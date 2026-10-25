# Android Wrapper App for Jules Shell (Flutter)

An Android wrapper application capable of **self-hosting** the Flutter code locally on device (offline) or connecting to a **remote server** endpoint dynamically.

---

## 🌟 Key Features

1. **Self-Hosted Local Mode (Offline Ready)**
   - Packages Flutter Web build assets directly inside Android assets (`android/app/src/main/assets/web/`).
   - Serves local assets securely using **`WebViewAssetLoader`** (`https://appassets.androidplatform.net/assets/web/index.html`) and an embedded lightweight Android Kotlin **`LocalWebServer`** (`http://127.0.0.1:8080/`).
   - Operates completely offline with zero external network dependencies.

2. **Remote Server Configuration**
   - Configurable remote server endpoint (e.g. `http://10.0.2.2:8080` for Android Emulator, `http://192.168.x.x:8080`, or custom HTTPS URLs).
   - Real-time connection testing with latency measurement.
   - Intelligent **Auto-Fallback**: If the remote server is unreachable, the wrapper automatically falls back to local self-hosted code.

3. **Native Android Interface & Server Config Dialog**
   - Built-in Material Server Configuration Dialog accessible via the Toolbar gear icon or web bridge (`window.AndroidBridge.openServerConfig()`).
   - Host mode selector (`Self-Hosted (Local Assets)`, `Remote Server URL`, `Native Flutter Engine`).
   - Quick server presets (`10.0.2.2:8080` for Android Emulator, `127.0.0.1:8080`, custom).
   - Pull-to-refresh (`SwipeRefreshLayout`) and loading indicators.

4. **Web-to-Native JavaScript Bridge (`AndroidBridge`)**
   - Exposes `window.AndroidBridge` to web code running in WebView.
   - Query wrapper mode (`getHostingMode()`), remote URL (`getRemoteServerUrl()`), trigger config dialog (`openServerConfig()`), or show native Android toasts.

---

## 🚀 Getting Started

### 1. Build and Sync Flutter Web Code to Android Wrapper Assets

Before running the Android wrapper, compile the Flutter web application and sync assets to `android/app/src/main/assets/web/`:

```bash
# Option A: Using Python sync script
python scripts/sync_flutter_web.py

# Option B: Using Shell script
chmod +x scripts/build_and_sync_web.sh
./scripts/build_and_sync_web.sh

# Option C: Using Gradle task
cd android
./gradlew :app:syncFlutterWebAssets
```

### 2. Run the Android Wrapper App

Open the `android/` directory in Android Studio or run via Gradle/Flutter CLI:

```bash
# Run on connected Android device/emulator
flutter run -d android
```

---

## ⚙️ How to Configure Server Settings

1. Tap the **⚙️ Server Config** button in the app toolbar or in the app settings tab.
2. Choose your **Hosting Mode**:
   - **Self-Hosted (Local Assets)**: Runs bundled Flutter code directly from device storage.
   - **Remote Server**: Enter your remote web server URL (e.g., `http://10.0.2.2:8080`).
   - **Native Flutter Engine**: Renders using native FlutterActivity engine.
3. Tap **Test Connection** to check remote server availability and latency.
4. Toggle **Auto-fallback** if you want the app to switch to self-hosted mode if the remote server goes offline.
5. Tap **Save & Reload**.

---

## 📁 Architecture Overview

- `android/app/src/main/kotlin/com/example/app/`
  - `MainActivity.kt`: Main wrapper activity managing WebView, Toolbar, SwipeRefreshLayout, and FlutterActivity fallback.
  - `ServerConfigManager.kt`: SharedPreferences manager for hosting modes, remote URLs, and health checks.
  - `LocalWebServer.kt`: Lightweight embedded HTTP server (`com.sun.net.httpserver.HttpServer`) serving assets on `127.0.0.1:8080`.
  - `AndroidBridge.kt`: `@JavascriptInterface` bridge between JavaScript and native Kotlin.
  - `ServerConfigDialog.kt`: Material configuration dialog for server settings.
- `android/app/src/main/assets/web/`: Self-hosted Flutter web application runtime (`index.html`, `main.dart.js`, `styles.css`, `manifest.json`).
- `scripts/`: Synchronization tools (`sync_flutter_web.py`, `build_and_sync_web.sh`).
