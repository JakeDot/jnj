enum GitHubItemType { issue, pullRequest }

class GitHubItem {
  final String id;
  final int number;
  final String title;
  final String state; // 'open', 'closed', 'merged'
  final GitHubItemType type;
  final String repo; // 'owner/repo'
  final String url;
  final String author;
  final String body;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  GitHubItem({
    required this.id,
    required this.number,
    required this.title,
    required this.state,
    required this.type,
    required this.repo,
    required this.url,
    required this.author,
    this.body = '',
    this.commentsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPR => type == GitHubItemType.pullRequest;
  bool get isIssue => type == GitHubItemType.issue;

  String get shortRef => '$repo#$number';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'title': title,
      'state': state,
      'type': type.name,
      'repo': repo,
      'url': url,
      'author': author,
      'body': body,
      'commentsCount': commentsCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GitHubItem.fromJson(Map<String, dynamic> json) {
    return GitHubItem(
      id: json['id'] as String? ?? '0',
      number: json['number'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      state: json['state'] as String? ?? 'open',
      type: json['type'] == 'pullRequest' || json['type'] == 'pr'
          ? GitHubItemType.pullRequest
          : GitHubItemType.issue,
      repo: json['repo'] as String? ?? '',
      url: json['url'] as String? ?? '',
      author: json['author'] as String? ?? 'unknown',
      body: json['body'] as String? ?? '',
      commentsCount: json['commentsCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory GitHubItem.fromGitHubApi(Map<String, dynamic> json, String repo, {required bool isPR}) {
    return GitHubItem(
      id: (json['id'] ?? json['number']).toString(),
      number: json['number'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      state: isPR && (json['merged'] == true)
          ? 'merged'
          : (json['state'] as String? ?? 'open'),
      type: isPR ? GitHubItemType.pullRequest : GitHubItemType.issue,
      repo: repo,
      url: json['html_url'] as String? ?? '',
      author: (json['user'] is Map) ? (json['user']['login'] as String? ?? 'unknown') : 'unknown',
      body: json['body'] as String? ?? '',
      commentsCount: json['comments'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
