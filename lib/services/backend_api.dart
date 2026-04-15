import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendApiException implements Exception {
  final String message;
  BackendApiException(this.message);

  @override
  String toString() => message;
}

class BackendApi {
  BackendApi._();

  static final BackendApi instance = BackendApi._();

  String get _baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }

    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }

    return 'http://localhost:5000';
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath').replace(queryParameters: query);
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw BackendApiException('Invalid server response format');
  }

  List<dynamic> _decodeList(http.Response response) {
    final decoded = json.decode(response.body);
    if (decoded is List<dynamic>) {
      return decoded;
    }
    throw BackendApiException('Invalid server response format');
  }

  Never _throwError(http.Response response) {
    try {
      final data = _decodeObject(response);
      final message = data['error']?.toString() ?? data['message']?.toString();
      throw BackendApiException(message ?? 'HTTP ${response.statusCode}');
    } catch (_) {
      throw BackendApiException('HTTP ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200) {
      _throwError(response);
    }

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> signup({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? profileImagePath,
  }) async {
    final response = await http.post(
      _uri('/api/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'profile_image_path': profileImagePath,
      }),
    );

    if (response.statusCode != 201) {
      _throwError(response);
    }

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> getUser(String username) async {
    final response = await http.get(_uri('/api/users/$username'));
    if (response.statusCode != 200) {
      _throwError(response);
    }
    return _decodeObject(response);
  }

  Future<List<Map<String, dynamic>>> listEspNodes(String username) async {
    final response = await http.get(
      _uri('/api/esp-nodes', {'username': username}),
    );
    if (response.statusCode != 200) {
      _throwError(response);
    }

    return _decodeList(response)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createEspNode(Map<String, dynamic> payload) async {
    final response = await http.post(
      _uri('/api/esp-nodes'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode != 201) {
      _throwError(response);
    }

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> updateEspNode(int nodeId, Map<String, dynamic> payload) async {
    final response = await http.put(
      _uri('/api/esp-nodes/$nodeId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      _throwError(response);
    }

    return _decodeObject(response);
  }

  Future<void> deleteEspNode(int nodeId) async {
    final response = await http.delete(_uri('/api/esp-nodes/$nodeId'));
    if (response.statusCode != 200) {
      _throwError(response);
    }
  }

  Future<List<Map<String, dynamic>>> listScenarios(String username) async {
    final response = await http.get(
      _uri('/api/scenarios', {'username': username}),
    );

    if (response.statusCode != 200) {
      _throwError(response);
    }

    return _decodeList(response)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createScenario(Map<String, dynamic> payload) async {
    final response = await http.post(
      _uri('/api/scenarios'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode != 201) {
      _throwError(response);
    }

    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> updateScenario(int scenarioId, Map<String, dynamic> payload) async {
    final response = await http.put(
      _uri('/api/scenarios/$scenarioId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      _throwError(response);
    }

    return _decodeObject(response);
  }

  Future<void> deleteScenario(int scenarioId) async {
    final response = await http.delete(_uri('/api/scenarios/$scenarioId'));
    if (response.statusCode != 200) {
      _throwError(response);
    }
  }

  Future<List<Map<String, dynamic>>> listLogs({
    required String username,
    String? logType,
    int limit = 200,
  }) async {
    final query = <String, String>{
      'username': username,
      'limit': '$limit',
    };
    if (logType != null) {
      query['log_type'] = logType;
    }

    final response = await http.get(_uri('/api/logging', query));
    if (response.statusCode != 200) {
      _throwError(response);
    }

    return _decodeList(response)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createLog({
    required String username,
    required String logType,
    required String actionLog,
    String? concernedColumn,
  }) async {
    final response = await http.post(
      _uri('/api/logging'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'log_type': logType,
        'action_log': actionLog,
        'concerned_column': concernedColumn,
      }),
    );

    if (response.statusCode != 201) {
      _throwError(response);
    }

    return _decodeObject(response);
  }

  Future<List<Map<String, dynamic>>> listTemperatures({
    required int espNodeId,
    int limit = 400,
  }) async {
    final response = await http.get(
      _uri('/api/temperatures', {
        'esp_node_id': '$espNodeId',
        'limit': '$limit',
      }),
    );

    if (response.statusCode != 200) {
      _throwError(response);
    }

    return _decodeList(response)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> scanEsp32OnBackend({
    List<String> preferredHosts = const [],
    List<String> extraCandidates = const [],
    int timeoutMs = 700,
    int maxResults = 5,
    bool scanFullSubnet = true,
  }) async {
    final response = await http.post(
      _uri('/api/network/scan-esp32'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'preferred_hosts': preferredHosts,
        'extra_candidates': extraCandidates,
        'timeout_ms': timeoutMs,
        'max_results': maxResults,
        'scan_full_subnet': scanFullSubnet,
      }),
    );

    if (response.statusCode != 200) {
      _throwError(response);
    }

    return _decodeObject(response);
  }
}
