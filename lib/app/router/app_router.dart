import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/app/provider/user_provider.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/features/account/presentation/pages/account_settings_page.dart';
import 'package:test_app/features/account/presentation/pages/change_password_page.dart';
import 'package:test_app/features/account/presentation/pages/edit_account_page.dart';
import 'package:test_app/features/tests/presentation/models/resultado_test_args.dart';
import 'package:test_app/features/auth/models/user_model.dart';
import 'package:test_app/features/patients/presentation/pages/patients_list_page.dart';
import 'package:test_app/features/patients/presentation/pages/add_patient_page.dart';
import 'package:test_app/features/patients/presentation/pages/confirm_patient_access_page.dart';
import 'package:test_app/features/tests/presentation/pages/teste_tmt_b.dart';
import '../../features/auth/presentation/pages/index.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/tests/presentation/pages/index.dart';
import 'package:test_app/features/tests/presentation/pages/line_chart.dart';

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

// You'll need to pass the BuildContext to access the provider
GoRouter createAppRouter(BuildContext context) {
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([
      GoRouterRefreshStream(_authChanges),
      userProvider,
    ]),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggingIn = state.matchedLocation == AppRoutes.login;
      final signingUp = state.matchedLocation == AppRoutes.signUp;
      final forgotPassword = state.matchedLocation == AppRoutes.forgotPassword;
      final isAuthRoute = state.matchedLocation == AppRoutes.auth;
      final isConfirmRoute =
          state.matchedLocation == AppRoutes.confirmPatientAccess;
      final isRootWithToken =
          state.matchedLocation == '/' &&
          state.uri.queryParameters['token'] != null;
      final isPublicPage =
          loggingIn ||
          signingUp ||
          forgotPassword ||
          isAuthRoute ||
          isConfirmRoute ||
          isRootWithToken;

      // Se chegou via deeplink /auth, redireciona para login
      if (isAuthRoute) {
        return AppRoutes.login;
      }

      // Se não está logado e não está em página pública, vai para login
      if (session == null && !isPublicPage) {
        return AppRoutes.login;
      }
      if (session != null && userProvider.isLoading) {
        return null; // Aguarda o provider terminar de carregar
      }
      // Se está logado e está em página de login/signup, redireciona para home apropriado
      if (session != null &&
          (state.matchedLocation == AppRoutes.login ||
              state.matchedLocation == AppRoutes.signUp ||
              state.matchedLocation == '/')) {
        // Usa o UserProvider para verificar o tipo de usuário
        if (userProvider.isDoctor) {
          return AppRoutes.doctorHome;
        } else if (userProvider.isPatient) {
          return AppRoutes.patientHome;
        }
      }

      return null;
    },
    routes: [
      // Rota raiz para capturar deep links com token
      GoRoute(
        path: '/',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          final session = Supabase.instance.client.auth.currentSession;
          if (token != null && token.isNotEmpty) {
            // Se tem token, vai para confirmação
            return ConfirmPatientAccessPage(token: token);
          }

          // Mostra loading enquanto o UserProvider está carregando
          final userProvider = Provider.of<UserProvider>(context);

          // Senão, redireciona para login
          if (session == null) {
            return const LoginPage();
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      // Deeplink route - redireciona para login
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.patientHome,
        builder: (context, state) {
          return PatientHomePage();
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
        path: AppRoutes.stroopTest,
        builder: (context, state) => const StroopTestPage(),
      ),
      GoRoute(path: AppRoutes.tmtB, builder: (context, state) => TmtB()),
      GoRoute(
        path: AppRoutes.resultadoTeste,
        builder: (context, state) {
          final args = state.extra as ResultadoTesteArgs;
          return ResultadoTestePage(
            pontuacao: args.pontuacao,
            tempoMedioMs: args.tempoMedioMs,
            patientId: args.patientId,
            doctorId: args.doctorId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.lineChart,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountSettings,
        builder: (context, state) {
          return const AccountSettingsPage();
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
      GoRoute(
        path: AppRoutes.patientsList,
        builder: (context, state) {
          final doctorId = state.extra as String;
          return PatientsListPage(doctorId: doctorId);
        },
      ),
      GoRoute(
        path: AppRoutes.addPatient,
        builder: (context, state) {
          final doctorId = state.extra as String;
          return AddPatientPage(doctorId: doctorId);
        },
      ),
      GoRoute(
        path: AppRoutes.confirmPatientAccess,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ConfirmPatientAccessPage(token: token);
        },
      ),
      // Doctor routes for patient tests
      GoRoute(
        path: AppRoutes.doctorPatientHistory,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return DashboardScreen(
            patientId: args['patientId'] as int,
            patientName: args['patientName'] as String,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.doctorPatientMemoryTest,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return TesteMemoriaPage(
            patientId: args['patientId'] as int,
            doctorId: args['doctorId'] as String,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.doctorPatientTmtA,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return TmtA(
            patientId: args['patientId'] as int,
            doctorId: args['doctorId'] as String,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.doctorPatientStroopTest,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return StroopTestPage(
            patientId: args['patientId'] as int,
            doctorId: args['doctorId'] as String,
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
}
