import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/app/provider/supabase_provider.dart';
import 'package:test_app/features/auth/service/auth_service.dart';
import 'package:test_app/core/utils/validators.dart';
import 'package:test_app/core/utils/format_utils.dart';

class SignPage extends StatefulWidget {
  const SignPage({super.key});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  String tipoSelecionado = 'Paciente';
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController crmController = TextEditingController();
  final TextEditingController dataNascimentoController =
      TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController =
      TextEditingController();

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(supabase.client);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (senhaController.text != confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final metadata = {
        'name': nomeController.text,
        'birth_date': FormatUtils.formatDateForDatabase(dataNascimentoController.text),
      };

      if (tipoSelecionado == 'Médico' && crmController.text.isNotEmpty) {
        metadata['crm'] = crmController.text;
      }

      // Criar usuário
      await _authService.signUp(
        emailController.text.trim(),
        senhaController.text,
        metadata: metadata,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso! Verifique seu email.'),
        ),
      );
      
      context.go(AppRoutes.login);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Image.asset(
                      'assets/logo-with-name.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Dropdown Tipo
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Tipo', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: tipoSelecionado,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Paciente',
                        child: Text('Paciente'),
                      ),
                      DropdownMenuItem(value: 'Médico', child: Text('Médico')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        tipoSelecionado = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nome
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Nome', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: nomeController,
                    validator: Validators.validateName,
                    decoration: InputDecoration(
                      hintText: 'Nome',
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
                    child: Text('Email', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: emailController,
                    validator: Validators.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
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

                  // CRM apenas para médicos
                  if (tipoSelecionado == 'Médico') ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('CRM', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: crmController,
                      inputFormatters: [CrmFormatter()],
                      validator: (value) => Validators.validateCRM(value, isRequired: tipoSelecionado == 'Médico'),
                      decoration: InputDecoration(
                        hintText: 'CRM/SP 123456',
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
                  ],

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
                    controller: dataNascimentoController,
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
                        dataNascimentoController.text = FormatUtils.formatPickedDate(pickedDate);
                      }
                    },
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),

                  // Senha
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Senha', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: senhaController,
                    validator: Validators.validatePassword,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Senha',
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

                // Confirmar Senha
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Confirmar Senha',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: confirmarSenhaController,
                  validator: (value) => Validators.validatePasswordConfirmation(value, senhaController.text),
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirmar Senha',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Registrar-se
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Registrar-se',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 8),

                // Já tem uma conta?
                TextButton(
                  onPressed: () {
                    context.go(AppRoutes.login);
                  },
                  child: const Text(
                    'Já tem uma conta?',
                    style: TextStyle(
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    crmController.dispose();
    dataNascimentoController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }
}
