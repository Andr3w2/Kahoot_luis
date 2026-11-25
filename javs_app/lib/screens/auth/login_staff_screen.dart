import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../panel_maestro_screen.dart';

class LoginStaffScreen extends StatefulWidget {
  const LoginStaffScreen({super.key});

  @override
  State<LoginStaffScreen> createState() => _LoginStaffScreenState();
}

class _LoginStaffScreenState extends State<LoginStaffScreen> {
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _cargando = false;

  Future<void> _iniciarSesion() async {
    if (_correoCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;

    setState(() => _cargando = true);
    final res = await AuthService.login(
      _correoCtrl.text.trim(),
      _passCtrl.text,
    );
    setState(() => _cargando = false);

    if (!mounted) return;

    if (res['ok'] == true) {
      if (res['rol'] == 'Admin') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin/home',
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => PanelMaestroScreen(
              idMaestro: res['idUsuario'],
              nombreMaestro: res['nombre'],
            ),
          ),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['mensaje'] ?? 'Error al iniciar sesión')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso Maestros y Admin')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school, size: 72, color: Color(0xFF46178F)),
                const SizedBox(height: 16),
                const Text(
                  'Jabs Quizz! - Personal',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _cargando ? null : _iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF46178F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Iniciar Sesión',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/auth/registro-maestro'),
                  child: const Text(
                    '¿Tienes un código de invitación? Regístrate como Maestro',
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
