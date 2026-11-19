import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'ingreso_codigo_screen.dart';
import 'panel_maestro_screen.dart';

class SeleccionPerfilScreen extends StatefulWidget {
  const SeleccionPerfilScreen({super.key});

  @override
  State<SeleccionPerfilScreen> createState() => _SeleccionPerfilScreenState();
}

class _SeleccionPerfilScreenState extends State<SeleccionPerfilScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _claveMaestroController =
      TextEditingController(); // 1. NUEVO CONTROLADOR
  String? _rolSeleccionado;
  bool _cargando = false;

  Future<void> _continuarConPerfil() async {
    final nombre = _nombreController.text.trim();
    final claveDocente = _claveMaestroController.text.trim();

    if (nombre.isEmpty || _rolSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe tu nombre para continuar')),
      );
      return;
    }

    // 2. VALIDACIÓN LOCAL PREVIA PARA MAESTROS
    if (_rolSeleccionado == 'Maestro' && claveDocente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la clave de acceso docente')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final correoGenerado =
          '${nombre.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}@jabs.edu';

      final usuario = await ApiService.registrarUsuario(
        nombre: nombre,
        correo: correoGenerado,
        rol: _rolSeleccionado!,
        claveDocente: _rolSeleccionado == 'Maestro' ? claveDocente : null,
      );

      if (!mounted) return;

      // 3. SI LA API RECHAZA LA CLAVE (401), DETIENE EL ACCESO
      if (usuario == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFE21B3C),
            content: Text('Clave de maestro incorrecta. Acceso denegado.'),
          ),
        );
        return;
      }

      final int idUsuario = usuario['idUsuario'] ?? 2;

      if (_rolSeleccionado == 'Alumno') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                IngresoCodigoScreen(idUsuario: idUsuario, nombreAlumno: nombre),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PanelMaestroScreen(idMaestro: idUsuario, nombreMaestro: nombre),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al conectar perfil: $e')));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _claveMaestroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF46178F),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  '¿Quién va a jugar hoy?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _TarjetaRol(
                        titulo: 'Soy Alumno',
                        icono: Icons.school_rounded,
                        color: const Color(0xFF1368CE),
                        seleccionado: _rolSeleccionado == 'Alumno',
                        onTap: () =>
                            setState(() => _rolSeleccionado = 'Alumno'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TarjetaRol(
                        titulo: 'Soy Maestro',
                        icono: Icons.co_present_rounded,
                        color: const Color(0xFFD89E00),
                        seleccionado: _rolSeleccionado == 'Maestro',
                        onTap: () =>
                            setState(() => _rolSeleccionado = 'Maestro'),
                      ),
                    ),
                  ],
                ),
                if (_rolSeleccionado != null) ...[
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _rolSeleccionado == 'Alumno'
                              ? 'Escribe tu nombre o apodo'
                              : 'Nombre del Profesor(a)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nombreController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: _rolSeleccionado == 'Alumno'
                                ? 'Ej. Mateo'
                                : 'Ej. Prof. Laura',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        // 4. CAMPO DE CLAVE QUE SOLO SE MUESTRA PARA MAESTROS
                        if (_rolSeleccionado == 'Maestro') ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _claveMaestroController,
                            obscureText: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Clave de Maestro',
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _continuarConPerfil,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF26890C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _cargando
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'CONTINUAR',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaRol extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  const _TarjetaRol({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? Colors.white : Colors.transparent,
            width: 4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icono, size: 58, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
