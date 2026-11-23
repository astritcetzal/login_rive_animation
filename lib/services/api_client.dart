import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String backendUsername = 'Astrit Cetzal';
  static const String backendPassword = '1234';
  // Chrome / Windows: localhost. Celular: http://192.168.1.6:8090
  static const String baseUrl = 'http://localhost:8090';

  static String? _token;

  static Map<String, String> get _authHeaders => {
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

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
      Uri.parse('$baseUrl/Orders/'),
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