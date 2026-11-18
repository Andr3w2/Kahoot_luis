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

  // Registrar usuario (Alumno o Maestro)
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

  // Obtener lista de cuestionarios (para el panel del Maestro)
  static Future<List<dynamic>> obtenerCuestionarios() async {
    final response = await http.get(Uri.parse('$baseUrl/Cuestionarios'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  // Validar código de acceso de sala
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

  // Registrar entrada del alumno a la partida
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

  // Obtener preguntas con opciones de respuesta
  static Future<List<dynamic>> obtenerPreguntas(int idCuestionario) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Preguntas/cuestionario/$idCuestionario'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  // Enviar respuesta del alumno
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

  // Consultar ranking final
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
