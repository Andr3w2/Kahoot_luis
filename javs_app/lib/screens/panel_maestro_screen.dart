import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'ranking_screen.dart';
import 'sala_espera_screen.dart'; // 1. NUEVO IMPORT

class PanelMaestroScreen extends StatefulWidget {
  final int idMaestro;
  final String nombreMaestro;

  const PanelMaestroScreen({
    super.key,
    required this.idMaestro,
    required this.nombreMaestro,
  });

  @override
  State<PanelMaestroScreen> createState() => _PanelMaestroScreenState();
}

class _PanelMaestroScreenState extends State<PanelMaestroScreen> {
  late Future<List<dynamic>> _cuestionariosFuture;

  @override
  void initState() {
    super.initState();
    _cuestionariosFuture = ApiService.obtenerCuestionarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF46178F),
        foregroundColor: Colors.white,
        title: Text('Hola, ${widget.nombreMaestro}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _cuestionariosFuture = ApiService.obtenerCuestionarios();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _cuestionariosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = snapshot.data ?? [];
          if (lista.isEmpty) {
            return const Center(
              child: Text('No hay cuestionarios creados aún.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final q = lista[index];
              final String codigo = q['codigoAcceso'] ?? '------';
              final String titulo = q['titulo'] ?? 'Sin título';
              final int idCuestionario = q['idCuestionario'];

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        backgroundColor: Colors.amber.shade100,
                        label: Text(
                          'CÓDIGO: $codigo',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 2. NUEVA FILA DE BOTONES DE ACCIÓN PARA EL MAESTRO
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SalaEsperaScreen(
                                      idCuestionario: idCuestionario,
                                      tituloSala: titulo,
                                      codigoAcceso: codigo,
                                      esMaestro: true,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF26890C),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.groups_rounded),
                              label: const Text('Abrir Sala'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RankingScreen(
                                    idCuestionario: idCuestionario,
                                    tituloSala: titulo,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.emoji_events),
                            label: const Text('Podio'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
