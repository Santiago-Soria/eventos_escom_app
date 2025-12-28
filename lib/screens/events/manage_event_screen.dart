import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ManageEventScreen extends StatefulWidget {
  final DocumentSnapshot? eventSnapshot; // Si es null, crea. Si no, edita.

  const ManageEventScreen({super.key, this.eventSnapshot});

  @override
  State<ManageEventScreen> createState() => _ManageEventScreenState();
}

class _ManageEventScreenState extends State<ManageEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final currentUser = FirebaseAuth.instance.currentUser;

  // Controladores
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();

  // Variables de Estado
  String _modality = 'Presencial';
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedCategoryId;
  String? _selectedLocationId;

  // Estado de carga
  bool _isLoading = false;

  // Imágenes
  File? _imageFile;
  String? _currentImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.eventSnapshot != null) {
      _loadEventData();
    }
  }

  void _loadEventData() {
    var data = widget.eventSnapshot!.data() as Map<String, dynamic>;
    _titleController.text = data['title'] ?? '';
    _descController.text = data['description'] ?? '';
    _linkController.text = data['virtualLink'] ?? '';
    _modality = data['modality'] ?? 'Presencial';
    _selectedCategoryId = data['categoryId'];
    _selectedLocationId = data['locationId'];
    _currentImageUrl = data['imageUrl'];

    if (data['date'] != null) {
      _selectedDate = (data['date'] as Timestamp).toDate();
    }

    if (data['startTime'] != null) _startTime = _parseTime(data['startTime']);
    if (data['endTime'] != null) _endTime = _parseTime(data['endTime']);
  }

  TimeOfDay _parseTime(String timeStr) {
    final format = DateFormat.Hm();
    try {
      final dt = format.parse(timeStr);
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      locale: const Locale('es', 'MX'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona una fecha')));
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Define hora de inicio y fin')));
      return;
    }

    final double startDouble = _startTime!.hour + _startTime!.minute / 60.0;
    final double endDouble = _endTime!.hour + _endTime!.minute / 60.0;
    if (endDouble <= startDouble) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('La hora de término debe ser posterior a la de inicio')),
      );
      return;
    }

    if (_modality == 'Presencial' && _selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una ubicación')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _currentImageUrl;

      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('event_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      final String startStr =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
      final String endStr =
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';

      Map<String, dynamic> eventData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate!),
        'startTime': startStr,
        'endTime': endStr,
        'modality': _modality,
        'categoryId': _selectedCategoryId,
        'organizerId': currentUser!.uid,
        'imageUrl': imageUrl,
        'virtualLink':
            _modality == 'Virtual' ? _linkController.text.trim() : null,
        'locationId': _modality == 'Presencial' ? _selectedLocationId : null,
        'searchKeywords': _titleController.text.toLowerCase().split(' '),
        'isApproved': false, // Requiere aprobación del admin
        'approvedBy': null,
        'approvedAt': null,
        'status': 'pending', // pending, approved, rejected
        'rejectionReason': null,
      };

      if (widget.eventSnapshot == null) {
        eventData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('events').add(eventData);
      } else {
        await widget.eventSnapshot!.reference.update(eventData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.eventSnapshot == null
                  ? 'Evento creado'
                  : 'Evento actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // DISEÑO HOMOGÉNEO: Stack con Fondo + Contenido Blanco Curvo
    return Scaffold(
      extendBodyBehindAppBar: true, // Permite que el fondo llegue hasta arriba
      body: Stack(
        children: [
          // 1. FONDO GLOBAL (Igual que en Home)
          Positioned.fill(
            child: Image.asset(
              "assets/images/escom_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(color: const Color(0xFF010415)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          // 2. CONTENIDO
          SafeArea(
            child: Column(
              children: [
                // HEADER PERSONALIZADO
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      // Botón Atrás
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.eventSnapshot == null
                            ? "Nuevo Evento"
                            : "Editar Evento",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // FORMULARIO EN TARJETA BLANCA
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(25),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // SELECCIÓN DE IMAGEN
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      height: 180,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        image: _imageFile != null
                                            ? DecorationImage(
                                                image: FileImage(_imageFile!),
                                                fit: BoxFit.cover)
                                            : (_currentImageUrl != null
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                        _currentImageUrl!),
                                                    fit: BoxFit.cover)
                                                : null),
                                      ),
                                      child: (_imageFile == null &&
                                              _currentImageUrl == null)
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(Icons.add_a_photo_outlined,
                                                    size: 40,
                                                    color: Color(0xFF2660A5)),
                                                SizedBox(height: 10),
                                                Text("Subir portada",
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFF2660A5),
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 25),

                                  _buildSectionTitle("Información General"),
                                  const SizedBox(height: 15),
                                  _buildTextField("Título del evento",
                                      _titleController, Icons.title),
                                  const SizedBox(height: 15),
                                  _buildTextField(
                                      "Descripción",
                                      _descController,
                                      Icons.description_outlined,
                                      maxLines: 3),

                                  const SizedBox(height: 25),
                                  _buildSectionTitle("Fecha y Hora"),
                                  const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSelector(
                                          label: _selectedDate == null
                                              ? "Fecha"
                                              : DateFormat('dd/MM/yyyy')
                                                  .format(_selectedDate!),
                                          icon: Icons.calendar_today,
                                          onTap: () => _selectDate(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSelector(
                                          label: _startTime == null
                                              ? "Inicio"
                                              : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                                          icon: Icons.access_time,
                                          onTap: () =>
                                              _selectTime(context, true),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildSelector(
                                          label: _endTime == null
                                              ? "Fin"
                                              : '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
                                          icon: Icons.access_time_filled,
                                          onTap: () =>
                                              _selectTime(context, false),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 25),
                                  _buildSectionTitle("Detalles del Evento"),
                                  const SizedBox(height: 15),

                                  // CATEGORÍA
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('categories')
                                        .orderBy('name')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData)
                                        return const SizedBox();
                                      List<DropdownMenuItem<String>> items =
                                          snapshot.data!.docs.map((doc) {
                                        return DropdownMenuItem(
                                            value: doc.id,
                                            child: Text(doc['name']));
                                      }).toList();
                                      return DropdownButtonFormField<String>(
                                        value: _selectedCategoryId,
                                        items: items,
                                        onChanged: (val) => setState(
                                            () => _selectedCategoryId = val),
                                        decoration: _inputDecoration(
                                            "Categoría",
                                            Icons.category_outlined),
                                        validator: (val) => val == null
                                            ? "Selecciona una categoría"
                                            : null,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 15),

                                  // MODALIDAD (Radio Buttons Estilizados)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildRadioOption("Presencial",
                                            const Color(0xFF2660A5)),
                                        _buildRadioOption(
                                            "Virtual", Colors.purple),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  if (_modality == 'Presencial')
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('locations')
                                          .orderBy('name')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData)
                                          return const SizedBox();
                                        List<DropdownMenuItem<String>> items =
                                            snapshot.data!.docs.map((doc) {
                                          return DropdownMenuItem(
                                              value: doc.id,
                                              child: Text(doc['name']));
                                        }).toList();
                                        return DropdownButtonFormField<String>(
                                          value: _selectedLocationId,
                                          items: items,
                                          onChanged: (val) => setState(
                                              () => _selectedLocationId = val),
                                          decoration: _inputDecoration(
                                              "Ubicación",
                                              Icons.location_on_outlined),
                                        );
                                      },
                                    )
                                  else
                                    _buildTextField("Enlace de reunión",
                                        _linkController, Icons.link),

                                  const SizedBox(height: 40),

                                  // BOTÓN DE ACCIÓN
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: _saveEvent,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF2660A5),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15)),
                                        elevation: 5,
                                        shadowColor: const Color(0xFF2660A5)
                                            .withOpacity(0.4),
                                      ),
                                      child: Text(
                                        widget.eventSnapshot == null
                                            ? "Crear Evento"
                                            : "Guardar Cambios",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE ESTILO ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF203957),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController ctrl, IconData icon,
      {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: (val) => val!.isEmpty ? "Campo obligatorio" : null,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF2660A5)),
      filled: true,
      fillColor:
          const Color(0xFFF8F9FA), // Fondo gris muy claro para los inputs
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF2660A5), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildSelector(
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF2660A5)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, Color color) {
    bool isSelected = _modality == label;
    return InkWell(
      onTap: () => setState(() => _modality = label),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
