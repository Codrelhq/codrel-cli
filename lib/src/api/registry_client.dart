import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/cli_component.dart';

/// Exception thrown when a registry network or parsing operation fails.
class RegistryException implements Exception {
  final String message;
  const RegistryException(this.message);

  @override
  String toString() => message;
}

/// Client for communicating with the remote Codrel component registry.
class RegistryClient {
  final String baseUrl;
  final String apiKey;
  final http.Client _httpClient;

  RegistryClient({
    String? baseUrl,
    String? apiKey,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ??
            Platform.environment['CODREL_SUPABASE_URL'] ??
            'https://plmlqswnblgtsnvhbmjs.supabase.co',
        apiKey = apiKey ??
            Platform.environment['CODREL_SUPABASE_KEY'] ??
            'sb_publishable_wn16IRfYvn_TmPiQfMbn0A_UnkyB9p4',
        _httpClient = httpClient ?? http.Client();

  Map<String, String> get _headers => {
        'apikey': apiKey,
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  /// Fetches all available components from the registry.
  Future<List<CliComponent>> listComponents() async {
    try {
      final uri = Uri.parse(
        '$baseUrl/rest/v1/components?select=id,name,file_name,description,complexity,tags,downloads_count,created_at&order=id.asc',
      );
      final response = await _httpClient
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) => CliComponent.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw RegistryException(
          'Failed to retrieve components from registry (HTTP ${response.statusCode}).',
        );
      }
    } on SocketException {
      throw const RegistryException(
        'Unable to connect to the Codrel registry. Please verify your internet connection.',
      );
    } on TimeoutException {
      throw const RegistryException(
        'Connection to the Codrel registry timed out. Please try again.',
      );
    } on FormatException {
      throw const RegistryException(
        'Received an invalid response format from the registry.',
      );
    }
  }

  /// Retrieves a single component by its unique identifier or slug.
  Future<CliComponent?> getComponent(String id) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/rest/v1/components?id=eq.$id&select=*',
      );
      final response = await _httpClient
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        if (list.isNotEmpty) {
          return CliComponent.fromJson(list.first as Map<String, dynamic>);
        }
        return null;
      } else {
        throw RegistryException(
          'Failed to retrieve component "$id" (HTTP ${response.statusCode}).',
        );
      }
    } on SocketException {
      throw const RegistryException(
        'Unable to connect to the Codrel registry. Please verify your internet connection.',
      );
    } on TimeoutException {
      throw const RegistryException(
        'Connection to the Codrel registry timed out. Please try again.',
      );
    } on FormatException {
      throw const RegistryException(
        'Received an invalid response format from the registry.',
      );
    }
  }

  /// Requests architectural conversion for a component via the edge function.
  Future<String?> getArchitectureFromCloud({
    required String componentId,
    required String architecture,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/functions/v1/convert-architecture');
      final response = await _httpClient
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({
              'component_id': componentId,
              'architecture': architecture,
            }),
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['code'] is String) {
          final code = (data['code'] as String).trim();
          if (code.contains('class ') && !code.startsWith('parent passes')) {
            return code;
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Increments the download counter for a component.
  Future<bool> incrementDownloads(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/rest/v1/rpc/increment_downloads');
      final response = await _httpClient
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({'row_id': id}),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Closes the underlying HTTP client.
  void close() {
    _httpClient.close();
  }
}
