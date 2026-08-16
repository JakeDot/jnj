import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/app_config.dart';
import 'package:app/models/github_item.dart';
import 'package:app/models/jules_request.dart';
import 'package:app/services/jules_api_service.dart';

void main() {
  group('JulesApiService Tests', () {
    late JulesApiService apiService;

    setUp(() {
      apiService = JulesApiService(
        config: const AppConfig(
          apiKey: 'mock_jules_api_key',
          useMockMode: true,
        ),
      );
    });

    test('Sends request and returns completed JulesRequest', () async {
      final request = await apiService.sendRequest(prompt: 'Fix issue in shell input');

      expect(request.prompt, equals('Fix issue in shell input'));
      expect(request.status, equals(RequestStatus.completed));
      expect(request.response, contains('Automated Solution Plan'));
      expect(request.executionLogs.isNotEmpty, isTrue);
    });

    test('Supports attaching linked GitHub items to request', () async {
      final item = GitHubItem(
        id: '123',
        number: 42,
        title: 'Fix issue in terminal keyboard',
        state: 'open',
        type: GitHubItemType.issue,
        repo: 'flutter/flutter',
        url: 'https://github.com/flutter/flutter/issues/42',
        author: 'jules-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final request = await apiService.sendRequest(
        prompt: 'Analyze bug',
        linkedItems: [item],
      );

      expect(request.linkedGitHubItems.length, equals(1));
      expect(request.linkedGitHubItems.first.number, equals(42));
      expect(request.response, contains('flutter/flutter#42'));
    });

    test('Updates app config successfully', () {
      final newConfig = apiService.config.copyWith(apiKey: 'new_secret_key');
      apiService.updateConfig(newConfig);

      expect(apiService.config.apiKey, equals('new_secret_key'));
    });
  });
}
