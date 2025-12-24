import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_eventos/services/event_service.dart';
import 'package:proyecto_eventos/widgets/custom_alert_dialog.dart';

class EventDetailsScreen extends StatefulWidget {
  final DocumentSnapshot eventSnapshot;
  final bool isOrganizer;

  const EventDetailsScreen({
    super.key,
    required this.eventSnapshot,
    this.isOrganizer = false,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final EventService _eventService = EventService();
  bool _isRegistering = false;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  void _checkRegistrationStatus() {
    if (currentUser == null) return;
    FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventSnapshot.id)
        .collection('attendees')
        .doc(currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _isRegistered = snapshot.exists;
        });
      }
    });
  }

  Future<void> _registerForEvent() async {
    if (currentUser == null) return;
    setState(() => _isRegistering = true);

    try {
      await _eventService.registerAttendance(widget.eventSnapshot.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("¡Registro exitoso!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> _cancelRegistration() async {
    // ALERTA UNIFICADA
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const CustomAlertDialog(
        title: "¿Eliminar registro?",
        content:
            "Si eliminas tu registro, liberarás tu lugar. Podrás registrarte de nuevo si hay cupo.",
        confirmText: "Sí", // Botón corto para consistencia y evitar overflow
      ),
    );

    if (confirm == true) {
      setState(() => _isRegistering = true);
      try {
        await _eventService.cancelAttendance(widget.eventSnapshot.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Haz eliminado tu registro en el evento")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Error al cancelar: $e"),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data =
        widget.eventSnapshot.data() as Map<String, dynamic>;

    String title = data['title'] ?? 'Evento sin título';
    String description = data['description'] ?? 'Sin descripción';
    String imageUrl = data['imageUrl'] ?? '';
    String locationId = data['locationId'] ?? '';

    // --- LÓGICA DE FECHA Y HORA ACTUALIZADA ---
    DateTime date = data['date'] != null
        ? (data['date'] as Timestamp).toDate()
        : DateTime.now();
    String dateString = DateFormat('EEEE d, MMMM yyyy', 'es_MX').format(date);

    String startTime = data['startTime'] ?? '--:--';
    String endTime = data['endTime'] ?? ''; // Verificamos si existe hora de fin

    // Si hay hora de fin, mostramos el rango "10:00 - 12:00", si no, solo "10:00"
    String timeDisplay =
        endTime.isNotEmpty ? "$startTime - $endTime" : startTime;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Imagen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Container(color: Colors.grey[300]),
          ),
          // Botón Atrás
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Contenido
          Positioned.fill(
            top: 250,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF203957)),
                  ),
                  const SizedBox(height: 15),

                  // Hora corregida aquí
                  _buildInfoRow(
                      Icons.calendar_month, "$dateString  |  $timeDisplay"),
                  const SizedBox(height: 10),

                  FutureBuilder<DocumentSnapshot>(
                    future: locationId.isNotEmpty
                        ? FirebaseFirestore.instance
                            .collection('locations')
                            .doc(locationId)
                            .get()
                        : null,
                    builder: (context, snapshot) {
                      String locationName = "Ubicación por definir";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        locationName = snapshot.data!.get('name') ??
                            "Ubicación desconocida";
                      }
                      return _buildInfoRow(Icons.location_on, locationName);
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text("Acerca del evento",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(description,
                          style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5)),
                    ),
                  ),

                  const SizedBox(height: 10),
                  _buildActionButtons(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // 1. SI ES ORGANIZADOR, SOLO MOSTRAMOS UN TEXTO INFORMATIVO
    if (widget.isOrganizer) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          "Vista de Organizador (Solo lectura)",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (_isRegistering) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isRegistered) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text("Ya estás registrado",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.green.shade400,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _cancelRegistration,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              "Eliminar registro",
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline),
            ),
          )
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _registerForEvent,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2660A5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text(
            "Registrarme al evento",
            style: TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF2660A5), size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF203957),
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
