import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_config.dart';
import '../models/github_item.dart';

class GitHubService {
  AppConfig _config;
  final http.Client _client;

  GitHubService({
    required AppConfig config,
    http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client();

  void updateConfig(AppConfig config) {
    _config = config;
  }

  AppConfig get config => _config;

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'Jules-Shell-App',
    };
    if (_config.githubToken.isNotEmpty) {
      headers['Authorization'] = 'token ${_config.githubToken}';
    }
    return headers;
  }

  Future<List<GitHubItem>> fetchPullRequests({String? repo}) async {
    final targetRepo = (repo != null && repo.isNotEmpty) ? repo : _config.defaultRepo;
    if (targetRepo.isEmpty) return _getDemoPullRequests('flutter/flutter');

    try {
      final uri = Uri.parse('https://api.github.com/repos/$targetRepo/pulls?state=all&per_page=15');
      final response = await _client.get(uri, headers: _buildHeaders()).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) => GitHubItem.fromGitHubApi(e as Map<String, dynamic>, targetRepo, isPR: true))
            .toList();
      }
    } catch (_) {}

    return _getDemoPullRequests(targetRepo);
  }

  Future<List<GitHubItem>> fetchIssues({String? repo}) async {
    final targetRepo = (repo != null && repo.isNotEmpty) ? repo : _config.defaultRepo;
    if (targetRepo.isEmpty) return _getDemoIssues('flutter/flutter');

    try {
      final uri = Uri.parse('https://api.github.com/repos/$targetRepo/issues?state=all&per_page=15');
      final response = await _client.get(uri, headers: _buildHeaders()).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .where((e) => (e as Map<String, dynamic>)['pull_request'] == null)
            .map((e) => GitHubItem.fromGitHubApi(e as Map<String, dynamic>, targetRepo, isPR: false))
            .toList();
      }
    } catch (_) {}

    return _getDemoIssues(targetRepo);
  }

  static final RegExp _prRegExp = RegExp(r'github\.com/([^/]+/[^/]+)/pull/(\d+)');
  static final RegExp _issueRegExp = RegExp(r'github\.com/([^/]+/[^/]+)/issues/(\d+)');
  static final RegExp _shortRefRegExp = RegExp(r'^(?:([^/]+/[^#]+))?#(\d+)$');

  GitHubItem? parseGitHubUrl(String input, {String? defaultRepo}) {
    final trimmed = input.trim();
    final repo = defaultRepo ?? _config.defaultRepo;

    var match = _prRegExp.firstMatch(trimmed);
    if (match != null) {
      final matchedRepo = match.group(1)!;
      final number = int.parse(match.group(2)!);
      return GitHubItem(
        id: 'pr_$number',
        number: number,
        title: 'Pull Request #$number ($matchedRepo)',
        state: 'open',
        type: GitHubItemType.pullRequest,
        repo: matchedRepo,
        url: trimmed,
        author: 'github-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    match = _issueRegExp.firstMatch(trimmed);
    if (match != null) {
      final matchedRepo = match.group(1)!;
      final number = int.parse(match.group(2)!);
      return GitHubItem(
        id: 'issue_$number',
        number: number,
        title: 'Issue #$number ($matchedRepo)',
        state: 'open',
        type: GitHubItemType.issue,
        repo: matchedRepo,
        url: trimmed,
        author: 'github-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    match = _shortRefRegExp.firstMatch(trimmed);
    if (match != null) {
      final matchedRepo = match.group(1) ?? repo;
      final number = int.parse(match.group(2)!);
      return GitHubItem(
        id: 'item_$number',
        number: number,
        title: 'GitHub Reference #$number ($matchedRepo)',
        state: 'open',
        type: GitHubItemType.issue,
        repo: matchedRepo,
        url: 'https://github.com/$matchedRepo/issues/$number',
        author: 'github-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return null;
  }

  List<GitHubItem> _getDemoPullRequests(String repo) {
    return [
      GitHubItem(
        id: 'pr_101',
        number: 101,
        title: 'Fix state preservation in Jules desktop view',
        state: 'open',
        type: GitHubItemType.pullRequest,
        repo: repo,
        url: 'https://github.com/$repo/pull/101',
        author: 'alex-dev',
        body: 'Improves state persistence and multi-window shell handling on Windows Desktop.',
        commentsCount: 3,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      GitHubItem(
        id: 'pr_102',
        number: 102,
        title: 'Add Android mobile shell layout and responsive gestures',
        state: 'merged',
        type: GitHubItemType.pullRequest,
        repo: repo,
        url: 'https://github.com/$repo/pull/102',
        author: 'jules-team',
        body: 'Adds touch optimized navigation bar and quick-action menu for Android app.',
        commentsCount: 8,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }

  List<GitHubItem> _getDemoIssues(String repo) {
    return [
      GitHubItem(
        id: 'issue_201',
        number: 201,
        title: 'Feature Request: Direct GitHub PR linkage in Jules prompt',
        state: 'open',
        type: GitHubItemType.issue,
        repo: repo,
        url: 'https://github.com/$repo/issues/201',
        author: 'dev-user',
        body: 'Allow selecting PRs or Issues directly to start a new Jules session without manual URL pasting.',
        commentsCount: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      GitHubItem(
        id: 'issue_202',
        number: 202,
        title: 'Bug: Terminal shell input line wrapping on Android screens',
        state: 'open',
        type: GitHubItemType.issue,
        repo: repo,
        url: 'https://github.com/$repo/issues/202',
        author: 'mobile-tester',
        body: 'When typing long commands on smaller screens, ensure auto-wrapping behaves cleanly.',
        commentsCount: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
