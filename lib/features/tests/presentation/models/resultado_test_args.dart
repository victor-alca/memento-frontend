class ResultadoTesteArgs {
  final int pontuacao;
  final double tempoMedioMs;
  final double tempoTotalMs;


  ResultadoTesteArgs({required this.pontuacao, required this.tempoMedioMs}): tempoTotalMs = 0.0;

  ResultadoTesteArgs.tmt({required this.pontuacao, required this.tempoTotalMs}) : tempoMedioMs = 0.0;
}
