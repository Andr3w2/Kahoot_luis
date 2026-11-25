import 'package:flutter/material.dart';

import 'screens/seleccion_perfil_screen.dart';
import 'screens/auth/login_staff_screen.dart';
import 'screens/auth/registro_maestro_screen.dart';
import 'screens/admin/admin_home_screen.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => const SeleccionPerfilScreen(),
        '/auth/login': (context) => const LoginStaffScreen(),
        '/auth/registro-maestro': (context) => const RegistroMaestroScreen(),
        '/admin/home': (context) => const AdminHomeScreen(),
      },
    );
  }
}
