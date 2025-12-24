import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- 1. INICIAR SESIÓN ---
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = 'Usuario o contraseña incorrectos.';
      } else if (e.code == 'wrong-password') {
        message = 'Contraseña incorrecta.';
      } else {
        message = 'Error al iniciar sesión: ${e.message}';
      }
      throw message;
    } catch (e) {
      throw 'Ocurrió un error inesperado: $e';
    }
  }

  // --- 2. REGISTRAR USUARIO (CORREGIDO) ---
  Future<User?> registerUser({
    required String email,
    required String password,
    required String name,
    required String lastName,
    required String role,
    String? department,
    String? photoUrl, // <--- 1. Agregamos el parámetro aquí
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email.trim(),
          'name': name.trim(),
          'lastName': lastName.trim(),
          'role': role,
          'department': department?.trim(),
          'photoUrl': photoUrl, // <--- 2. Guardamos la URL recibida (o null)
          'interests': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Error desconocido al registrar';
    }
  }

  // --- 3. CERRAR SESIÓN ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- 4. SUBIR FOTO (Lo mantenemos por si se usa en perfil) ---
  Future<String> uploadProfilePhoto(File imageFile, String uid) async {
    try {
      final ref = _storage.ref().child('users/$uid/profile.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Error al subir imagen: $e';
    }
  }

  // --- 5. OBTENER DATOS DEL USUARIO ACTUAL ---
  Future<DocumentSnapshot> getUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw "No hay usuario logueado";
    return await _firestore.collection('users').doc(currentUser.uid).get();
  }

  // --- 6. RECUPERAR CONTRASEÑA ---
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Error al enviar correo de recuperación";
    }
  }
}
