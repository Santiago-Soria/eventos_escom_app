import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelText;
  final String confirmText;
  final VoidCallback? onConfirm; // Ahora es opcional
  final bool isDestructive;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText = "Cancelar",
    this.confirmText = "Confirmar",
    this.onConfirm,
    this.isDestructive = true, // Por defecto true para borrar/salir (Rojo)
  });

  @override
  Widget build(BuildContext context) {
    const Color darkText = Color(0xFF203957);
    const Color greenConfirm = Color(0xFF5BB56F);
    const Color redDestructive = Color(0xFFBC0F0F);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(2, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TÍTULO
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkText,
                fontSize: 18,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            // CONTENIDO
            Text(
              content,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 25),

            // BOTONES
            Row(
              children: [
                // BOTÓN CANCELAR (Devuelve false)
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: redDestructive),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pop(context, false), // <--- Retorna FALSE
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          color: redDestructive,
                          fontSize: 16,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // BOTÓN CONFIRMAR (Devuelve true y ejecuta acción)
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: greenConfirm,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        if (onConfirm != null) onConfirm!();
                        Navigator.pop(context, true); // <--- Retorna TRUE
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
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
}
