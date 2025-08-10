import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/resultado_teste.dart';
import 'pages/teste_memoria.dart';
import 'pages/login_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ljymwvozzshiiwlgdgxc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxqeW13dm96enNoaWl3bGdkZ3hjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxNzc2NzgsImV4cCI6MjA2Mzc1MzY3OH0.1bH3WSb-HDBHfEEET4l1qYzHL0DIlzHTAiZpUFS4Rlw',
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
      home: const LoginPage(),
    );
  }
}
