import 'package:flutter/material.dart';

import 'screens/ingreso_codigo_screen.dart';

void main() {
  runApp(const JabsQuizzApp());
}

class JabsQuizzApp extends StatelessWidget {
  const JabsQuizzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jabs Quizz!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF46178F)),
        useMaterial3: true,
      ),
      home: const IngresoCodigoScreen(),
    );
  }
}
