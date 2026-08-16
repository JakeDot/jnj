import 'github_item.dart';
import 'jules_request.dart';

enum ShellOutputType { text, success, error, info, json, card }

class ShellOutput {
  final String content;
  final ShellOutputType type;
  final DateTime timestamp;
  final JulesRequest? request;
  final GitHubItem? githubItem;

  ShellOutput({
    required this.content,
    this.type = ShellOutputType.text,
    DateTime? timestamp,
    this.request,
    this.githubItem,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ParsedCommand {
  final String command;
  final List<String> args;
  final Map<String, String> options;
  final String rawInput;

  ParsedCommand({
    required this.command,
    required this.args,
    required this.options,
    required this.rawInput,
  });

  static ParsedCommand parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return ParsedCommand(command: '', args: [], options: {}, rawInput: input);
    }

    final tokens = _tokenize(trimmed);
    if (tokens.isEmpty) {
      return ParsedCommand(command: '', args: [], options: {}, rawInput: input);
    }

    var cmd = tokens.first.toLowerCase();
    // Allow 'jules <cmd>' prefix
    int startIndex = 1;
    if (cmd == 'jules' && tokens.length > 1) {
      cmd = tokens[1].toLowerCase();
      startIndex = 2;
    }

    final args = <String>[];
    final options = <String, String>{};

    for (int i = startIndex; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.startsWith('--')) {
        final parts = token.substring(2).split('=');
        final key = parts[0];
        final val = parts.length > 1 ? parts.sublist(1).join('=') : 'true';
        options[key] = val;
      } else if (token.startsWith('-') && token.length == 2) {
        final key = token.substring(1);
        if (i + 1 < tokens.length && !tokens[i + 1].startsWith('-')) {
          options[key] = tokens[i + 1];
          i++;
        } else {
          options[key] = 'true';
        }
      } else {
        args.add(token);
      }
    }

    return ParsedCommand(
      command: cmd,
      args: args,
      options: options,
      rawInput: input,
    );
  }

  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    final sb = StringBuffer();
    bool inQuote = false;
    String quoteChar = '';

    for (int i = 0; i < input.length; i++) {
      final c = input[i];

      if ((c == '"' || c == "'")) {
        if (!inQuote) {
          inQuote = true;
          quoteChar = c;
        } else if (quoteChar == c) {
          inQuote = false;
          quoteChar = '';
        } else {
          sb.write(c);
        }
      } else if (c == ' ' && !inQuote) {
        if (sb.isNotEmpty) {
          tokens.add(sb.toString());
          sb.clear();
        }
      } else {
        sb.write(c);
      }
    }

    if (sb.isNotEmpty) {
      tokens.add(sb.toString());
    }

    return tokens;
  }
}
