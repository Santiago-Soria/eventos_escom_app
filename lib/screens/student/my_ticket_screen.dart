import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class MyTicketScreen extends StatelessWidget {
  final Map<String, dynamic>
  eventData; // Datos del evento (Título, fecha, etc.)
  final String eventId;

  const MyTicketScreen({
    super.key,
    required this.eventData,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    // EL QR ES EL ID DEL USUARIO
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    // Formatear fecha para que se vea bonita en el ticket
    String dateString = "Fecha por definir";
    if (eventData['date'] != null) {
      // Manejamos si viene como String o Timestamp
      try {
        DateTime date = eventData['date'].toDate();
        dateString = DateFormat(
          'EEEE d, MMMM yyyy',
          'es_MX',
        ).format(date); // Requiere intl initialize
      } catch (e) {
        dateString = "Fecha pendiente";
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Mi Pase de Acceso"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. FONDO UNIFICADO
          Positioned.fill(
            child: Image.asset(
              "assets/images/escom_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(color: const Color(0xFF010415)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ), // Un poco más oscuro para resaltar el ticket
          // 2. TICKET CENTRADO
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TÍTULO DEL EVENTO
                  Text(
                    eventData['title'] ?? "Evento ESCOM",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203957),
                      fontFamily: 'Montserrat',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 5),

                  Text(
                    dateString,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Nunito',
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  // CÓDIGO QR
                  if (userId.isNotEmpty)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF203957),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: QrImageView(
                            data: userId, // <--- LA CLAVE: El QR es tu ID
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Acceso Autorizado",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    const Text("Error: No se pudo cargar tu ID"),

                  const SizedBox(height: 25),

                  // INSTRUCCIONES
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Muestra este código al organizador en la entrada del evento para validar tu asistencia.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontFamily: 'Nunito',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
