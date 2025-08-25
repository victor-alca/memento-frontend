import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:test_app/app/provider/user_provider.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/features/account/presentation/service/account_service.dart';
import 'package:test_app/core/utils/validators.dart';
import 'package:test_app/core/utils/format_utils.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController birthController = TextEditingController();

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late final AccountService _accountService;

  @override
  void initState() {
    super.initState();
    _accountService = AccountService();
    // TODO: Load current user data into controllers
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    // Add logic to load current user data if available
    // This would depend on your AccountService implementation
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _accountService.updateUserData(
        name: nameController.text.trim(),
        birthDate: birthController.text,
      );

      if (emailController.text.trim().isNotEmpty) {
        await _accountService.changeEmail(emailController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,

                  children: [
                    const SizedBox(height: 32),

                    // Profile Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.account_circle,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Nome
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Nome', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: nameController,
                      validator: Validators.validateName,
                      decoration: InputDecoration(
                        hintText: 'Nome completo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Novo Email', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: emailController,
                      validator: (value) {
                        // Only validate if field is not empty (optional field)
                        if (value != null && value.trim().isNotEmpty) {
                          return Validators.validateEmail(value);
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Novo email (opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Data de Nascimento
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Data de Nascimento',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: birthController,
                      validator: Validators.validateBirthDate,
                      decoration: InputDecoration(
                        hintText: 'dd/mm/aaaa',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          birthController.text = FormatUtils.formatPickedDate(
                            pickedDate,
                          );
                        }
                      },
                      readOnly: true,
                    ),
                    const SizedBox(height: 32),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Alterar Dados',
                                  style: TextStyle(fontSize: 18),
                                ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextButton(
                onPressed: () => context.go(AppRoutes.accountSettings),
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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    birthController.dispose();
    super.dispose();
  }
}
