import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_eventos/services/auth_services.dart';
import 'package:proyecto_eventos/widgets/custom_alert_dialog.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();

  // Controladores
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  // Imágenes
  File? _imageFile;
  String? _currentPhotoUrl;
  final ImagePicker _picker = ImagePicker();

  // Intereses
  final List<String> _allInterests = [
    'Académico',
    'Cultural',
    'Deportivo',
    'Profesional',
    'Comunidad',
    'Conferencias',
    'Talleres',
    'Tecnología'
  ];
  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _emailController.text = currentUser!.email ?? '';
        _currentPhotoUrl = data['photoUrl'];

        if (data['interests'] != null) {
          _selectedInterests = List<String>.from(data['interests']);
        }
      }
    } catch (e) {
      debugPrint("Error cargando perfil: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      String? photoUrl = _currentPhotoUrl;

      // 1. Subir imagen si hay nueva
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_photos')
            .child('${currentUser!.uid}.jpg');
        await ref.putFile(_imageFile!);
        photoUrl = await ref.getDownloadURL();
      }

      // 2. Actualizar Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'name': _nameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'interests': _selectedInterests,
        'photoUrl': photoUrl,
      });

      setState(() {
        _isEditing = false;
        _currentPhotoUrl = photoUrl;
        _imageFile = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // SIN SCAFFOLD para respetar el fondo de StudentHome
    return Column(
      children: [
        // --- HEADER PERSONALIZADO ---
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mi Perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w600,
                ),
              ),
              // BOTÓN CERRAR SESIÓN
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (c) => const CustomAlertDialog(
                      title: "Cerrar Sesión",
                      content: "¿Estás seguro de que deseas salir?",
                      confirmText: "Salir",
                    ),
                  );
                  if (confirm == true) {
                    await _authService.signOut();
                  }
                },
              ),
            ],
          ),
        ),

        // --- CONTENIDO ---
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      // Tarjeta contenedora translúcida
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                              alpha: 0.95), // Casi sólido para leer bien
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // FOTO
                            GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: _imageFile != null
                                        ? FileImage(_imageFile!)
                                        : (_currentPhotoUrl != null
                                            ? NetworkImage(_currentPhotoUrl!)
                                                as ImageProvider
                                            : null),
                                    child: (_imageFile == null &&
                                            _currentPhotoUrl == null)
                                        ? Icon(Icons.person,
                                            size: 50,
                                            color: Colors.grey.shade400)
                                        : null,
                                  ),
                                  if (_isEditing)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor:
                                            const Color(0xFF2660A5),
                                        child: const Icon(Icons.camera_alt,
                                            size: 18, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // BOTÓN EDITAR / GUARDAR (Arriba para acceso rápido)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!_isEditing)
                                  TextButton.icon(
                                    onPressed: () =>
                                        setState(() => _isEditing = true),
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text("Editar Perfil"),
                                  )
                                else
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _isEditing = false;
                                            _imageFile = null;
                                            _loadUserData(); // Revertir cambios
                                          });
                                        },
                                        child: const Text("Cancelar",
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            _isSaving ? null : _saveProfile,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF2660A5),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                        ),
                                        child: _isSaving
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white))
                                            : const Text("Guardar",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 10),

                            // CAMPOS DE TEXTO
                            _buildTextField("Nombre", _nameController,
                                enabled: _isEditing),
                            const SizedBox(height: 15),
                            _buildTextField("Apellidos", _lastNameController,
                                enabled: _isEditing),
                            const SizedBox(height: 15),
                            _buildTextField(
                                "Correo Institucional", _emailController,
                                enabled: false), // Correo no editable

                            const SizedBox(height: 25),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Intereses",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF203957),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildInterestsChips(),
                          ],
                        ),
                      ),
                      const SizedBox(
                          height: 100), // Espacio final para el navbar
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF203957),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF0ECEC) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: enabled ? Colors.transparent : Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
                color: enabled ? Colors.black87 : Colors.grey.shade600),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allInterests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: _isEditing
              ? (selected) {
                  setState(() {
                    if (selected) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                }
              : null, // Deshabilitado si no se está editando
          selectedColor: const Color(0xFF2660A5).withValues(alpha: 0.2),
          checkmarkColor: const Color(0xFF2660A5),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF2660A5) : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: isSelected
                    ? const Color(0xFF2660A5)
                    : Colors.grey.shade300),
          ),
        );
      }).toList(),
    );
  }
}
