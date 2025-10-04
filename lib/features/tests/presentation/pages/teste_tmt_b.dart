import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/features/tests/presentation/models/resultado_test_args.dart';

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
  const TmtB({super.key});

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
    '1', 'A', '2', 'B', '3', 'C', '4', 'D', '5', 'E',
    '6', 'F', '7', 'G', '8', 'H', '9', 'I', '10', 'J'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateButtons(context);
    });
  }

  void _generateButtons(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const double buttonSize = 40;
    final double safeTop = kToolbarHeight + 20;
    const double padding = 5;
    const double restartBtnWidth = 56;
    const double restartBtnHeight = 56;

    currentIndex = 0;
    erros = 0;
    _buttonInfos.clear();

    for (var char in charList) {
      double left, top;
      bool overlap;

      // tenta achar posição válida
      do {
        overlap = false;
        left = _random.nextDouble() * (screenSize.width - buttonSize - padding);
        top = safeTop +
            _random.nextDouble() * (screenSize.height - safeTop - buttonSize - padding);

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

      _buttonInfos.add(ButtonInfoB(
        value: char,
        left: left,
        top: top,
      ));
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
      int pontuacao = 20 - erros;

      double tempoTotal = 0.0;
      if (_startTime != null) {
        tempoTotal =
            DateTime.now().difference(_startTime!).inMilliseconds / 1000.0;
      }

      await supabase.from('resultados_tmt').insert({
        'pontuacao': pontuacao,
        'tempo_total': tempoTotal,
        'data': DateTime.now().toIso8601String(),
      });

        Future.delayed(Duration.zero, () {
        context.go(
          AppRoutes.resultadoTeste,
          extra: ResultadoTesteArgs.tmt(
            pontuacao: pontuacao,
            tempoTotalMs: tempoTotal,
          ),
        );
      });

      debugPrint("Resultado salvo com sucesso!");
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
            child: Text(
              'Erros: $erros',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    onPressed: btn.disabled
                        ? null
                        : () => _disableButton(btn.value),
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
