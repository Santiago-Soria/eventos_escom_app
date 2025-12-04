import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_eventos/screens/auth/login_screen.dart';
import 'package:proyecto_eventos/services/role_wrapper.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Escucha cambios en la autenticación (login, logout, registro)
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si está esperando respuesta de Firebase...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si hay datos (usuario logueado), ve al Home
        if (snapshot.hasData) {
          return const RoleWrapper(); // ¡Tendrás que crear esta pantalla!
        }

        // Si no hay datos (usuario no logueado), ve al Login
        return const LoginScreen(); // ¡Tendrás que crear esta pantalla!
      },
    );
  }
}