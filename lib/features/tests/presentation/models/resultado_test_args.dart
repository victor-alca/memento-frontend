class ResultadoTesteArgs {
  final int pontuacao;
  final double tempoMedioMs;
  final double tempoTotalMs;
  final int? patientId;
  final String? doctorId;


  ResultadoTesteArgs({
    required this.pontuacao, 
    required this.tempoMedioMs,
    this.patientId,
    this.doctorId,
  }): tempoTotalMs = 0.0;

  ResultadoTesteArgs.tmt({
    required this.pontuacao, 
    required this.tempoTotalMs,
    this.patientId,
    this.doctorId,
  }) : tempoMedioMs = 0.0;
}
