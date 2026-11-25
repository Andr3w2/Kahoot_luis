import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../panel_maestro_screen.dart';

class RegistroMaestroScreen extends StatefulWidget {
  const RegistroMaestroScreen({super.key});

  @override
  State<RegistroMaestroScreen> createState() => _RegistroMaestroScreenState();
}

class _RegistroMaestroScreenState extends State<RegistroMaestroScreen> {
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  bool _cargando = false;

  Future<void> _registrar() async {
    if (_nombreCtrl.text.isEmpty ||
        _correoCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _codigoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => _cargando = true);
    final res = await AuthService.registrarMaestro(
      nombre: _nombreCtrl.text,
      correo: _correoCtrl.text,
      password: _passCtrl.text,
      codigoInvitacion: _codigoCtrl.text,
    );
    setState(() => _cargando = false);

    if (!mounted) return;

    if (res['ok'] == true) {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['mensaje'] ?? 'No se pudo completar el registro'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Maestro')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _codigoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Código de invitación (Ej. PROF-4829)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo del maestro',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
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
                    labelText: 'Crea tu contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _cargando ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF46178F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Crear Cuenta de Maestro',
                          style: TextStyle(fontSize: 16),
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
