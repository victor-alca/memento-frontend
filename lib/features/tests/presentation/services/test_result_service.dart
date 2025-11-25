import 'package:supabase_flutter/supabase_flutter.dart';

class TestResult {
  final int id;
  final int patientId;
  final int testId;
  final String testName;
  final double score;
  final double timeSpent;
  final DateTime testDate;
  final double? averageTime;
  final String? doctorId;

  TestResult({
    required this.id,
    required this.patientId,
    required this.testId,
    required this.testName,
    required this.score,
    required this.timeSpent,
    required this.testDate,
    this.averageTime,
    this.doctorId,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'] as int,
      patientId: json['patient_id'] as int,
      testId: json['test_id'] as int,
      testName: json['test_name'] as String,
      score: (json['score'] as num).toDouble(),
      timeSpent: (json['time_spent'] as num).toDouble(),
      testDate: DateTime.parse(json['test_date'] as String),
      averageTime:
          json['average_time'] != null
              ? (json['average_time'] as num).toDouble()
              : null,
      doctorId: json['doctor_id'] as String?,
    );
  }
}

class TestResultsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch test results for a patient with optional date range and test type filters
  ///
  /// [userId] - The Supabase user ID (from user_id in patients table)
  /// [startDate] - Optional start date for filtering
  /// [endDate] - Optional end date for filtering
  /// [testId] - Optional test type ID for filtering (1=Stroop, 2=Trail Making, 3=Memory)
  Future<List<TestResult>> getTestResults({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int? testId,
    int? patientId,
    bool? withDoctorOnly, // Novo parâmetro
  }) async {
    try {
      int finalPatientId;

      if (patientId != null) {
        finalPatientId = patientId;
      } else {
        final patientResponse =
            await _supabase
                .from('patients')
                .select('id')
                .eq('user_id', userId)
                .single();

        finalPatientId = patientResponse['id'] as int;
      }

      // Build the base query
      var queryBuilder = _supabase
          .from('patient_tests')
          .select('''
            id,
            patient_id,
            test_id,
            score,
            time_spent,
            test_date,
            average_time,
            doctor_id,
            tests!inner(name)
          ''')
          .eq('patient_id', finalPatientId);

      // Apply test type filter
      if (testId != null) {
        queryBuilder = queryBuilder.eq('test_id', testId);
      }

      // Apply doctor filter
      if (withDoctorOnly == true) {
        queryBuilder = queryBuilder.not('doctor_id', 'is', null);
      }

      // Apply date range filters
      if (startDate != null) {
        queryBuilder = queryBuilder.gte(
          'test_date',
          startDate.toIso8601String(),
        );
      }

      if (endDate != null) {
        // Add one day to include the end date fully
        final endDateInclusive = endDate.add(const Duration(days: 1));
        queryBuilder = queryBuilder.lt(
          'test_date',
          endDateInclusive.toIso8601String(),
        );
      }

      // Execute query with ordering
      final response = await queryBuilder.order('test_date', ascending: false);

      // Parse the response
      final List<TestResult> results =
          (response as List).map((json) {
            return TestResult(
              id: json['id'] as int,
              patientId: json['patient_id'] as int,
              testId: json['test_id'] as int,
              testName: json['tests']['name'] as String,
              score: (json['score'] as num?)?.toDouble() ?? 0.0,
              timeSpent: (json['time_spent'] as num).toDouble(),
              testDate: DateTime.parse(json['test_date'] as String),
              averageTime:
                  json['average_time'] != null
                      ? (json['average_time'] as num).toDouble()
                      : null,
              doctorId: json['doctor_id'] as String?, // Adicionar este campo
            );
          }).toList();

      return results;
    } catch (e) {
      throw Exception('Erro ao buscar resultados dos testes: $e');
    }
  }

  /// Get test results grouped by test type with statistics
  Future<Map<String, List<TestResult>>> getTestResultsByType({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final results = await getTestResults(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    final Map<String, List<TestResult>> groupedResults = {};

    for (var result in results) {
      if (!groupedResults.containsKey(result.testName)) {
        groupedResults[result.testName] = [];
      }
      groupedResults[result.testName]!.add(result);
    }

    return groupedResults;
  }

  /// Get available test types
  Future<List<Map<String, dynamic>>> getTestTypes() async {
    try {
      final response = await _supabase
          .from('tests')
          .select('id, name')
          .order('id');

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Erro ao buscar tipos de teste: $e');
    }
  }

  /// Calculate statistics for a list of test results
  Map<String, dynamic> calculateStatistics(List<TestResult> results) {
    if (results.isEmpty) {
      return {
        'count': 0,
        'averageScore': 0.0,
        'averageTime': 0.0,
        'bestScore': 0.0,
        'worstScore': 0.0,
      };
    }

    final scores = results.map((r) => r.score).toList();
    final times = results.map((r) => r.timeSpent).toList();

    return {
      'count': results.length,
      'averageScore': scores.reduce((a, b) => a + b) / scores.length,
      'averageTime': times.reduce((a, b) => a + b) / times.length,
      'bestScore': scores.reduce((a, b) => a > b ? a : b),
      'worstScore': scores.reduce((a, b) => a < b ? a : b),
      'latestScore': results.first.score,
    };
  }
}
