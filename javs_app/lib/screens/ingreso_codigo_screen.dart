import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'sala_espera_screen.dart';

class IngresoCodigoScreen extends StatefulWidget {
  final int idUsuario;
  final String nombreAlumno;

  const IngresoCodigoScreen({
    super.key,
    this.idUsuario = 2,
    this.nombreAlumno = 'Alumno',
  });

  @override
  State<IngresoCodigoScreen> createState() => _IngresoCodigoScreenState();
}

class _IngresoCodigoScreenState extends State<IngresoCodigoScreen> {
  final TextEditingController _codigoController = TextEditingController();
  bool _cargando = false;

  Future<void> _entrarASala() async {
    final codigo = _codigoController.text.trim().toUpperCase();

    if (codigo.isEmpty) {
      _mostrarMensaje('Escribe el código de la sala para jugar');
      return;
    }

    setState(() => _cargando = true);

    try {
      final cuestionario = await ApiService.buscarCuestionarioPorCodigo(codigo);

      // 1. MODIFICADO: Mensaje más claro cuando la API devuelve 404/400 (código inválido o sala cerrada)
      if (cuestionario == null) {
        _mostrarMensaje(
          'La sala no existe o aún no ha sido abierta por el maestro.',
        );
        return;
      }

      // 2. AGREGADO: Validación explícita del estado de la sala antes de registrar al alumno
      final String estado = (cuestionario['estado'] ?? '').toString();
      if (estado != 'Esperando') {
        _mostrarMensaje(
          'La sala aún no está abierta. Espera a que el maestro la abra.',
        );
        return;
      }

      final int idCuestionario = cuestionario['idCuestionario'];
      final String titulo = cuestionario['titulo'] ?? 'Cuestionario';

      final participacion = await ApiService.iniciarParticipacion(
        widget.idUsuario,
        idCuestionario,
      );

      if (participacion == null) {
        _mostrarMensaje('No se pudo entrar a la sala. Intenta otra vez.');
        return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SalaEsperaScreen(
            idCuestionario: idCuestionario,
            tituloSala: titulo,
            codigoAcceso: codigo,
            esMaestro: false,
            idParticipacion: participacion['idParticipacion'],
          ),
        ),
      );
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF46178F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Hola, ${widget.nombreAlumno}'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.extension_rounded,
                  size: 72,
                  color: Colors.amber,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Jabs Quizz!',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _codigoController,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'CÓDIGO',
                          counterText: '',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _entrarASala,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF26890C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _cargando
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  '¡ENTRAR!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
