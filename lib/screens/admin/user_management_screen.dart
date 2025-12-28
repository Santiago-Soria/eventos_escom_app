import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_eventos/services/auth_services.dart';
import 'package:proyecto_eventos/widgets/custom_alert_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchText = "";
  String _filterRole = 'all'; // all, estudiante, organizador, admin
  bool _isLoading = false;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkIfSuperAdmin();
  }

  Future<void> _checkIfSuperAdmin() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _isSuperAdmin = data['isSuperAdmin'] == true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // FONDO
          Positioned.fill(
            child: Image.asset(
              "assets/images/escom_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF010415)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gestión de Usuarios',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isSuperAdmin)
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: _showAddAdminDialog,
                          tooltip: 'Crear nuevo administrador',
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // FILTROS Y BUSCADOR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // BUSCADOR
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _searchText = val.toLowerCase()),
                          decoration: const InputDecoration(
                            hintText: 'Buscar usuarios...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(bottom: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // FILTROS DE ROL
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFilterButton('Todos', 'all'),
                            _buildFilterButton('Estudiantes', 'estudiante'),
                            _buildFilterButton('Organizadores', 'organizador'),
                            _buildFilterButton('Admins', 'admin'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // LISTA DE USUARIOS
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 60,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'No hay usuarios registrados',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          var docs = snapshot.data!.docs;

                          // Filtrar por rol
                          if (_filterRole != 'all') {
                            docs = docs.where((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              return data['role'] == _filterRole;
                            }).toList();
                          }

                          // Filtrar por búsqueda
                          if (_searchText.isNotEmpty) {
                            docs = docs.where((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              String name = (data['name'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              String lastName = (data['lastName'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              String email = (data['email'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              return name.contains(_searchText) ||
                                  lastName.contains(_searchText) ||
                                  email.contains(_searchText);
                            }).toList();
                          }

                          // Excluir al usuario actual de la lista
                          String currentUserId = _auth.currentUser?.uid ?? '';
                          docs = docs
                              .where((doc) => doc.id != currentUserId)
                              .toList();

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                            itemCount: docs.length,
                            itemBuilder: (context, index) =>
                                _buildUserCard(docs[index]),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // LOADING OVERLAY
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    bool isSelected = _filterRole == value;
    return GestureDetector(
      onTap: () => setState(() => _filterRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2660A5) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String userId = doc.id;
    String name = data['name'] ?? 'Sin nombre';
    String lastName = data['lastName'] ?? '';
    String email = data['email'] ?? 'Sin email';
    String role = data['role'] ?? 'estudiante';
    String? photoUrl = data['photoUrl'];
    DateTime? createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    bool isSuperAdmin = data['isSuperAdmin'] == true;

    Color roleColor;
    IconData roleIcon;
    String roleText;

    switch (role) {
      case 'admin':
        roleColor = isSuperAdmin ? Colors.red[900]! : Colors.red;
        roleIcon = Icons.admin_panel_settings;
        roleText = isSuperAdmin ? 'Super Admin' : 'Administrador';
        break;
      case 'organizador':
        roleColor = Colors.green;
        roleIcon = Icons.event;
        roleText = 'Organizador';
        break;
      default:
        roleColor = Colors.blue;
        roleIcon = Icons.school;
        roleText = 'Estudiante';
    }

    // Verificar qué acciones puede realizar el usuario actual
    bool canChangeRole = role != 'admin' || (role == 'admin' && _isSuperAdmin && !isSuperAdmin);
    bool canDeleteUser = _canDeleteUser(role, isSuperAdmin);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: roleColor.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            // AVATAR
            CircleAvatar(
              radius: 25,
              backgroundColor: roleColor.withOpacity(0.1),
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl == null
                  ? Icon(roleIcon, color: roleColor, size: 24)
                  : null,
            ),

            const SizedBox(width: 15),

            // INFORMACIÓN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name $lastName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203957),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(roleIcon, size: 12, color: roleColor),
                            const SizedBox(width: 5),
                            Text(
                              roleText,
                              style: TextStyle(
                                fontSize: 11,
                                color: roleColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSuperAdmin) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[900]!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 10, color: Colors.red[900]),
                              const SizedBox(width: 3),
                              Text(
                                'Super',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (createdAt != null) ...[
                        const Spacer(),
                        Text(
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // BOTONES DE ACCIÓN
            if (canChangeRole || canDeleteUser)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'make_organizer') {
                    _changeUserRole(userId, 'organizador', email, name);
                  } else if (value == 'make_student') {
                    _changeUserRole(userId, 'estudiante', email, name);
                  } else if (value == 'make_admin' && _isSuperAdmin) {
                    _changeUserRole(userId, 'admin', email, name);
                  } else if (value == 'delete_user') {
                    _deleteUser(userId, email, name, role, isSuperAdmin);
                  }
                },
                itemBuilder: (context) {
                  List<PopupMenuEntry<String>> items = [];

                  if (canChangeRole && role != 'admin') {
                    items.addAll([
                      const PopupMenuItem(
                        value: 'make_organizer',
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 18, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Hacer Organizador'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'make_student',
                        child: Row(
                          children: [
                            Icon(Icons.school, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Hacer Estudiante'),
                          ],
                        ),
                      ),
                    ]);
                  }

                  if (_isSuperAdmin && role != 'admin') {
                    items.add(const PopupMenuItem(
                      value: 'make_admin',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hacer Administrador'),
                        ],
                      ),
                    ));
                  }

                  if (canDeleteUser) {
                    if (items.isNotEmpty) {
                      items.add(const PopupMenuDivider());
                    }
                    items.add(const PopupMenuItem(
                      value: 'delete_user',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar Usuario',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ));
                  }

                  return items;
                },
              ),
          ],
        ),
      ),
    );
  }

  bool _canDeleteUser(String targetUserRole, bool targetIsSuperAdmin) {
    // Si es super admin, puede eliminar a cualquier usuario excepto a sí mismo
    if (_isSuperAdmin) {
      return !targetIsSuperAdmin; // No puede eliminar a otros super admins
    }
    
    // Si es admin normal, solo puede eliminar estudiantes y organizadores
    return targetUserRole != 'admin';
  }

  Future<void> _changeUserRole(String userId, String newRole, String userEmail, String userName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomAlertDialog(
        title: "¿Cambiar rol de usuario?",
        content:
            "El usuario $userName ($userEmail) será cambiado a '$newRole'.\n\n¿Estás seguro de continuar?",
        confirmText: "Cambiar Rol",
        isDestructive: false,
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        Map<String, dynamic> updateData = {
          'role': newRole,
          'roleChangedAt': FieldValue.serverTimestamp(),
          'roleChangedBy': _auth.currentUser?.uid,
        };

        // Si se hace admin, agregar permisos básicos
        if (newRole == 'admin') {
          updateData['isSuperAdmin'] = false;
          updateData['permissions'] = [
            'validate_events',
            'manage_users',
            'delete_events',
            'edit_events'
          ];
        } else if (newRole == 'organizador') {
          updateData['department'] = 'Por asignar';
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update(updateData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userName cambiado a $newRole exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cambiar rol: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteUser(String userId, String userEmail, String userName, String userRole, bool isSuperAdmin) async {
    // Validaciones adicionales
    if (isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes eliminar a un Super Administrador'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomAlertDialog(
        title: "¿Eliminar usuario?",
        content:
            "Se eliminará permanentemente el usuario:\n\n$userName\n$userEmail\nRol: $userRole\n\n⚠️ Esta acción NO se puede deshacer.\n\n¿Estás seguro de continuar?",
        confirmText: "Eliminar",
        isDestructive: true,
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        // 1. Verificar si el usuario tiene eventos creados
        final userEvents = await FirebaseFirestore.instance
            .collection('events')
            .where('organizerId', isEqualTo: userId)
            .get();

        // 2. Eliminar o transferir eventos del usuario
        if (userEvents.docs.isNotEmpty) {
          // Opción A: Eliminar todos los eventos del usuario
          for (var eventDoc in userEvents.docs) {
            await FirebaseFirestore.instance
                .collection('events')
                .doc(eventDoc.id)
                .delete();
            
            // También eliminar subcolecciones (attendees, comments, etc.)
            final subcollections = ['attendees', 'comments', 'notifications'];
            for (var collection in subcollections) {
              final subcollectionDocs = await FirebaseFirestore.instance
                  .collection('events')
                  .doc(eventDoc.id)
                  .collection(collection)
                  .get();
              
              for (var doc in subcollectionDocs.docs) {
                await doc.reference.delete();
              }
            }
          }
        }

        // 3. Eliminar al usuario de la colección de usuarios
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();

        // 4. Intentar eliminar de Firebase Auth (opcional - requiere privilegios)
        try {
          await _authService.deleteUserAccount(userId);
        } catch (authError) {
          print('No se pudo eliminar de Auth: $authError');
          // Continuamos aunque falle Auth, porque ya eliminamos de Firestore
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuario $userName eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar usuario: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddAdminDialog() async {
    if (!_isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo super administradores pueden crear nuevos admins'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    TextEditingController nameController = TextEditingController();
    TextEditingController lastNameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Administrador'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa los datos del nuevo administrador:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Institucional',
                  hintText: 'usuario@escom.ipn.mx',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña Temporal (mínimo 6 caracteres)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'El nuevo administrador tendrá permisos para validar eventos y gestionar usuarios, pero no podrá crear otros administradores.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  lastNameController.text.trim().isEmpty ||
                  emailController.text.trim().isEmpty ||
                  passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor completa todos los campos'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La contraseña debe tener al menos 6 caracteres'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (!emailController.text.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa un correo válido'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              setState(() => _isLoading = true);
              
              try {
                // Usar el método existente en AuthService
                await _authService.createAdminUser(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  name: nameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Administrador creado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al crear administrador: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Crear Administrador'),
          ),
        ],
      ),
    );
  }
}