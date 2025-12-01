import 'package:test_app/app/provider/user_provider.dart';
import 'package:test_app/features/tests/presentation/services/test_result_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:test_app/app/provider/user_provider.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/core/enum/test_type.dart';
import 'package:test_app/features/tests/presentation/models/resultado_test_args.dart';
import 'package:test_app/features/tests/presentation/services/test_result_service.dart';

class DashboardScreen extends StatefulWidget {
  final int? patientId;
  final String? patientName;

  const DashboardScreen({super.key, this.patientId, this.patientName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  final TestResultsService _testResultsService = TestResultsService();
  List<TestResult> _testResults = [];
  bool _isLoadingResults = false;
  int? _selectedTestType;
  List<Map<String, dynamic>> _testTypes = [];
  bool _showOnlyWithDoctor = false; // Novo estado para o filtro

  @override
  void initState() {
    super.initState();
    _loadTestTypes();
    _loadTestResults();
  }

  Future<void> _loadTestTypes() async {
    try {
      final types = await _testResultsService.getTestTypes();
      setState(() {
        _testTypes = types;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar tipos de teste: $e')),
        );
      }
    }
  }

  Future<void> _loadTestResults() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.user == null) return;

    setState(() {
      _isLoadingResults = true;
    });

    try {
      final results = await _testResultsService.getTestResults(
        userId: userProvider.user!.id,
        startDate: _rangeStart,
        endDate: _rangeEnd,
        testId: _selectedTestType,
        patientId: widget.patientId,
        withDoctorOnly: _showOnlyWithDoctor, // Adicionar o novo filtro
      );

      setState(() {
        _testResults = results;
        _isLoadingResults = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingResults = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar resultados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDoctorViewing =
        widget.patientId != null && widget.patientName != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title:
            isDoctorViewing
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Histórico do Paciente',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.patientName!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                )
                : const Text(
                  'Histórico',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Calendar Card
            _buildCalendarCard(),
            const SizedBox(height: 20),

            // Test Type Filter
            _buildTestTypeFilter(),
            const SizedBox(height: 20),

            // Doctor Filter - apenas para médicos visualizando pacientes
            if (isDoctorViewing) ...[
              _buildDoctorFilter(),
              const SizedBox(height: 20),
            ],

            // Range info
            if (_rangeStart != null && _rangeEnd != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text(
                      'Período: ${_rangeStart!.day}/${_rangeStart!.month} - ${_rangeEnd!.day}/${_rangeEnd!.month}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _rangeStart = null;
                          _rangeEnd = null;
                          _rangeSelectionMode = RangeSelectionMode.toggledOff;
                        });
                        _loadTestResults();
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Limpar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            // Test Results Section
            _buildTestResultsSection(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 20,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mostrar apenas testes realizados com médico',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: _showOnlyWithDoctor,
              onChanged: (value) {
                setState(() {
                  _showOnlyWithDoctor = value ?? false;
                });
                _loadTestResults();
              },
              activeColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        rangeStartDay: _rangeStart,
        rangeEndDay: _rangeEnd,
        rangeSelectionMode: _rangeSelectionMode,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          rangeStartDecoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
          rangeStartTextStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          rangeEndTextStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          rangeHighlightColor: Colors.grey.shade200,
          withinRangeDecoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          withinRangeTextStyle: const TextStyle(color: Colors.black),
          defaultTextStyle: const TextStyle(color: Colors.black),
          weekendTextStyle: const TextStyle(color: Colors.black),
          outsideTextStyle: TextStyle(color: Colors.grey.shade400),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.black),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: Colors.black,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _rangeStart = null;
              _rangeEnd = null;
              _rangeSelectionMode = RangeSelectionMode.toggledOff;
            });
          }
        },
        onRangeSelected: (start, end, focusedDay) {
          setState(() {
            _selectedDay = null;
            _focusedDay = focusedDay;
            _rangeStart = start;
            _rangeEnd = end;
            _rangeSelectionMode = RangeSelectionMode.toggledOn;
          });
          _loadTestResults();
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildTestTypeFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Filtrar por teste:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedTestType,
                isExpanded: true,
                hint: const Text('Todos os testes'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos os testes'),
                  ),
                  ..._testTypes.map((type) {
                    return DropdownMenuItem<int?>(
                      value: type['id'] as int,
                      child: Text(type['name'] as String),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTestType = value;
                  });
                  _loadTestResults();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultsSection() {
    if (_isLoadingResults) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_testResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.assessment_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum resultado encontrado',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tente ajustar os filtros ou realizar mais testes',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Resultados (${_testResults.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _testResults.length,
          itemBuilder: (context, index) {
            return _buildTestResultCard(_testResults[index]);
          },
        ),
      ],
    );
  }

  Widget _buildTestResultCard(TestResult result) {
    // Convert UTC time to local time
    final localDate = result.testDate.toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to ResultadoTestePage with test data
            context.push(
              AppRoutes.resultadoTeste,
              extra: _createResultadoTesteArgs(result),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Test icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getTestColor(result.testId).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTestIcon(result.testId),
                    color: _getTestColor(result.testId),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Test info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              result.testName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Indicador de teste com médico
                          if (result.doctorId != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.medical_services,
                                    size: 12,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Com médico',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(localDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Score and time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(result.score).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${result.score.toStringAsFixed(0)} pts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getScoreColor(result.score),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(result.timeSpent / 1000),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Seta indicando que é clicável
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Método para criar ResultadoTesteArgs a partir do TestResult
  // No método _createResultadoTesteArgs
  ResultadoTesteArgs _createResultadoTesteArgs(TestResult result) {
    TestType tipo;
    switch (result.testId) {
      case 1:
        tipo = TestType.stroop;
        break;
      case 2:
        tipo = TestType.tmtA;
        break;
      case 3:
        tipo = TestType.memoriaVerbal;
        break;
      default:
        tipo = TestType.stroop;
    }

    // Para Stroop (test_id = 1)
    if (result.testId == 1) {
      final acertos = result.score.toInt();
      final erros = 50 - acertos;

      return ResultadoTesteArgs(
        tipo: tipo,
        pontuacao: acertos,
        tempoTotalSeg: result.timeSpent / 1000,
        acertos: acertos,
        erros: erros,
        fromDashboard: true, // Adicionar
      );
    }

    // Para TMT (test_id = 2)
    if (result.testId == 2) {
      return ResultadoTesteArgs(
        tipo: tipo,
        pontuacao: result.score.toInt(),
        tempoTotalSeg: result.timeSpent / 1000,
        tempoA: null,
        tempoB: null,
        pontuacaoA: null,
        pontuacaoB: null,
        fromDashboard: true,
      );
    }

    // Para Memória Verbal (test_id = 3)
    if (result.testId == 3) {
      final acertos = result.score.toInt();
      final erros = 20 - acertos;

      return ResultadoTesteArgs(
        tipo: tipo,
        pontuacao: acertos,
        tempoTotalSeg: result.timeSpent / 1000,
        acertos: acertos,
        erros: erros,
        fromDashboard: true, // Adicionar
      );
    }

    // Fallback
    return ResultadoTesteArgs(
      tipo: tipo,
      pontuacao: result.score.toInt(),
      tempoTotalSeg: result.timeSpent / 1000,
      fromDashboard: true, // Adicionar
    );
  }

  IconData _getTestIcon(int testId) {
    switch (testId) {
      case 1: // Stroop Test
        return Icons.palette_outlined;
      case 2: // Trail Making Test
        return Icons.route_outlined;
      case 3: // Memory Test
        return Icons.psychology_outlined;
      default:
        return Icons.assessment_outlined;
    }
  }

  Color _getTestColor(int testId) {
    switch (testId) {
      case 1: // Stroop Test
        return Colors.purple;
      case 2: // Trail Making Test
        return Colors.blue;
      case 3: // Memory Test
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás - ${date.day}/${date.month}/${date.year}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatTime(double seconds) {
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(1)}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}m ${remainingSeconds.toStringAsFixed(0)}s';
    }
  }
}
