import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'ranking_screen.dart';

class JuegoScreen extends StatefulWidget {
  final int idCuestionario;
  final int idParticipacion;
  final String tituloSala;

  const JuegoScreen({
    super.key,
    required this.idCuestionario,
    required this.idParticipacion,
    required this.tituloSala,
  });

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> {
  List<dynamic> _preguntas = [];
  int _indiceActual = 0;
  bool _cargando = true;
  bool _respondiendo = false;

  Timer? _timer;
  int _segundosTranscurridos = 0;
  int _tiempoLimite = 20;

  final List<Color> _coloresOpciones = const [
    Color(0xFFE21B3C),
    Color(0xFF1368CE),
    Color(0xFFD89E00),
    Color(0xFF26890C),
  ];

  final List<IconData> _iconosOpciones = const [
    Icons.change_history_rounded,
    Icons.square_rounded,
    Icons.circle,
    Icons.star_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _cargarPreguntas();
  }

  Future<void> _cargarPreguntas() async {
    try {
      final datos = await ApiService.obtenerPreguntas(widget.idCuestionario);
      if (!mounted) return;
      setState(() {
        _preguntas = datos;
        _cargando = false;
      });
      if (_preguntas.isNotEmpty) {
        _iniciarTemporizador();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar preguntas: $e')));
    }
  }

  void _iniciarTemporizador() {
    _timer?.cancel();
    final preguntaActual = _preguntas[_indiceActual];
    _tiempoLimite = preguntaActual['tiempoLimite'] ?? 20;
    _segundosTranscurridos = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_segundosTranscurridos >= _tiempoLimite) {
        _timer?.cancel();
        _siguientePregunta();
      } else {
        setState(() => _segundosTranscurridos++);
      }
    });
  }

  String _formatearTimeSpan(int segundos) {
    final horas = (segundos ~/ 3600).toString().padLeft(2, '0');
    final minutos = ((segundos % 3600) ~/ 60).toString().padLeft(2, '0');
    final segs = (segundos % 60).toString().padLeft(2, '0');
    return '$horas:$minutos:$segs';
  }

  Future<void> _seleccionarOpcion(Map<String, dynamic> opcion) async {
    if (_respondiendo) return;
    _timer?.cancel();
    setState(() => _respondiendo = true);

    final preguntaActual = _preguntas[_indiceActual];
    final int idPregunta = preguntaActual['idPregunta'];
    final int idOpcion = opcion['idOpcion'];

    try {
      final resultado = await ApiService.enviarRespuesta(
        idParticipacion: widget.idParticipacion,
        idPregunta: idPregunta,
        idOpcion: idOpcion,
        tiempoRespuesta: _formatearTimeSpan(_segundosTranscurridos),
      );

      if (!mounted) return;

      final bool esCorrecta = resultado?['esCorrecta'] ?? false;
      final int puntos = resultado?['puntosObtenidos'] ?? 0;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: esCorrecta
              ? const Color(0xFF26890C)
              : const Color(0xFFE21B3C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Icon(
            esCorrecta ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: Colors.white,
            size: 64,
          ),
          content: Text(
            esCorrecta
                ? '¡Correcto!\n+$puntos puntos'
                : '¡Incorrecto!\n0 puntos',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Siguiente'),
              ),
            ),
          ],
        ),
      );

      _siguientePregunta();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al enviar respuesta: $e')));
      setState(() => _respondiendo = false);
    }
  }

  void _siguientePregunta() {
    if (!mounted) return;
    if (_indiceActual + 1 < _preguntas.length) {
      setState(() {
        _indiceActual++;
        _respondiendo = false;
      });
      _iniciarTemporizador();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RankingScreen(
            idCuestionario: widget.idCuestionario,
            tituloSala: widget.tituloSala,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF46178F),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_preguntas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.tituloSala)),
        body: const Center(
          child: Text('Este cuestionario aún no tiene preguntas.'),
        ),
      );
    }

    final pregunta = _preguntas[_indiceActual];
    final List<dynamic> opciones = pregunta['opcionesRespuesta'] ?? [];
    final int segundosRestantes = (_tiempoLimite - _segundosTranscurridos)
        .clamp(0, _tiempoLimite);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF46178F),
        foregroundColor: Colors.white,
        title: Text('Pregunta ${_indiceActual + 1} de ${_preguntas.length}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF46178F),
              child: Text(
                '$segundosRestantes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                pregunta['textoPregunta'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: opciones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final opcion = opciones[index];
                  final color =
                      _coloresOpciones[index % _coloresOpciones.length];
                  final icono = _iconosOpciones[index % _iconosOpciones.length];

                  return SizedBox(
                    height: 68,
                    child: ElevatedButton.icon(
                      onPressed: _respondiendo
                          ? null
                          : () => _seleccionarOpcion(opcion),
                      icon: Icon(icono, size: 28, color: Colors.white),
                      label: Text(
                        opcion['textoOpcion'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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
