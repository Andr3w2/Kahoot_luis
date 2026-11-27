import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/auth_service.dart';

class AnaliticaOlapScreen extends StatefulWidget {
  final bool mostrarCubo3d;

  const AnaliticaOlapScreen({super.key, this.mostrarCubo3d = true});

  @override
  State<AnaliticaOlapScreen> createState() => _AnaliticaOlapScreenState();
}

class _AnaliticaOlapScreenState extends State<AnaliticaOlapScreen> {
  int _trimestre = 0; // 0 = Todos, 1 = Q1, 2 = Q2, 3 = Q3
  String _nivel = 'area';
  String _modoCubo = 'respuestas'; // 'respuestas', 'constelacion', 'tiempos'
  String _dimensionVista = '3d'; // '3d' o '4d'
  bool _cargando = true;
  Map<String, dynamic>? _cuboData;

  final ScrollController _scroll4dController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarCubo();
  }

  @override
  void dispose() {
    _scroll4dController.dispose();
    super.dispose();
  }

  void _moverVista4d(double delta) {
    if (!_scroll4dController.hasClients) return;
    final destino = (_scroll4dController.offset + delta).clamp(
      0.0,
      _scroll4dController.position.maxScrollExtent,
    );
    _scroll4dController.animateTo(
      destino,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _cargarCubo() async {
    setState(() => _cargando = true);
    try {
      final url = Uri.parse(
        '${AuthService.baseUrl}/analytics/cubo?trimestre=$_trimestre&nivel=$_nivel',
      );
      final response = await http.get(url);
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _cuboData = jsonDecode(response.body) as Map<String, dynamic>;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String get _textoCorte {
    switch (_trimestre) {
      case 1:
        return 'Slice Activo: Q1 (Marzo)';
      case 2:
        return 'Slice Activo: Q2 (Abril – Junio)';
      case 3:
        return 'Slice Activo: Q3 (Julio – Agosto)';
      default:
        return 'Cubo Completo: Q1 – Q3 (Marzo – Agosto)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumen = _cuboData?['resumen'] as Map<String, dynamic>?;
    final cubo3d = _cuboData?['cubo3d'] as Map<String, dynamic>?;
    final cubo4d = (_cuboData?['cubo4d'] as List<dynamic>?) ?? [];
    final datos = (_cuboData?['datos'] as List<dynamic>?) ?? [];

    int maxValor = 1;
    for (final item in datos) {
      final c = (item['consultas'] as num).toInt();
      final r = (item['totalRespuestas'] as num).toInt();
      if (c > maxValor) maxValor = c;
      if (r > maxValor) maxValor = r;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mostrarCubo3d
              ? 'Minería de Datos — Cubo OLAP'
              : 'Estadísticas de Desempeño',
        ),
        backgroundColor: const Color(0xFF46178F),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF46178F).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF46178F)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dimensión Fija: Escuela Fernando Montaño • 1.º Primaria (Tepic, Nayarit)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SECCIÓN 1: CUBO OLAP 3D Y VISTA 4D (SOLO ADMINISTRADOR)
                  if (widget.mostrarCubo3d && cubo3d != null) ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _dimensionVista == '3d'
                                            ? 'Cubo OLAP 3D (Tiempo × Área × Métrica)'
                                            : 'Vista OLAP 4D (+ 4ª Dimensión: DIM_USUARIO)',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF46178F),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _textoCorte,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _trimestre == 0
                                              ? Colors.grey.shade700
                                              : const Color(0xFF1368CE),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: '3d',
                                      label: Text('Vista 3D'),
                                    ),
                                    ButtonSegment(
                                      value: '4d',
                                      label: Text('Vista 4D'),
                                    ),
                                  ],
                                  selected: {_dimensionVista},
                                  onSelectionChanged: (val) {
                                    setState(() => _dimensionVista = val.first);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'respuestas',
                                  label: Text('Correctas vs. Incorrectas'),
                                ),
                                ButtonSegment(
                                  value: 'constelacion',
                                  label: Text('Consultas vs. Respuestas'),
                                ),
                                ButtonSegment(
                                  value: 'tiempos',
                                  label: Text('Tiempo Prom. (s)'),
                                ),
                              ],
                              selected: {_modoCubo},
                              onSelectionChanged: (val) {
                                setState(() => _modoCubo = val.first);
                              },
                            ),
                            const SizedBox(height: 14),

                            if (_dimensionVista == '3d')
                              SizedBox(
                                height: 340,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: _CuboOlapPainter(
                                    cubo3d: cubo3d,
                                    modo: _modoCubo,
                                    trimestreSeleccionado: _trimestre,
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  // Botones de navegación rápida para los cubos 4D
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Desplaza la barra inferior o usa las flechas:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.outlined(
                                        icon: const Icon(Icons.chevron_left),
                                        tooltip: 'Desplazar a la izquierda',
                                        onPressed: () => _moverVista4d(-540),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton.outlined(
                                        icon: const Icon(Icons.chevron_right),
                                        tooltip: 'Desplazar a la derecha',
                                        onPressed: () => _moverVista4d(540),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Scrollbar(
                                    controller: _scroll4dController,
                                    thumbVisibility: true,
                                    trackVisibility: true,
                                    thickness: 10,
                                    radius: const Radius.circular(8),
                                    child: SingleChildScrollView(
                                      controller: _scroll4dController,
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Row(
                                        children: cubo4d.map((item) {
                                          final grupoMap =
                                              item as Map<String, dynamic>;
                                          final tituloGrupo =
                                              grupoMap['etiquetaGrupo']
                                                  .toString();
                                          final datosCubo =
                                              grupoMap['datosCubo']
                                                  as Map<String, dynamic>;

                                          return Container(
                                            width: 530,
                                            margin: const EdgeInsets.only(
                                              right: 16,
                                            ),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFF46178F)
                                                    .withValues(alpha: 0.35),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: Colors.grey.shade50,
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  tituloGrupo,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF46178F),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                SizedBox(
                                                  height: 300,
                                                  width: double.infinity,
                                                  child: CustomPaint(
                                                    painter: _CuboOlapPainter(
                                                      cubo3d: datosCubo,
                                                      modo: _modoCubo,
                                                      trimestreSeleccionado:
                                                          _trimestre,
                                                      compacto: true,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // SECCIÓN 2: OPERACIONES SLICE Y DRILL-DOWN
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Todos')),
                          ButtonSegment(value: 1, label: Text('Q1')),
                          ButtonSegment(value: 2, label: Text('Q2')),
                          ButtonSegment(value: 3, label: Text('Q3')),
                        ],
                        selected: {_trimestre},
                        onSelectionChanged: (val) {
                          setState(() => _trimestre = val.first);
                          _cargarCubo();
                        },
                      ),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'area',
                            label: Text('Áreas (5)'),
                          ),
                          ButtonSegment(
                            value: 'tema',
                            label: Text('Temas (14)'),
                          ),
                        ],
                        selected: {_nivel},
                        onSelectionChanged: (val) {
                          setState(() => _nivel = val.first);
                          _cargarCubo();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // TARJETAS KPI
                  if (resumen != null)
                    Row(
                      children: [
                        _KpiCard(
                          titulo: 'Consultas',
                          valor: '${resumen['totalConsultas']}',
                          color: const Color(0xFF1368CE),
                        ),
                        const SizedBox(width: 8),
                        _KpiCard(
                          titulo: 'Respuestas',
                          valor: '${resumen['totalRespuestas']}',
                          color: const Color(0xFF26890C),
                        ),
                        const SizedBox(width: 8),
                        _KpiCard(
                          titulo: '% Acierto',
                          valor: '${resumen['porcentajeAcierto']}%',
                          color: const Color(0xFFD89E00),
                        ),
                        const SizedBox(width: 8),
                        _KpiCard(
                          titulo: 'Tiempo Prom.',
                          valor: '${resumen['tiempoPromedioGlobal']}s',
                          color: const Color(0xFFE21B3C),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LeyendaItem(
                        color: Color(0xFF1368CE),
                        texto: 'Consultas',
                      ),
                      SizedBox(width: 16),
                      _LeyendaItem(
                        color: Color(0xFF26890C),
                        texto: 'Correctas',
                      ),
                      SizedBox(width: 16),
                      _LeyendaItem(
                        color: Color(0xFFE21B3C),
                        texto: 'Incorrectas',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // GRÁFICAS DE BARRAS POR ÁREA O TEMA
                  ...datos.map((item) {
                    final cat = item['categoria'].toString();
                    final cons = (item['consultas'] as num).toInt();
                    final corr = (item['correctas'] as num).toInt();
                    final inc = (item['incorrectas'] as num).toInt();
                    final tProm = item['tiempoPromedio'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    cat,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '⏱ ${tProm}s prom.',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _BarraMetrica(
                              etiqueta: 'Consultas ($cons)',
                              valor: cons,
                              maximo: maxValor,
                              color: const Color(0xFF1368CE),
                            ),
                            const SizedBox(height: 6),
                            _BarraMetrica(
                              etiqueta: 'Correctas ($corr)',
                              valor: corr,
                              maximo: maxValor,
                              color: const Color(0xFF26890C),
                            ),
                            const SizedBox(height: 6),
                            _BarraMetrica(
                              etiqueta: 'Incorrectas ($inc)',
                              valor: inc,
                              maximo: maxValor,
                              color: const Color(0xFFE21B3C),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _CuboOlapPainter extends CustomPainter {
  final Map<String, dynamic> cubo3d;
  final String modo;
  final int trimestreSeleccionado;
  final bool compacto;

  _CuboOlapPainter({
    required this.cubo3d,
    required this.modo,
    required this.trimestreSeleccionado,
    this.compacto = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final areas = List<String>.from(cubo3d['areas'] ?? []);
    final trimestres = List<String>.from(cubo3d['trimestres'] ?? []);
    final correctas = (cubo3d['correctas'] as List)
        .map((r) => List<num>.from(r))
        .toList();
    final incorrectas = (cubo3d['incorrectas'] as List)
        .map((r) => List<num>.from(r))
        .toList();
    final consultas = (cubo3d['consultas'] as List)
        .map((r) => List<num>.from(r))
        .toList();
    final tiempos = (cubo3d['tiempos'] as List)
        .map((r) => List<num>.from(r))
        .toList();

    List<List<String>> frente;
    List<List<String>> fondo;
    List<String> capasLabels;
    Color colorFrente;
    Color colorTop;
    Color colorSide;
    Color colorSliceActivo;

    if (modo == 'constelacion') {
      frente = consultas
          .map((r) => r.map((v) => '${v.toInt()}').toList())
          .toList();
      fondo = List.generate(
        3,
        (r) => List.generate(
          5,
          (c) => '${(correctas[r][c] + incorrectas[r][c]).toInt()}',
        ),
      );
      capasLabels = ['Consultas', 'Respuestas'];
      colorFrente = const Color(0xFFF1F9F2);
      colorTop = const Color(0xFFD6EED9);
      colorSide = const Color(0xFFBBE2C0);
      colorSliceActivo = const Color(0xFFBCE8C3);
    } else if (modo == 'tiempos') {
      frente = tiempos.map((r) => r.map((v) => '${v}s').toList()).toList();
      fondo = correctas
          .map((r) => r.map((v) => '${v.toInt()}').toList())
          .toList();
      capasLabels = ['Tiempo (s)', 'Aciertos'];
      colorFrente = const Color(0xFFFFF8EC);
      colorTop = const Color(0xFFFCE8C3);
      colorSide = const Color(0xFFF7D79C);
      colorSliceActivo = const Color(0xFFF9DC9E);
    } else {
      frente = correctas
          .map((r) => r.map((v) => '${v.toInt()}').toList())
          .toList();
      fondo = incorrectas
          .map((r) => r.map((v) => '${v.toInt()}').toList())
          .toList();
      capasLabels = ['Correctas (1)', 'Incorrectas (0)'];
      colorFrente = const Color(0xFFF2F5FC);
      colorTop = const Color(0xFFDCE4F7);
      colorSide = const Color(0xFFC5D3F2);
      colorSliceActivo = const Color(0xFFC8D8FA);
    }

    const nRows = 3;
    const nCols = 5;
    const nDepth = 2;

    final cw = (size.width * (compacto ? 0.50 : 0.56)) / nCols;
    final ch = compacto ? 46.0 : 54.0;
    final dx = compacto ? 24.0 : 34.0;
    final dy = compacto ? 19.0 : 24.0;

    final totalW = nCols * cw + nDepth * dx;
    final x0 = (size.width - totalW) / 2 + (compacto ? 44 : 30);
    final y0 = compacto ? 62.0 : 75.0;

    final strokeNormal = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final strokeAtenuado = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final strokeActivo = Paint()
      ..color = const Color(0xFF46178F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    // 1. Cara Frontal
    for (int r = 0; r < nRows; r++) {
      final bool esFilaActiva =
          trimestreSeleccionado == 0 || trimestreSeleccionado == (r + 1);
      final Color fill = trimestreSeleccionado == 0
          ? colorFrente
          : (esFilaActiva ? colorSliceActivo : Colors.grey.shade100);
      final Paint borde = trimestreSeleccionado == 0
          ? strokeNormal
          : (esFilaActiva ? strokeActivo : strokeAtenuado);
      final Color textColor = esFilaActiva
          ? const Color(0xFF1A252F)
          : Colors.grey.shade400;

      for (int c = 0; c < nCols; c++) {
        final rect = Rect.fromLTWH(x0 + c * cw, y0 + r * ch, cw, ch);
        canvas.drawRect(rect, Paint()..color = fill);
        canvas.drawRect(rect, borde);
        _drawText(
          canvas,
          frente[r][c],
          Offset(rect.center.dx, rect.center.dy),
          fontSize: compacto ? 11.5 : 13,
          bold: true,
          color: textColor,
        );
      }
    }

    // 2. Cara Superior (Profundidad)
    final int filaRefTop = trimestreSeleccionado == 0
        ? 0
        : (trimestreSeleccionado - 1);
    for (int d = 0; d < nDepth; d++) {
      for (int c = 0; c < nCols; c++) {
        final bx = x0 + c * cw + d * dx;
        final by = y0 - d * dy;
        final path = Path()
          ..moveTo(bx, by)
          ..lineTo(bx + cw, by)
          ..lineTo(bx + cw + dx, by - dy)
          ..lineTo(bx + dx, by - dy)
          ..close();
        canvas.drawPath(path, Paint()..color = colorTop);
        canvas.drawPath(path, strokeNormal);

        final val = d == 0 ? frente[filaRefTop][c] : fondo[filaRefTop][c];
        _drawText(
          canvas,
          val,
          Offset(bx + cw / 2 + dx / 2, by - dy / 2),
          fontSize: compacto ? 10 : 11,
          bold: true,
          color: const Color(0xFF1F3A60),
        );
      }
    }

    // 3. Cara Lateral Derecha
    for (int d = 0; d < nDepth; d++) {
      for (int r = 0; r < nRows; r++) {
        final bool esFilaActiva =
            trimestreSeleccionado == 0 || trimestreSeleccionado == (r + 1);
        final Color sideFill = trimestreSeleccionado == 0
            ? colorSide
            : (esFilaActiva ? colorSide : Colors.grey.shade200);
        final Paint sideStroke = trimestreSeleccionado == 0
            ? strokeNormal
            : (esFilaActiva ? strokeActivo : strokeAtenuado);
        final Color sideTextColor = esFilaActiva
            ? const Color(0xFF1F3A60)
            : Colors.grey.shade400;

        final bx = x0 + nCols * cw + d * dx;
        final by = y0 + r * ch - d * dy;
        final path = Path()
          ..moveTo(bx, by)
          ..lineTo(bx + dx, by - dy)
          ..lineTo(bx + dx, by + ch - dy)
          ..lineTo(bx, by + ch)
          ..close();
        canvas.drawPath(path, Paint()..color = sideFill);
        canvas.drawPath(path, sideStroke);

        final val = d == 0 ? frente[r][nCols - 1] : fondo[r][nCols - 1];
        _drawText(
          canvas,
          val,
          Offset(bx + dx / 2, by + ch / 2 - dy / 2),
          fontSize: compacto ? 10 : 11,
          bold: true,
          color: sideTextColor,
        );
      }
    }

    // Etiquetas Filas (DIM_TIEMPO)
    for (int r = 0; r < nRows; r++) {
      final bool esFilaActiva =
          trimestreSeleccionado == 0 || trimestreSeleccionado == (r + 1);
      _drawText(
        canvas,
        trimestres[r],
        Offset(x0 - (compacto ? 42 : 46), y0 + r * ch + ch / 2),
        fontSize: compacto ? 10 : 11.5,
        bold: true,
        color: esFilaActiva
            ? (trimestreSeleccionado == 0
                  ? const Color(0xFF2C3E50)
                  : const Color(0xFF46178F))
            : Colors.grey.shade400,
      );
    }

    // Etiquetas Columnas (DIM_TEMA)
    for (int c = 0; c < nCols; c++) {
      _drawText(
        canvas,
        compacto ? areas[c].substring(0, 4) : areas[c],
        Offset(x0 + c * cw + cw / 2, y0 + nRows * ch + 16),
        fontSize: compacto ? 10 : 11.5,
        bold: true,
        color: const Color(0xFF46178F),
      );
    }

    // Etiquetas Profundidad (Capas)
    for (int d = 0; d < nDepth; d++) {
      _drawText(
        canvas,
        capasLabels[d],
        Offset(x0 + d * dx - (compacto ? 28 : 28), y0 - d * dy - dy / 2),
        fontSize: compacto ? 9.5 : 11,
        bold: true,
        color: const Color(0xFF1368CE),
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    double fontSize = 12,
    bool bold = false,
    Color color = Colors.black,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CuboOlapPainter oldDelegate) =>
      oldDelegate.modo != modo ||
      oldDelegate.cubo3d != cubo3d ||
      oldDelegate.trimestreSeleccionado != trimestreSeleccionado ||
      oldDelegate.compacto != compacto;
}

class _KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;

  const _KpiCard({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String texto;

  const _LeyendaItem({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BarraMetrica extends StatelessWidget {
  final String etiqueta;
  final int valor;
  final int maximo;
  final Color color;

  const _BarraMetrica({
    required this.etiqueta,
    required this.valor,
    required this.maximo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final factor = maximo > 0 ? (valor / maximo).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: factor,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
