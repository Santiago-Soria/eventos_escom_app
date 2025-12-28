import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_eventos/screens/events/manage_event_screen.dart';
import 'package:proyecto_eventos/widgets/custom_alert_dialog.dart';

class EventModerationScreen extends StatefulWidget {
  const EventModerationScreen({super.key});

  @override
  State<EventModerationScreen> createState() => _EventModerationScreenState();
}

class _EventModerationScreenState extends State<EventModerationScreen> {
  String _filterStatus = 'all';
  String _searchText = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // FONDO
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
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Moderación de Eventos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 48), // Espacio para balancear
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // FILTROS Y BUSCADOR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // BUSCADOR
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _searchText = val.toLowerCase()),
                          decoration: const InputDecoration(
                            hintText: 'Buscar eventos por título...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(bottom: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // FILTROS DE ESTADO
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFilterButton('Todos', 'all'),
                            _buildFilterButton('Pendientes', 'pending'),
                            _buildFilterButton('Aprobados', 'approved'),
                            _buildFilterButton('Rechazados', 'rejected'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // LISTA DE EVENTOS
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
                            .orderBy('date', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 60,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'No hay eventos para moderar',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          var docs = snapshot.data!.docs;

                          // Filtrar por estado
                          if (_filterStatus != 'all') {
                            docs = docs.where((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              return data['status'] == _filterStatus;
                            }).toList();
                          }

                          // Filtrar por búsqueda
                          if (_searchText.isNotEmpty) {
                            docs = docs.where((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              String title = (data['title'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              String description = (data['description'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              return title.contains(_searchText) ||
                                  description.contains(_searchText);
                            }).toList();
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                            itemCount: docs.length,
                            itemBuilder: (context, index) =>
                                _buildEventCard(docs[index]),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // LOADING OVERLAY
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    bool isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2660A5) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String title = data['title'] ?? 'Sin título';
    String description = data['description'] ?? 'Sin descripción';
    String status = data['status'] ?? 'pending';
    String? imageUrl = data['imageUrl'];
    DateTime? date = data['date'] != null
        ? (data['date'] as Timestamp).toDate()
        : null;
    String location = data['location'] ?? 'Ubicación no especificada';
    String organizerName = data['organizerName'] ?? 'Organizador desconocido';
    String department = data['department'] ?? 'Departamento no especificado';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Aprobado';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rechazado';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'Pendiente';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN Y TÍTULO
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGEN DEL EVENTO
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image,
                                color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image,
                              color: Colors.grey),
                        ),
                ),

                const SizedBox(width: 15),

                // TÍTULO Y FECHA
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF203957),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 5),
                          Text(
                            date != null
                                ? DateFormat('dd/MM/yyyy - HH:mm')
                                    .format(date)
                                : 'Fecha no especificada',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 5),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // DESCRIPCIÓN
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // INFORMACIÓN ADICIONAL Y BOTONES
            Row(
              children: [
                // INFO DEL ORGANIZADOR
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 5),
                          Text(
                            organizerName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.business,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 5),
                          Text(
                            department,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // BADGE DE ESTADO
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // BOTONES DE ACCIÓN
            Row(
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Editar',
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageEventScreen(
                          eventSnapshot: doc,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                if (status != 'approved')
                  _buildActionButton(
                    icon: Icons.check_circle,
                    label: 'Aprobar',
                    color: Colors.green,
                    onPressed: () => _updateStatus(doc.id, 'approved'),
                  ),
                const SizedBox(width: 8),
                if (status != 'rejected')
                  _buildActionButton(
                    icon: Icons.cancel,
                    label: 'Rechazar',
                    color: Colors.red,
                    onPressed: () => _updateStatus(doc.id, 'rejected'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomAlertDialog(
        title: "¿Confirmar acción?",
        content: "El evento cambiará su estado a '$newStatus'.\n\n¿Estás seguro de continuar?",
        confirmText: newStatus == 'approved' ? 'Aprobar' : 'Rechazar',
        isDestructive: newStatus == 'rejected',
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        await FirebaseFirestore.instance.collection('events').doc(id).update({
          'status': newStatus,
          'isApproved': newStatus == 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus == 'approved'
                    ? 'Evento aprobado exitosamente'
                    : 'Evento rechazado exitosamente',
              ),
              backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar estado: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}