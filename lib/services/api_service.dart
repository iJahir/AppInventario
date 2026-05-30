import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/db_config.dart';

class ApiService {
  final String baseUrl = DbConfig.apiBaseUrl;

  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'X-Database-Name': DbConfig.databaseName, // Pasa el nombre de la BD en los headers por si el backend lo requiere
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Realiza una solicitud HTTP GET
  Future<dynamic> get(String endpoint, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('GET Request to: $url');
    try {
      final response = await http
          .get(url, headers: _getHeaders(token: token))
          .timeout(const Duration(seconds: DbConfig.connectionTimeoutSeconds));
      return _processResponse(response);
    } catch (e) {
      print('GET Error: $e');
      throw Exception('Error de conexión a la base de datos/servidor: $e');
    }
  }

  /// Realiza una solicitud HTTP POST
  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('POST Request to: $url with data: $data');
    try {
      final response = await http
          .post(
            url,
            headers: _getHeaders(token: token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: DbConfig.connectionTimeoutSeconds));
      return _processResponse(response);
    } catch (e) {
      print('POST Error: $e');
      throw Exception('Error de conexión a la base de datos/servidor: $e');
    }
  }

  /// Realiza una solicitud HTTP PUT
  Future<dynamic> put(String endpoint, Map<String, dynamic> data, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('PUT Request to: $url with data: $data');
    try {
      final response = await http
          .put(
            url,
            headers: _getHeaders(token: token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: DbConfig.connectionTimeoutSeconds));
      return _processResponse(response);
    } catch (e) {
      print('PUT Error: $e');
      throw Exception('Error de conexión a la base de datos/servidor: $e');
    }
  }

  /// Realiza una solicitud HTTP DELETE
  Future<dynamic> delete(String endpoint, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('DELETE Request to: $url');
    try {
      final response = await http
          .delete(url, headers: _getHeaders(token: token))
          .timeout(const Duration(seconds: DbConfig.connectionTimeoutSeconds));
      return _processResponse(response);
    } catch (e) {
      print('DELETE Error: $e');
      throw Exception('Error de conexión a la base de datos/servidor: $e');
    }
  }

  /// Procesa la respuesta HTTP y maneja errores comunes
  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      print('HTTP Error Status: $statusCode, Body: $body');
      String errorMessage = 'Error del servidor ($statusCode)';
      try {
        final parsed = jsonDecode(body);
        if (parsed is Map && parsed.containsKey('message')) {
          errorMessage = parsed['message'];
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
