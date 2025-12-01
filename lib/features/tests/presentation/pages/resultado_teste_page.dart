import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/features/tests/presentation/models/resultado_test_args.dart';
import 'package:test_app/core/widgets/resultado_teste.dart';
import 'package:test_app/features/auth/service/auth_service.dart';
import 'package:test_app/app/provider/supabase_provider.dart';
import 'package:test_app/core/enum/test_type.dart';

class ResultadoTestePage extends StatefulWidget {
  final ResultadoTesteArgs args;

  const ResultadoTestePage({super.key, required this.args});

  @override
  State<ResultadoTestePage> createState() => _ResultadoTestePageState();
}

class _ResultadoTestePageState extends State<ResultadoTestePage> {
  late final AuthService authService;
  bool isDoctor = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    authService = AuthService(supabase.client);
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = supabase.client.auth.currentUser;
    if (user != null) {
      final userData = await authService.getUserData(user.id);
      setState(() {
        isDoctor = userData.isDoctor;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getTitulo() {
    switch (widget.args.tipo) {
      case TestType.stroop:
        return "Resultado Stroop Test";
      case TestType.tmtA:
        return "Resultado Trail Making Test";
      case TestType.memoriaVerbal:
        return "Resultado Teste de Memória";
      default:
        return "Resultado do Teste";
    }
  }

  void _handleVoltar() {
    // Se vier do dashboard, volta para o dashboard
    if (widget.args.fromDashboard) {
      context.pop();
    } else {
      // Se vier de fazer o teste, volta para a home
      isDoctor
          ? context.go(AppRoutes.doctorHome)
          : context.go(AppRoutes.patientHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitulo(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ResultadoTeste(
                tipo: widget.args.tipo,
                tempoTotalSeg: widget.args.tempoTotalSeg ?? 0,
                tempoA: widget.args.tempoA,
                tempoB: widget.args.tempoB,
                totalAcertos: widget.args.acertos,
                totalErros: widget.args.erros,
                pontuacao: widget.args.pontuacao,
                pontuacaoA: widget.args.pontuacaoA,
                pontuacaoB: widget.args.pontuacaoB,
                onVoltar: _handleVoltar,
              ),
    );
  }
}
