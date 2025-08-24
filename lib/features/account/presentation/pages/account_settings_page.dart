import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/app/provider/user_provider.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações da Conta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Configurações da Conta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.go('/account/edit'),
              child: const Text('Alterar dados da conta'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/account/password'),
              child: const Text('Alterar senha'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                // Fazer logout usando Supabase
                await Supabase.instance.client.auth.signOut();
                context.go('/login');
              },
              child: const Text('Sair'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
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
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Deleção de conta requer função personalizada no Supabase.',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                );
              },
              child: const Text('Deletar Minha Conta'),
            ),
          ],
        ),
      ),
    );
  }
}
