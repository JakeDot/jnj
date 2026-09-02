import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/app_config.dart';
import 'package:app/models/github_item.dart';
import 'package:app/services/github_service.dart';

void main() {
  group('GitHubService Tests', () {
    late GitHubService gitHubService;

    setUp(() {
      gitHubService = GitHubService(
        config: const AppConfig(
          apiKey: 'test-key',
          defaultRepo: 'flutter/flutter',
        ),
      );
    });

    test('Parses pull request URL correctly', () {
      const url = 'https://github.com/flutter/flutter/pull/12345';
      final item = gitHubService.parseGitHubUrl(url);

      expect(item, isNotNull);
      expect(item!.number, equals(12345));
      expect(item.repo, equals('flutter/flutter'));
      expect(item.isPR, isTrue);
    });

    test('Parses issue URL correctly', () {
      const url = 'https://github.com/google/jules/issues/99';
      final item = gitHubService.parseGitHubUrl(url);

      expect(item, isNotNull);
      expect(item!.number, equals(99));
      expect(item.repo, equals('google/jules'));
      expect(item.isIssue, isTrue);
    });

    test('Parses shorthand reference owner/repo#number', () {
      const ref = 'flutter/engine#88';
      final item = gitHubService.parseGitHubUrl(ref);

      expect(item, isNotNull);
      expect(item!.number, equals(88));
      expect(item.repo, equals('flutter/engine'));
    });

    test('Parses short hash #123 with default repo', () {
      const ref = '#202';
      final item = gitHubService.parseGitHubUrl(ref);

      expect(item, isNotNull);
      expect(item!.number, equals(202));
      expect(item.repo, equals('flutter/flutter'));
    });

    test('Returns mock PRs when offline/fallback', () async {
      final prs = await gitHubService.fetchPullRequests(repo: 'flutter/flutter');
      expect(prs.isNotEmpty, isTrue);
      expect(prs.first.isPR, isTrue);
    });

    test('Returns mock Issues when offline/fallback', () async {
      final issues = await gitHubService.fetchIssues(repo: 'flutter/flutter');
      expect(issues.isNotEmpty, isTrue);
      expect(issues.first.isIssue, isTrue);
    });

    test('searchableText includes number, shorthand, title, and author in lower case', () {
      final item = GitHubItem(
        id: '1',
        number: 101,
        title: 'Fix Terminal View Layout',
        state: 'open',
        type: GitHubItemType.pullRequest,
        repo: 'flutter/flutter',
        url: 'https://github.com/flutter/flutter/pull/101',
        author: 'AlexDev',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final search = item.searchableText;
      expect(search.contains('101'), isTrue);
      expect(search.contains('#101'), isTrue);
      expect(search.contains('fix terminal view layout'), isTrue);
      expect(search.contains('alexdev'), isTrue);
    });
  });
}
