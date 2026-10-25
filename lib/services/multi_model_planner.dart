import 'dart:async';
import '../models/ai_model_config.dart';
import '../models/app_config.dart';
import '../models/github_item.dart';
import 'ai_model_provider.dart';
import 'mcp_steering_server.dart';

class MultiModelPlan {
  final String prompt;
  final List<AiContribution> contributions;
  final String consensusSummary;
  final List<String> unifiedSuggestions;
  final List<String> unifiedRisks;
  final double overallConfidence;
  final List<McpContextEntry> mcpSharedContextPool;
  final List<McpSteeringDirective> mcpActiveDirectives;
  final DateTime createdAt;

  const MultiModelPlan({
    required this.prompt,
    required this.contributions,
    required this.consensusSummary,
    required this.unifiedSuggestions,
    required this.unifiedRisks,
    required this.overallConfidence,
    this.mcpSharedContextPool = const [],
    this.mcpActiveDirectives = const [],
    required this.createdAt,
  });

  String formatMarkdownOutput() {
    final sb = StringBuffer();
    sb.writeln('### 🧠 Multi-Model Consensus Plan (MCP In-Flight Steering)');
    sb.writeln('**Prompt:** "$prompt"\n');

    sb.writeln('#### 🤖 Participating AI Models (${contributions.length}):');
    for (var c in contributions) {
      final scorePct = (c.confidenceScore * 100).toInt();
      sb.writeln('- **${c.providerName}** `[${c.role}]` — Confidence: $scorePct%');
    }
    sb.writeln();

    sb.writeln('#### 📌 Unified Consensus Strategy:');
    sb.writeln(consensusSummary);
    sb.writeln();

    if (mcpActiveDirectives.isNotEmpty) {
      sb.writeln('#### 🔄 MCP In-Flight Steering Directives (${mcpActiveDirectives.length}):');
      for (var dir in mcpActiveDirectives) {
        sb.writeln('- **[${dir.sourceModelId} ➔ ${dir.targetModelId}]** `${dir.directiveType}`: "${dir.instruction}"');
      }
      sb.writeln();
    }

    if (unifiedSuggestions.isNotEmpty) {
      sb.writeln('#### 💡 Consolidated Key Recommendations:');
      for (var s in unifiedSuggestions) {
        sb.writeln('- $s');
      }
      sb.writeln();
    }

    if (unifiedRisks.isNotEmpty) {
      sb.writeln('#### ⚠️ Identified Security & Structural Risks:');
      for (var r in unifiedRisks) {
        sb.writeln('- $r');
      }
      sb.writeln();
    }

    sb.writeln('#### 🔍 Individual Provider Perspectives:');
    for (var c in contributions) {
      sb.writeln('**[${c.providerName}] - ${c.role}:**');
      sb.writeln('> ${c.summary}');
      for (var sug in c.suggestions) {
        sb.writeln('  * Suggestion: $sug');
      }
      sb.writeln();
    }

    return sb.toString();
  }
}

class MultiModelPlanner {
  final AppConfig config;

  MultiModelPlanner({required this.config});

  List<BaseAiProvider> _buildEnabledProviders() {
    final providers = <BaseAiProvider>[];

    for (var cfg in config.multiModelProviders) {
      if (!cfg.isEnabled) continue;

      switch (cfg.type) {
        case AiProviderType.googleJules:
          providers.add(GoogleJulesModelProvider(cfg.copyWith(apiKey: config.julesApiKey)));
          break;
        case AiProviderType.gemini:
          providers.add(GeminiModelProvider(cfg));
          break;
        case AiProviderType.openAi:
          providers.add(OpenAiModelProvider(cfg));
          break;
        case AiProviderType.anthropic:
          providers.add(ClaudeModelProvider(cfg));
          break;
        case AiProviderType.localOllama:
          providers.add(LocalOllamaModelProvider(cfg));
          break;
        case AiProviderType.custom:
          providers.add(GoogleJulesModelProvider(cfg));
          break;
      }
    }

    if (providers.isEmpty) {
      final defaultJulesCfg = AiModelConfig(
        id: 'google_jules',
        name: 'Google Jules AI Agent',
        type: AiProviderType.googleJules,
        apiKey: config.julesApiKey,
        endpoint: config.julesBaseUrl,
        role: 'Primary Execution Agent',
      );
      providers.add(GoogleJulesModelProvider(defaultJulesCfg));
    }

    return providers;
  }

  Future<MultiModelPlan> executeMultiModelPlanning({
    required String prompt,
    List<GitHubItem> linkedItems = const [],
  }) async {
    final activeProviders = _buildEnabledProviders();
    final mcpServer = config.enableMcpInFlightSteering ? McpSteeringServer() : null;

    final futures = activeProviders.map((provider) {
      return provider
          .generateContribution(
            prompt: prompt,
            linkedItems: linkedItems,
            mcpServer: mcpServer,
          )
          .catchError((e) {
        return AiContribution(
          providerId: provider.config.id,
          providerName: provider.config.name,
          role: provider.config.role,
          summary: 'Provider execution error: ${e.toString()}',
          suggestions: const [],
          risksIdentified: const ['Provider offline or misconfigured.'],
          confidenceScore: 0.0,
          rawResponse: e.toString(),
          timestamp: DateTime.now(),
        );
      });
    }).toList();

    final contributions = await Future.wait(futures);

    // Synthesize consensus recommendations
    final allSuggestions = <String>{};
    final allRisks = <String>{};
    double totalWeight = 0.0;
    double weightedScore = 0.0;

    for (var c in contributions) {
      allSuggestions.addAll(c.suggestions);
      allRisks.addAll(c.risksIdentified);

      final providerWeight = activeProviders
          .firstWhere((p) => p.config.id == c.providerId, orElse: () => activeProviders.first)
          .config
          .weight;

      totalWeight += providerWeight;
      weightedScore += (c.confidenceScore * providerWeight);
    }

    final overallConfidence = totalWeight > 0 ? (weightedScore / totalWeight) : 0.9;

    final primaryContribution = contributions.firstWhere(
      (c) => c.providerId == 'google_jules',
      orElse: () => contributions.first,
    );

    final steeringCount = mcpServer?.activeDirectives.length ?? 0;
    final consensusSummary = 'Multi-model consensus reached across ${contributions.length} AI providers via MCP In-Flight Steering ($steeringCount directives issued). '
        'Primary execution strategy anchored by ${primaryContribution.providerName} with multi-perspective validation.';

    return MultiModelPlan(
      prompt: prompt,
      contributions: contributions,
      consensusSummary: consensusSummary,
      unifiedSuggestions: allSuggestions.toList(),
      unifiedRisks: allRisks.toList(),
      overallConfidence: overallConfidence,
      mcpSharedContextPool: mcpServer?.sharedContextPool ?? const [],
      mcpActiveDirectives: mcpServer?.activeDirectives ?? const [],
      createdAt: DateTime.now(),
    );
  }
}
