import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. OBTENER EVENTOS
  Stream<QuerySnapshot> getEvents({
    String? categoryId,
    String? locationId,
    DateTime? date,
  }) {
    Query query = _firestore.collection('events');

    // Filtrar por ID de Categoría
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    
    // Filtrar por ID de Ubicación
    if (locationId != null && locationId.isNotEmpty) {
      query = query.where('locationId', isEqualTo: locationId);
    }

    return query.snapshots();
  }

  // 2. OBTENER CATEGORÍAS
  Stream<QuerySnapshot> getCategories() {
    return _firestore.collection('categories').orderBy('name').snapshots();
  }

  // 3. OBTENER UBICACIONES
  Stream<QuerySnapshot> getLocations() {
    return _firestore.collection('locations').orderBy('name').snapshots();
  }

  // 4. REGISTRAR ASISTENCIA
  Future<void> registerAttendance(String eventId) async {
    User? user = _auth.currentUser;
    if (user == null) throw "Usuario no autenticado";

    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('attendees')
        .doc(user.uid)
        .set({
      'registeredAt': FieldValue.serverTimestamp(),
      'userId': user.uid,
      'status': 'confirmed',
    });

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('myEvents')
        .doc(eventId)
        .set({
      'registeredAt': FieldValue.serverTimestamp(),
      'eventId': eventId,
    });
  }

  // 5. VERIFICAR REGISTRO
  Stream<bool> isUserRegistered(String eventId) {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('attendees')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // 6. OBTENER MIS REGISTROS (Solo los IDs)
  Stream<QuerySnapshot> getMyRegistrations() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    // Escuchamos la subcolección 'myEvents' del usuario
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('myEvents')
        .orderBy('registeredAt', descending: true)
        .snapshots();
  }

  // 7. OBTENER DATOS DE UN SOLO EVENTO (Para llenar las tarjetas de Mis Eventos)
  Future<DocumentSnapshot> getEventById(String eventId) {
    return _firestore.collection('events').doc(eventId).get();
  }

  // 8. CANCELAR ASISTENCIA (Borrar de ambos lados)
  Future<void> cancelAttendance(String eventId) async {
    User? user = _auth.currentUser;
    if (user == null) throw "Usuario no autenticado";

    WriteBatch batch = _firestore.batch();

    // 1. Referencia en la colección del evento
    DocumentReference eventAttendanceRef = _firestore
        .collection('events')
        .doc(eventId)
        .collection('attendees')
        .doc(user.uid);

    // 2. Referencia en el perfil del usuario
    DocumentReference userMyEventRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('myEvents')
        .doc(eventId);

    // Ejecutamos ambas eliminaciones atómicamente
    batch.delete(eventAttendanceRef);
    batch.delete(userMyEventRef);

    await batch.commit();
  }

}