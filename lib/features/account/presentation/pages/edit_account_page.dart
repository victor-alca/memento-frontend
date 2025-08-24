import 'package:flutter/material.dart';
import 'package:test_app/features/account/presentation/service/account_service.dart';

class EditAccountPage extends StatelessWidget {
  const EditAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final birthController = TextEditingController();
    final service = AccountService();

    return Scaffold(
      appBar: AppBar(title: const Text('Alterar dados da conta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.purple),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Novo Email'),
            ),
            TextField(
              controller: birthController,
              decoration: const InputDecoration(
                labelText: 'Data de Nascimento',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await service.updateUserData(
                    name: nameController.text,
                    birthDate: birthController.text,
                  );
                  await service.changeEmail(emailController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dados atualizados com sucesso.'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erro: \$e')));
                }
              },
              child: const Text('Alterar'),
            ),
          ],
        ),
      ),
    );
  }
}
