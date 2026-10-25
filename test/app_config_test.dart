import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('Default AppConfig values are correct', () {
      const config = AppConfig.defaultConfig;

      expect(config.defaultRepo, equals('flutter/flutter'));
      expect(config.baseUrl, equals('https://api.jules.ai/v1'));
      expect(config.useMockMode, isTrue);
      expect(config.remoteServerUrl, equals('http://10.0.2.2:8080'));
      expect(config.isSelfHosted, isTrue);
    });

    test('copyWith updates properties correctly', () {
      const config = AppConfig.defaultConfig;
      final updated = config.copyWith(
        apiKey: 'test_key',
        remoteServerUrl: 'https://jules.example.com',
        isSelfHosted: false,
      );

      expect(updated.apiKey, equals('test_key'));
      expect(updated.remoteServerUrl, equals('https://jules.example.com'));
      expect(updated.isSelfHosted, isFalse);
      expect(updated.defaultRepo, equals('flutter/flutter'));
    });

    test('toJson and fromJson preserve values', () {
      const config = AppConfig(
        apiKey: 'secret_123',
        githubToken: 'ghp_abc',
        defaultRepo: 'owner/repo',
        baseUrl: 'https://custom.api/v1',
        useMockMode: false,
        remoteServerUrl: 'http://192.168.1.50:8080',
        isSelfHosted: false,
      );

      final json = config.toJson();
      final restored = AppConfig.fromJson(json);

      expect(restored.apiKey, equals('secret_123'));
      expect(restored.githubToken, equals('ghp_abc'));
      expect(restored.defaultRepo, equals('owner/repo'));
      expect(restored.baseUrl, equals('https://custom.api/v1'));
      expect(restored.useMockMode, isFalse);
      expect(restored.remoteServerUrl, equals('http://192.168.1.50:8080'));
      expect(restored.isSelfHosted, isFalse);
    });
  });
}
