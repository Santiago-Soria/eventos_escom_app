import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
// 1. IMPORTA ESTO
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:proyecto_eventos/role_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('es_MX', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EventOS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2660A5),
        ),
        useMaterial3: true,
        fontFamily: 'Nunito',
      ),
      // 2. AGREGA ESTE BLOQUE DE LOCALIZACIÓN
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'MX'), // Español México
        Locale('en', 'US'), // Inglés (Respaldo)
      ],
      // -------------------------------------
      home: const RoleWrapper(),
    );
  }
}
