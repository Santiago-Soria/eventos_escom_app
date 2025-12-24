import 'package:flutter/material.dart';
import 'package:proyecto_eventos/services/auth_services.dart';
import 'package:proyecto_eventos/screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  // Estados de la UI
  bool _isLoading = false;
  bool _obscurePassword = true; // Variable para controlar el "ojito"

  void _login() async {
    // Cierra el teclado antes de procesar
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // El RoleWrapper se encarga de la navegación al detectar el cambio de usuario
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating, // Se ve más moderno flotando
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Escribe tu correo primero para recuperarla.')),
      );
      return;
    }
    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correo de recuperación enviado. Revisa tu bandeja.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2660A5);

    // UX MEJORA 2: GestureDetector para cerrar teclado al tocar fuera
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset:
            true, // Permite que el teclado empuje el contenido si es necesario
        body: Stack(
          children: [
            // 1. Imagen de Fondo
            Positioned.fill(
              child: Image.asset(
                'assets/images/escom_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Container(color: const Color(0xFF010415)),
              ),
            ),
            // Capa oscura para contraste
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),

            // 2. Contenido
            Column(
              children: [
                // Parte Superior (Logo)
                Expanded(
                  flex: 4,
                  child: SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(Icons.event,
                                size: 80, color: Colors.white),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            "EventOS",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'League Spartan',
                                letterSpacing: 2.0,
                                shadows: [
                                  Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black45)
                                ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Parte Inferior (Tarjeta de Login)
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withOpacity(0.92), // Opacidad calibrada
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        )
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(30, 40, 30, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Bienvenido",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF203957),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            const Text(
                              "Ingresa tus credenciales para continuar",
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Nunito',
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // CAMPO CORREO
                            _buildTextField(
                              controller: _emailController,
                              label: "Correo institucional",
                              icon: Icons.email_outlined,
                              primaryColor: primaryBlue,
                              inputType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),

                            // CAMPO CONTRASEÑA (CON OJITO)
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: (value) => value!.isEmpty
                                  ? "Ingresa tu contraseña"
                                  : null,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: primaryBlue),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                hintText: "Contraseña",
                                hintStyle: const TextStyle(
                                    fontFamily: 'Nunito', color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18, horizontal: 15),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                      color: primaryBlue, width: 1.5),
                                ),
                              ),
                            ),

                            // Olvidé contraseña
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _resetPassword,
                                child: Text(
                                  "¿Olvidaste tu contraseña?",
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // BOTÓN LOGIN
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 8,
                                  shadowColor: primaryBlue.withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5))
                                    : const Text(
                                        "Iniciar Sesión",
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Nunito'),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // LINK DE REGISTRO
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "¿No tienes cuenta?",
                                  style: TextStyle(
                                      color: Colors.black54,
                                      fontFamily: 'Nunito'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterScreen()),
                                    );
                                  },
                                  child: Text(
                                    "Regístrate aquí",
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Espacio extra para que no se pegue al fondo en pantallas muy largas
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper para el campo de email (el de password lo hice manual arriba para agregar el suffixIcon)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: (value) => value!.isEmpty ? "Este campo es obligatorio" : null,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryColor),
        hintText: label,
        hintStyle: const TextStyle(fontFamily: 'Nunito', color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
