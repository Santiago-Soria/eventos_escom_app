import 'package:flutter/material.dart';
import 'package:proyecto_eventos/services/auth_services.dart';

class OrganizerHome extends StatefulWidget {
  const OrganizerHome({super.key});

  @override
  State<OrganizerHome> createState() => _OrganizerHomeState();
}

class _OrganizerHomeState extends State<OrganizerHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text("Módulo: Mis Eventos Creados")), // Index 0
    const Center(child: Text("Módulo: Perfil Organizador")),  // Index 1
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Organizador"),
        backgroundColor: Colors.indigo.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          )
        ],
      ),
      body: _pages[_currentIndex],

      // EL ORGANIZADOR TIENE UN BOTÓN FLOTANTE PARA CREAR
      floatingActionButton: _currentIndex == 0 
        ? FloatingActionButton.extended(
            onPressed: () {
              // Aquí navegaremos a la pantalla de crear evento
              print("Crear evento");
            },
            label: const Text("Nuevo Evento"),
            icon: const Icon(Icons.add),
            backgroundColor: const Color(0xFF1E4079),
            foregroundColor: Colors.white,
          )
        : null, // Solo mostramos el botón en la primera pestaña

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF1E4079),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Gestionar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}