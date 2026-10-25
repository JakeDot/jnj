import 'ai_model_config.dart';

class AppConfig {
  final String julesApiKey;
  final String julesBaseUrl;
  final String githubToken;
  final String defaultRepo;
  final bool useMockMode;
  final String remoteServerUrl;
  final bool isSelfHosted;
  final bool enableMultiModelPlanning;
  final bool enableMcpInFlightSteering;
  final List<AiModelConfig> multiModelProviders;
  final String firebaseProjectId;
  final String firebaseUserId;
  final bool enableCloudSync;

  const AppConfig({
    this.julesApiKey = '',
    this.julesBaseUrl = 'https://api.jules.ai/v1',
    this.githubToken = '',
    this.defaultRepo = 'flutter/flutter',
    this.useMockMode = true,
    this.remoteServerUrl = 'http://10.0.2.2:8080',
    this.isSelfHosted = true,
    this.enableMultiModelPlanning = true,
    this.enableMcpInFlightSteering = true,
    this.multiModelProviders = const [],
    this.firebaseProjectId = 'jnj-jules-shell',
    this.firebaseUserId = 'default_user',
    this.enableCloudSync = true,
  });

  // Backward-compatible getters for legacy references
  String get apiKey => julesApiKey;
  String get baseUrl => julesBaseUrl;

  static const String _envApiKey = String.fromEnvironment(
    'JULES_API_KEY',
    defaultValue: '',
  );

  AppConfig copyWith({
    String? julesApiKey,
    String? julesBaseUrl,
    String? apiKey,
    String? baseUrl,
    String? githubToken,
    String? defaultRepo,
    bool? useMockMode,
    String? remoteServerUrl,
    bool? isSelfHosted,
    bool? enableMultiModelPlanning,
    bool? enableMcpInFlightSteering,
    List<AiModelConfig>? multiModelProviders,
    String? firebaseProjectId,
    String? firebaseUserId,
    bool? enableCloudSync,
  }) {
    final effectiveJulesKey = julesApiKey ?? apiKey ?? this.julesApiKey;
    final effectiveJulesUrl = julesBaseUrl ?? baseUrl ?? this.julesBaseUrl;

    return AppConfig(
      julesApiKey: effectiveJulesKey,
      julesBaseUrl: effectiveJulesUrl,
      githubToken: githubToken ?? this.githubToken,
      defaultRepo: defaultRepo ?? this.defaultRepo,
      useMockMode: useMockMode ?? this.useMockMode,
      remoteServerUrl: remoteServerUrl ?? this.remoteServerUrl,
      isSelfHosted: isSelfHosted ?? this.isSelfHosted,
      enableMultiModelPlanning: enableMultiModelPlanning ?? this.enableMultiModelPlanning,
      enableMcpInFlightSteering: enableMcpInFlightSteering ?? this.enableMcpInFlightSteering,
      multiModelProviders: multiModelProviders ?? this.multiModelProviders,
      firebaseProjectId: firebaseProjectId ?? this.firebaseProjectId,
      firebaseUserId: firebaseUserId ?? this.firebaseUserId,
      enableCloudSync: enableCloudSync ?? this.enableCloudSync,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'julesApiKey': julesApiKey,
      'julesBaseUrl': julesBaseUrl,
      'apiKey': julesApiKey, // legacy key sync
      'baseUrl': julesBaseUrl,
      'githubToken': githubToken,
      'defaultRepo': defaultRepo,
      'useMockMode': useMockMode,
      'remoteServerUrl': remoteServerUrl,
      'isSelfHosted': isSelfHosted,
      'enableMultiModelPlanning': enableMultiModelPlanning,
      'enableMcpInFlightSteering': enableMcpInFlightSteering,
      'multiModelProviders': multiModelProviders.map((e) => e.toJson()).toList(),
      'firebaseProjectId': firebaseProjectId,
      'firebaseUserId': firebaseUserId,
      'enableCloudSync': enableCloudSync,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final rawJulesKey = json['julesApiKey'] as String? ?? json['apiKey'] as String? ?? _envApiKey;
    final rawJulesUrl = json['julesBaseUrl'] as String? ?? json['baseUrl'] as String? ?? 'https://api.jules.ai/v1';

    final rawProviders = json['multiModelProviders'] as List<dynamic>?;
    final providers = rawProviders != null && rawProviders.isNotEmpty
        ? rawProviders.map((e) => AiModelConfig.fromJson(e as Map<String, dynamic>)).toList()
        : AiModelConfig.defaultProviders(julesKey: rawJulesKey);

    return AppConfig(
      julesApiKey: rawJulesKey,
      julesBaseUrl: rawJulesUrl,
      githubToken: json['githubToken'] as String? ?? '',
      defaultRepo: json['defaultRepo'] as String? ?? 'flutter/flutter',
      useMockMode: json['useMockMode'] as bool? ?? true,
      remoteServerUrl: json['remoteServerUrl'] as String? ?? 'http://10.0.2.2:8080',
      isSelfHosted: json['isSelfHosted'] as bool? ?? true,
      enableMultiModelPlanning: json['enableMultiModelPlanning'] as bool? ?? true,
      enableMcpInFlightSteering: json['enableMcpInFlightSteering'] as bool? ?? true,
      multiModelProviders: providers,
      firebaseProjectId: json['firebaseProjectId'] as String? ?? 'jnj-jules-shell',
      firebaseUserId: json['firebaseUserId'] as String? ?? 'default_user',
      enableCloudSync: json['enableCloudSync'] as bool? ?? true,
    );
  }

  static final AppConfig defaultConfig = AppConfig(
    julesApiKey: _envApiKey,
    julesBaseUrl: 'https://api.jules.ai/v1',
    githubToken: '',
    defaultRepo: 'flutter/flutter',
    useMockMode: true,
    remoteServerUrl: 'http://10.0.2.2:8080',
    isSelfHosted: true,
    enableMultiModelPlanning: true,
    enableMcpInFlightSteering: true,
    multiModelProviders: AiModelConfig.defaultProviders(julesKey: _envApiKey),
    firebaseProjectId: 'jnj-jules-shell',
    firebaseUserId: 'default_user',
    enableCloudSync: true,
  );
}
