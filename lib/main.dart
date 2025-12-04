import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:proyecto_eventos/services/auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Asegurar que los Widgets estén listos antes de tocar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESCOM Eventos',
      debugShowCheckedModeBanner: false,
      
      // 3. Aquí aplicarás tus colores de Figma más tarde
      theme: ThemeData(
        primarySwatch: Colors.blue, // Usa los colores de la ESCOM
        useMaterial3: true,
      ),

      // 4. El "AuthGate" (Ver punto siguiente)
      home: const AuthGate(), 
    );
  }
}
