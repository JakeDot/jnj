import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/mcp_steering_server.dart';

void main() {
  group('McpSteeringServer JSON-RPC 2.0 Tests', () {
    late McpSteeringServer mcpServer;

    setUp(() {
      mcpServer = McpSteeringServer();
    });

    test('Handles MCP initialize method', () async {
      final request = {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {},
      };

      final response = await mcpServer.handleJsonRpcRequest(request);

      expect(response['jsonrpc'], equals('2.0'));
      expect(response['id'], equals(1));
      expect(response['result']['protocolVersion'], equals('2024-11-05'));
      expect(response['result']['serverInfo']['name'], equals('jnj-mcp-steering-server'));
    });

    test('Lists registered MCP steering tools', () async {
      final request = {
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'tools/list',
      };

      final response = await mcpServer.handleJsonRpcRequest(request);

      final tools = response['result']['tools'] as List<dynamic>;
      expect(tools.length, greaterThanOrEqualTo(3));
      expect(tools.any((t) => t['name'] == 'mcp_share_context'), isTrue);
      expect(tools.any((t) => t['name'] == 'mcp_query_peer_model'), isTrue);
      expect(tools.any((t) => t['name'] == 'mcp_steer_consensus'), isTrue);
    });

    test('Executes mcp_share_context tool call', () async {
      final result = await mcpServer.executeTool('mcp_share_context', {
        'modelId': 'google_jules',
        'modelName': 'Google Jules AI',
        'role': 'Primary Agent',
        'topic': 'code_patch',
        'content': 'Apply null check on request handler.',
      });

      expect(result['status'], equals('success'));
      expect(mcpServer.sharedContextPool.length, equals(1));
      expect(mcpServer.sharedContextPool.first.modelId, equals('google_jules'));
    });

    test('Executes mcp_steer_consensus tool call and registers directive', () async {
      final result = await mcpServer.executeTool('mcp_steer_consensus', {
        'sourceModelId': 'claude_35',
        'targetModelId': 'google_jules',
        'directiveType': 'security_guard',
        'instruction': 'Sanitize shell input arguments before subprocess invocation.',
      });

      expect(result['status'], equals('success'));
      expect(mcpServer.activeDirectives.length, equals(1));
      expect(mcpServer.activeDirectives.first.sourceModelId, equals('claude_35'));
    });

    test('Reads resource://steering/consensus_plan', () async {
      await mcpServer.executeTool('mcp_share_context', {
        'modelId': 'gemini_15',
        'modelName': 'Gemini 1.5',
        'role': 'Architect',
        'topic': 'decoupling',
        'content': 'Decouple state logic.',
      });

      final request = {
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'resources/read',
        'params': {'uri': 'resource://steering/consensus_plan'},
      };

      final response = await mcpServer.handleJsonRpcRequest(request);

      final contents = response['result']['contents'] as List<dynamic>;
      expect(contents.first['uri'], equals('resource://steering/consensus_plan'));
      expect(contents.first['text'], contains('gemini_15'));
    });
  });
}
