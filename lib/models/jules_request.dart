import 'github_item.dart';

enum RequestStatus { pending, running, completed, failed }

class JulesRequest {
  final String id;
  final String prompt;
  final RequestStatus status;
  final String response;
  final List<GitHubItem> linkedGitHubItems;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<String> executionLogs;

  JulesRequest({
    required this.id,
    required this.prompt,
    required this.status,
    this.response = '',
    this.linkedGitHubItems = const [],
    required this.createdAt,
    this.completedAt,
    this.executionLogs = const [],
  });

  JulesRequest copyWith({
    String? id,
    String? prompt,
    RequestStatus? status,
    String? response,
    List<GitHubItem>? linkedGitHubItems,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? executionLogs,
  }) {
    return JulesRequest(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      status: status ?? this.status,
      response: response ?? this.response,
      linkedGitHubItems: linkedGitHubItems ?? this.linkedGitHubItems,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      executionLogs: executionLogs ?? this.executionLogs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'status': status.name,
      'response': response,
      'linkedGitHubItems': linkedGitHubItems.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'executionLogs': executionLogs,
    };
  }

  factory JulesRequest.fromJson(Map<String, dynamic> json) {
    return JulesRequest(
      id: json['id'] as String,
      prompt: json['prompt'] as String? ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      response: json['response'] as String? ?? '',
      linkedGitHubItems: (json['linkedGitHubItems'] as List<dynamic>?)
              ?.map((e) => GitHubItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      executionLogs: (json['executionLogs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
