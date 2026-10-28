import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiClient {
  final String? _customBaseUrl;

  ApiClient({String? baseUrl}) : _customBaseUrl = baseUrl;

  String get baseUrl => _customBaseUrl ?? ApiConstants.defaultBaseUrl;


  Map<String, String> _buildHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {String? token}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .get(uri, headers: _buildHeaders(token))
        .timeout(const Duration(seconds: 90));

    return _handleResponse(response);
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .post(
          uri,
          headers: _buildHeaders(token),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 90));

    return _handleResponse(response);
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .put(
          uri,
          headers: _buildHeaders(token),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 90));

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Lỗi máy chủ (${response.statusCode})';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('message')) {
          final msg = errorData['message'];
          errorMessage = msg is List ? msg.join(', ') : msg.toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
