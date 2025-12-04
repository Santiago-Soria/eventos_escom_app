import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_eventos/services/event_service.dart';
import 'package:proyecto_eventos/screens/events/event_details_screen.dart';

class ExploreEventsTab extends StatefulWidget {
  const ExploreEventsTab({super.key});

  @override
  State<ExploreEventsTab> createState() => _ExploreEventsTabState();
}

class _ExploreEventsTabState extends State<ExploreEventsTab> {
  final EventService _eventService = EventService();
  
  String? _selectedCategoryId; 
  String? _selectedLocationId; 
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. BARRA DE BÚSQUEDA Y FILTRO
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Buscar eventos...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Botón de Filtro
              InkWell(
                onTap: _showFilterModal,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_selectedCategoryId != null || _selectedLocationId != null || _selectedDate != null)
                        ? const Color(0xFF1E4079) 
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.filter_list, 
                    color: (_selectedCategoryId != null || _selectedLocationId != null || _selectedDate != null)
                        ? Colors.white 
                        : const Color(0xFF1E4079)
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. TÍTULO
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Eventos disponibles",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 3. LISTA DE EVENTOS
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _eventService.getEvents(
              categoryId: _selectedCategoryId,
              locationId: _selectedLocationId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              // --- MANEJO DE ERRORES ---
              // Si hay un error (como falta de índices), lo mostramos en consola
              if (snapshot.hasError) {
                return Center(child: Text("Error al cargar: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No hay eventos con estos filtros.", style: TextStyle(color: Colors.grey)));
              }

              // Obtenemos la lista de documentos
              List<QueryDocumentSnapshot> events = snapshot.data!.docs;

              // --- ORDENAMIENTO EN CLIENTE (SOLUCIÓN) ---
              // Como quitamos el orderBy de Firestore, ordenamos aquí manualmente por fecha
              events.sort((a, b) {
                Timestamp tA = a['startTimestamp'];
                Timestamp tB = b['startTimestamp'];
                return tA.compareTo(tB); // Orden ascendente (más próximo primero)
              });

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final eventDoc = events[index];
                  final eventData = eventDoc.data() as Map<String, dynamic>;
                  final String eventId = eventDoc.id;

                  // Filtrado de fecha en cliente
                  if (_selectedDate != null) {
                    final DateTime eventDate = (eventData['startTimestamp'] as Timestamp).toDate();
                    if (!_isSameDay(eventDate, _selectedDate!)) {
                      return const SizedBox.shrink(); 
                    }
                  }

                  return _buildEventCard(context, eventId, eventData);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- MODAL DE FILTROS DINÁMICO ---
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.8, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50, height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Filtros", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (_selectedCategoryId != null || _selectedLocationId != null || _selectedDate != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategoryId = null;
                              _selectedDate = null;
                              _selectedLocationId = null;
                            });
                            Navigator.pop(context);
                          }, 
                          child: const Text("Borrar todo")
                        )
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // --- SECCIÓN CATEGORÍA (Desde Firestore) ---
                  const Text("Categoría", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: _eventService.getCategories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      
                      final categories = snapshot.data!.docs;
                      
                      return Wrap(
                        spacing: 8,
                        children: categories.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final String id = doc.id; 
                          final String name = data['name'] ?? id; 
                          final bool isSelected = _selectedCategoryId == id;

                          return ChoiceChip(
                            label: Text(name),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setModalState(() => _selectedCategoryId = selected ? id : null);
                            },
                            selectedColor: Colors.blue[100],
                            backgroundColor: Colors.white,
                            side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF1E4079) : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                            ),
                          );
                        }).toList(),
                      );
                    }
                  ),

                  const SizedBox(height: 20),

                  // --- SECCIÓN FECHA ---
                  const Text("Fecha", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              primaryColor: const Color(0xFF1E4079), 
                              colorScheme: const ColorScheme.light(primary: Color(0xFF1E4079)),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() => _selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        color: _selectedDate != null ? Colors.blue[50] : Colors.white
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null 
                            ? "Seleccionar fecha" 
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                            style: TextStyle(
                              color: _selectedDate != null ? const Color(0xFF1E4079) : Colors.black,
                              fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.normal
                            ),
                          ),
                          Icon(Icons.calendar_today, size: 20, 
                            color: _selectedDate != null ? const Color(0xFF1E4079) : Colors.grey
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- SECCIÓN UBICACIÓN (Desde Firestore) ---
                  const Text("Ubicación", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: _eventService.getLocations(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      
                      final locations = snapshot.data!.docs;
                      
                      return Wrap(
                        spacing: 8,
                        children: locations.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final String id = doc.id; 
                          final String name = data['name'] ?? 'Sin nombre'; 
                          final bool isSelected = _selectedLocationId == id;

                          return ChoiceChip(
                            label: Text(name),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setModalState(() => _selectedLocationId = selected ? id : null);
                            },
                            selectedColor: Colors.blue[100],
                            backgroundColor: Colors.white,
                            side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF1E4079) : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                            ),
                          );
                        }).toList(),
                      );
                    }
                  ),

                  const Spacer(),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {}); 
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4079),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("Aplicar Filtros", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventCard(BuildContext context, String eventId, Map<String, dynamic> data) {
    final DateTime start = (data['startTimestamp'] as Timestamp).toDate();
    final DateTime end = (data['endTimestamp'] as Timestamp).toDate();
    final String dateString = DateFormat('dd/MM/yyyy').format(start);
    final String timeString = "${DateFormat('h:mm a').format(start)} a ${DateFormat('h:mm a').format(end)}";

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  data['imageUrl'] ?? 'https://via.placeholder.com/400x200',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, _, __) => Container(
                    height: 150, color: Colors.grey[300], 
                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('d').format(start),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E4079)),
                      ),
                      Text(
                        DateFormat('MMM').format(start).toUpperCase(),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Evento',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "Organizado por: ${data['organizerName'] ?? 'Desconocido'}",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "$dateString - $timeString",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 15),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailsScreen(
                            eventId: eventId,
                            eventData: data,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E4079),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Ver detalles"),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}