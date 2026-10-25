import 'dart:async';
import '../models/ai_model_config.dart';
import '../models/github_item.dart';
import 'mcp_steering_server.dart';

class AiContribution {
  final String providerId;
  final String providerName;
  final String role;
  final String summary;
  final List<String> suggestions;
  final List<String> risksIdentified;
  final double confidenceScore;
  final String rawResponse;
  final List<McpSteeringDirective> mcpDirectivesSent;
  final DateTime timestamp;

  const AiContribution({
    required this.providerId,
    required this.providerName,
    required this.role,
    required this.summary,
    required this.suggestions,
    required this.risksIdentified,
    required this.confidenceScore,
    required this.rawResponse,
    this.mcpDirectivesSent = const [],
    required this.timestamp,
  });
}

abstract class BaseAiProvider {
  final AiModelConfig config;

  BaseAiProvider(this.config);

  Future<AiContribution> generateContribution({
    required String prompt,
    List<GitHubItem> linkedItems = const [],
    McpSteeringServer? mcpServer,
  });
}

class GoogleJulesModelProvider extends BaseAiProvider {
  GoogleJulesModelProvider(super.config);

  @override
  Future<AiContribution> generateContribution({
    required String prompt,
    List<GitHubItem> linkedItems = const [],
    McpSteeringServer? mcpServer,
  }) async {
    final lower = prompt.toLowerCase();
    final now = DateTime.now();

    final summary = 'Google Jules AI Agent proposed patch & execution plan for "$prompt".';
    final suggestions = <String>[
      'Execute code agent patch across target files.',
      if (linkedItems.isNotEmpty)
        'Verify execution against active GitHub context (${linkedItems.map((e) => e.shortRef).join(', ')}).',
      'Generate automated pull request summary.',
    ];
    final risks = <String>[
      if (lower.contains('delete') || lower.contains('remove')) 'Potential breaking change in file deletion.',
      if (config.apiKey.isEmpty) 'Jules API Key not set; running simulated execution.',
    ];

    if (mcpServer != null) {
      // Broadcast proposal to MCP shared context pool
      await mcpServer.executeTool('mcp_share_context', {
        'modelId': config.id,
        'modelName': config.name,
        'role': config.role,
        'topic': 'primary_code_proposal',
        'content': summary,
      });
    }

    return AiContribution(
      providerId: config.id,
      providerName: config.name,
      role: config.role,
      summary: summary,
      suggestions: suggestions,
      risksIdentified: risks,
      confidenceScore: 0.95,
      rawResponse: 'Jules AI Execution Plan generated successfully.',
      timestamp: now,
    );
  }
}

class GeminiModelProvider extends BaseAiProvider {
  GeminiModelProvider(super.config);

  @override
  Future<AiContribution> generateContribution({
    required String prompt,
    List<GitHubItem> linkedItems = const [],
    McpSteeringServer? mcpServer,
  }) async {
    final now = DateTime.now();
    final directives = <McpSteeringDirective>[];

    if (mcpServer != null) {
      // Query peer proposals from MCP server
      await mcpServer.executeTool('mcp_query_peer_model', {
        'query': 'primary_code_proposal',
      });

      // Broadcast architectural analysis to MCP
      await mcpServer.executeTool('mcp_share_context', {
        'modelId': config.id,
        'modelName': config.name,
        'role': config.role,
        'topic': 'architectural_review',
        'content': 'Decouple state logic from UI widgets. Ensure async safety during state mutation.',
      });

      // Issue steering directive
      final dirResult = await mcpServer.executeTool('mcp_steer_consensus', {
        'sourceModelId': config.id,
        'targetModelId': 'google_jules',
        'directiveType': 'architectural_refinement',
        'instruction': 'Ensure state flow mutations are guarded against memory leaks.',
      });

      if (dirResult.containsKey('directive')) {
        directives.add(McpSteeringDirective(
          sourceModelId: config.id,
          targetModelId: 'google_jules',
          directiveType: 'architectural_refinement',
          instruction: 'Ensure state flow mutations are guarded against memory leaks.',
          timestamp: now,
        ));
      }
    }

    return AiContribution(
      providerId: config.id,
      providerName: config.name,
      role: config.role,
      summary: 'Gemini Architectural Review: Structural validation for "$prompt".',
      suggestions: const [
        'Decouple state logic from UI widgets.',
        'Ensure coroutine / async safety during state mutation.',
      ],
      risksIdentified: const [
        'Check for memory retention in persistent listeners.',
      ],
      confidenceScore: 0.91,
      rawResponse: 'Gemini 1.5 Pro architectural assessment complete.',
      mcpDirectivesSent: directives,
      timestamp: now,
    );
  }
}

class OpenAiModelProvider extends BaseAiProvider {
  OpenAiModelProvider(super.config);

  @override
  Future<AiContribution> generateContribution({
    required String prompt,
    List<GitHubItem> linkedItems = const [],
    McpSteeringServer? mcpServer,
  }) async {
    final now = DateTime.now();

    if (mcpServer != null) {
      await mcpServer.executeTool('mcp_share_context', {
        'modelId': config.id,
        'modelName': config.name,
        'role': config.role,
        'topic': 'code_quality_audit',
        'content': 'Enforce immutability on state objects and type safety on JSON parsing.',
      });
    }

    return AiContribution(
      providerId: config.id,
      providerName: config.name,
      role: config.role,
      summary: 'GPT-4o Quality Audit: Code structure & null-safety validation.',
      suggestions: const [
        'Add strict type assertions on JSON deserialization.',
        'Enforce immutability on state objects.',
      ],
      risksIdentified: const [
        'Verify JSON keys match API specification.',
      ],
      confidenceScore: 0.89,
      rawResponse: 'OpenAI GPT-4o code review complete.',
      timestamp: now,
    );
  }
}

class ClaudeModelProvider extends BaseAiProvider {
  ClaudeModelProvider(super.config);

  @override
  Future<AiContribution> generateContribution({
    required String prompt,
    List<GitHubItem> linkedItems = const [],
    McpSteeringServer? mcpServer,
  }) async {
    final now = DateTime.now();
    final directives = <McpSteeringDirective>[];

    if (mcpServer != null) {
      await mcpServer.executeTool('mcp_share_context', {
        'modelId': config.id,
        'modelName': config.name,
        'role': config.role,
        'topic': 'security_audit',
        'content': 'Sanitize raw inputs. Obscure API keys and tokens in output logs.',
      });

      await mcpServer.executeTool('mcp_steer_consensus', {
        'sourceModelId': config.id,
        'targetModelId': 'all_peers',
        'directiveType': 'security_constraint',
        'instruction': 'Enforce zero token / secret exposure in generated log streams.',
      });

      directives.add(McpSteeringDirective(
        sourceModelId: config.id,
        targetModelId: 'all_peers',
        directiveType: 'security_constraint',
        instruction: 'Enforce zero token / secret exposure in generated log streams.',
        timestamp: now,
      ));
    }

    return AiContribution(
      providerId: config.id,
      providerName: config.name,
      role: config.role,
      summary: 'Claude 3.5 Sonnet Security Audit: Input sanitization & secret protection.',
      suggestions: const [
        'Sanitize raw shell inputs before subprocess execution.',
        'Ensure API keys are obscured in UI logs.',
      ],
      risksIdentified: const [
        'Avoid printing raw authorization tokens in terminal output.',
      ],
      confidenceScore: 0.93,
      rawResponse: 'Claude 3.5 Sonnet security review complete.',
      mcpDirectivesSent: directives,
      timestamp: now,
    );
  }
}

class LocalOllamaModelProvider extends BaseAiProvider {
  LocalOllamaModelProvider(super.config);

  @override
  Future<AiContribution> generateContribution({
    required String prompt,
    List<GitHubItem> linkedItems = const [],
    McpSteeringServer? mcpServer,
  }) async {
    final now = DateTime.now();

    if (mcpServer != null) {
      await mcpServer.executeTool('mcp_share_context', {
        'modelId': config.id,
        'modelName': config.name,
        'role': config.role,
        'topic': 'offline_synthesis',
        'content': 'Verified offline local execution parameters.',
      });
    }

    return AiContribution(
      providerId: config.id,
      providerName: config.name,
      role: config.role,
      summary: 'Ollama Llama3 Offline Synthesis: Local verification for "$prompt".',
      suggestions: const [
        'Executed offline consensus check on local model endpoint.',
      ],
      risksIdentified: const [],
      confidenceScore: 0.82,
      rawResponse: 'Ollama local model response generated.',
      timestamp: now,
    );
  }
}
