import 'package:flutter/material.dart';
import 'package:test_app/core/enum/test_type.dart';

class ResultadoTeste extends StatelessWidget {
  final TestType tipo;

  // --- Dados comuns
  final double tempoTotalSeg;

  // --- Stroop
  final int? totalAcertos;
  final int? totalErros;

  // --- TMT
  final double? tempoA;
  final double? tempoB;
  final int? pontuacao;

  // --- Navigation callback
  final VoidCallback? onVoltar;

  final int? pontuacaoA;
  final int? pontuacaoB;

  const ResultadoTeste({
    super.key,
    required this.tipo,
    required this.tempoTotalSeg,
    this.totalAcertos,
    this.totalErros,
    this.tempoA,
    this.tempoB,
    this.pontuacao,
    this.pontuacaoA,
    this.pontuacaoB,
    this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 16.0,
              ),
              child: _buildContent(),
            ),
          ),
        ),
        // Botão Voltar
        if (onVoltar != null)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextButton(
              onPressed: onVoltar,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.arrow_back, size: 20, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'Voltar',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------
  // Seleciona qual conteúdo montar
  // -------------------------------
  Widget _buildContent() {
    switch (tipo) {
      case TestType.stroop:
        return _buildStroopCards();

      case TestType.tmtA:
        return _buildTmtCards();

      case TestType.memoriaVerbal:
        return _buildMemoriaCards();

      default:
        return const Text("Tipo de teste desconhecido");
    }
  }

  // ============================================================
  //                      CARDS: STROOP
  // ============================================================
  Widget _buildStroopCards() {
    final acertos = totalAcertos ?? 0;
    final erros = totalErros ?? 0;
    final totalRespostas = acertos + erros;

    // Porcentagem de acerto do usuário
    final porcentagemAcertos =
        totalRespostas > 0
            ? (acertos / totalRespostas * 100).toStringAsFixed(1)
            : "0.0";

    // Índice de Controle
    // Média da população controle: 32.5/50 = 65%
    final mediaControle = 32.5;
    final diferencaAbsoluta = acertos - mediaControle;
    final porcentagemDiferenca =
        ((diferencaAbsoluta / mediaControle) * 100).abs();

    // Determina se está acima ou abaixo da média
    String descricaoControle;
    if (acertos > mediaControle) {
      descricaoControle =
          "${porcentagemDiferenca.toStringAsFixed(1)}% acima da média";
    } else if (acertos < mediaControle) {
      descricaoControle =
          "${porcentagemDiferenca.toStringAsFixed(1)}% abaixo da média";
    } else {
      descricaoControle = "igual à média";
    }

    return Column(
      children: [
        _buildMetricCard(
          title: "Tempo Total",
          value: tempoTotalSeg.toStringAsFixed(2),
          unit: "segundos",
          color: const Color(0xFFB388EB),
          icon: Icons.timer_outlined,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Acertos",
          value: acertos.toString(),
          unit: "respostas corretas",
          color: const Color(0xFF8BC34A),
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Taxa de Acerto",
          value: porcentagemAcertos,
          unit: "% de precisão",
          color: const Color(0xFF29B6F6),
          icon: Icons.percent,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Índice de Controle",
          value: diferencaAbsoluta.toStringAsFixed(1),
          unit: descricaoControle,
          color:
              acertos >= mediaControle
                  ? const Color(0xFF66BB6A) // Verde se acima/igual
                  : const Color(0xFFFF9800), // Laranja se abaixo
          icon:
              acertos >= mediaControle
                  ? Icons.trending_up
                  : Icons.trending_down,
        ),
      ],
    );
  }

  // ============================================================
  //                      CARDS: TMT
  // ============================================================
  Widget _buildTmtCards() {
    // Se vier do dashboard e não tiver tempoA/tempoB separados, mostra apenas resumo
    final bool showSummaryOnly = (tempoA == null || tempoB == null);

    if (showSummaryOnly) {
      return _buildTmtSummaryCards();
    }

    // Versão completa com A, B e Total
    return _buildTmtFullCards();
  }

  // ============================================================
  //                  CARDS: TMT RESUMO (do Dashboard)
  // ============================================================
  Widget _buildTmtSummaryCards() {
    return Column(
      children: [
        _buildMetricCard(
          title: "Tempo Total",
          value: tempoTotalSeg.toStringAsFixed(2),
          unit: "segundos",
          color: const Color(0xFF6C63FF),
          icon: Icons.access_time,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Speed Score",
          value:
              tempoTotalSeg > 0
                  ? (1 / tempoTotalSeg).toStringAsFixed(3)
                  : "0.000",
          unit: "s⁻¹",
          color: const Color(0xFF9C27B0),
          icon: Icons.flash_on,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Pontuação Total",
          value: pontuacao?.toString() ?? "0",
          unit: "pontos",
          color: const Color(0xFF29B6F6),
          icon: Icons.emoji_events,
        ),
      ],
    );
  }

  // ============================================================
  //              CARDS: TMT COMPLETO (após fazer o teste)
  // ============================================================
  Widget _buildTmtFullCards() {
    // Tempos estimados da população controle
    const double tempoEstimadoA = 20.0; // segundos
    const double tempoEstimadoB = 46.0; // segundos
    const double tempoEstimadoTotal = 66.0; // segundos

    // Speed scores da população controle
    const double speedScoreControleA = 3.0; // s⁻¹
    const double speedScoreControleB = 1.3; // s⁻¹

    final tempoRealA = tempoA ?? 0.0;
    final tempoRealB = tempoB ?? 0.0;
    final tempoRealTotal = tempoTotalSeg;

    // Cálculo do Speed Score do usuário
    final speedScoreA = tempoRealA > 0 ? (1 / tempoRealA) : 0.0;
    final speedScoreB = tempoRealB > 0 ? (1 / tempoRealB) : 0.0;
    final speedScoreTotal = tempoRealTotal > 0 ? (1 / tempoRealTotal) : 0.0;

    // Cálculos de comparação para TMT A (tempo)
    final diferencaA = tempoRealA - tempoEstimadoA;
    final porcentagemDiferencaA = ((diferencaA / tempoEstimadoA) * 100).abs();
    String descricaoControleA;
    if (tempoRealA > tempoEstimadoA) {
      descricaoControleA =
          "${porcentagemDiferencaA.toStringAsFixed(1)}% acima do estimado";
    } else if (tempoRealA < tempoEstimadoA) {
      descricaoControleA =
          "${porcentagemDiferencaA.toStringAsFixed(1)}% abaixo do estimado";
    } else {
      descricaoControleA = "igual ao estimado";
    }

    // Comparação Speed Score A
    final diferencaSpeedA = speedScoreA - speedScoreControleA;
    final porcentagemSpeedA =
        ((diferencaSpeedA / speedScoreControleA) * 100).abs();
    String descricaoSpeedA;
    if (speedScoreA > speedScoreControleA) {
      descricaoSpeedA =
          "${porcentagemSpeedA.toStringAsFixed(1)}% acima da média";
    } else if (speedScoreA < speedScoreControleA) {
      descricaoSpeedA =
          "${porcentagemSpeedA.toStringAsFixed(1)}% abaixo da média";
    } else {
      descricaoSpeedA = "igual à média";
    }

    // Cálculos de comparação para TMT B (tempo)
    final diferencaB = tempoRealB - tempoEstimadoB;
    final porcentagemDiferencaB = ((diferencaB / tempoEstimadoB) * 100).abs();
    String descricaoControleB;
    if (tempoRealB > tempoEstimadoB) {
      descricaoControleB =
          "${porcentagemDiferencaB.toStringAsFixed(1)}% acima do estimado";
    } else if (tempoRealB < tempoEstimadoB) {
      descricaoControleB =
          "${porcentagemDiferencaB.toStringAsFixed(1)}% abaixo do estimado";
    } else {
      descricaoControleB = "igual ao estimado";
    }

    // Comparação Speed Score B
    final diferencaSpeedB = speedScoreB - speedScoreControleB;
    final porcentagemSpeedB =
        ((diferencaSpeedB / speedScoreControleB) * 100).abs();
    String descricaoSpeedB;
    if (speedScoreB > speedScoreControleB) {
      descricaoSpeedB =
          "${porcentagemSpeedB.toStringAsFixed(1)}% acima da média";
    } else if (speedScoreB < speedScoreControleB) {
      descricaoSpeedB =
          "${porcentagemSpeedB.toStringAsFixed(1)}% abaixo da média";
    } else {
      descricaoSpeedB = "igual à média";
    }

    // Cálculos de comparação para Total (tempo)
    final diferencaTotal = tempoRealTotal - tempoEstimadoTotal;
    final porcentagemDiferencaTotal =
        ((diferencaTotal / tempoEstimadoTotal) * 100).abs();
    String descricaoControleTotal;
    if (tempoRealTotal > tempoEstimadoTotal) {
      descricaoControleTotal =
          "${porcentagemDiferencaTotal.toStringAsFixed(1)}% acima do estimado";
    } else if (tempoRealTotal < tempoEstimadoTotal) {
      descricaoControleTotal =
          "${porcentagemDiferencaTotal.toStringAsFixed(1)}% abaixo do estimado";
    } else {
      descricaoControleTotal = "igual ao estimado";
    }

    return Column(
      children: [
        // Seção TMT A
        _buildSectionTitle("TMT A"),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Tempo Real A",
          value: tempoRealA.toStringAsFixed(2),
          unit: "segundos",
          color: const Color(0xFFB388EB),
          icon: Icons.timer_outlined,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Speed Score A",
          value: speedScoreA.toStringAsFixed(2),
          unit: descricaoSpeedA,
          color:
              speedScoreA >= speedScoreControleA
                  ? const Color(0xFF66BB6A) // Verde se maior/igual
                  : const Color(0xFFFF9800), // Laranja se menor
          icon:
              speedScoreA >= speedScoreControleA
                  ? Icons.trending_up
                  : Icons.trending_down,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Comparação Tempo A",
          value: diferencaA.toStringAsFixed(1),
          unit: descricaoControleA,
          color:
              tempoRealA <= tempoEstimadoA
                  ? const Color(0xFF66BB6A) // Verde se menor/igual
                  : const Color(0xFFFF9800), // Laranja se maior
          icon: tempoRealA <= tempoEstimadoA ? Icons.speed : Icons.schedule,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Pontuação A",
          value: pontuacaoA?.toString() ?? "0",
          unit: "pontos",
          color: const Color(0xFF8BC34A),
          icon: Icons.star_outline,
        ),

        const SizedBox(height: 24),

        // Seção TMT B
        _buildSectionTitle("TMT B"),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Tempo Real B",
          value: tempoRealB.toStringAsFixed(2),
          unit: "segundos",
          color: const Color(0xFF8E97FD),
          icon: Icons.timer_outlined,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Speed Score B",
          value: speedScoreB.toStringAsFixed(2),
          unit: descricaoSpeedB,
          color:
              speedScoreB >= speedScoreControleB
                  ? const Color(0xFF66BB6A) // Verde se maior/igual
                  : const Color(0xFFFF9800), // Laranja se menor
          icon:
              speedScoreB >= speedScoreControleB
                  ? Icons.trending_up
                  : Icons.trending_down,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Comparação Tempo B",
          value: diferencaB.toStringAsFixed(1),
          unit: descricaoControleB,
          color:
              tempoRealB <= tempoEstimadoB
                  ? const Color(0xFF66BB6A) // Verde se menor/igual
                  : const Color(0xFFFF9800), // Laranja se maior
          icon: tempoRealB <= tempoEstimadoB ? Icons.speed : Icons.schedule,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Pontuação B",
          value: pontuacaoB?.toString() ?? "0",
          unit: "pontos",
          color: const Color(0xFF66BB6A),
          icon: Icons.star_outline,
        ),

        const SizedBox(height: 24),

        // Seção Resultado Final
        _buildSectionTitle("Resultado Final"),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Tempo Real Total",
          value: tempoRealTotal.toStringAsFixed(2),
          unit: "segundos (A + B)",
          color: const Color(0xFF6C63FF),
          icon: Icons.access_time,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Speed Score Total",
          value: speedScoreTotal.toStringAsFixed(3),
          unit: "s⁻¹",
          color: const Color(0xFF9C27B0),
          icon: Icons.flash_on,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Comparação Total",
          value: diferencaTotal.toStringAsFixed(1),
          unit: descricaoControleTotal,
          color:
              tempoRealTotal <= tempoEstimadoTotal
                  ? const Color(0xFF66BB6A) // Verde se menor/igual
                  : const Color(0xFFFF9800), // Laranja se maior
          icon:
              tempoRealTotal <= tempoEstimadoTotal
                  ? Icons.speed
                  : Icons.schedule,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Pontuação Total",
          value: pontuacao?.toString() ?? "0",
          unit: "pontos (A + B)",
          color: const Color(0xFF29B6F6),
          icon: Icons.emoji_events,
        ),
      ],
    );
  }

  // ============================================================
  //                  CARDS: MEMÓRIA VERBAL
  // ============================================================
  Widget _buildMemoriaCards() {
    final acertos = totalAcertos ?? 0;
    final erros = totalErros ?? 0;
    final totalRespostas = acertos + erros;

    final porcentagemAcertos =
        totalRespostas > 0
            ? (acertos / totalRespostas * 100).toStringAsFixed(1)
            : "0.0";

    // Calcula tempo médio por resposta
    final tempoMedioPorResposta =
        totalRespostas > 0
            ? (tempoTotalSeg / totalRespostas).toStringAsFixed(2)
            : "0.00";

    return Column(
      children: [
        _buildMetricCard(
          title: "Tempo Total",
          value: tempoTotalSeg.toStringAsFixed(2),
          unit: "segundos",
          color: const Color(0xFFB388EB),
          icon: Icons.timer_outlined,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Tempo Médio",
          value: tempoMedioPorResposta,
          unit: "segundos por resposta",
          color: const Color(0xFF9C27B0),
          icon: Icons.speed,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Acertos",
          value: "$acertos",
          unit: "respostas corretas",
          color: const Color(0xFF8BC34A),
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Erros",
          value: erros.toString(),
          unit: "respostas incorretas",
          color: const Color(0xFFEF5350),
          icon: Icons.cancel_outlined,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Taxa de Acerto",
          value: porcentagemAcertos,
          unit: "% de precisão",
          color: const Color(0xFF29B6F6),
          icon: Icons.percent,
        ),
      ],
    );
  }

  // ============================================================
  //                   COMPONENTE: TÍTULO DE SEÇÃO
  // ============================================================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //                   COMPONENTE: CARD DE MÉTRICA
  // ============================================================
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decoração de fundo com ícone específico
          Positioned(
            right: 15,
            bottom: 15,
            child: Icon(icon, size: 60, color: Colors.white.withOpacity(0.15)),
          ),

          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Valor principal
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Unidade/descrição
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
