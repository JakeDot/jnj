import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';
import '../models/jules_request.dart';

class StorageService {
  static const String _configKey = 'jules_app_config';
  static const String _requestsKey = 'jules_saved_requests';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  AppConfig loadConfig() {
    final raw = _prefs.getString(_configKey);
    if (raw == null || raw.isEmpty) {
      return AppConfig.defaultConfig;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppConfig.fromJson(json);
    } catch (_) {
      return AppConfig.defaultConfig;
    }
  }

  Future<bool> saveConfig(AppConfig config) async {
    final raw = jsonEncode(config.toJson());
    return await _prefs.setString(_configKey, raw);
  }

  List<JulesRequest> loadRequests() {
    final raw = _prefs.getString(_requestsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => JulesRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveRequests(List<JulesRequest> requests) async {
    final raw = jsonEncode(requests.map((e) => e.toJson()).toList());
    return await _prefs.setString(_requestsKey, raw);
  }

  Future<bool> clearRequests() async {
    return await _prefs.remove(_requestsKey);
  }
}
