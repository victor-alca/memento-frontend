import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/app/theme/app_colors.dart';
import 'package:test_app/app/theme/app_spacing.dart';

class PatientOptionsDialog extends StatelessWidget {
  final int patientId;
  final String patientName;
  final String doctorId;

  const PatientOptionsDialog({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              patientName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Selecione uma opção',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildOptionButton(
              context: context,
              icon: Icons.history,
              title: 'Ver Histórico',
              subtitle: 'Visualizar resultados do paciente',
              onTap: () {
                Navigator.pop(context);
                context.push(
                  AppRoutes.doctorPatientHistory,
                  extra: {
                    'patientId': patientId,
                    'patientName': patientName,
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Realizar Teste',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildOptionButton(
              context: context,
              icon: Icons.memory,
              title: 'Teste de Memória',
              subtitle: 'Teste de memória verbal',
              onTap: () {
                Navigator.pop(context);
                context.push(
                  AppRoutes.doctorPatientMemoryTest,
                  extra: {
                    'patientId': patientId,
                    'doctorId': doctorId,
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildOptionButton(
              context: context,
              icon: Icons.play_arrow,
              title: 'TMT A',
              subtitle: 'Trail Making Test A',
              onTap: () {
                Navigator.pop(context);
                context.push(
                  AppRoutes.doctorPatientTmtA,
                  extra: {
                    'patientId': patientId,
                    'doctorId': doctorId,
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildOptionButton(
              context: context,
              icon: Icons.psychology,
              title: 'Stroop Test',
              subtitle: 'Teste de Stroop',
              onTap: () {
                Navigator.pop(context);
                context.push(
                  AppRoutes.doctorPatientStroopTest,
                  extra: {
                    'patientId': patientId,
                    'doctorId': doctorId,
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
