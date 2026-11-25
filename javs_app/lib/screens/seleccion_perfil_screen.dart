import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'ingreso_codigo_screen.dart';
import 'auth/login_staff_screen.dart';

class SeleccionPerfilScreen extends StatefulWidget {
  const SeleccionPerfilScreen({super.key});

  @override
  State<SeleccionPerfilScreen> createState() => _SeleccionPerfilScreenState();
}

class _SeleccionPerfilScreenState extends State<SeleccionPerfilScreen> {
  final TextEditingController _nombreController = TextEditingController();
  bool _mostrarInputAlumno = false;
  bool _cargando = false;

  Future<void> _continuarComoAlumno() async {
    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe tu nombre para continuar')),
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
        rol: 'Alumno',
      );

      if (!mounted) return;

      final int idUsuario = usuario?['idUsuario'] ?? 2;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              IngresoCodigoScreen(idUsuario: idUsuario, nombreAlumno: nombre),
        ),
      );
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
                        seleccionado: _mostrarInputAlumno,
                        onTap: () => setState(() => _mostrarInputAlumno = true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TarjetaRol(
                        titulo: 'Maestro / Admin',
                        icono: Icons.co_present_rounded,
                        color: const Color(0xFFD89E00),
                        seleccionado: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginStaffScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (_mostrarInputAlumno) ...[
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Escribe tu nombre o apodo',
                          style: TextStyle(
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
                            hintText: 'Ej. Mateo',
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
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _continuarComoAlumno,
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
