import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'package:proyecto_eventos/services/event_service.dart';

class EventDetailsScreen extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  Widget build(BuildContext context) {
    final EventService eventService = EventService();
    
    final DateTime start = (eventData['startTimestamp'] as Timestamp).toDate();
    final DateTime end = (eventData['endTimestamp'] as Timestamp).toDate();
    final String dateFormatted = DateFormat('dd/MM/yyyy').format(start);
    final String timeFormatted = "${DateFormat('h:mm a').format(start)} a ${DateFormat('h:mm a').format(end)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles del evento"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E4079), Color(0xFF001F3F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN GRANDE
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    eventData['imageUrl'] ?? 'https://via.placeholder.com/400x200',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('d').format(start),
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E4079)
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(start).toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            // INFORMACIÓN
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventData['title'] ?? 'Evento sin título',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4079),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  Text(
                    "Descripción:",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    eventData['description'] ?? 'Sin descripción disponible.',
                    style: TextStyle(color: Colors.grey[700], height: 1.5),
                  ),
                  const SizedBox(height: 25),

                  _buildInfoRow(Icons.business, "Organizado por:", eventData['organizerName'] ?? 'Desconocido'),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.calendar_today, "Fecha y Hora:", "$dateFormatted - $timeFormatted"),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.location_on, "Ubicación:", eventData['locationName'] ?? 'Por definir'),
                  
                  const SizedBox(height: 40),

                  // LÓGICA DE BOTONES (ASISTIR / CANCELAR)
                  StreamBuilder<bool>(
                    stream: eventService.isUserRegistered(eventId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final bool isRegistered = snapshot.data ?? false;

                      return Column(
                        children: [
                          // Botón Principal
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: isRegistered 
                                ? null // Deshabilitado visualmente si ya está registrado
                                : () => _confirmAttendance(context, eventService),
                              icon: Icon(isRegistered ? Icons.check : Icons.bookmark_add),
                              label: Text(
                                isRegistered ? "Ya estás registrado" : "Asistir",
                                style: const TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isRegistered ? Colors.green : const Color(0xFF1E4079),
                                disabledBackgroundColor: Colors.green.shade300,
                                disabledForegroundColor: Colors.white,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                          
                          // Opción de Cancelar (Solo si está registrado)
                          if (isRegistered) ...[
                            const SizedBox(height: 15),
                            TextButton.icon(
                              onPressed: () => _confirmCancellation(context, eventService),
                              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                              label: const Text(
                                "Cancelar mi asistencia",
                                style: TextStyle(color: Colors.red, fontSize: 16),
                              ),
                            ),
                          ]
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[800], size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 15),
              children: [
                TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Alerta para Registrarse
  void _confirmAttendance(BuildContext context, EventService service) async {
    try {
      await service.registerAttendance(eventId);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 15),
                Text("¡Asistencia Confirmada!", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Aceptar"))
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Alerta para Cancelar
  void _confirmCancellation(BuildContext context, EventService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancelar asistencia"),
        content: const Text("¿Estás seguro de que deseas cancelar tu registro a este evento?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("No, volver"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Cerrar alerta
              await service.cancelAttendance(eventId); // Ejecutar borrado
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Registro cancelado correctamente"))
                );
              }
            },
            child: const Text("Sí, cancelar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}