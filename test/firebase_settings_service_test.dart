import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/app_config.dart';
import 'package:app/services/firebase_settings_service.dart';

void main() {
  group('FirebaseSettingsService Tests', () {
    late FirebaseSettingsService firebaseService;

    setUp(() {
      firebaseService = FirebaseSettingsService();
    });

    test('Initializes with un-synced cloud status', () {
      expect(firebaseService.isCloudSynced, isFalse);
      expect(firebaseService.lastSyncedAt, isNull);
    });

    test('Saves user settings to Firebase and sets cloud status', () async {
      const config = AppConfig(
        julesApiKey: 'cloud_test_key_99',
        firebaseProjectId: 'test-project',
        firebaseUserId: 'test_user_01',
        enableCloudSync: true,
      );

      final result = await firebaseService.saveSettingsToFirebase(config: config);

      expect(result.success, isTrue);
      expect(firebaseService.isCloudSynced, isTrue);
      expect(firebaseService.lastSyncedAt, isNotNull);
    });
  });
}
