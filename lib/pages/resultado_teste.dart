import 'package:flutter/material.dart';

class ResultadoTestePage extends StatelessWidget {

  final int pontuacao;

  const ResultadoTestePage({super.key, required this.pontuacao});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  // ----------------------------
  //          APP BAR
  // ----------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Resultado do Teste',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      titleSpacing: 20.0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    );
  }

  // ----------------------------
  //            BODY
  // ----------------------------
  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildNextButton(context),
          const SizedBox(height: 16),
          _buildResultadoCard(),
        ],
      ),
    );
  }

  // Botão de avançar
  Widget _buildNextButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: IconButton(
          icon: const Icon(Icons.arrow_forward, size: 32),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProximaTela()),
            );
          },
        ),
      ),
    );
  }

  // Card de resultado
  Widget _buildResultadoCard() {
    return Center(
      child: Card(
        color: const Color.fromARGB(255, 245, 187, 94),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Memória Verbal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              _buildTable(),
            ],
          ),
        ),
      ),
    );
  }

  // Tabela de resultados
  Widget _buildTable() {
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 18, color: Colors.black),
      child: Table(
        border: TableBorder(
          verticalInside: BorderSide(color: Colors.black, width: 1),
        ),
        columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth()},
        children: [
          _buildHeaderRow(),
          _buildDividerRow(),
          _buildDataRow(
            'Tempo médio de resposta: xx:xx',
            'Tempo médio de resposta: xx:xx',
          ),
          _buildDataRow('Taxa de acerto médio: x%', 'Taxa de acerto médio: x%'),
          _buildDataRow('Pontuação: x', 'Pontuação: x'),
        ],
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return const TableRow(
      children: [
        _TableCellHeader('Seu desempenho'),
        _TableCellHeader('Desempenho médio para sua idade'),
      ],
    );
  }

  TableRow _buildDividerRow() {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
      ),
      children: [SizedBox(height: 0), SizedBox(height: 0)],
    );
  }

  TableRow _buildDataRow(String left, String right) {
    return TableRow(children: [_TableCellData(left), _TableCellData(right)]);
  }

  // ----------------------------
  //            BUTTON
  // ----------------------------
  Widget _buildBottomButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TelaAnterior()),
            );
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Voltar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------
// COMPONENTES AUXILIARES DE TABELA
// ----------------------------
class _TableCellHeader extends StatelessWidget {
  final String text;

  const _TableCellHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _TableCellData extends StatelessWidget {
  final String text;

  const _TableCellData(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 22)),
    );
  }
}

// ----------------------------
// TELAS DE NAVEGAÇÃO
// ----------------------------
class ProximaTela extends StatelessWidget {
  const ProximaTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Próxima Tela')),
      body: const Center(child: Text('Conteúdo da próxima tela')),
    );
  }
}

class TelaAnterior extends StatelessWidget {
  const TelaAnterior({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tela Anterior')),
      body: const Center(child: Text('Conteúdo da tela anterior')),
    );
  }
}
