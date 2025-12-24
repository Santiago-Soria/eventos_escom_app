import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_eventos/screens/events/event_details_screen.dart';
import 'package:proyecto_eventos/screens/student/my_ticket_screen.dart';
import 'package:proyecto_eventos/services/event_service.dart';
import 'package:proyecto_eventos/widgets/custom_alert_dialog.dart';
import 'package:proyecto_eventos/screens/events/filter_modal.dart';

class MyEventsTab extends StatefulWidget {
  const MyEventsTab({super.key});

  @override
  State<MyEventsTab> createState() => _MyEventsTabState();
}

class _MyEventsTabState extends State<MyEventsTab> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final EventService _eventService = EventService();

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
    // 1. ESTRUCTURA LIMPIA:
    // Eliminamos Scaffold, Stack y SafeArea propios.
    // Usamos una Column simple para que el fondo sea el de StudentHome.
    return Column(
      children: [
        // --- HEADER ---
        // Padding alineado con ExploreEventsTab (20, 10, 20, 10)
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
                              color: Colors.black, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: "Buscar...",
                            prefixIcon: Icon(Icons.search,
                                size: 20, color: Colors.grey),
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

        // --- FILTROS ACTIVOS ---
        _buildActiveFilters(),

        // --- TÍTULO DE SECCIÓN ---
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Mis inscripciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // --- LISTA ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getMyRegistrationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.confirmation_number_outlined,
                          size: 50, color: Colors.white70),
                      SizedBox(height: 10),
                      Text("No tienes eventos registrados",
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  String eventId = docs[index].id;
                  DocumentReference eventRef = FirebaseFirestore.instance
                      .collection('events')
                      .doc(eventId);

                  return _EventCardLoader(
                    eventRef: eventRef,
                    searchText: _searchText,
                    eventService: _eventService,
                    filterCategory: _selectedCategoryId,
                    filterLocation: _selectedLocationId,
                    filterDate: _selectedDate,
                  );
                },
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
        _selectedDate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 5),
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
            child: const Text("Borrar todo",
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      {required String label,
      required IconData icon,
      required VoidCallback onDeleted}) {
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
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onDeleted,
            child: const Icon(Icons.close, size: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getMyRegistrationsStream() {
    if (currentUser == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('myEvents')
        .orderBy('registeredAt', descending: true)
        .snapshots();
  }
}

class _EventCardLoader extends StatelessWidget {
  final DocumentReference eventRef;
  final String searchText;
  final EventService eventService;
  final String? filterCategory;
  final String? filterLocation;
  final DateTime? filterDate;

  const _EventCardLoader({
    required this.eventRef,
    required this.searchText,
    required this.eventService,
    this.filterCategory,
    this.filterLocation,
    this.filterDate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: eventRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists)
          return const SizedBox();

        var doc = snapshot.data!;
        var data = doc.data() as Map<String, dynamic>;

        // --- FILTROS ---
        String title = (data['title'] ?? '').toString().toLowerCase();
        if (searchText.isNotEmpty && !title.contains(searchText)) {
          return const SizedBox();
        }
        if (filterCategory != null && data['categoryId'] != filterCategory) {
          return const SizedBox();
        }
        if (filterLocation != null && data['locationId'] != filterLocation) {
          return const SizedBox();
        }
        if (filterDate != null && data['date'] != null) {
          DateTime eventDate = (data['date'] as Timestamp).toDate();
          bool isSameDay = eventDate.year == filterDate!.year &&
              eventDate.month == filterDate!.month &&
              eventDate.day == filterDate!.day;
          if (!isSameDay) return const SizedBox();
        }

        return _buildInteractableCard(doc, context);
      },
    );
  }

  Widget _buildInteractableCard(DocumentSnapshot doc, BuildContext context) {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text("Eliminar registro",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Icon(Icons.event_busy, color: Colors.white, size: 30),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => const CustomAlertDialog(
            title: "¿Eliminar registro?",
            content:
                "Si eliminas tu registro, liberarás tu lugar. Podrás registrarte de nuevo si hay cupo.",
            confirmText: "Sí",
          ),
        );
      },
      onDismissed: (direction) async {
        await eventService.cancelAttendance(doc.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Has eliminado tu registro en el evento")),
          );
        }
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(eventSnapshot: doc),
            ),
          );
        },
        child: _buildCardContent(doc, context),
      ),
    );
  }

  Widget _buildCardContent(DocumentSnapshot doc, BuildContext context) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String title = data['title'] ?? 'Sin título';
    String imageUrl = data['imageUrl'] ?? '';
    DateTime date = data['date'] != null
        ? (data['date'] as Timestamp).toDate()
        : DateTime.now();
    String dateString = DateFormat('dd/MM/yyyy').format(date);
    String timeString = data['startTime'] ?? '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4)),
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
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Colors.white70, size: 12),
                              const SizedBox(width: 4),
                              Text("$dateString  •  $timeString",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MyTicketScreen(eventData: data, eventId: doc.id),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2660A5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.qr_code, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text("Ver Pase",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'Nunito')),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
