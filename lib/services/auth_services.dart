import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  // Instancias de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- 1. INICIAR SESIÓN (RF-002) ---
  // Retorna el usuario si es exitoso, o lanza un error si falla.
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password.trim()
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Manejo de errores comunes para mostrar mensajes claros en la UI
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'No existe usuario con ese correo.';
      } else if (e.code == 'wrong-password') {
        message = 'Contraseña incorrecta.';
      } else {
        message = 'Error al iniciar sesión: ${e.message}';
      }
      throw message; // Enviamos el error a la pantalla para mostrarlo
    } catch (e) {
      throw 'Ocurrió un error inesperado.';
    }
  }

  // --- 2. REGISTRARSE (RF-001 y RF-004) ---
  // Este es el método más importante: Crea la cuenta Y guarda los datos en Firestore
  Future<User?> register({
    required String email,
    required String password,
    required String name,
    required String role, // 'estudiante' u 'organizador'
    String? department, // Parametro opcional (solo si es organizador)
  }) async {
    try {
      // A. Crear el usuario en el sistema de Autenticación
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      User? user = result.user;

      if (user != null) {
        // Preparamos los datos del usuario
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': email.trim(),
          'name': name.trim(),
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'interests': [],
          'profilePhotoUrl': '',
        };

        // Solo agregamos el departamento si no es nulo
        if (department != null && department.isNotEmpty) {
          userData['department'] = department.trim();
        }

        await _firestore.collection('users').doc(user.uid).set(userData);
      }

      return user;

    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'La contraseña es muy débil.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Ya existe una cuenta con este correo.';
      } else {
        message = 'Error en el registro: ${e.message}';
      }
      throw message;
    } catch (e) {
      throw 'Ocurrió un error al registrar los datos.';
    }
  }

  // --- 3. CERRAR SESIÓN ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- 4. RECUPERAR CONTRASEÑA (RF-003) ---
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw 'Error al enviar correo: ${e.message}';
    }
  }

  // --- 5. OBTENER DATOS DEL USUARIO ACTUAL (Utilidad) ---
  // Sirve para saber qué rol tiene el usuario logueado
  Future<DocumentSnapshot> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await _firestore.collection('users').doc(user.uid).get();
    } else {
      throw 'No hay usuario logueado';
    }
  }

   // 6. ACTUALIZAR DATOS DEL USUARIO (Nombre e Intereses)
  Future<void> updateUserData({
    required String name,
    required List<String> interests,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw "No autenticado";

    await _firestore.collection('users').doc(user.uid).update({
      'name': name,
      'interests': interests,
    });
  }

  // 7. ACTUALIZAR CONTRASEÑA
  Future<void> updatePassword(String newPassword) async {
    User? user = _auth.currentUser;
    if (user == null) throw "No autenticado";

    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Por seguridad, debes cerrar sesión y volver a entrar para cambiar tu contraseña.';
      }
      throw 'Error al cambiar contraseña: ${e.message}';
    }
  }

  // 8. SUBIR FOTO DE PERFIL Y OBTENER URL
  Future<String> uploadProfilePhoto(File imageFile) async {
    User? user = _auth.currentUser;
    if (user == null) throw "No autenticado";

    // Creamos una referencia: users/UID/profile.jpg
    final ref = _storage.ref().child('users/${user.uid}/profile.jpg');
    
    // Subimos el archivo
    await ref.putFile(imageFile);
    
    // Obtenemos la URL pública
    final url = await ref.getDownloadURL();

    // Guardamos la URL en Firestore
    await _firestore.collection('users').doc(user.uid).update({
      'profilePhotoUrl': url,
    });

    return url;
}
}