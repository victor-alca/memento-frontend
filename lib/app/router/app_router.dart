import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/core/widgets/auth_wrapper.dart';
import 'package:test_app/features/account/presentation/pages/account_settings_page.dart';
import 'package:test_app/features/account/presentation/pages/change_password_page.dart';
import 'package:test_app/features/account/presentation/pages/edit_account_page.dart';
import 'package:test_app/features/tests/presentation/models/resultado_test_args.dart';
import 'package:test_app/features/auth/models/user_model.dart';
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
    final signingUp = state.matchedLocation == AppRoutes.signUp;
    final isAuthPage = loggingIn || signingUp;

    // Se não está logado e não está em página de auth, vai para login
    if (session == null && !isAuthPage) {
      return AppRoutes.login;
    }

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
      path: AppRoutes.patientHome,
      builder: (context, state) {
        final user = state.extra as UserModel;
        return PatientHomePage(user: user);
      },
    ),
    GoRoute(
      path: AppRoutes.doctorHome,
      builder: (context, state) {
        final user = state.extra as UserModel;
        return DoctorHomePage(user: user);
      },
    ),
    GoRoute(
      path: AppRoutes.testeMemoria,
      builder: (context, state) => const TesteMemoriaPage(),
    ),
    GoRoute(path: AppRoutes.tmtA, builder: (context, state) => TmtA()),
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
    GoRoute(
      path: AppRoutes.accountSettings,
      builder: (context, state) {
        return const AuthWrapper(child: AccountSettingsPage());
      },
    ),

    GoRoute(
      path: AppRoutes.editAccount,
      builder: (context, state) => const EditAccountPage(),
    ),
    GoRoute(
      path: AppRoutes.changePassword,
      builder: (context, state) => const ChangePasswordPage(),
    ),
  ],
  errorBuilder:
      (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: Center(child: Text(state.error.toString())),
      ),
);
