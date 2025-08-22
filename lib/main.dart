import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/app/app.dart';
import 'package:test_app/app/config/env.dart';
import 'pages/resultado_teste.dart';
import 'pages/teste_memoria.dart';
import 'pages/teste_tmt_a.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    debug: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App de Testes',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: TmtA(),
  }
}