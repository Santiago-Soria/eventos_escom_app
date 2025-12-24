import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_eventos/services/auth_services.dart';
import 'package:proyecto_eventos/screens/home/student_home.dart';
import 'package:proyecto_eventos/screens/home/organizer_home.dart';
import 'package:proyecto_eventos/screens/auth/login_screen.dart';

class RoleWrapper extends StatelessWidget {
  const RoleWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    // 1. ESCUCHAR CAMBIOS EN TIEMPO REAL
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Cargando estado de auth...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // Si no hay usuario, mostrar Login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 2. Si hay usuario, buscar su ROL en Firestore
        // CORRECCIÓN: Llamamos a getUserData() sin argumentos
        return FutureBuilder<DocumentSnapshot>(
          future: authService.getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                !snapshot.data!.exists) {
              // Si falla la carga del rol, por seguridad mandamos al login
              return const LoginScreen();
            }

            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            String role = data['role'] ?? 'estudiante';

            if (role == 'organizador') {
              return const OrganizerHome();
            } else {
              return const StudentHome();
            }
          },
        );
      },
    );
  }
}
