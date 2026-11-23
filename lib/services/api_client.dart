import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // Encapsulamiento: los getters leen el entorno de forma segura y centralizada
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://localhost:8090';

  static String get backendUsername => dotenv.env['BACKEND_USERNAME'] ?? '';

  static String get _backendPassword => dotenv.env['BACKEND_PASSWORD'] ?? '';

  static String? _token;

  static Map<String, String> get _authHeaders => {
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // Método sobrecargado o directo que usa las credenciales del entorno
  static Future<void> loginWithEnvCredentials() async {
    await login(backendUsername, _backendPassword);
  }

  static Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      var token = response.body.trim();
      if (token.startsWith('"') && token.endsWith('"')) {
        token = token.substring(1, token.length - 1);
      }
      if (token.isEmpty) {
        throw Exception('El servidor no devolvió un token');
      }
      _token = token;
      return;
    }

    if (response.statusCode == 401) {
      throw Exception('Credenciales no válidas');
    }
    throw Exception('El servidor respondió ${response.statusCode}');
  }

  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: _authHeaders,
    );
    return _decodeList(response);
  }

  static Future<List<dynamic>> getOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: _authHeaders,
    );
    return _decodeList(response);
  }

  static List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sesión no autorizada. Vuelve a iniciar sesión.');
    }
    throw Exception('El servidor respondió ${response.statusCode}');
  }
  static void logout() {
    _token = null;
  }
}