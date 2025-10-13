import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_app/app/theme/app_colors.dart';
import 'package:test_app/app/theme/app_spacing.dart';
import 'package:test_app/features/patients/service/patient_service.dart';
import 'package:test_app/app/provider/supabase_provider.dart';
import 'package:test_app/app/router/app_routes.dart';

class ConfirmPatientAccessPage extends StatefulWidget {
  final String token;

  const ConfirmPatientAccessPage({
    super.key,
    required this.token,
  });

  @override
  State<ConfirmPatientAccessPage> createState() => _ConfirmPatientAccessPageState();
}

class _ConfirmPatientAccessPageState extends State<ConfirmPatientAccessPage> {
  late final PatientService _patientService;
  bool _isLoading = true;
  bool _isConfirmed = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _patientService = PatientService(supabase.client);
    _confirmAccess();
  }

  Future<void> _confirmAccess() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _patientService.confirmPatientAccess(widget.token);
      
      setState(() {
        _isConfirmed = success;
        _message = success 
            ? 'Acesso confirmado com sucesso! O médico agora pode visualizar seus dados.'
            : 'Token inválido ou expirado. Entre em contato com seu médico.';
      });
    } catch (e) {
      setState(() {
        _isConfirmed = false;
        _message = 'Erro ao confirmar acesso: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Confirmação de Acesso'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Confirmando acesso...',
                  style: TextStyle(fontSize: 16),
                ),
              ] else ...[
                Icon(
                  _isConfirmed ? Icons.check_circle : Icons.error,
                  size: 80,
                  color: _isConfirmed ? Colors.green : Colors.red,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _isConfirmed ? 'Sucesso!' : 'Erro',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isConfirmed ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () {
                    context.go(AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: const Text('Ir para Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}