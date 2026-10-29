import 'dart:js_interop';

@JS('window.AndroidBridge')
external JSObject? get androidBridge;

bool hasAndroidBridgeJs() {
  try {
    return androidBridge != null;
  } catch (_) {
    return false;
  }
}

String? callAndroidBridgeJs(String methodName, [List<dynamic>? args]) {
  try {
    if (!hasAndroidBridgeJs()) return null;
    final bridge = androidBridge;
    if (bridge == null) return null;

    if (methodName == 'getHostingMode') {
      return bridge.getHostingMode()?.toDart;
    } else if (methodName == 'getRemoteServerUrl') {
      return bridge.getRemoteServerUrl()?.toDart;
    } else if (methodName == 'getActiveUrl') {
      return bridge.getActiveUrl()?.toDart;
    } else if (methodName == 'openServerConfig') {
      bridge.openServerConfig();
      return 'true';
    } else if (methodName == 'reloadApp') {
      bridge.reloadApp();
      return 'true';
    } else if (methodName == 'showToast') {
      final msg = (args != null && args.isNotEmpty) ? args[0].toString() : '';
      bridge.showToast(msg.toJS);
      return 'true';
    }
    return null;
  } catch (_) {
    return null;
  }
}

extension AndroidBridgeExtension on JSObject {
  @JS('getHostingMode')
  external JSString? getHostingMode();

  @JS('getRemoteServerUrl')
  external JSString? getRemoteServerUrl();

  @JS('getActiveUrl')
  external JSString? getActiveUrl();

  @JS('openServerConfig')
  external void openServerConfig();

  @JS('reloadApp')
  external void reloadApp();

  @JS('showToast')
  external void showToast(JSString message);
}
