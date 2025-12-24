import 'package:flutter/material.dart';
import 'package:proyecto_eventos/screens/events/explore_events_tab.dart';
import 'package:proyecto_eventos/screens/events/my_events_tab.dart';
import 'package:proyecto_eventos/screens/profile/profile_tab.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  // Iniciamos en 1 para que "Home/Explorar" sea la pantalla principal al entrar,
  // tal como suele ser estándar, pero si prefieres que inicie en "Mis Eventos", cambia esto a 0.
  int _currentIndex = 1;

  // ORDEN SOLICITADO:
  // 0: Mis Eventos (Izquierda)
  // 1: Explorar/Home (Centro)
  // 2: Perfil (Derecha)
  final List<Widget> _pages = [
    const MyEventsTab(), // Index 0
    const ExploreEventsTab(isOrganizer: false), // Index 1
    const ProfileTab(), // Index 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. FONDO GLOBAL
          Positioned.fill(
            child: Image.asset(
              "assets/images/escom_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF010415)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // 2. CONTENIDO
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      // Usamos el mismo diseño manual que en OrganizerHome
      bottomNavigationBar: _buildCustomNavBar(),
    );
  }

  Widget _buildCustomNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF415C7E),
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // BOTÓN IZQUIERDO: Mis Eventos
          IconButton(
            icon: Icon(
              Icons.confirmation_number, // Icono de Ticket/Mis Eventos
              color: _currentIndex == 0 ? Colors.white : Colors.white54,
              size: 28,
            ),
            onPressed: () => setState(() => _currentIndex = 0),
          ),

          // BOTÓN CENTRAL: Home/Explorar
          GestureDetector(
            onTap: () => setState(() => _currentIndex = 1),
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: _currentIndex == 1
                    ? const Color(0xFF2660A5) // Azul activo
                    : Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: _currentIndex == 1
                    ? [const BoxShadow(color: Colors.black26, blurRadius: 8)]
                    : null,
              ),
              child: const Icon(Icons.home, color: Colors.white, size: 28),
            ),
          ),

          // BOTÓN DERECHO: Perfil
          IconButton(
            icon: Icon(
              Icons.person,
              color: _currentIndex == 2 ? Colors.white : Colors.white54,
              size: 28,
            ),
            onPressed: () => setState(() => _currentIndex = 2),
          ),
        ],
      ),
    );
  }
}
