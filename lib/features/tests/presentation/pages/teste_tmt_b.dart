import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/core/enum/test_type.dart';
import 'package:test_app/features/tests/presentation/models/resultado_test_args.dart';
import 'package:test_app/features/auth/service/auth_service.dart';
import 'package:test_app/app/provider/supabase_provider.dart';
import 'package:test_app/features/auth/models/user_model.dart';

// Classe para armazenar dados do botão
class ButtonInfoB {
  final String value;
  final double left;
  final double top;
  bool disabled;

  ButtonInfoB({
    required this.value,
    required this.left,
    required this.top,
    this.disabled = false,
  });
}

class TmtB extends StatefulWidget {
  final Map<String, dynamic>? extra;

  const TmtB({super.key, this.extra});

  @override
  _TmtBState createState() => _TmtBState();
}

class _TmtBState extends State<TmtB> {
  final Random _random = Random();
  int currentIndex = 0;
  int erros = 0;

  List<ButtonInfoB> _buttonInfos = [];
  DateTime? _startTime;

  // sequência fixa do TMT-B
  final List<String> charList = [
    '1',
    'A',
    '2',
    'B',
    '3',
    'C',
    '4',
    'D',
    '5',
    'E',
    '6',
    'F',
    '7',
    'G',
    '8',
    'H',
    '9',
    'I',
    '10',
    'J',
  ];

  late final AuthService authService;

  double? get tempoA => widget.extra?['tempoA'] as double?;
  int? get pontuacaoA => widget.extra?['pontuacaoA'] as int?;
  int? get patientId => widget.extra?['patientId'] as int?;
  String? get doctorId => widget.extra?['doctorId'] as String?;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateButtons(context);
    });
    authService = AuthService(supabase.client);
  }

  void _generateButtons(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const double buttonSize = 40;
    final double safeTop = kToolbarHeight + 20;
    const double padding = 5;
    const double restartBtnWidth = 56;
    final safeArea = MediaQuery.of(context).padding;

    final appBarHeight = kToolbarHeight;

    const double restartBtnHeight = 56;
    final double usableHeight =
        screenSize.height - appBarHeight - safeArea.top - safeArea.bottom - 40;

    currentIndex = 0;
    erros = 0;
    _buttonInfos.clear();

    for (var char in charList) {
      double left, top;
      bool overlap;

      // tenta achar posição válida
      do {
        overlap = false;
        left =
            padding +
            _random.nextDouble() *
                (screenSize.width - buttonSize - padding * 2);

        top =
            padding +
            _random.nextDouble() * (usableHeight - buttonSize - padding * 2) +
            40;

        for (var other in _buttonInfos) {
          if ((left - other.left).abs() < buttonSize + padding &&
              (top - other.top).abs() < buttonSize + padding) {
            overlap = true;
            break;
          }
        }

        if (left > screenSize.width - restartBtnWidth - 10 &&
            top < safeTop + restartBtnHeight + 10) {
          overlap = true;
        }
      } while (overlap);

      _buttonInfos.add(ButtonInfoB(value: char, left: left, top: top));
    }

    setState(() {});
  }

  void _disableButton(String value) {
    setState(() {
      final btn = _buttonInfos.firstWhere((b) => b.value == value);

      if (btn.value == charList[currentIndex]) {
        btn.disabled = true;

        if (currentIndex == 0) {
          _startTime = DateTime.now();
        }

        currentIndex++;

        if (currentIndex == charList.length) {
          _salvarResultado();
        }
      } else {
        erros++;
      }
    });
  }

  Future<void> _salvarResultado() async {
    try {
      final supabase = Supabase.instance.client;

      // Calcula pontuação B (20 - erros)
      int pontuacaoB = 20 - erros;

      // Pontuação total = A + B
      int pontuacaoTotal = (pontuacaoA ?? 0) + pontuacaoB;

      // Tempo B em SEGUNDOS
      double tempoB = 0.0;
      if (_startTime != null) {
        tempoB = DateTime.now().difference(_startTime!).inMilliseconds / 1000.0;
      }

      // Tempo total = A + B
      double tempoTotal = (tempoA ?? 0.0) + tempoB;

      final User? user = supabase.auth.currentUser;
      if (user != null) {
        UserModel _role = await authService.getUserData(user.id);

        if (patientId != null && doctorId != null) {
          await supabase.from('patient_tests').insert({
            'patient_id': patientId,
            'test_id': 2,
            'score': pontuacaoTotal,
            'average_time': null,
            'time_spent': tempoTotal * 1000,
            'test_date': DateTime.now().toIso8601String(),
            'doctor_id': doctorId,
          });
        } else if (_role.isPatient) {
          final patient =
              await supabase
                  .from('patients')
                  .select('id')
                  .eq('user_id', user.id)
                  .maybeSingle();

          final patientId = patient?['id'];

          await supabase.from('patient_tests').insert({
            'patient_id': patientId,
            'test_id': 2,
            'score': pontuacaoTotal,
            'average_time': null,
            'time_spent': tempoTotal * 1000,
            'test_date': DateTime.now().toIso8601String(),
            'doctor_id': null,
          });
        } else if (_role.isDoctor) {
          final doctor =
              await supabase
                  .from('doctors')
                  .select('id')
                  .eq('user_id', user.id)
                  .maybeSingle();

          final doctorId = doctor?['id'];

          await supabase.from('patient_tests').insert({
            'patient_id': null,
            'test_id': 2,
            'score': pontuacaoTotal,
            'average_time': null,
            'time_spent': tempoTotal * 1000,
            'test_date': DateTime.now().toIso8601String(),
            'doctor_id': doctorId,
          });
        }
      }

      if (mounted) {
        context.go(
          AppRoutes.resultadoTeste,
          extra: ResultadoTesteArgs(
            tipo: TestType.tmtA,
            pontuacao: pontuacaoTotal,
            tempoMedioMs: null,
            tempoA: tempoA,
            tempoB: tempoB,
            tempoTotalSeg: tempoTotal,
            pontuacaoA: pontuacaoA,
            pontuacaoB: pontuacaoB,
            patientId: patientId,
            doctorId: doctorId,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao salvar resultado: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teste TMT B',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Erros: $erros',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (tempoA != null)
                  Text(
                    'Tempo A: ${tempoA!.toStringAsFixed(2)}s',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                if (pontuacaoA != null)
                  Text(
                    'Pontuação A: $pontuacaoA',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              onPressed: () => _generateButtons(context),
              child: const Icon(Icons.refresh),
            ),
          ),
          ..._buttonInfos.map((btn) {
            return Positioned(
              left: btn.left,
              top: btn.top,
              child: Opacity(
                opacity: btn.disabled ? 0.4 : 1.0,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      backgroundColor: btn.disabled ? Colors.grey : null,
                    ),
                    onPressed:
                        btn.disabled ? null : () => _disableButton(btn.value),
                    child: Text(btn.value),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
