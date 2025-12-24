import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:proyecto_eventos/widgets/custom_alert_dialog.dart'; // <--- Importante

class QRScannerScreen extends StatefulWidget {
  final String eventId;

  const QRScannerScreen({super.key, required this.eventId});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Escanear Asistencia"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          ValueListenableBuilder(
            valueListenable: cameraController,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.off
                      ? Icons.flash_off
                      : Icons.flash_on,
                ),
                onPressed: () => cameraController.toggleTorch(),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: cameraController,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.cameraDirection == CameraFacing.front
                      ? Icons.camera_front
                      : Icons.camera_rear,
                ),
                onPressed: () => cameraController.switchCamera(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (!_isProcessing && barcode.rawValue != null) {
                  _processQRCode(barcode.rawValue!);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2660A5), width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  "Apunta al QR del estudiante",
                  style: TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // BOTÓN DE TRUCO (SOLO PARA PRUEBAS - BORRAR DESPUÉS)
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(15),
              ),
              icon: const Icon(Icons.bug_report, color: Colors.white),
              onPressed: () {
                _processQRCode("0mLoRTWyEUY7q3mH1T5PmdxJbcc2");
              },
              label: const Text(
                "Simular Escaneo (Test)",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processQRCode(String userId) async {
    setState(() => _isProcessing = true);

    try {
      final attendeeRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('attendees')
          .doc(userId);

      final doc = await attendeeRef.get();

      if (!doc.exists) {
        _showResultDialog(
          title: "No registrado",
          message: "Este estudiante no está en la lista de invitados.",
          isSuccess: false,
        );
      } else {
        final data = doc.data();
        if (data != null && data['attended'] == true) {
          _showResultDialog(
            title: "Ya validado",
            message: "Este estudiante ya había ingresado al evento.",
            isSuccess: true, // Es éxito de lectura, aunque sea warning
          );
        } else {
          await attendeeRef.update({
            'attended': true,
            'checkInTime': FieldValue.serverTimestamp(),
          });

          _showResultDialog(
            title: "¡Acceso Correcto!",
            message: "Asistencia registrada exitosamente.",
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      _showResultDialog(
        title: "Error",
        message: "No se pudo leer el código: $e",
        isSuccess: false,
      );
    }
  }

  // --- ALERTA HOMOGENEIZADA ---
  void _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CustomAlertDialog(
        title: title,
        content: message,
        // Adaptamos los textos de los botones a la lógica del escáner
        cancelText: "Escanear otro",
        confirmText: isSuccess ? "Terminar" : "Salir",

        // Si es éxito (Acceso Correcto), ponemos el botón "Terminar" en verde (estilo default).
        // Si es error, mantenemos el estilo por defecto (Rojo para cancelar/reintentar).
        onConfirm: () {
          // Al presionar "Terminar" o "Salir", cerramos la pantalla del escáner
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      // Cuando se cierra el diálogo (ya sea por confirmar o cancelar)
      // damos un pequeño respiro antes de volver a leer
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    });
  }
}
