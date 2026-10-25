# Jules Shell Terminal & Android Wrapper App

**Jules Shell** is a multi-platform Flutter application and hybrid Android Wrapper App designed for executing coding agent prompts with the **Google Jules AI API**, managing terminal workflows, linking GitHub repositories/issues, and offering **cross-platform multi-model AI consensus planning**, **Model Context Protocol (MCP) in-flight inter-model steering**, **Firebase server-side settings storage**, and **dual self-hosted offline / remote server execution** on Android.

---

## 🌟 Key Features

### 🧠 1. Cross-Platform Multi-Model AI Planning Stage & MCP In-Flight Steering
- **Cross-Platform Planning Stage**: Multi-model consensus is built in Flutter Dart code and works across **all platforms** (Windows, Web, macOS, Linux, iOS, and Android).
- **MCP (Model Context Protocol) In-Flight Steering Gateway**: Implements Anthropic's open MCP standard over JSON-RPC 2.0 (`initialize`, `tools/list`, `tools/call`, `resources/read`).
  - **`mcp_share_context`**: Models broadcast reasoning proposals and code patch snippets to peer models in real-time.
  - **`mcp_query_peer_model`**: Models query peer analyses and context during generation to eliminate manual copy-pasting.
  - **`mcp_steer_consensus`**: Security/Architectural reviewer models issue in-flight steering directives (`security_constraint`, `architectural_refinement`) to steer peer plans dynamically.
- **Participating AI Providers**:
  - **Google Jules AI Agent**: Primary Execution & Patch Agent
  - **Google Gemini 1.5 Pro**: Architectural & Structural Reviewer
  - **OpenAI GPT-4o**: Code Quality & Null-Safety Inspector
  - **Anthropic Claude 3.5 Sonnet**: Security & Edge-Case Auditor
  - **Ollama / Local Llama 3**: Self-Hosted Offline Model Synthesizer

### ☁️ 2. Split Settings & Firebase Server-Side Storage
- **Tab 1: App-Level Settings (JNJ Client Settings)**
  - Google Jules AI API Key & Base URL Configuration.
  - Multi-Model AI Consensus Stage provider selection, API key inputs, and MCP Steering toggle switch.
  - GitHub Integration & Repositories (`owner/repo`).
  - **Firebase Firestore Server-Side Storage**: Persists user-level settings on Firebase Firestore Cloud (`/user_settings/{userId}`) with real-time sync, "Sync to Firebase" and "Pull from Firebase" actions, and local `SharedPreferences` fallback.
- **Tab 2: Server & Hosting Settings**
  - Android Wrapper Hosting Mode (Self-Hosted Local vs Remote Server).
  - Remote Server Endpoint URL (GitHub Pages `https://JakeDot.github.io/jnj/` or custom server).
  - JNJ Backend Base API URL.
  - Offline / Simulation Mode toggle.

### 💻 3. Jules Shell & Terminal Engine
- **Interactive Terminal**: Run shell commands, ping Jules AI API endpoints, list active multi-model AI providers (`models`), inspect execution history, and clear logs.
- **Agent Prompting**: Submit AI coding requests and view real-time execution logs and multi-model solution plans.
- **GitHub Linkage**: Parse, link, and track GitHub PRs, issues, and repositories (`owner/repo#number`).
- **Dashboard & Analytics**: Monitor total execution counts, multi-model consensus status, API connection health, and active server configurations.

### 📱 4. Hybrid Android Wrapper App
- **Self-Hosted Local Mode (100% Offline)**: Bundles compiled Flutter web code in `android/app/src/main/assets/web/`. Serves assets locally on device using **`WebViewAssetLoader`** (`https://appassets.androidplatform.net/assets/web/index.html`) and an embedded Kotlin **`LocalWebServer`** (`http://127.0.0.1:8080/`).
- **Remote Server Mode**: Connects dynamically to any remote web server or **GitHub Pages** endpoint (`https://JakeDot.github.io/jnj/`).
- **Real-Time Health Checks & Latency Testing**: Test connection speeds and status before applying remote server settings.
- **Intelligent Auto-Fallback**: Automatically falls back to local self-hosted offline assets if the remote server becomes unreachable.
- **Native Android Bridge (`AndroidBridge`)**: JS-to-Kotlin bridge (`window.AndroidBridge`) allowing web UI to invoke native Material configuration dialogs and Android notifications.

### 🚀 5. CI/CD & GitHub Pages Automated Deployment
- GitHub Actions workflow ([`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)) automatically runs unit tests (`flutter test`), compiles Flutter Web with base-href support, and deploys to **GitHub Pages** on every push to `main` or `master`.

---

## 📂 Project Structure

```
jnj/
├── lib/                             # Flutter Dart source code
│   ├── models/                      # AppConfig, AiModelConfig, JulesRequest, ShellCommand, GitHubItem
│   ├── services/                    # McpSteeringServer, MultiModelPlanner, AiModelProvider, FirebaseSettingsService, ShellEngine, JulesApiService, StorageService
│   └── views/                       # SettingsView (App vs Server Tabs), TerminalView, DashboardView, GitHubLinkageView
├── android/                         # Android Wrapper Native Application
│   └── app/src/main/
│       ├── assets/web/              # Self-hosted bundled Flutter web assets with multi-model terminal
│       ├── kotlin/com/example/app/  # MainActivity, LocalWebServer, ServerConfigManager, AndroidBridge
│       └── res/                     # Material themes, layouts, dialogs, and menus
├── .github/workflows/               # GitHub Actions deployment workflow
│   └── deploy.yml                   # Automated build & GitHub Pages deploy
├── scripts/                         # Web asset build & synchronization scripts
│   ├── sync_flutter_web.py          # Python sync script
│   └── build_and_sync_web.sh        # Bash sync script
├── test/                            # Unit & Widget test suite
│   ├── mcp_steering_server_test.dart# Unit tests for MCP JSON-RPC 2.0 in-flight steering
│   ├── firebase_settings_service_test.dart # Unit tests for Firebase Firestore Cloud sync
│   ├── multi_model_planner_test.dart# Unit tests for multi-model consensus strategy
│   └── app_config_test.dart         # Unit tests for settings serialization & cloud properties
└── README_ANDROID_WRAPPER.md        # Detailed Android Wrapper documentation
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `>= 3.0.0 < 4.0.0`
- **Android SDK**: API Level 21+
- **Java Development Kit (JDK)**: Java 17

### 1. Running the Flutter App Locally

```bash
# Get dependencies
flutter pub get

# Run unit & widget test suite
flutter test

# Run on desktop / web / mobile
flutter run
```

### 2. Building & Running the Android Wrapper App

```bash
# Step A: Compile Flutter web and sync assets into Android wrapper
python scripts/sync_flutter_web.py

# Step B: Run the Android Wrapper App
flutter run -d android
```

---

## 🧪 Testing

Run the full automated test suite including `McpSteeringServer`, `FirebaseSettingsService`, `MultiModelPlanner`, `AppConfig`, `ShellEngine`, `GitHubService`, and `JulesApiService` tests:

```bash
flutter test
```

---

## 📄 License

This project is licensed under the MIT License.
