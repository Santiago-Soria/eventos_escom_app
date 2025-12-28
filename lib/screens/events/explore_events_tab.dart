import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_eventos/screens/events/event_details_screen.dart';
import 'package:proyecto_eventos/screens/events/filter_modal.dart'; // <--- IMPORTANTE

class ExploreEventsTab extends StatefulWidget {
  final bool isOrganizer;
  const ExploreEventsTab({super.key, this.isOrganizer = false});

  @override
  State<ExploreEventsTab> createState() => _ExploreEventsTabState();
}

class _ExploreEventsTabState extends State<ExploreEventsTab> {
  final currentUser = FirebaseAuth.instance.currentUser;

  // Estado de Búsqueda y Filtros
  String _searchText = "";
  String? _selectedCategoryId;
  String? _selectedLocationId;
  DateTime? _selectedDate;

  // --- ABRIR EL MODAL DE FILTROS (REUTILIZABLE) ---
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
          // 1. FONDO UNIFICADO
          Positioned.fill(
            child: Image.asset(
              "assets/images/escom_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFF010415));
              },
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
                // HEADER (Buscador y Botón Filtro)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      // Logo
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
                      // Buscador
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
                                    hintText: "Buscar...",
                                    prefixIcon: Icon(
                                      Icons.search,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.only(bottom: 12),
                                  ),
                                  onChanged: (val) => setState(
                                    () => _searchText = val.toLowerCase(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Botón Filtro
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

                // FILTROS ACTIVOS (Chips)
                _buildActiveFilters(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Próximos Eventos',
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

                // LISTA DE EVENTOS
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getEventsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var docs = snapshot.data?.docs ?? [];

                      // Filtros Client-Side (Texto y Fecha Exacta)
                      if (_selectedDate != null) {
                        docs = docs.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          if (data['date'] == null) return false;
                          DateTime eventDate =
                              (data['date'] as Timestamp).toDate();
                          return eventDate.year == _selectedDate!.year &&
                              eventDate.month == _selectedDate!.month &&
                              eventDate.day == _selectedDate!.day;
                        }).toList();
                      }

                      if (_searchText.isNotEmpty) {
                        docs = docs.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          String title =
                              (data['title'] ?? '').toString().toLowerCase();
                          return title.contains(_searchText);
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.event_busy,
                                size: 50,
                                color: Colors.white70,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "No se encontraron eventos",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          return _buildEventCard(docs[index]);
                        },
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

  // --- QUERY STREAM ---
  Stream<QuerySnapshot> _getEventsStream() {
    Query query = FirebaseFirestore.instance.collection('events');

    // SOLO MOSTRAR EVENTOS APROBADOS
    query = query.where('isApproved', isEqualTo: true);

    // Filtros de servidor (Categoría y Ubicación)
    if (_selectedCategoryId != null) {
      query = query.where('categoryId', isEqualTo: _selectedCategoryId);
    }
    if (_selectedLocationId != null) {
      query = query.where('locationId', isEqualTo: _selectedLocationId);
    }

    // Ordenar por fecha (requiere índice compuesto si se combina con filtros)
    return query.orderBy('date', descending: false).snapshots();
  }

  // --- WIDGET FILTROS ACTIVOS ---
  Widget _buildActiveFilters() {
    if (_selectedCategoryId == null &&
        _selectedLocationId == null &&
        _selectedDate == null) {
      return const SizedBox(height: 10);
    }

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
            onPressed: () {
              setState(() {
                _selectedCategoryId = null;
                _selectedLocationId = null;
                _selectedDate = null;
              });
            },
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

  // --- TARJETA DE EVENTO (PÚBLICA) ---
  Widget _buildEventCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String title = data['title'] ?? 'Sin título';
    String imageUrl = data['imageUrl'] ?? '';

    DateTime date;
    if (data['date'] != null) {
      date = (data['date'] as Timestamp).toDate();
    } else {
      date = DateTime.now();
    }
    String dateString = DateFormat('dd/MM/yyyy').format(date);
    String timeString = data['startTime'] ?? '--:--';

    return GestureDetector(
      onTap: () {
        // Navegar a Detalle
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              eventSnapshot: doc,
              isOrganizer: widget.isOrganizer,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2), // Fix deprecation
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

              // Gradiente Inferior
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
                        Colors.black.withValues(alpha: 0.9), // Fix deprecation
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
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$dateString  •  $timeString",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botón visual "Ver más"
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2660A5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
