import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RankingScreen extends StatefulWidget {
  final int idCuestionario;
  final String tituloSala;

  const RankingScreen({
    super.key,
    required this.idCuestionario,
    required this.tituloSala,
  });

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<dynamic>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = ApiService.obtenerRanking(widget.idCuestionario);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF46178F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Podio - ${widget.tituloSala}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar puntajes',
            onPressed: () {
              setState(() {
                _rankingFuture = ApiService.obtenerRanking(
                  widget.idCuestionario,
                );
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          final ranking = snapshot.data ?? [];
          if (ranking.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay puntajes registrados.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 76,
                  color: Colors.amber,
                ),
                const SizedBox(height: 8),
                const Text(
                  '¡Tabla de Posiciones!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: ranking.length,
                    itemBuilder: (context, index) {
                      final item = ranking[index];
                      final String nombre =
                          item['nombreAlumno'] ??
                          item['usuario']?['nombre'] ??
                          'Jugador #${item['idUsuario'] ?? index + 1}';
                      final int puntaje =
                          int.tryParse(
                            item['puntuacionTotal']?.toString() ?? '0',
                          ) ??
                          0;

                      Color colorTarjeta = Colors.white;
                      IconData icono = Icons.person;
                      Color colorMedalla = Colors.grey;

                      if (index == 0) {
                        colorTarjeta = const Color(0xFFFFF8E1);
                        icono = Icons.looks_one_rounded;
                        colorMedalla = const Color(0xFFFFB300); // Oro
                      } else if (index == 1) {
                        icono = Icons.looks_two_rounded;
                        colorMedalla = const Color(0xFF90A4AE); // Plata
                      } else if (index == 2) {
                        icono = Icons.looks_3_rounded;
                        colorMedalla = const Color(0xFFA1887F); // Bronce
                      }

                      return Card(
                        color: colorTarjeta,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: colorMedalla,
                            child: Icon(icono, color: Colors.white),
                          ),
                          title: Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Text(
                            '$puntaje pts',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF46178F),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    // MODIFICADO: Cierra la sala en SQLite antes de regresar al menú inicial
                    onPressed: () async {
                      await ApiService.cambiarEstadoCuestionario(
                        widget.idCuestionario,
                        'Cerrado',
                      );
                      if (!context.mounted) return;
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26890C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'VOLVER AL INICIO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
