import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para seleccionar foto
import 'package:firebase_storage/firebase_storage.dart'; // Para subir foto
import 'package:proyecto_eventos/services/auth_services.dart';
import 'package:proyecto_eventos/screens/home/organizer_home.dart';
// import 'package:proyecto_eventos/screens/home/student_home.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deptController = TextEditingController();

  String _selectedRole = 'estudiante';
  bool _isLoading = false;

  // Variables para imagen
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final AuthService _authService = AuthService();

  // Función para seleccionar imagen
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String? deptToSend =
          _selectedRole == 'organizador' ? _deptController.text.trim() : null;

      try {
        String? photoUrl;

        // 1. Subir foto si existe
        if (_imageFile != null) {
          // Crear referencia única: profile_TIMESTAMP.jpg
          final ref = FirebaseStorage.instance
              .ref()
              .child('user_photos')
              .child('profile_${DateTime.now().millisecondsSinceEpoch}.jpg');

          await ref.putFile(_imageFile!);
          photoUrl = await ref.getDownloadURL();
        }

        // 2. Registrar usuario pasando la URL de la foto
        // NOTA: Asegúrate que tu AuthService.registerUser acepte 'photoUrl'
        // Si no lo acepta, avísame para modificar el AuthService.
        await _authService.registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          lastName: _lastnameController.text.trim(),
          role: _selectedRole,
          department: deptToSend,
          photoUrl: photoUrl, // <--- Nuevo parámetro
        );

        if (mounted) {
          if (_selectedRole == 'organizador') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OrganizerHome()),
            );
          } else {
            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentHome()));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cuenta creada. ¡Bienvenido!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // Regresa al Login
          }
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
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2660A5);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Crear Cuenta",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'League Spartan',
              fontSize: 22),
        ),
      ),
      body: Stack(
        children: [
          // 1. FONDO (Homogeneizado)
          Positioned.fill(
            child: Image.asset(
              "assets/images/escom_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Container(color: const Color(0xFF010415)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),

          // 2. FORMULARIO FLOTANTE
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.92), // Glassmorphism consistente
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          "Únete a EventOS",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF203957),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Completa tus datos para comenzar",
                          style: TextStyle(
                              color: Colors.grey, fontFamily: 'Nunito'),
                        ),
                        const SizedBox(height: 20),

                        // --- SELECTOR DE FOTO ---
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : null,
                                child: _imageFile == null
                                    ? Icon(Icons.person,
                                        size: 50, color: Colors.grey.shade400)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                      color: primaryBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2)),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 16),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text("Subir foto de perfil",
                            style: TextStyle(fontSize: 12, color: Colors.grey)),

                        const SizedBox(height: 25),

                        // FILA: Nombre y Apellido
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _nameController,
                                label: "Nombre(s)",
                                icon: Icons.person,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildTextField(
                                controller: _lastnameController,
                                label: "Apellidos",
                                icon: Icons.person_outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // EMAIL
                        _buildTextField(
                          controller: _emailController,
                          label: "Correo Institucional",
                          icon: Icons.email_outlined,
                          inputType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 15),

                        // PASSWORD
                        _buildTextField(
                          controller: _passwordController,
                          label: "Contraseña",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 20),

                        // SELECCIÓN DE ROL
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Quiero registrarme como:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF203957),
                                fontFamily: 'Montserrat'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleCard('Estudiante', 'estudiante',
                                  Icons.school, primaryBlue),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildRoleCard(
                                  'Organizador',
                                  'organizador',
                                  Icons.event_available,
                                  primaryBlue),
                            ),
                          ],
                        ),

                        if (_selectedRole == 'organizador') ...[
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _deptController,
                            label: "Departamento / Academia",
                            icon: Icons.business,
                          ),
                        ],

                        const SizedBox(height: 30),

                        // BOTÓN REGISTRAR
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white))
                                : const Text(
                                    "Registrarme",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Nunito'),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      validator: (value) {
        if (value == null || value.isEmpty) return "Requerido";
        if (label.contains("Correo") && !value.contains("@"))
          return "Correo inválido";
        if (label.contains("Contraseña") && value.length < 6)
          return "Mínimo 6 caracteres";
        return null;
      },
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF2660A5), size: 20),
        hintText: label,
        hintStyle: const TextStyle(
            fontFamily: 'Nunito', fontSize: 14, color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF2660A5), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
      String title, String value, IconData icon, Color primaryColor) {
    bool isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.grey, size: 28),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
