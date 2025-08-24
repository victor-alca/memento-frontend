import 'dart:math';
import 'package:flutter/material.dart';

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
  @override
  _TmtAState createState() => _TmtAState();
}

class _TmtAState extends State<TmtA> {
  final Random _random = Random();
  int lastNumber = 0;
  int erros = 0;

  List<ButtonInfo> _buttonInfos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateButtons(context);
    });
  }

  void _generateButtons(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double buttonSize = 40;
    final double safeTop = kToolbarHeight + 20; // evita appbar e contador
    final double padding = 5; // margem entre botões
    final double restartBtnWidth = 56;
    final double restartBtnHeight = 56;

    lastNumber = 0;
    erros = 0;
    _buttonInfos.clear();

    for (int number = 1; number <= 20; number++) {
      double left, top;
      bool overlap;

      // tenta achar posição válida
      do {
        overlap = false;

        left = _random.nextDouble() * (screenSize.width - buttonSize - padding);
        top =
            safeTop +
            _random.nextDouble() *
                (screenSize.height - safeTop - buttonSize - padding);

        // verifica colisão com outros botões
        for (var other in _buttonInfos) {
          if ((left - other.left).abs() < buttonSize + padding &&
              (top - other.top).abs() < buttonSize + padding) {
            overlap = true;
            break;
          }
        }

        // evita sobreposição com o botão de reiniciar
        if (left > screenSize.width - restartBtnWidth - 10 &&
            top < safeTop + restartBtnHeight + 10) {
          overlap = true;
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
      } else {
        erros++;
      }
    });
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // botão de reiniciar
          Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              onPressed: () => _generateButtons(context),
              child: Icon(Icons.refresh),
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
                      shape: CircleBorder(),
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
