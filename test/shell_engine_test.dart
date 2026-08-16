import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/app_config.dart';
import 'package:app/models/shell_command.dart';
import 'package:app/services/github_service.dart';
import 'package:app/services/jules_api_service.dart';
import 'package:app/services/shell_engine.dart';

void main() {
  group('ShellEngine Tests', () {
    late ShellEngine engine;
    late JulesApiService julesApiService;
    late GitHubService gitHubService;

    setUp(() {
      const config = AppConfig(
        apiKey: 'mock_jules_api_key',
        defaultRepo: 'flutter/flutter',
        useMockMode: true,
      );
      julesApiService = JulesApiService(config: config);
      gitHubService = GitHubService(config: config);
      engine = ShellEngine(
        julesApiService: julesApiService,
        gitHubService: gitHubService,
      );
    });

    test('Parses command arguments and options correctly', () {
      final parsed = ParsedCommand.parse('jules send "Fix bug" --repo=my/repo -v');
      expect(parsed.command, equals('send'));
      expect(parsed.args, contains('Fix bug'));
      expect(parsed.options['repo'], equals('my/repo'));
      expect(parsed.options['v'], equals('true'));
    });

    test('Executes help command', () async {
      final output = await engine.executeInput('help');
      expect(output.type, equals(ShellOutputType.info));
      expect(output.content, contains('Jules Shell Commands Reference'));
    });

    test('Executes jules send prompt and updates history', () async {
      final output = await engine.executeInput('send "Review PR code"');
      expect(output.type, equals(ShellOutputType.success));
      expect(engine.requestHistory.length, equals(1));
      expect(engine.requestHistory.first.prompt, equals('Review PR code'));
    });

    test('Sets and clears active GitHub context', () async {
      final linkOutput = await engine.executeInput('gh link https://github.com/flutter/flutter/issues/201');
      expect(linkOutput.type, equals(ShellOutputType.success));
      expect(engine.activeGitHubContext, isNotNull);
      expect(engine.activeGitHubContext!.number, equals(201));

      final clearOutput = await engine.executeInput('gh context clear');
      expect(clearOutput.content, contains('Cleared active GitHub context'));
      expect(engine.activeGitHubContext, isNull);
    });

    test('Updates config via shell command', () async {
      final output = await engine.executeInput('config set-key new_key_123');
      expect(output.type, equals(ShellOutputType.success));
      expect(julesApiService.config.apiKey, equals('new_key_123'));
    });
  });
}
