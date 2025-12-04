import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_eventos/services/auth_services.dart';
import 'package:proyecto_eventos/screens/home/student_home.dart';
import 'package:proyecto_eventos/screens/home/organizer_home.dart';

class RoleWrapper extends StatelessWidget {
  const RoleWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return FutureBuilder<DocumentSnapshot>(
      future: authService.getUserData(), // Usamos el método que creamos antes
      builder: (context, snapshot) {
        
        // 1. Esperando respuesta...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Si hubo error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        // 3. Si tenemos datos
        if (snapshot.hasData && snapshot.data!.exists) {
          // Extraemos el rol del documento
          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          String role = data['role'] ?? 'estudiante'; // Default por seguridad

          // 4. EL GRAN SWITCH
          if (role == 'organizador') {
            return const OrganizerHome();
          } else if (role == 'estudiante') {
            return const StudentHome();
          } else if (role == 'admin') {
            // Como no está definido, mostramos una pantalla simple
            return Scaffold(
              appBar: AppBar(title: const Text("Admin Panel")),
              body: const Center(child: Text("Panel de Administrador (En construcción)")),
            );
          }
        }

        // Fallback por si algo sale muy mal
        return const Scaffold(
          body: Center(child: Text("No se pudo determinar el rol del usuario.")),
        );
      },
    );
  }
}