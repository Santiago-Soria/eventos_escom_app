import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_eventos/services/event_service.dart';
import 'package:proyecto_eventos/screens/events/event_details_screen.dart';

class MyEventsTab extends StatelessWidget {
  const MyEventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final EventService eventService = EventService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 40, 16, 10),
          child: Text(
            "Mis Registros",
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: Colors.white
            ),
          ),
        ),
        
        Expanded(
          // 1. Escuchamos la lista de IDs en el perfil del usuario
          child: StreamBuilder<QuerySnapshot>(
            stream: eventService.getMyRegistrations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      Text(
                        "No te has registrado a ningún evento aún.",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              }

              final myEventDocs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: myEventDocs.length,
                itemBuilder: (context, index) {
                  final String eventId = myEventDocs[index].id;

                  // 2. Para cada ID, buscamos los detalles reales del evento
                  return FutureBuilder<DocumentSnapshot>(
                    future: eventService.getEventById(eventId),
                    builder: (context, eventSnapshot) {
                      if (!eventSnapshot.hasData) {
                        return const SizedBox(
                          height: 100, 
                          child: Center(child: LinearProgressIndicator())
                        );
                      }

                      // Manejo de caso: El evento fue borrado por el organizador pero sigue en mi lista
                      if (!eventSnapshot.data!.exists) {
                        return const SizedBox.shrink(); 
                      }

                      final eventData = eventSnapshot.data!.data() as Map<String, dynamic>;

                      // Reutilizamos el diseño de tarjeta
                      return _buildMyEventCard(context, eventId, eventData);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Tarjeta simplificada para "Mis Eventos"
  Widget _buildMyEventCard(BuildContext context, String eventId, Map<String, dynamic> data) {
    final DateTime start = (data['startTimestamp'] as Timestamp).toDate();
    final String dateString = DateFormat('dd/MM/yyyy').format(start);
    final String timeString = DateFormat('h:mm a').format(start);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: InkWell(
        onTap: () {
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen pequeña (Thumbnail)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  data['imageUrl'] ?? 'https://via.placeholder.com/150',
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (c,e,s) => Container(width: 80, height: 80, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 15),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Evento',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text("$dateString - $timeString", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade200)
                      ),
                      child: const Text(
                        "Registrado",
                        style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}