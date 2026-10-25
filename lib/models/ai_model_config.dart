enum AiProviderType {
  googleJules,
  gemini,
  openAi,
  anthropic,
  localOllama,
  custom,
}

class AiModelConfig {
  final String id;
  final String name;
  final AiProviderType type;
  final String apiKey;
  final String endpoint;
  final String modelName;
  final String role;
  final bool isEnabled;
  final double weight;

  const AiModelConfig({
    required this.id,
    required this.name,
    required this.type,
    this.apiKey = '',
    this.endpoint = '',
    this.modelName = '',
    this.role = 'Collaborative Reviewer',
    this.isEnabled = true,
    this.weight = 1.0,
  });

  AiModelConfig copyWith({
    String? id,
    String? name,
    AiProviderType? type,
    String? apiKey,
    String? endpoint,
    String? modelName,
    String? role,
    bool? isEnabled,
    double? weight,
  }) {
    return AiModelConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      apiKey: apiKey ?? this.apiKey,
      endpoint: endpoint ?? this.endpoint,
      modelName: modelName ?? this.modelName,
      role: role ?? this.role,
      isEnabled: isEnabled ?? this.isEnabled,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'apiKey': apiKey,
      'endpoint': endpoint,
      'modelName': modelName,
      'role': role,
      'isEnabled': isEnabled,
      'weight': weight,
    };
  }

  factory AiModelConfig.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'custom';
    final type = AiProviderType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => AiProviderType.custom,
    );

    return AiModelConfig(
      id: json['id'] as String? ?? 'provider_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Custom AI Model',
      type: type,
      apiKey: json['apiKey'] as String? ?? '',
      endpoint: json['endpoint'] as String? ?? '',
      modelName: json['modelName'] as String? ?? '',
      role: json['role'] as String? ?? 'Collaborative Reviewer',
      isEnabled: json['isEnabled'] as bool? ?? true,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  static List<AiModelConfig> defaultProviders({String julesKey = ''}) {
    return [
      AiModelConfig(
        id: 'google_jules',
        name: 'Google Jules AI Agent',
        type: AiProviderType.googleJules,
        apiKey: julesKey,
        endpoint: 'https://api.jules.ai/v1',
        modelName: 'jules-v1',
        role: 'Primary Execution & Code Agent',
        isEnabled: true,
        weight: 1.0,
      ),
      const AiModelConfig(
        id: 'gemini_flash',
        name: 'Google Gemini 1.5 Pro',
        type: AiProviderType.gemini,
        apiKey: '',
        endpoint: 'https://generativelanguage.googleapis.com/v1beta',
        modelName: 'gemini-1.5-pro',
        role: 'Architectural & Design Reviewer',
        isEnabled: true,
        weight: 0.9,
      ),
      const AiModelConfig(
        id: 'openai_gpt4',
        name: 'OpenAI GPT-4o',
        type: AiProviderType.openAi,
        apiKey: '',
        endpoint: 'https://api.openai.com/v1',
        modelName: 'gpt-4o',
        role: 'Code Inspector & Quality Auditor',
        isEnabled: true,
        weight: 0.85,
      ),
      const AiModelConfig(
        id: 'anthropic_claude',
        name: 'Anthropic Claude 3.5 Sonnet',
        type: AiProviderType.anthropic,
        apiKey: '',
        endpoint: 'https://api.anthropic.com/v1',
        modelName: 'claude-3-5-sonnet',
        role: 'Security & Edge-Case Auditor',
        isEnabled: true,
        weight: 0.85,
      ),
      const AiModelConfig(
        id: 'local_ollama',
        name: 'Ollama / Local AI Model',
        type: AiProviderType.localOllama,
        apiKey: '',
        endpoint: 'http://127.0.0.1:11434',
        modelName: 'llama3:latest',
        role: 'Offline Self-Hosted Synthesizer',
        isEnabled: false,
        weight: 0.7,
      ),
    ];
  }
}
