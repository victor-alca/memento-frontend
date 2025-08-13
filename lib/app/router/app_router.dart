import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/features/tests/presentation/models/resultado_test_args.dart';
import '../../features/auth/presentation/pages/index.dart';
import '../../features/tests/presentation/pages/index.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authChanges = Supabase.instance.client.auth.onAuthStateChange;

final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  refreshListenable: GoRouterRefreshStream(_authChanges),
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final loggingIn = state.matchedLocation == AppRoutes.login;
    if (session == null && !loggingIn) return AppRoutes.login;
    if (session != null && loggingIn) return AppRoutes.testeMemoria;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      builder: (context, state) => const SignPage(),
    ),
    GoRoute(
      path: AppRoutes.testeMemoria,
      builder: (context, state) => const TesteMemoriaPage(),
    ),
    GoRoute(
      path: AppRoutes.resultadoTeste,
      builder: (context, state) {
        final args = state.extra as ResultadoTesteArgs;
        return ResultadoTestePage(
          pontuacao: args.pontuacao,
          tempoMedioMs: args.tempoMedioMs,
        );
      },
    ),
  ],
  errorBuilder:
      (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: Center(child: Text(state.error.toString())),
      ),
);
