import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FilterModal extends StatefulWidget {
  final String? initialCategory;
  final String? initialLocation;
  final DateTime? initialDate;

  const FilterModal({
    super.key,
    this.initialCategory,
    this.initialLocation,
    this.initialDate,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  // Colores de tu diseño Figma
  final Color darkText = const Color(0xFF203957);
  final Color lightText = const Color(0xFF809EC2);
  final Color primaryBlue = const Color(0xFF2660A5);

  // Estado local
  String? _selectedCategory;
  String? _selectedLocation;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedLocation = widget.initialLocation;
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height * 0.85, // Ocupa 85% de la pantalla
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Indicador de "arrastrar"
          Container(
            width: 70,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF425D7E),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // Título
          Text(
            'Filtros',
            style: TextStyle(
              color: darkText,
              fontSize: 22,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // CONTENIDO SCROLLEABLE
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECCIÓN CATEGORÍA ---
                  _buildSectionTitle("Categoría"),
                  const SizedBox(height: 15),
                  // Traemos categorías de Firebase para crear los Chips
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const LinearProgressIndicator();

                      var docs = snapshot.data!.docs;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: docs.map((doc) {
                          return _buildChip(
                            label: doc['name'],
                            value: doc.id,
                            groupValue: _selectedCategory,
                            onTap: (val) =>
                                setState(() => _selectedCategory = val),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // --- SECCIÓN FECHA (Calendario Real) ---
                  _buildSectionTitle("Fecha"),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: CalendarDatePicker(
                      initialDate: _selectedDate!,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                      onDateChanged: (date) =>
                          setState(() => _selectedDate = date),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- SECCIÓN UBICACIÓN ---
                  _buildSectionTitle("Ubicación"),
                  const SizedBox(height: 15),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('locations')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const LinearProgressIndicator();

                      var docs = snapshot.data!.docs;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: docs.map((doc) {
                          return _buildChip(
                            label: doc['name'],
                            value: doc.id,
                            groupValue: _selectedLocation,
                            onTap: (val) =>
                                setState(() => _selectedLocation = val),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // --- BOTONES INFERIORES ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Botón Cancelar
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(
                      "Cancelar",
                      style: TextStyle(
                        color: primaryBlue,
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Botón Aplicar
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Regresamos los datos seleccionados al cerrar
                      Navigator.pop(context, {
                        'category': _selectedCategory,
                        'location': _selectedLocation,
                        'date': _selectedDate,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "Aplicar",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para el Título de Sección
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: darkText,
        fontSize: 18,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Widget auxiliar para los Chips (Píldoras)
  Widget _buildChip({
    required String label,
    required String value,
    required String? groupValue,
    required Function(String) onTap,
  }) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2660A5)
                : const Color(0xFF203957),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF2660A5)
                : const Color(0xFF203957),
            fontFamily: 'Montserrat',
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
