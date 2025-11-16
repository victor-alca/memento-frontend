import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/app/provider/user_provider.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/features/account/presentation/service/account_service.dart';
import 'package:test_app/features/auth/presentation/pages/login_page.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final _accountService = AccountService();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with user info - black background
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // First column: USUÁRIO and email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'usuario@email.com',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Second column: user icon
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.purple[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.purple[600],
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Configurações da Conta section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Configurações da Conta',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          title: 'Alterar dados da conta',
                          onTap: () => context.go('/account/edit'),
                          showDivider: true,
                        ),
                        _buildMenuItem(
                          icon: Icons.key_outlined,
                          title: 'Alterar senha',
                          onTap: () => context.go('/account/password'),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Outras Opções section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Outras Opções',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Sair',
                      onTap: () async {
                        await Supabase.instance.client.auth.signOut();
                        context.go('/login');
                      },
                      showDivider: false,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Delete account button - separate red container
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      title: const Text(
                        'Deletar Minha Conta',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Confirmar'),
                                content: const Text(
                                  'Deseja realmente deletar sua conta?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context); // Fecha o dialog

                                      // Mostra loading
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder:
                                            (context) => const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                      );

                                      try {
                                        await _accountService.deleteAccount();

                                        if (context.mounted) {
                                          Navigator.pop(
                                            context,
                                          ); // Remove loading

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Conta deletada com sucesso',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );

                                          // Navega para tela de login
                                          Navigator.of(
                                            context,
                                          ).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      const LoginPage(),
                                            ),
                                            (route) => false,
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          Navigator.pop(
                                            context,
                                          ); // Remove loading

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString()),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Confirmar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Voltar button at bottom
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextButton(
                onPressed: () {
                  (user?.isDoctor ?? false)
                      ? context.go(AppRoutes.doctorHome)
                      : context.go(AppRoutes.patientHome);
                },
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
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black, size: 24),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
