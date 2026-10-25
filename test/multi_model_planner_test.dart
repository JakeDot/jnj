import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/ai_model_config.dart';
import 'package:app/models/app_config.dart';
import 'package:app/services/multi_model_planner.dart';

void main() {
  group('MultiModelPlanner Tests', () {
    late AppConfig config;
    late MultiModelPlanner planner;

    setUp(() {
      config = AppConfig(
        julesApiKey: 'test_jules_key_123',
        julesBaseUrl: 'https://api.jules.ai/v1',
        enableMultiModelPlanning: true,
        multiModelProviders: AiModelConfig.defaultProviders(julesKey: 'test_jules_key_123'),
      );
      planner = MultiModelPlanner(config: config);
    });

    test('Executes multi-model planning across enabled providers', () async {
      final plan = await planner.executeMultiModelPlanning(
        prompt: 'Fix state synchronization issue',
      );

      expect(plan.prompt, equals('Fix state synchronization issue'));
      expect(plan.contributions.length, equals(4)); // Google Jules, Gemini, GPT-4, Claude
      expect(plan.overallConfidence, greaterThan(0.8));
      expect(plan.unifiedSuggestions.isNotEmpty, isTrue);
    });

    test('Formats multi-model plan as markdown string', () async {
      final plan = await planner.executeMultiModelPlanning(
        prompt: 'Implement secure login flow',
      );

      final markdown = plan.formatMarkdownOutput();

      expect(markdown, contains('Multi-Model Consensus Plan'));
      expect(markdown, contains('Google Jules AI Agent'));
      expect(markdown, contains('Google Gemini 1.5 Pro'));
      expect(markdown, contains('OpenAI GPT-4o'));
      expect(markdown, contains('Anthropic Claude 3.5 Sonnet'));
    });

    test('Respects provider enable/disable settings', () async {
      final disabledProviders = config.multiModelProviders.map((p) {
        if (p.type == AiProviderType.openAi || p.type == AiProviderType.anthropic) {
          return p.copyWith(isEnabled: false);
        }
        return p;
      }).toList();

      final customConfig = config.copyWith(multiModelProviders: disabledProviders);
      final customPlanner = MultiModelPlanner(config: customConfig);

      final plan = await customPlanner.executeMultiModelPlanning(
        prompt: 'Refactor UI widget',
      );

      expect(plan.contributions.length, equals(2)); // Only Jules and Gemini
      expect(plan.contributions.any((c) => c.providerName.contains('GPT-4')), isFalse);
    });
  });
}
