import 'package:flutter/foundation.dart';

import 'android_wrapper_js.dart';

/// Cross-platform service that interfaces with the Native Android Wrapper JS Bridge (`window.AndroidBridge`).
class AndroidWrapperService {
  final bool Function()? _isWrapperDetector;
  final String Function()? _hostingModeGetter;
  final String Function()? _remoteUrlGetter;
  final String Function()? _activeUrlGetter;
  final VoidCallback? _openConfigHandler;
  final VoidCallback? _reloadAppHandler;
  final void Function(String message)? _toastHandler;

  AndroidWrapperService({
    bool Function()? isWrapperDetector,
    String Function()? hostingModeGetter,
    String Function()? remoteUrlGetter,
    String Function()? activeUrlGetter,
    VoidCallback? openConfigHandler,
    VoidCallback? reloadAppHandler,
    void Function(String message)? toastHandler,
  })  : _isWrapperDetector = isWrapperDetector,
        _hostingModeGetter = hostingModeGetter,
        _remoteUrlGetter = remoteUrlGetter,
        _activeUrlGetter = activeUrlGetter,
        _openConfigHandler = openConfigHandler,
        _reloadAppHandler = reloadAppHandler,
        _toastHandler = toastHandler;

  /// Detects whether the app is running inside the Android Wrapper WebView.
  bool isAndroidWrapper() {
    if (_isWrapperDetector != null) {
      return _isWrapperDetector!();
    }
    return hasAndroidBridgeJs();
  }

  /// Returns the active hosting mode from Android Wrapper (e.g. SELF_HOSTED, REMOTE_SERVER, NATIVE_FLUTTER).
  String getHostingMode() {
    if (_hostingModeGetter != null) {
      return _hostingModeGetter!();
    }
    if (!isAndroidWrapper()) return 'STANDALONE';
    final mode = callAndroidBridgeJs('getHostingMode');
    return mode ?? 'SELF_HOSTED';
  }

  /// Returns the remote server URL configured in Android Wrapper.
  String getRemoteServerUrl() {
    if (_remoteUrlGetter != null) {
      return _remoteUrlGetter!();
    }
    if (!isAndroidWrapper()) return '';
    final url = callAndroidBridgeJs('getRemoteServerUrl');
    return url ?? 'http://10.0.2.2:8080';
  }

  /// Returns the active URL being served by Android Wrapper.
  String getActiveUrl() {
    if (_activeUrlGetter != null) {
      return _activeUrlGetter!();
    }
    if (!isAndroidWrapper()) return '';
    final active = callAndroidBridgeJs('getActiveUrl');
    return active ?? 'https://appassets.androidplatform.net/assets/web/index.html';
  }

  /// Triggers the native Android Material Server Configuration dialog.
  bool openServerConfig() {
    if (_openConfigHandler != null) {
      _openConfigHandler!();
      return true;
    }
    if (!isAndroidWrapper()) return false;
    callAndroidBridgeJs('openServerConfig');
    return true;
  }

  /// Requests the Android Wrapper to reload the WebView.
  bool reloadApp() {
    if (_reloadAppHandler != null) {
      _reloadAppHandler!();
      return true;
    }
    if (!isAndroidWrapper()) return false;
    callAndroidBridgeJs('reloadApp');
    return true;
  }

  /// Displays a native Android toast message.
  bool showToast(String message) {
    if (_toastHandler != null) {
      _toastHandler!(message);
      return true;
    }
    if (!isAndroidWrapper()) return false;
    callAndroidBridgeJs('showToast', [message]);
    return true;
  }
}
