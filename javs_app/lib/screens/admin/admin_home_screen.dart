import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List<dynamic> _codigos = [];
  List<dynamic> _maestros = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final codigos = await AuthService.obtenerCodigos();
    final maestros = await AuthService.obtenerMaestros();
    if (!mounted) return;
    setState(() {
      _codigos = codigos;
      _maestros = maestros;
      _cargando = false;
    });
  }

  Future<void> _nuevoCodigo() async {
    final creado = await AuthService.generarCodigoInvitacion();
    if (!mounted) return;

    if (creado != null) {
      final codigo = creado['codigo'].toString();
      await Clipboard.setData(ClipboardData(text: codigo));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código $codigo generado y copiado al portapapeles'),
        ),
      );
      _cargarDatos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al generar código. Verifica tu sesión.'),
        ),
      );
    }
  }

  Future<void> _toggleMaestro(int idUsuario, bool nuevoEstado) async {
    final ok = await AuthService.cambiarEstadoMaestro(idUsuario, nuevoEstado);
    if (ok) _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Administrador'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await AuthService.cerrarSesion();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.vpn_key), text: 'Códigos'),
              Tab(icon: Icon(Icons.people), text: 'Maestros'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _nuevoCodigo,
          icon: const Icon(Icons.add),
          label: const Text('Generar Código'),
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: _cargarDatos,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _codigos.length,
                      itemBuilder: (context, i) {
                        final item = _codigos[i];
                        final usado = item['usado'] == true;
                        final codigo = item['codigo'] ?? '';
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              usado ? Icons.check_circle : Icons.timer,
                              color: usado ? Colors.grey : Colors.green,
                            ),
                            title: Text(
                              codigo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              usado
                                  ? 'Estado: Ya utilizado'
                                  : 'Estado: Disponible (48h)',
                            ),
                            trailing: usado
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: codigo),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            SnackBar(
                                              content: Text('Copiado: $codigo'),
                                            ),
                                          );
                                    },
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: _cargarDatos,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _maestros.length,
                      itemBuilder: (context, i) {
                        final m = _maestros[i];
                        final activo = m['activo'] == true;
                        return Card(
                          child: SwitchListTile(
                            title: Text(m['nombre'] ?? ''),
                            subtitle: Text(m['correo'] ?? ''),
                            value: activo,
                            onChanged: (val) =>
                                _toggleMaestro(m['idUsuario'], val),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
