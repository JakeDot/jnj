import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/app_config.dart';
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

    test('matchesSearch performs cached case-insensitive lookup for title, number, author, and repo ref', () {
      final item = gitHubService.parseGitHubUrl('https://github.com/flutter/flutter/pull/12345')!;
      expect(item.matchesSearch('12345'), isTrue);
      expect(item.matchesSearch('flutter/flutter'), isTrue);
      expect(item.matchesSearch('PULL REQUEST'), isTrue);
      expect(item.matchesSearch('nonexistent'), isFalse);
    });
  });
}
