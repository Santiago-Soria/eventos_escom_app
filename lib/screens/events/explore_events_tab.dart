import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_eventos/screens/events/event_details_screen.dart';
import 'package:proyecto_eventos/screens/events/event_attendees_screen.dart'; 
import 'package:proyecto_eventos/screens/events/manage_event_screen.dart'; 
import 'package:proyecto_eventos/screens/events/filter_modal.dart';

class ExploreEventsTab extends StatefulWidget {
  final bool isOrganizer;
  const ExploreEventsTab({super.key, this.isOrganizer = false});

  @override
  State<ExploreEventsTab> createState() => _ExploreEventsTabState();
}

class _ExploreEventsTabState extends State<ExploreEventsTab> {
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
      backgroundColor: Colors.transparent, // Importante para ver el fondo global

      // BOTÓN FLOTANTE: Aparece sobre la lista para crear eventos
      floatingActionButton: widget.isOrganizer
          ? Padding(
              padding: const EdgeInsets.only(bottom: 85), // Lo subimos para que no tape la nav bar
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageEventScreen()),
                  );
                },
                backgroundColor: const Color(0xFF2660A5),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Nuevo Evento", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          : null,

      body: Stack(
        children: [
          // 1. FONDO
          Positioned.fill(
            child: Image.asset(
              "assets/images/escom_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF010415)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),

          // 2. CONTENIDO
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                _buildActiveFilters(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isOrganizer ? 'Gestionar mis Eventos' : 'Próximos Eventos',
                      style: const TextStyle(
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
                    stream: _getEventsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Center(child: Text("Error", style: TextStyle(color: Colors.white)));
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                      var docs = snapshot.data?.docs ?? [];

                      // Filtros locales
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
                          return (data['title'] ?? '').toString().toLowerCase().contains(_searchText);
                        }).toList();
                      }

                      if (docs.isEmpty) return _buildEmptyState();

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                        itemCount: docs.length,
                        itemBuilder: (context, index) => _buildEventCard(docs[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getEventsStream() {
    Query query = FirebaseFirestore.instance.collection('events');
    if (widget.isOrganizer) {
      // Como organizador, ves todo lo tuyo (Pestaña Gestionar)
      query = query.where('organizerId', isEqualTo: currentUser?.uid);
    } else {
      // Como alumno, solo ves lo aprobado (Pestaña Explorar)
      query = query.where('isApproved', isEqualTo: true);
    }
    return query.orderBy('date', descending: false).snapshots();
  }

  Widget _buildEventCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String title = data['title'] ?? 'Sin título';
    String imageUrl = data['imageUrl'] ?? '';
    String status = data['status'] ?? 'pending';

    DateTime date = data['date'] != null ? (data['date'] as Timestamp).toDate() : DateTime.now();
    String dateString = DateFormat('dd/MM/yyyy').format(date);
    String timeString = data['startTime'] ?? '--:--';

    return GestureDetector(
      onTap: () {
        if (widget.isOrganizer) {
          // Navega a gestión (QR y Edición)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EventAttendeesScreen(eventId: doc.id)),
          );
        } else {
          // Navega a detalles normales
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EventDetailsScreen(eventSnapshot: doc, isOrganizer: false)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
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
              if (widget.isOrganizer) _buildStatusBadge(status),
              _buildCardFooter(title, dateString, timeString),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    return Positioned(
      top: 12, left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10)),
        child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCardFooter(String title, String date, String time) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text("$date  •  $time", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFF2660A5), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Row(children: [
            Image.asset("assets/images/logo.png", height: 30),
            const SizedBox(width: 8),
            const Text('EventOS', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
          ])),
          Expanded(flex: 3, child: Row(children: [
            Expanded(child: Container(
              height: 35,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                decoration: const InputDecoration(hintText: "Buscar...", prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 12)),
                onChanged: (val) => setState(() => _searchText = val.toLowerCase()),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showFilterDialog,
              child: Container(width: 35, height: 35, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.filter_list, size: 20, color: Colors.black54),
              ),
            ),
          ])),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    if (_selectedCategoryId == null && _selectedLocationId == null && _selectedDate == null) return const SizedBox(height: 10);
    return Container(
      height: 40, margin: const EdgeInsets.only(bottom: 10),
      child: ListView(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          if (_selectedDate != null) _buildFilterChip(label: DateFormat('dd/MM/yyyy').format(_selectedDate!), icon: Icons.calendar_today, onDeleted: () => setState(() => _selectedDate = null)),
          TextButton(onPressed: () => setState(() { _selectedCategoryId = null; _selectedLocationId = null; _selectedDate = null; }), child: const Text("Borrar todo", style: TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required IconData icon, required VoidCallback onDeleted}) {
    return Container(
      margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFF2660A5), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)), const SizedBox(width: 5),
        GestureDetector(onTap: onDeleted, child: const Icon(Icons.close, size: 16, color: Colors.white70)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No hay eventos disponibles", style: TextStyle(color: Colors.white70)));
  }
}