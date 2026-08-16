class AppConfig {
  final String apiKey;
  final String githubToken;
  final String defaultRepo;
  final String baseUrl;
  final bool useMockMode;

  const AppConfig({
    required this.apiKey,
    this.githubToken = '',
    this.defaultRepo = 'flutter/flutter',
    this.baseUrl = 'https://api.jules.ai/v1',
    this.useMockMode = true,
  });

  static const String _envApiKey = String.fromEnvironment(
    'JULES_API_KEY',
    defaultValue: '',
  );

  AppConfig copyWith({
    String? apiKey,
    String? githubToken,
    String? defaultRepo,
    String? baseUrl,
    bool? useMockMode,
  }) {
    return AppConfig(
      apiKey: apiKey ?? this.apiKey,
      githubToken: githubToken ?? this.githubToken,
      defaultRepo: defaultRepo ?? this.defaultRepo,
      baseUrl: baseUrl ?? this.baseUrl,
      useMockMode: useMockMode ?? this.useMockMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'githubToken': githubToken,
      'defaultRepo': defaultRepo,
      'baseUrl': baseUrl,
      'useMockMode': useMockMode,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      apiKey: json['apiKey'] as String? ?? _envApiKey,
      githubToken: json['githubToken'] as String? ?? '',
      defaultRepo: json['defaultRepo'] as String? ?? 'flutter/flutter',
      baseUrl: json['baseUrl'] as String? ?? 'https://api.jules.ai/v1',
      useMockMode: json['useMockMode'] as bool? ?? true,
    );
  }

  static const AppConfig defaultConfig = AppConfig(
    apiKey: _envApiKey,
    githubToken: '',
    defaultRepo: 'flutter/flutter',
    baseUrl: 'https://api.jules.ai/v1',
    useMockMode: true,
  );
}
