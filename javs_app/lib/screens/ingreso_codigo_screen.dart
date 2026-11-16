import 'package:flutter/material.dart';

import '../services/api_service.dart';

class IngresoCodigoScreen extends StatefulWidget {
  const IngresoCodigoScreen({super.key});

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
      // 1. Buscar el cuestionario en la API .NET
      final cuestionario = await ApiService.buscarCuestionarioPorCodigo(codigo);

      if (cuestionario == null) {
        _mostrarMensaje(
          'Código no encontrado. Revisa las letras e intenta de nuevo.',
        );
        return;
      }

      final int idCuestionario = cuestionario['idCuestionario'];
      final String titulo = cuestionario['titulo'] ?? 'Cuestionario';

      // 2. Registrar participación (usando idUsuario: 2 de tu prueba en Swagger)
      final participacion = await ApiService.iniciarParticipacion(
        2,
        idCuestionario,
      );

      if (participacion == null) {
        _mostrarMensaje('No se pudo entrar a la sala. Intenta otra vez.');
        return;
      }

      if (!mounted) return;

      // Confirmación visual de conexión exitosa con SQLite
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('¡Listo para jugar!', textAlign: TextAlign.center),
          content: Text(
            'Sala: $titulo\nID Participación: ${participacion['idParticipacion']}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _mostrarMensaje(
        'Error de conexión con el servidor. Verifica que la API esté corriendo.',
      );
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
      backgroundColor: const Color(0xFF46178F), // Morado estilo Kahoot
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
