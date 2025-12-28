import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_eventos/widgets/custom_alert_dialog.dart';

// Pantallas
import 'package:proyecto_eventos/screens/events/manage_event_screen.dart';
import 'package:proyecto_eventos/screens/events/event_attendees_screen.dart';
import 'package:proyecto_eventos/screens/profile/profile_tab.dart';
import 'package:proyecto_eventos/screens/events/explore_events_tab.dart';
import 'package:proyecto_eventos/screens/events/filter_modal.dart';

class OrganizerHome extends StatefulWidget {
  const OrganizerHome({super.key});

  @override
  State<OrganizerHome> createState() => _OrganizerHomeState();
}

class _OrganizerHomeState extends State<OrganizerHome> {
  int _currentIndex = 0;
  final currentUser = FirebaseAuth.instance.currentUser;

  String _searchText = "";

  String? _selectedCategoryId;
  String? _selectedLocationId;
  DateTime? _selectedDate;

  void _showFilterDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModal(
        initialCategory: _selectedCategoryId,
        initialLocation: _selectedLocationId,
        initialDate: _selectedDate,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCategoryId = result['category'];
        _selectedLocationId = result['location'];
        _selectedDate = result['date'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
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
                _buildMyEventsView(),
                const ExploreEventsTab(isOrganizer: true),
                const ProfileTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? _buildFloatingButton() : null,
      bottomNavigationBar: _buildCustomNavBar(),
    );
  }

  Widget _buildMyEventsView() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Image.asset(
                      "assets/images/logo.png",
                      height: 30,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.event, color: Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'EventOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 35,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: TextField(
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Mis eventos...",
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(bottom: 12),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchText = val.toLowerCase()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showFilterDialog,
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.filter_list,
                          size: 20,
                          color: (_selectedCategoryId != null ||
                                  _selectedLocationId != null ||
                                  _selectedDate != null)
                              ? const Color(0xFF2660A5)
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildActiveFilters(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Gestionar mis eventos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getMyEventsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              var docs = snapshot.data?.docs ?? [];

              if (_selectedDate != null) {
                docs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (data['date'] == null) return false;
                  DateTime eventDate = (data['date'] as Timestamp).toDate();
                  return eventDate.year == _selectedDate!.year &&
                      eventDate.month == _selectedDate!.month &&
                      eventDate.day == _selectedDate!.day;
                }).toList();
              }
              if (_searchText.isNotEmpty) {
                docs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String title = (data['title'] ?? '').toString().toLowerCase();
                  return title.contains(_searchText);
                }).toList();
              }
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.filter_alt_off,
                        size: 40,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No se encontraron eventos',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: docs.length,
                itemBuilder: (context, index) =>
                    _buildOrganizerEventCard(docs[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    if (_selectedCategoryId == null &&
        _selectedLocationId == null &&
        _selectedDate == null) return const SizedBox(height: 10);
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          if (_selectedDate != null)
            _buildFilterChip(
              label: DateFormat('dd/MM/yyyy').format(_selectedDate!),
              icon: Icons.calendar_today,
              onDeleted: () => setState(() => _selectedDate = null),
            ),
          if (_selectedCategoryId != null)
            _buildFilterChip(
              label: "Categoría",
              icon: Icons.category,
              onDeleted: () => setState(() => _selectedCategoryId = null),
            ),
          if (_selectedLocationId != null)
            _buildFilterChip(
              label: "Ubicación",
              icon: Icons.location_on,
              onDeleted: () => setState(() => _selectedLocationId = null),
            ),
          TextButton(
            onPressed: () => setState(() {
              _selectedCategoryId = null;
              _selectedLocationId = null;
              _selectedDate = null;
            }),
            child: const Text(
              "Borrar todo",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onDeleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2660A5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onDeleted,
            child: const Icon(Icons.close, size: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerEventCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String title = data['title'] ?? 'Sin título';
    String imageUrl = data['imageUrl'] ?? '';
    DateTime date = data['date'] != null
        ? (data['date'] as Timestamp).toDate()
        : DateTime.now();
    String dateString = DateFormat('dd/MM/yyyy').format(date);

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Eliminar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.delete_outline, color: Colors.white, size: 30),
          ],
        ),
      ),
      // --- USO DEL CUSTOM ALERT DIALOG ---
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => const CustomAlertDialog(
            title: "¿Eliminar evento?",
            content:
                "Esta acción es irreversible y cancelará los registros de asistencia.",
            confirmText: "Eliminar",
            // No pasamos onConfirm porque la lógica de borrado está en onDismissed
          ),
        );
      },
      onDismissed: (direction) async {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(doc.id)
            .delete();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Evento eliminado")));
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventAttendeesScreen(eventId: doc.id),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.26),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey[300]),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.9),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                              ),
                              Text(
                                dateString,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ManageEventScreen(eventSnapshot: doc),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2660A5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.touch_app, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          "Ver detalles",
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getMyEventsStream() {
    Query query = FirebaseFirestore.instance.collection('events');
    query = query.where('organizerId', isEqualTo: currentUser?.uid);
    
    // REMOVER el filtro de isApproved para que vean todos sus eventos
    // query = query.where('isApproved', isEqualTo: true); // ELIMINA ESTA LÍNEA
    
    if (_selectedCategoryId != null)
      query = query.where('categoryId', isEqualTo: _selectedCategoryId);
    if (_selectedLocationId != null)
      query = query.where('locationId', isEqualTo: _selectedLocationId);
    return query.orderBy('date', descending: true).snapshots();
  }

  Widget _buildFloatingButton() {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF425D7E), Color(0xFF2660A5)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManageEventScreen()),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
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
          IconButton(
            icon: Icon(
              Icons.dashboard_customize,
              color: _currentIndex == 0 ? Colors.white : Colors.white54,
              size: 28,
            ),
            onPressed: () => setState(() => _currentIndex = 0),
          ),
          GestureDetector(
            onTap: () => setState(() => _currentIndex = 1),
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: _currentIndex == 1
                    ? const Color(0xFF2660A5)
                    : Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: _currentIndex == 1
                    ? [const BoxShadow(color: Colors.black26, blurRadius: 8)]
                    : null,
              ),
              child: const Icon(Icons.home, color: Colors.white, size: 28),
            ),
          ),
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
