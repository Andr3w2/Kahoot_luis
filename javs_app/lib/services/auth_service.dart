import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

typedef JsonMap = Map<String, dynamic>;
typedef HeaderMap = Map<String, String>;

class AuthService {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5062/api';
    }
    return 'http://localhost:5062/api';
  }

  static Future<void> guardarSesion(
    int idUsuario,
    String token,
    String rol,
    String nombre,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', idUsuario);
    await prefs.setString('jwt_token', token);
    await prefs.setString('user_rol', rol);
    await prefs.setString('user_nombre', nombre);
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('jwt_token');
    await prefs.remove('user_rol');
    await prefs.remove('user_nombre');
  }

  static Future<HeaderMap> headersConToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<JsonMap> login(String correo, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await guardarSesion(
        data['idUsuario'],
        data['token'],
        data['rol'],
        data['nombre'],
      );
      return {
        'ok': true,
        'idUsuario': data['idUsuario'],
        'rol': data['rol'],
        'nombre': data['nombre'],
      };
    }
    return {'ok': false, 'mensaje': response.body};
  }

  static Future<JsonMap> registrarMaestro({
    required String nombre,
    required String correo,
    required String password,
    required String codigoInvitacion,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/registro-maestro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'codigoInvitacion': codigoInvitacion,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await guardarSesion(
        data['idUsuario'],
        data['token'],
        data['rol'],
        data['nombre'],
      );
      return {
        'ok': true,
        'idUsuario': data['idUsuario'],
        'rol': data['rol'],
        'nombre': data['nombre'],
      };
    }
    return {'ok': false, 'mensaje': response.body};
  }

  static Future<JsonMap?> generarCodigoInvitacion() async {
    final headers = await headersConToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/codigos'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as JsonMap;
    }
    return null;
  }

  static Future<List<dynamic>> obtenerCodigos() async {
    final headers = await headersConToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/codigos'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  static Future<List<dynamic>> obtenerMaestros() async {
    final headers = await headersConToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/maestros'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  static Future<bool> cambiarEstadoMaestro(int idUsuario, bool activo) async {
    final headers = await headersConToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/maestros/$idUsuario/estado'),
      headers: headers,
      body: jsonEncode(activo),
    );
    return response.statusCode == 200;
  }
}
