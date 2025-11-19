import 'package:test_app/core/enum/test_type.dart';

class ResultadoTesteArgs {
  final TestType tipo;
  final int? pontuacao;
  final double? tempoMedioMs;
  final double? tempoTotalSeg;
  final double? tempoA;
  final double? tempoB;
  final int? acertos;
  final int? erros;
  final int? pontuacaoA;
  final int? pontuacaoB;
  final int? patientId;
  final String? doctorId;

  ResultadoTesteArgs({
    required this.tipo,
    this.pontuacao,
    this.tempoMedioMs,
    this.tempoTotalSeg,
    this.tempoA,
    this.tempoB,
    this.acertos,
    this.erros,
    this.pontuacaoA,
    this.pontuacaoB,
    this.patientId,
    this.doctorId,
  });
}
