import 'package:app/services/android_wrapper_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AndroidWrapperService Tests', () {
    test('Default service returns non-wrapper mode in standard test environment', () {
      final service = AndroidWrapperService();

      expect(service.isAndroidWrapper(), isFalse);
      expect(service.getHostingMode(), equals('STANDALONE'));
      expect(service.getRemoteServerUrl(), isEmpty);
      expect(service.getActiveUrl(), isEmpty);
      expect(service.openServerConfig(), isFalse);
      expect(service.reloadApp(), isFalse);
      expect(service.showToast('Test Toast'), isFalse);
    });

    test('Injecting mock Android Wrapper handlers overrides behavior accurately', () {
      bool configOpened = false;
      bool reloaded = false;
      String? lastToastMessage;

      final service = AndroidWrapperService(
        isWrapperDetector: () => true,
        hostingModeGetter: () => 'SELF_HOSTED',
        remoteUrlGetter: () => 'http://10.0.2.2:8080',
        activeUrlGetter: () => 'https://appassets.androidplatform.net/assets/web/index.html',
        openConfigHandler: () {
          configOpened = true;
        },
        reloadAppHandler: () {
          reloaded = true;
        },
        toastHandler: (msg) {
          lastToastMessage = msg;
        },
      );

      expect(service.isAndroidWrapper(), isTrue);
      expect(service.getHostingMode(), equals('SELF_HOSTED'));
      expect(service.getRemoteServerUrl(), equals('http://10.0.2.2:8080'));
      expect(service.getActiveUrl(), equals('https://appassets.androidplatform.net/assets/web/index.html'));

      expect(service.openServerConfig(), isTrue);
      expect(configOpened, isTrue);

      expect(service.reloadApp(), isTrue);
      expect(reloaded, isTrue);

      expect(service.showToast('Hello Android Wrapper'), isTrue);
      expect(lastToastMessage, equals('Hello Android Wrapper'));
    });
  });
}
