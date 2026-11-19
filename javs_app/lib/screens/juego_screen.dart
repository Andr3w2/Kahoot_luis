import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'ranking_screen.dart';

/// Pantalla principal de juego donde el alumno visualiza cada pregunta,
/// selecciona una opción antes de que se agote el tiempo límite y acumula puntaje.
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
  // Estado del cuestionario y control de navegación entre preguntas
  List<dynamic> _preguntas = [];
  int _indiceActual = 0;
  bool _cargando = true;
  bool _respondiendo = false;

  // Variables para el temporizador de cuenta regresiva por pregunta
  Timer? _timer;
  int _segundosTranscurridos = 0;
  int _tiempoLimite = 20;

  // Paleta de colores e íconos estilo Kahoot para los 4 botones de respuesta
  final List<Color> _coloresOpciones = const [
    Color(0xFFE21B3C), // Rojo
    Color(0xFF1368CE), // Azul
    Color(0xFFD89E00), // Amarillo
    Color(0xFF26890C), // Verde
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

  /// Obtiene desde la API todas las preguntas y opciones asociadas al cuestionario.
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

  /// Reinicia e inicia el reloj de cuenta regresiva según el tiempo límite
  /// configurado en la pregunta actual. Si el tiempo llega a 0, avanza sola.
  void _iniciarTemporizador() {
    _timer?.cancel();
    final preguntaActual = _preguntas[_indiceActual];
    _tiempoLimite =
        int.tryParse(preguntaActual['tiempoLimite']?.toString() ?? '30') ?? 30;
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

  /// Convierte los segundos transcurridos al formato HH:mm:ss esperado por
  /// el tipo TimeSpan/String del backend en .NET.
  String _formatearTimeSpan(int segundos) {
    final horas = (segundos ~/ 3600).toString().padLeft(2, '0');
    final minutos = ((segundos % 3600) ~/ 60).toString().padLeft(2, '0');
    final segs = (segundos % 60).toString().padLeft(2, '0');
    return '$horas:$minutos:$segs';
  }

  /// Envía la opción seleccionada por el alumno a la API, recibe si fue correcta
  /// y muestra retroalimentación visual antes de avanzar a la siguiente pregunta.
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

      if (resultado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La API rechazó la respuesta (revisa Models/Respuesta.cs).',
            ),
          ),
        );
        setState(() => _respondiendo = false);
        return;
      }

      // Conversión segura de los valores String devueltos por SQLite/.NET
      final String esCorrectaStr = (resultado['esCorrecta'] ?? 'false')
          .toString()
          .toLowerCase();
      final bool esCorrecta = esCorrectaStr == 'true' || esCorrectaStr == '1';
      final String puntos = (resultado['puntosObtenidos'] ?? '0').toString();

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

  /// Avanza al siguiente índice de pregunta o redirige al podio final
  /// cuando ya se respondieron todas.
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

  /// Muestra un cuadro de diálogo de advertencia cuando el alumno intenta
  /// regresar o salir de la pantalla en medio del cuestionario (anti-misclick).
  Future<void> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('¿Salir de la partida?'),
          ],
        ),
        content: const Text(
          'Si sales ahora perderás tu avance en este cuestionario y no podrás volver a entrar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir jugando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE21B3C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (salir == true && mounted) {
      _timer?.cancel();
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    // Libera el temporizador de memoria al destruir la pantalla
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

    // CORRECCIÓN APLICADA AQUÍ: Se envuelve el Scaffold principal en PopScope
    // para interceptar el botón de regreso y ejecutar _confirmarSalida().
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmarSalida();
        }
      },
      child: Scaffold(
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
              // Indicador circular de segundos restantes
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
              // Tarjeta con el enunciado de la pregunta
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
                  pregunta['texto'] ?? pregunta['textoPregunta'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Lista de botones de opciones de respuesta
              Expanded(
                child: ListView.separated(
                  itemCount: opciones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final opcion = opciones[index];
                    final color =
                        _coloresOpciones[index % _coloresOpciones.length];
                    final icono =
                        _iconosOpciones[index % _iconosOpciones.length];

                    return SizedBox(
                      height: 68,
                      child: ElevatedButton.icon(
                        onPressed: _respondiendo
                            ? null
                            : () => _seleccionarOpcion(opcion),
                        icon: Icon(icono, size: 28, color: Colors.white),
                        label: Text(
                          opcion['texto'] ?? opcion['textoOpcion'] ?? '',
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
      ),
    );
  }
}
