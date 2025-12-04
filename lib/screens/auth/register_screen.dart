import 'package:flutter/material.dart';
import 'package:proyecto_eventos/services/auth_services.dart';

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
  final AuthService _authService = AuthService();

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      String fullName = "${_nameController.text} ${_lastnameController.text}";
      
      // Si es organizador, tomamos el texto del controlador.
      // Si es estudiante, enviamos NULL explícitamente.
      final String? deptToSend = _selectedRole == 'organizador' 
          ? _deptController.text 
          : null;

      try {
        await _authService.register(
          email: _emailController.text,
          password: _passwordController.text,
          name: fullName,
          role: _selectedRole,
          department: deptToSend, // Enviamos el valor condicional
        );

        if (mounted) {
          // --- ALERTA DE ÉXITO ---
          showDialog(
            context: context,
            barrierDismissible: false, // El usuario DEBE presionar el botón
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 50),
                  SizedBox(height: 10),
                  Text("¡Registro Exitoso!"),
                ],
              ),
              content: const Text(
                "Tu cuenta ha sido creada correctamente.\nPor favor inicia sesión con tus credenciales.",
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Cierra el diálogo
                    Navigator.of(context).pop(); // Cierra la pantalla de registro (vuelve al Login)
                  },
                  child: const Text("Aceptar", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        }
        
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.toString())),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF1E4079); 

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/escom_bg.png'), // Asegúrate de la extensión correcta
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: Colors.black.withOpacity(0.5)), 
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "EventOS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.70, 
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        "Registrarse",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(_nameController, "Nombre(s)", Icons.person),
                      const SizedBox(height: 15),
                      _buildTextField(_lastnameController, "Apellidos", Icons.person_outline),
                      const SizedBox(height: 15),
                      _buildTextField(_emailController, "Correo institucional", Icons.email_outlined),
                      const SizedBox(height: 15),
                      _buildTextField(_passwordController, "Contraseña", Icons.lock_outline, isPassword: true),
                      const SizedBox(height: 15),

                      // Radio Buttons para el Rol
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Radio<String>(
                            value: 'estudiante',
                            groupValue: _selectedRole,
                            activeColor: primaryBlue,
                            onChanged: (val) => setState(() => _selectedRole = val!),
                          ),
                          const Text("Soy estudiante"),
                          const SizedBox(width: 10),
                          Radio<String>(
                            value: 'organizador',
                            groupValue: _selectedRole,
                            activeColor: primaryBlue,
                            onChanged: (val) => setState(() => _selectedRole = val!),
                          ),
                          const Text("Soy organizador"),
                        ],
                      ),
                      
                      // --- LÓGICA CONDICIONAL ---
                      // Usamos un 'collection if' de Dart.
                      // Si la condición es verdadera, se agregan estos widgets a la columna.
                      if (_selectedRole == 'organizador') ...[
                        const SizedBox(height: 15),
                        _buildTextField(_deptController, "Nombre del departamento", Icons.business),
                      ],

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Registrarse",
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                        ),
                      ),

                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("¿Ya tienes una cuenta? "),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              "Inicia sesión",
                              style: TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      // Validación básica: Si el campo NO es visible (ej. Depto cuando es estudiante), no validar.
      validator: (value) {
        // Solo validamos departamento si el rol es organizador
        if (controller == _deptController && _selectedRole != 'organizador') {
          return null; 
        }
        return value!.isEmpty ? "Campo obligatorio" : null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: label,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
    );
  }
}