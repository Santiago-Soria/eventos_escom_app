import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_eventos/screens/admin/user_management_screen.dart';
import 'package:proyecto_eventos/screens/admin/event_moderation_screen.dart';
import 'package:proyecto_eventos/screens/profile/profile_tab.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;
  
  // Estadísticas
  int _pendingEvents = 0;
  int _totalUsers = 0;
  int _organizersCount = 0;
  int _approvedEvents = 0;
  int _totalEvents = 0;
  int _totalAttendees = 0;
  
  // Datos para gráficos
  List<ChartData> _eventsByCategory = [];
  List<ChartData> _usersByRole = [];
  
  // Control de vista de reportes
  bool _showReports = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadChartsData();
  }

  Future<void> _loadStats() async {
    final firestore = FirebaseFirestore.instance;
    
    try {
      final snapshots = await Future.wait([
        firestore.collection('events').where('status', isEqualTo: 'pending').get(),
        firestore.collection('users').get(),
        firestore.collection('users').where('role', isEqualTo: 'organizador').get(),
        firestore.collection('events').where('status', isEqualTo: 'approved').get(),
        firestore.collection('events').get(),
      ]);

      if (mounted) {
        setState(() {
          _pendingEvents = snapshots[0].docs.length;
          _totalUsers = snapshots[1].docs.length;
          _organizersCount = snapshots[2].docs.length;
          _approvedEvents = snapshots[3].docs.length;
          _totalEvents = snapshots[4].docs.length;
        });
      }

      // Contar total de asistentes
      int totalAttendees = 0;
      for (var eventDoc in snapshots[4].docs) {
        final attendeesSnapshot = await firestore
            .collection('events')
            .doc(eventDoc.id)
            .collection('attendees')
            .get();
        totalAttendees += attendeesSnapshot.docs.length;
      }
      
      if (mounted) {
        setState(() {
          _totalAttendees = totalAttendees;
        });
      }
    } catch (e) {
      print("Error cargando estadísticas: $e");
    }
  }

  Future<void> _loadChartsData() async {
    final firestore = FirebaseFirestore.instance;
    
    try {
      // Cargar eventos por categoría
      final categoriesSnapshot = await firestore
          .collection('categories')
          .get();
      
      List<ChartData> eventsByCategoryTemp = [];
      for (var categoryDoc in categoriesSnapshot.docs) {
        final eventsSnapshot = await firestore
            .collection('events')
            .where('categoryId', isEqualTo: categoryDoc.id)
            .get();
        
        eventsByCategoryTemp.add(ChartData(
          categoryDoc['name'],
          eventsSnapshot.docs.length.toDouble(),
        ));
      }

      // Cargar usuarios por rol
      final usersSnapshot = await firestore
          .collection('users')
          .get();
      
      Map<String, int> roleCounts = {};
      for (var userDoc in usersSnapshot.docs) {
        var data = userDoc.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'estudiante';
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }
      
      List<ChartData> usersByRoleTemp = [];
      roleCounts.forEach((role, count) {
        usersByRoleTemp.add(ChartData(
          role == 'admin' ? 'Administrador' : 
          role == 'organizador' ? 'Organizador' : 'Estudiante',
          count.toDouble(),
        ));
      });

      if (mounted) {
        setState(() {
          _eventsByCategory = eventsByCategoryTemp;
          _usersByRole = usersByRoleTemp;
        });
      }
    } catch (e) {
      print("Error cargando datos de gráficos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // FONDO GLOBAL
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
          
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _showReports ? _buildReportsView() : _buildDashboardView(),
                const EventModerationScreen(),
                const UserManagementScreen(),
                const ProfileTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildCustomNavBar(),
    );
  }

  Widget _buildDashboardView() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadStats();
        await _loadChartsData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel de Administración',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Bienvenido, Administrador',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, color: const Color(0xFF2660A5)),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            _buildStatsCards(),

            const SizedBox(height: 20),
            
            // GRÁFICOS
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eventos por Categoría',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203957),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildEventsChart(),
                  
                  const SizedBox(height: 25),
                  
                  const Text(
                    'Usuarios por Rol',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203957),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildUsersChart(),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // ESTADÍSTICAS DETALLADAS
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estadísticas Detalladas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203957),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  _buildStatRow('Total de eventos', '$_totalEvents'),
                  _buildStatRow('Eventos aprobados', '$_approvedEvents'),
                  _buildStatRow('Eventos pendientes', '$_pendingEvents'),
                  _buildStatRow('Total de usuarios', '$_totalUsers'),
                  _buildStatRow('Organizadores activos', '$_organizersCount'),
                  _buildStatRow('Total de asistencias', '$_totalAttendees'),
                  _buildStatRow(
                    'Promedio asistentes/evento', 
                    _totalEvents > 0 
                      ? '${(_totalAttendees / _totalEvents).toStringAsFixed(1)}' 
                      : '0'
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsView() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadStats();
        await _loadChartsData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER CON BOTÓN DE REGRESO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => setState(() => _showReports = false),
                  tooltip: 'Volver al Dashboard',
                ),
                const Text(
                  'Reportes y Estadísticas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 48), // Para balancear
              ],
            ),

            const SizedBox(height: 20),

            // RESUMEN GENERAL
            const Text(
              'Resumen General',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 15),
            
            _buildReportsSummaryCards(),
            
            const SizedBox(height: 30),
            
            // GRÁFICOS
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Eventos por Categoría',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203957),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildEventsChart(),
                  
                  const SizedBox(height: 25),
                  
                  const Text(
                    'Usuarios por Rol',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203957),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildUsersChart(),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // ESTADÍSTICAS DETALLADAS
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estadísticas Detalladas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203957),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  _buildStatRow('Total de eventos', '$_totalEvents'),
                  _buildStatRow('Eventos aprobados', '$_approvedEvents'),
                  _buildStatRow('Eventos pendientes', '$_pendingEvents'),
                  _buildStatRow('Total de usuarios', '$_totalUsers'),
                  _buildStatRow('Organizadores activos', '$_organizersCount'),
                  _buildStatRow('Total de asistencias', '$_totalAttendees'),
                  _buildStatRow(
                    'Promedio asistentes/evento', 
                    _totalEvents > 0 
                      ? '${(_totalAttendees / _totalEvents).toStringAsFixed(1)}' 
                      : '0'
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(title: 'Pendientes', value: '$_pendingEvents', subtitle: 'Eventos', icon: Icons.pending_actions, color: Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(title: 'Usuarios', value: '$_totalUsers', subtitle: 'Registrados', icon: Icons.people, color: Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(title: 'Organizadores', value: '$_organizersCount', subtitle: 'Activos', icon: Icons.event, color: Colors.green)),
      ],
    );
  }

  Widget _buildReportsSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildReportStatCard(title: 'Eventos', value: '$_totalEvents', icon: Icons.event, color: Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildReportStatCard(title: 'Usuarios', value: '$_totalUsers', icon: Icons.people, color: Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildReportStatCard(title: 'Asistencias', value: '$_totalAttendees', icon: Icons.check_circle, color: Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _buildReportStatCard(title: 'Aprobados', value: '$_approvedEvents', icon: Icons.verified, color: Colors.purple)),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF203957)),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildReportStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsChart() {
    return SizedBox(
      height: 200,
      child: _eventsByCategory.isNotEmpty
          ? SfCircularChart(
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                textStyle: TextStyle(fontSize: 12),
              ),
              series: <CircularSeries>[
                PieSeries<ChartData, String>(
                  dataSource: _eventsByCategory,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                  dataLabelMapper: (ChartData data, _) => '${data.x}: ${data.y.toInt()}',
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                    textStyle: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            )
          : const Center(
              child: Text(
                'No hay datos de categorías disponibles',
                style: TextStyle(color: Colors.grey),
              ),
            ),
    );
  }

  Widget _buildUsersChart() {
    return SizedBox(
      height: 200,
      child: _usersByRole.isNotEmpty
          ? SfCircularChart(
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                textStyle: TextStyle(fontSize: 12),
              ),
              series: <CircularSeries>[
                DoughnutSeries<ChartData, String>(
                  dataSource: _usersByRole,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                  dataLabelMapper: (ChartData data, _) => '${data.x}: ${data.y.toInt()}',
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                    textStyle: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            )
          : const Center(
              child: Text(
                'No hay datos de usuarios disponibles',
                style: TextStyle(color: Colors.grey),
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF203957),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2660A5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF203957)),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNavBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFF415C7E),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.dashboard, 0, isDashboard: true),
          _navItem(Icons.event_available, 1, badgeCount: _pendingEvents),
          _navItem(Icons.people_alt, 2),
          _navItem(Icons.person, 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index, {int badgeCount = 0, bool isDashboard = false}) {
    bool isActive = _currentIndex == index;
    
    // Para el dashboard, también consideramos si estamos en la vista de reportes
    if (isDashboard && _showReports && _currentIndex == 0) {
      isActive = true;
    }
    
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 28),
          onPressed: () {
            if (index == 0 && _showReports) {
              // Si estamos en reportes y presionamos dashboard, volvemos al dashboard principal
              setState(() {
                _showReports = false;
                _currentIndex = index;
              });
            } else {
              setState(() {
                _showReports = false; // Asegurar que no estamos en reportes al cambiar pestaña
                _currentIndex = index;
              });
            }
          },
        ),
        if (badgeCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class ChartData {
  final String x;
  final double y;
  
  ChartData(this.x, this.y);
}