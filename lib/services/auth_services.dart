import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Lista de "super usuarios" iniciales (puedes agregar más correos)
  final List<String> _initialAdminEmails = [
    'admin@escom.ipn.mx',
    'superadmin@ipn.mx'
  ];

  // --- 1. INICIAR SESIÓN (CON LÓGICA PARA SUPER USUARIO INICIAL) ---
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      User? user = result.user;
      
      // Lógica para super usuario inicial
      if (user != null && _initialAdminEmails.contains(email.trim())) {
        // Verificar si ya existe en Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // Crear automáticamente como admin
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': email.trim(),
            'name': 'Administrador',
            'lastName': 'ESCOM',
            'role': 'admin',
            'isSuperAdmin': true,
            'createdAt': FieldValue.serverTimestamp(),
            'permissions': [
              'validate_events',
              'manage_users',
              'delete_events',
              'edit_events',
              'create_admins'
            ],
          });
        }
      }
      
      return user;
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
    String? photoUrl,
  }) async {
    try {
      // Validar que no sea registro de admin por usuarios normales
      if (role == 'admin') {
        throw 'No puedes registrarte como administrador. Contacta al soporte.';
      }
      
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
          'photoUrl': photoUrl,
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

  // --- 4. SUBIR FOTO ---
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

  // --- 7. VERIFICAR SI USUARIO ES ADMIN ---
  Future<bool> isUserAdmin() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    if (!userDoc.exists) return false;
    
    Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
    return data['role'] == 'admin';
  }

  // --- 8. CREAR USUARIO ADMIN (solo para administradores existentes) ---
  Future<void> createAdminUser({
    required String email,
    required String password,
    required String name,
    required String lastName,
  }) async {
    // Validar que el correo sea institucional de ESCOM
    if (!email.endsWith('@escom.ipn.mx') && !email.endsWith('@ipn.mx')) {
      throw 'Solo se permiten correos institucionales del IPN para administradores';
    }
    
    // Verificar que el usuario actual sea admin
    bool currentUserIsAdmin = await isUserAdmin();
    if (!currentUserIsAdmin) {
      throw 'No tienes permisos para crear administradores';
    }
    
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
          'role': 'admin',
          'isSuperAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
          'permissions': [
            'validate_events',
            'manage_users',
            'delete_events',
            'edit_events'
          ],
        });
      }
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Error al crear administrador';
    }
  }

  // --- 9. CAMBIAR ROL DE USUARIO (solo para admins) ---
  Future<void> changeUserRole(String userId, String newRole) async {
    // Verificar que el usuario actual sea admin
    bool currentUserIsAdmin = await isUserAdmin();
    if (!currentUserIsAdmin) {
      throw 'No tienes permisos para cambiar roles';
    }
    
    // Validar roles permitidos
    List<String> allowedRoles = ['estudiante', 'organizador'];
    if (!allowedRoles.contains(newRole)) {
      throw 'Rol no válido. Roles permitidos: estudiante, organizador';
    }
    
    await _firestore.collection('users').doc(userId).update({
      'role': newRole,
      'roleChangedAt': FieldValue.serverTimestamp(),
      'roleChangedBy': _auth.currentUser?.uid,
    });
  }

  // --- 10. OBTENER TODOS LOS USUARIOS (para gestión de admin) ---
  Future<QuerySnapshot> getAllUsers() async {
    bool currentUserIsAdmin = await isUserAdmin();
    if (!currentUserIsAdmin) {
      throw 'No tienes permisos para ver todos los usuarios';
    }
    
    return await _firestore.collection('users').orderBy('createdAt', descending: true).get();
  }

  // --- 11. ELIMINAR USUARIO (solo para super admins) ---
  Future<void> deleteUser(String userId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw "No hay usuario logueado";
    
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    if (!userDoc.exists) throw "Usuario no encontrado";
    
    Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
    
    // Solo super admins pueden eliminar usuarios
    if (data['isSuperAdmin'] != true) {
      throw 'No tienes permisos para eliminar usuarios';
    }
    
    // Verificar que no sea auto-eliminación
    if (currentUser.uid == userId) {
      throw 'No puedes eliminarte a ti mismo';
    }
    
    await _firestore.collection('users').doc(userId).delete();
    
    // Opcional: eliminar también de Firebase Auth
    // await _auth.deleteUser(userId);
  }

  // --- 12. ELIMINAR CUENTA DE USUARIO (para Firebase Auth) ---
  Future<void> deleteUserAccount(String userId) async {
    try {
      // IMPORTANTE: Esta operación requiere privilegios especiales
      // Normalmente se haría desde una Cloud Function o backend seguro
      
      print('Intentando eliminar cuenta de usuario: $userId');
      
      // NOTA: Para usar _auth.deleteUser(userId) necesitas:
      // 1. Haber iniciado sesión recientemente
      // 2. O tener privilegios de administrador en Firebase
      // 3. O hacerlo desde una Cloud Function con la Admin SDK
      
      // Método alternativo: Usar Firebase Admin SDK desde Cloud Functions
      // await FirebaseAuth.instance.deleteUser(userId);
      
      // Por ahora solo registramos la operación
      await _firestore.collection('deleted_users').doc(userId).set({
        'userId': userId,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.currentUser?.uid,
        'reason': 'Administrative action',
      });
      
      throw 'La eliminación de cuentas de Firebase Auth requiere Cloud Functions. Usuario marcado para eliminación.';
      
    } catch (e) {
      print('Error en deleteUserAccount: $e');
      throw 'No se pudo eliminar la cuenta de autenticación: $e';
    }
  }

  // --- 13. VERIFICAR SI USUARIO ES SUPER ADMIN ---
  Future<bool> isUserSuperAdmin() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    if (!userDoc.exists) return false;
    
    Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
    return data['isSuperAdmin'] == true;
  }

  // --- 14. OBTENER USUARIO POR ID ---
  Future<DocumentSnapshot> getUserById(String userId) async {
    bool currentUserIsAdmin = await isUserAdmin();
    if (!currentUserIsAdmin) {
      throw 'No tienes permisos para ver información de otros usuarios';
    }
    
    return await _firestore.collection('users').doc(userId).get();
  }
}