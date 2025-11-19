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
class ButtonInfo {
  final int number;
  final double left;
  final double top;
  bool disabled;

  ButtonInfo({
    required this.number,
    required this.left,
    required this.top,
    this.disabled = false,
  });
}

class TmtA extends StatefulWidget {
  final int? patientId;
  final String? doctorId;

  const TmtA({super.key, this.patientId, this.doctorId});

  @override
  _TmtAState createState() => _TmtAState();
}

class _TmtAState extends State<TmtA> {
  final Random _random = Random();
  int lastNumber = 0;
  int erros = 0;

  List<ButtonInfo> _buttonInfos = [];
  DateTime? _startTime;

  late final AuthService authService;

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
    final safeArea = MediaQuery.of(context).padding;
    const double buttonSize = 40;
    const double padding = 8;

    final appBarHeight = kToolbarHeight;

    // Altura realmente utilizável (sem AppBar, SafeAreas, nem área superior extra)
    final double usableHeight =
        screenSize.height - appBarHeight - safeArea.top - safeArea.bottom - 40;

    lastNumber = 0;
    erros = 0;
    _buttonInfos.clear();

    for (int number = 1; number <= 20; number++) {
      double left, top;
      bool overlap;

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
      } while (overlap);

      _buttonInfos.add(ButtonInfo(number: number, left: left, top: top));
    }

    setState(() {});
  }

  void _disableButton(int number) {
    setState(() {
      final btn = _buttonInfos.firstWhere((b) => b.number == number);

      if (btn.number == lastNumber + 1) {
        btn.disabled = true;
        lastNumber = btn.number;

        if (btn.number == 1) {
          _startTime = DateTime.now();
        }

        if (btn.number == 20) {
          _navegarParaTmtB();
        }
      } else {
        erros++;
      }
    });
  }

  void _navegarParaTmtB() {
    // Calcula tempo A em segundos
    double tempoA = 0.0;
    if (_startTime != null) {
      tempoA = DateTime.now().difference(_startTime!).inMilliseconds / 1000.0;
    }

    // Calcula pontuação A (20 - erros)
    int pontuacaoA = 20 - erros;

    // Navega para TMT B passando tempo A, pontuação A, patientId e doctorId
    if (mounted) {
      context.go(
        AppRoutes.tmtB,
        extra: {
          'tempoA': tempoA,
          'pontuacaoA': pontuacaoA,
          'patientId': widget.patientId,
          'doctorId': widget.doctorId,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teste TMT A',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // contador de erros
          Positioned(
            top: 10,
            left: 10,
            child: Text(
              'Erros: $erros',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // botão de reiniciar
          Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              onPressed: () => _generateButtons(context),
              child: const Icon(Icons.refresh),
            ),
          ),

          // botões
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
                        btn.disabled
                            ? null
                            : () {
                              _disableButton(btn.number);
                            },
                    child: Text('${btn.number}'),
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
