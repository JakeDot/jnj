import 'dart:async';
import 'dart:convert';

class McpTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  const McpTool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'inputSchema': inputSchema,
    };
  }
}

class McpContextEntry {
  final String modelId;
  final String modelName;
  final String role;
  final String topic;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const McpContextEntry({
    required this.modelId,
    required this.modelName,
    required this.role,
    required this.topic,
    required this.content,
    this.metadata = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'modelId': modelId,
      'modelName': modelName,
      'role': role,
      'topic': topic,
      'content': content,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class McpSteeringDirective {
  final String sourceModelId;
  final String targetModelId;
  final String directiveType; // e.g. "security_constraint", "architectural_refinement", "edge_case_warning"
  final String instruction;
  final DateTime timestamp;

  const McpSteeringDirective({
    required this.sourceModelId,
    required this.targetModelId,
    required this.directiveType,
    required this.instruction,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceModelId': sourceModelId,
      'targetModelId': targetModelId,
      'directiveType': directiveType,
      'instruction': instruction,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class McpSteeringServer {
  final String serverName;
  final String serverVersion;

  final List<McpContextEntry> _sharedContextPool = [];
  final List<McpSteeringDirective> _activeDirectives = [];
  final Map<String, McpTool> _tools = {};

  McpSteeringServer({
    this.serverName = 'jnj-mcp-steering-server',
    this.serverVersion = '1.0.0',
  }) {
    _registerDefaultTools();
  }

  List<McpContextEntry> get sharedContextPool => List.unmodifiable(_sharedContextPool);
  List<McpSteeringDirective> get activeDirectives => List.unmodifiable(_activeDirectives);

  void _registerDefaultTools() {
    registerTool(const McpTool(
      name: 'mcp_share_context',
      description: 'Broadcasts a model reasoning proposal, code patch snippet, or architectural constraint to peer models.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'modelId': {'type': 'string'},
          'modelName': {'type': 'string'},
          'role': {'type': 'string'},
          'topic': {'type': 'string'},
          'content': {'type': 'string'},
        },
        'required': ['modelId', 'topic', 'content'],
      },
    ));

    registerTool(const McpTool(
      name: 'mcp_query_peer_model',
      description: 'Queries in-flight shared context or previous analyses contributed by peer models in the session.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'query': {'type': 'string'},
          'targetRole': {'type': 'string'},
        },
        'required': ['query'],
      },
    ));

    registerTool(const McpTool(
      name: 'mcp_steer_consensus',
      description: 'Issues an in-flight steering directive to alter, refine, or enforce constraints on peer model plans.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'sourceModelId': {'type': 'string'},
          'targetModelId': {'type': 'string'},
          'directiveType': {'type': 'string'},
          'instruction': {'type': 'string'},
        },
        'required': ['sourceModelId', 'instruction'],
      },
    ));
  }

  void registerTool(McpTool tool) {
    _tools[tool.name] = tool;
  }

  // MCP JSON-RPC 2.0 Request Processor
  Future<Map<String, dynamic>> handleJsonRpcRequest(Map<String, dynamic> request) async {
    final jsonrpc = request['jsonrpc'] as String? ?? '2.0';
    final id = request['id'];
    final method = request['method'] as String? ?? '';
    final rawParams = request['params'];
    final params = rawParams is Map ? Map<String, dynamic>.from(rawParams) : <String, dynamic>{};

    if (jsonrpc != '2.0') {
      return _buildErrorResponse(id, -32600, 'Invalid JSON-RPC version.');
    }

    try {
      switch (method) {
        case 'initialize':
          return {
            'jsonrpc': '2.0',
            'id': id,
            'result': {
              'protocolVersion': '2024-11-05',
              'capabilities': {
                'tools': {'listChanged': true},
                'resources': {'subscribe': true},
              },
              'serverInfo': {
                'name': serverName,
                'version': serverVersion,
              },
            },
          };

        case 'tools/list':
          return {
            'jsonrpc': '2.0',
            'id': id,
            'result': {
              'tools': _tools.values.map((t) => t.toJson()).toList(),
            },
          };

        case 'tools/call':
          final name = params['name'] as String? ?? '';
          final rawArgs = params['arguments'];
          final arguments = rawArgs is Map ? Map<String, dynamic>.from(rawArgs) : <String, dynamic>{};
          final toolResult = await executeTool(name, arguments);
          return {
            'jsonrpc': '2.0',
            'id': id,
            'result': {
              'content': [
                {
                  'type': 'text',
                  'text': jsonEncode(toolResult),
                }
              ]
            },
          };

        case 'resources/list':
          return {
            'jsonrpc': '2.0',
            'id': id,
            'result': {
              'resources': [
                {
                  'uri': 'resource://steering/consensus_plan',
                  'name': 'Shared Steering Context Pool',
                  'mimeType': 'application/json',
                },
                {
                  'uri': 'resource://steering/active_directives',
                  'name': 'Active Model Steering Directives',
                  'mimeType': 'application/json',
                }
              ]
            },
          };

        case 'resources/read':
          final uri = params['uri'] as String? ?? '';
          if (uri == 'resource://steering/consensus_plan') {
            return {
              'jsonrpc': '2.0',
              'id': id,
              'result': {
                'contents': [
                  {
                    'uri': uri,
                    'mimeType': 'application/json',
                    'text': jsonEncode(_sharedContextPool.map((e) => e.toJson()).toList()),
                  }
                ]
              },
            };
          } else if (uri == 'resource://steering/active_directives') {
            return {
              'jsonrpc': '2.0',
              'id': id,
              'result': {
                'contents': [
                  {
                    'uri': uri,
                    'mimeType': 'application/json',
                    'text': jsonEncode(_activeDirectives.map((e) => e.toJson()).toList()),
                  }
                ]
              },
            };
          } else {
            return _buildErrorResponse(id, -32602, 'Resource not found: $uri');
          }

        default:
          return _buildErrorResponse(id, -32601, 'Method not found: $method');
      }
    } catch (e) {
      return _buildErrorResponse(id, -32603, 'Internal error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> executeTool(String toolName, Map<String, dynamic> args) async {
    final now = DateTime.now();

    switch (toolName) {
      case 'mcp_share_context':
        final entry = McpContextEntry(
          modelId: args['modelId'] as String? ?? 'unknown_model',
          modelName: args['modelName'] as String? ?? 'AI Model',
          role: args['role'] as String? ?? 'Contributor',
          topic: args['topic'] as String? ?? 'general_proposal',
          content: args['content'] as String? ?? '',
          metadata: args['metadata'] as Map<String, dynamic>? ?? {},
          timestamp: now,
        );
        _sharedContextPool.add(entry);
        return {
          'status': 'success',
          'message': 'Shared context entry broadcasted to MCP pool.',
          'totalSharedEntries': _sharedContextPool.length,
          'entry': entry.toJson(),
        };

      case 'mcp_query_peer_model':
        final query = (args['query'] as String? ?? '').toLowerCase();
        final targetRole = (args['targetRole'] as String? ?? '').toLowerCase();

        final matches = _sharedContextPool.where((entry) {
          final matchesQuery = query.isEmpty ||
              entry.content.toLowerCase().contains(query) ||
              entry.topic.toLowerCase().contains(query);
          final matchesRole = targetRole.isEmpty || entry.role.toLowerCase().contains(targetRole);
          return matchesQuery && matchesRole;
        }).toList();

        return {
          'status': 'success',
          'matchCount': matches.length,
          'matches': matches.map((e) => e.toJson()).toList(),
        };

      case 'mcp_steer_consensus':
        final directive = McpSteeringDirective(
          sourceModelId: args['sourceModelId'] as String? ?? 'steering_model',
          targetModelId: args['targetModelId'] as String? ?? 'all_peers',
          directiveType: args['directiveType'] as String? ?? 'refinement',
          instruction: args['instruction'] as String? ?? '',
          timestamp: now,
        );
        _activeDirectives.add(directive);
        return {
          'status': 'success',
          'message': 'In-flight steering directive registered.',
          'activeDirectivesCount': _activeDirectives.length,
          'directive': directive.toJson(),
        };

      default:
        throw Exception('Tool "$toolName" is not registered on this MCP server.');
    }
  }

  Map<String, dynamic> _buildErrorResponse(dynamic id, int code, String message) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {
        'code': code,
        'message': message,
      },
    };
  }

  void clearSession() {
    _sharedContextPool.clear();
    _activeDirectives.clear();
  }
}
