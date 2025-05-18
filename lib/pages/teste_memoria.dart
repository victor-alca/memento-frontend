import 'dart:math';
import 'package:flutter/material.dart';
import 'resultado_teste.dart';

class TesteMemoriaPage extends StatefulWidget {
  const TesteMemoriaPage({super.key});

  @override
  State<TesteMemoriaPage> createState() => _TesteMemoriaPageState();
}

class _TesteMemoriaPageState extends State<TesteMemoriaPage> {
  final List<String> palavrasBase = [
    'Casa', 'Carro', 'Mesa', 'Livro', 'Sol',
    'Chave', 'Gato', 'Copo', 'Porta', 'Janela',
    'Fogo', 'Água', 'Relógio', 'Bolsa', 'Cadeira',
    'Céu', 'Flor', 'Papel', 'Luz', 'Telefone', 'Celular'
  ];

  late List<String> sequenciaPalavras;
  final Set<String> palavrasVistas = {};
  int indiceAtual = 0;
  int pontuacao = 0;
  int erros = 0;

  @override
  void initState() {
    super.initState();
    sequenciaPalavras = _gerarSequenciaAleatoria();
  }

  List<String> _gerarSequenciaAleatoria() {
    List<String> sequencia = [];
    Random random = Random();
    for (int i = 0; i < 20; i++) {
      String palavra = palavrasBase[random.nextInt(palavrasBase.length)];
      sequencia.add(palavra);
    }
    return sequencia;
  }

  void responder(bool visto) {
    String palavraAtual = sequenciaPalavras[indiceAtual];
    bool jaViu = palavrasVistas.contains(palavraAtual);

    if ((jaViu && visto) || (!jaViu && !visto)) {
      pontuacao++;
    } else {
      erros++;
    }

    palavrasVistas.add(palavraAtual);

    setState(() {
      indiceAtual++;
    });

    if (indiceAtual >= sequenciaPalavras.length) {
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultadoTestePage(pontuacao: pontuacao),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String palavraAtual = indiceAtual < sequenciaPalavras.length
        ? sequenciaPalavras[indiceAtual]
        : '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Teste de Memória Verbal',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Memorize as palavras que surgirem.',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Erros | $erros',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500)),
                Text('Pontos | $pontuacao',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 50),
            Center(
              child: Text(
                palavraAtual,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBotao('VISTO', true),
                _buildBotao('NOVO', false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotao(String texto, bool isVisto) {
    return ElevatedButton(
      onPressed: () => responder(isVisto),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
