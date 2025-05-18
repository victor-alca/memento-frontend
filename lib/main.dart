import 'package:flutter/material.dart';
import 'pages/resultado_teste.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App de Testes',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const ResultadoTestePage(),
    );
  }
}
