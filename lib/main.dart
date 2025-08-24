import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/app/app.dart';
import 'package:test_app/app/config/env.dart';
import 'package:test_app/app/provider/user_provider.dart';
import 'package:test_app/features/auth/service/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    debug: Env.environment == 'dev',
  );

  final authService = AuthService(Supabase.instance.client);
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(authService),
      child: const MyApp(),
    ),
  );
}
