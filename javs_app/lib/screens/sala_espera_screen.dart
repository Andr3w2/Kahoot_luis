import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'juego_screen.dart';
import 'ranking_screen.dart';

class SalaEsperaScreen extends StatefulWidget {
  final int idCuestionario;
  final String tituloSala;
  final String codigoAcceso;
  final bool esMaestro;
  final int? idParticipacion;

  const SalaEsperaScreen({
    super.key,
    required this.idCuestionario,
    required this.tituloSala,
    required this.codigoAcceso,
    required this.esMaestro,
    this.idParticipacion,
  });

  @override
  State<SalaEsperaScreen> createState() => _SalaEsperaScreenState();
}

class _SalaEsperaScreenState extends State<SalaEsperaScreen> {
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  List<dynamic> _participantes = [];
  bool _iniciando = false;
  int _segundosEspera = 360;

  @override
  void initState() {
    super.initState();
    _prepararSala();
  }

  Future<void> _prepararSala() async {
    if (widget.esMaestro) {
      await ApiService.cambiarEstadoCuestionario(
        widget.idCuestionario,
        'Esperando',
      );
      await ApiService.limpiarSala(widget.idCuestionario);
    }

    await _sincronizarSala();

    // Sincroniza lista de alumnos y estado cada 2 segundos
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _sincronizarSala(),
    );

    // Temporizador de respaldo de 30 segundos
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_segundosEspera > 0) {
        setState(() => _segundosEspera--);
      } else {
        timer.cancel();
        // Si se agotan los 30s, el maestro inicia la sala automáticamente para todos
        if (widget.esMaestro && !_iniciando) {
          _iniciarPartidaMaestro();
        }
      }
    });
  }

  Future<void> _sincronizarSala() async {
    try {
      final lista = await ApiService.obtenerRanking(widget.idCuestionario);
      if (!mounted) return;
      setState(() => _participantes = lista);

      if (!widget.esMaestro) {
        final cuestionario = await ApiService.obtenerCuestionarioPorId(
          widget.idCuestionario,
        );
        final estado = (cuestionario?['estado'] ?? '').toString().toLowerCase();
        // MODIFICADO: Arranca de inmediato en cuanto el maestro inicia la sala
        if (estado == 'iniciado') {
          _irAJuego();
        }
      }
    } catch (_) {}
  }

  void _irAJuego() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => JuegoScreen(
          idCuestionario: widget.idCuestionario,
          idParticipacion: widget.idParticipacion ?? 1,
          tituloSala: widget.tituloSala,
        ),
      ),
    );
  }

  Future<void> _iniciarPartidaMaestro() async {
    if (_iniciando) return;
    setState(() => _iniciando = true);
    final ok = await ApiService.cambiarEstadoCuestionario(
      widget.idCuestionario,
      'Iniciado',
    );
    if (!mounted) return;
    setState(() => _iniciando = false);

    if (ok) {
      _pollingTimer?.cancel();
      _countdownTimer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RankingScreen(
            idCuestionario: widget.idCuestionario,
            tituloSala: widget.tituloSala,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo iniciar la sala. Revisa la API.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && widget.esMaestro) {
          await ApiService.cambiarEstadoCuestionario(
            widget.idCuestionario,
            'Cerrado',
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF46178F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(widget.tituloSala),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CÓDIGO DE SALA',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.codigoAcceso,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: Color(0xFF46178F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people_alt_rounded,
                        color: Colors.amber,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Integrantes: ${_participantes.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    backgroundColor: Colors.amber,
                    label: Text(
                      'Inicio auto: ${_segundosEspera}s',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _participantes.isEmpty
                    ? const Center(
                        child: Text(
                          'Esperando a que entren los alumnos...',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.8,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: _participantes.length,
                        itemBuilder: (context, index) {
                          final p = _participantes[index];
                          final nombre = p['nombreAlumno'] ?? 'Alumno';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.amber,
                                  child: Text(
                                    nombre.isNotEmpty
                                        ? nombre[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    nombre,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              if (widget.esMaestro)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _iniciando ? null : _iniciarPartidaMaestro,
                    icon: const Icon(Icons.play_arrow_rounded, size: 30),
                    label: Text(
                      _iniciando ? 'INICIANDO...' : '¡INICIAR PARTIDA!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26890C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.amber,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Esperando a que el maestro inicie...',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
