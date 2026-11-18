import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5062/api';
    }
    return 'http://127.0.0.1:5062/api';
  }

  static Future<Map<String, dynamic>?> registrarUsuario({
    required String nombre,
    required String correo,
    required String rol,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'contrasena': '123',
        'rol': rol,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<List<dynamic>> obtenerCuestionarios() async {
    final response = await http.get(Uri.parse('$baseUrl/Cuestionarios'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>?> obtenerCuestionarioPorId(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/Cuestionarios/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> cambiarEstadoCuestionario(int idCuestionario, String estado) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Cuestionarios/$idCuestionario/estado'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(estado),
    );
    return response.statusCode == 200;
  }

  static Future<void> limpiarSala(int idCuestionario) async {
    await http.delete(Uri.parse('$baseUrl/Participaciones/cuestionario/$idCuestionario'));
  }

  static Future<Map<String, dynamic>?> buscarCuestionarioPorCodigo(
    String codigo,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Cuestionarios/codigo/$codigo'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> iniciarParticipacion(
    int idUsuario,
    int idCuestionario,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Participaciones'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idUsuario': idUsuario,
        'idCuestionario': idCuestionario,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<List<dynamic>> obtenerPreguntas(int idCuestionario) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Preguntas/cuestionario/$idCuestionario'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>?> enviarRespuesta({
    required int idParticipacion,
    required int idPregunta,
    required int idOpcion,
    required String tiempoRespuesta,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Respuestas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idParticipacion': idParticipacion,
        'idPregunta': idPregunta,
        'idOpcion': idOpcion,
        'tiempoRespuesta': tiempoRespuesta,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<List<dynamic>> obtenerRanking(int idCuestionario) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Participaciones/ranking/$idCuestionario'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }
}
