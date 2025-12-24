import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_eventos/screens/events/manage_event_screen.dart';
import 'package:proyecto_eventos/screens/events/qr_scanner_screen.dart';
import 'package:proyecto_eventos/widgets/custom_alert_dialog.dart'; // <--- IMPORTANTE

class EventAttendeesScreen extends StatefulWidget {
  final String eventId;
  const EventAttendeesScreen({super.key, required this.eventId});

  @override
  State<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends State<EventAttendeesScreen> {
  // Función usando CustomAlertDialog
  void _deleteEvent() {
    showDialog(
      context: context,
      builder: (ctx) => CustomAlertDialog(
        title: "¿Deseas eliminar el evento?",
        content:
            "Esta acción es irreversible y se perderá toda la información.",
        confirmText: "Confirmar",
        onConfirm: () async {
          // Lógica de borrado
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .delete();
          if (mounted) {
            Navigator.pop(context); // Regresar al Home
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Evento eliminado")));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Gestión de Asistencia"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Editar detalles",
            onPressed: () async {
              var doc = await FirebaseFirestore.instance
                  .collection('events')
                  .doc(widget.eventId)
                  .get();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ManageEventScreen(eventSnapshot: doc),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/escom_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(color: const Color(0xFF010415)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10,
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .doc(widget.eventId)
                        .collection('attendees')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      int count = snapshot.data!.docs.length;
                      int checkedIn = snapshot.data!.docs
                          .where(
                            (doc) => (doc.data() as Map)['attended'] == true,
                          )
                          .length;
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.groups,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$count Inscritos",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              Text(
                                "$checkedIn han asistido (Check-in)",
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('events')
                            .doc(widget.eventId)
                            .collection('attendees')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off,
                                    size: 60,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Aún no hay inscritos",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 50),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20.0),
                                    child: TextButton.icon(
                                      onPressed: _deleteEvent,
                                      icon: const Icon(
                                        Icons.delete_forever,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        "Eliminar Evento",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          var attendees = snapshot.data!.docs;
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                            itemCount: attendees.length + 1,
                            itemBuilder: (context, index) {
                              if (index == attendees.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    top: 40.0,
                                    bottom: 20.0,
                                  ),
                                  child: InkWell(
                                    onTap: _deleteEvent,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        border: Border.all(color: Colors.red),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.delete_forever,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Cancelar y Eliminar Evento",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              var attendeeDoc = attendees[index];
                              var attendeeData =
                                  attendeeDoc.data() as Map<String, dynamic>;
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(attendeeDoc.id)
                                    .get(),
                                builder: (context, userSnapshot) {
                                  String name = "Estudiante";
                                  String email = "--";
                                  String? photoUrl;
                                  if (userSnapshot.hasData &&
                                      userSnapshot.data!.exists) {
                                    var d = userSnapshot.data!.data() as Map;
                                    name = d['name'] ?? "Estudiante";
                                    email = d['email'] ?? "--";
                                    photoUrl = d['photoUrl'];
                                  }
                                  bool hasAttended =
                                      attendeeData['attended'] == true;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: hasAttended
                                          ? Colors.green.shade50
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: hasAttended
                                            ? Colors.green.shade200
                                            : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFF2660A5,
                                        ),
                                        backgroundImage: photoUrl != null
                                            ? NetworkImage(photoUrl)
                                            : null,
                                        child: photoUrl == null
                                            ? const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF203957),
                                        ),
                                      ),
                                      subtitle: Text(
                                        email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      trailing: hasAttended
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 28,
                                            )
                                          : const Icon(
                                              Icons.access_time,
                                              color: Colors.grey,
                                              size: 20,
                                            ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRScannerScreen(eventId: widget.eventId),
          ),
        ),
        backgroundColor: const Color(0xFF2660A5),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text("Validar QR", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
