import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:test_app/app/theme/app_colors.dart';
import 'package:test_app/app/theme/app_spacing.dart';
import 'package:test_app/features/patients/models/patient_model.dart';
import 'package:test_app/features/patients/service/patient_service.dart';
import 'package:test_app/app/provider/supabase_provider.dart';
import 'package:test_app/app/router/app_routes.dart';

class PatientsListPage extends StatefulWidget {
  final String doctorId;

  const PatientsListPage({
    super.key,
    required this.doctorId,
  });

  @override
  State<PatientsListPage> createState() => _PatientsListPageState();
}

class _PatientsListPageState extends State<PatientsListPage> {
  late final PatientService _patientService;
  List<PatientModel> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _patientService = PatientService(supabase.client);
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final patients = await _patientService.getDoctorPatients(widget.doctorId);
      setState(() {
        _patients = patients;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar pacientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToAddPatient() async {
    final result = await context.push(AppRoutes.addPatient, extra: widget.doctorId);
    if (result == true) {
      _loadPatients(); // Recarregar lista
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Meus Pacientes'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _loadPatients,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPatient,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildBody() {
    if (_patients.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_patients.length} paciente${_patients.length != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.builder(
                itemCount: _patients.length,
                itemBuilder: (context, index) {
                  final patient = _patients[index];
                  return _buildPatientCard(patient);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhum paciente encontrado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Adicione pacientes para começar\na acompanhar seus resultados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _navigateToAddPatient,
              icon: const Icon(Icons.person_add),
              label: const Text('Adicionar Paciente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    patient.name.isNotEmpty 
                        ? patient.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        patient.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (patient.birthDate != null)
                        Text(
                          'Nascimento: ${_formatDate(patient.birthDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(patient.isConfirmed),
              ],
            ),
            if (!patient.isConfirmed) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildPendingConfirmationWidget(patient),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isConfirmed) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isConfirmed ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        isConfirmed ? 'Confirmado' : 'Pendente',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isConfirmed ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }

  Widget _buildPendingConfirmationWidget(PatientModel patient) {
    final isTokenExpired = _patientService.isTokenExpired(patient.tokenExpiresAt);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isTokenExpired ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isTokenExpired ? Colors.red.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTokenExpired ? Icons.warning_outlined : Icons.email_outlined,
                size: 16,
                color: isTokenExpired ? Colors.red.shade600 : Colors.orange.shade600,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isTokenExpired 
                      ? 'Token de confirmação expirado'
                      : 'Aguardando confirmação do paciente via email',
                  style: TextStyle(
                    fontSize: 12,
                    color: isTokenExpired ? Colors.red.shade700 : Colors.orange.shade700,
                    fontWeight: isTokenExpired ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          if (isTokenExpired) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _renewToken(patient),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Renovar Token'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ] else if (patient.tokenExpiresAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Expira em: ${_formatDate(patient.tokenExpiresAt!)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _renewToken(PatientModel patient) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renovando token...'),
          backgroundColor: Colors.blue,
        ),
      );

      final success = await _patientService.renewConfirmationToken(
        patientId: patient.id,
        doctorId: widget.doctorId,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token renovado! Novo email enviado ao paciente.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recarregar a lista para mostrar o novo status
        _loadPatients();
      } else {
        throw Exception('Falha ao renovar token');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao renovar token: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';  
  }
}