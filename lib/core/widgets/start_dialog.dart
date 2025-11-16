import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void showModernStartDialog(
  BuildContext context, {
  required String titulo,
  required String textoExplicativo,
  required VoidCallback onStart,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 50, color: Colors.blueAccent),
              SizedBox(height: 16),

              Text(
                titulo,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),

              Text(
                textoExplicativo,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: Text("Cancelar"),
                    ),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.pop();
                        onStart();
                      },
                      child: Text("Iniciar"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
