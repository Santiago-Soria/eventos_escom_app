import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_eventos/services/auth_services.dart';
import 'package:proyecto_eventos/services/event_service.dart'; 

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();
  final EventService _eventService = EventService();
  final ImagePicker _picker = ImagePicker();

  // Controladores
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Estado
  bool _isLoading = true;
  String? _currentPhotoUrl;
  File? _newPhotoFile; // Si el usuario selecciona una foto nueva
  List<String> _selectedInterests = [];
  List<String> _availableCategories = []; // Las traeremos de Firebase

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCategories();
  }

  // Carga inicial de datos
  Future<void> _loadUserData() async {
    try {
      final doc = await _authService.getUserData();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // 1. Manejo del Nombre Completo -> Nombre + Apellidos
        String fullName = data['name'] ?? '';
        List<String> nameParts = fullName.split(' ');
        
        if (nameParts.isNotEmpty) {
          _nameController.text = nameParts[0]; // Primer nombre
          if (nameParts.length > 1) {
            _lastNameController.text = nameParts.sublist(1).join(' '); // El resto son apellidos
          }
        }

        // 2. Foto e Intereses
        setState(() {
          _currentPhotoUrl = data['profilePhotoUrl'];
          // Convertimos la lista dinámica a lista de Strings
          _selectedInterests = List<String>.from(data['interests'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Cargar categorías disponibles para los intereses
  void _loadCategories() {
    _eventService.getCategories().listen((snapshot) {
      setState(() {
        _availableCategories = snapshot.docs.map((d) => d['name'] as String).toList();
      });
    });
  }

  // Seleccionar foto de galería
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newPhotoFile = File(picked.path);
      });
    }
  }

  // Guardar Cambios
  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      // 1. Subir Foto si hay una nueva
      if (_newPhotoFile != null) {
        await _authService.uploadProfilePhoto(_newPhotoFile!);
      }

      // 2. Actualizar Datos (Unimos Nombre + Apellido)
      String finalName = "${_nameController.text} ${_lastNameController.text}".trim();
      await _authService.updateUserData(
        name: finalName,
        interests: _selectedInterests,
      );

      // 3. Actualizar Contraseña (si escribió algo)
      if (_passwordController.text.isNotEmpty) {
        await _authService.updatePassword(_passwordController.text);
        _passwordController.clear(); // Limpiamos el campo por seguridad
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil actualizado correctamente"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _availableCategories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo oscuro acorde al diseño
      body: Column(
        children: [
          // Header Título
          AppBar(
            title: const Text("Editar Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: null, // Quitamos botón atrás si es tab
            automaticallyImplyLeading: false,
          ),
          
          // Contenido Blanco Curvo
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. FOTO DE PERFIL ---
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _newPhotoFile != null
                                ? FileImage(_newPhotoFile!) as ImageProvider
                                : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                                    ? NetworkImage(_currentPhotoUrl!)
                                    : null),
                            child: (_newPhotoFile == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty))
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E4079),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- 2. CAMPOS DE TEXTO ---
                    _buildLabel("Nombre(s)"),
                    _buildInput(_nameController, "Tu nombre"),
                    
                    const SizedBox(height: 15),
                    _buildLabel("Apellidos"),
                    _buildInput(_lastNameController, "Tus apellidos"),

                    const SizedBox(height: 15),
                    _buildLabel("Nueva Contraseña (Opcional)"),
                    _buildInput(_passwordController, "************", isPassword: true),

                    const SizedBox(height: 25),

                    // --- 3. INTERESES (CHIPS) ---
                    _buildLabel("Intereses"),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableCategories.map((category) {
                        final isSelected = _selectedInterests.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedInterests.add(category);
                              } else {
                                _selectedInterests.remove(category);
                              }
                            });
                          },
                          selectedColor: const Color(0xFF1E4079).withOpacity(0.1),
                          checkmarkColor: const Color(0xFF1E4079),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF1E4079) : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? const Color(0xFF1E4079) : Colors.grey.shade300),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),

                    // --- 4. BOTÓN GUARDAR ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E4079),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Guardar Cambios", style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 5),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}