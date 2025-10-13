import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_app/app/theme/app_colors.dart';
import 'package:test_app/app/theme/app_spacing.dart';
import 'package:test_app/core/utils/validators.dart';
import 'package:test_app/core/utils/format_utils.dart';
import 'package:test_app/features/patients/service/patient_service.dart';
import 'package:test_app/features/auth/models/user_model.dart';
import 'package:test_app/app/provider/supabase_provider.dart';

class AddPatientPage extends StatefulWidget {
  final String doctorId;

  const AddPatientPage({
    super.key,
    required this.doctorId,
  });

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _cpfController = TextEditingController();

  late final PatientService _patientService;
  
  bool _isExistingUser = true;
  bool _isLoading = false;
  bool _emailFound = false;
  UserModel? _foundUser;

  @override
  void initState() {
    super.initState();
    _patientService = PatientService(supabase.client);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    if (!Validators.isValidEmail(_emailController.text)) {
      _showError('Digite um email válido');
      return;
    }

    setState(() {
      _isLoading = true;
      _emailFound = false;
      _foundUser = null;
    });

    try {
      final user = await _patientService.searchUserByEmail(_emailController.text);
      
      setState(() {
        if (user != null) {
          _foundUser = user;
          _emailFound = true;
          _nameController.text = user.name;
          _birthDateController.text = user.birthDate != null 
              ? FormatUtils.formatDate(user.birthDate!)
              : '';
        } else {
          _emailFound = false;
          _showError('Usuário não encontrado');
        }
      });
    } catch (e) {
      _showError('Erro ao buscar usuário: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _linkExistingPatient() async {
    if (_foundUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _patientService.linkPatientToDoctor(
        doctorId: widget.doctorId,
        patientUserId: _foundUser!.id,
        patientEmail: _foundUser!.email,
        patientName: _foundUser!.name,
      );

      if (mounted) {
        _showSuccess('Solicitação enviada! O paciente receberá um email para confirmar.');
        context.pop();
      }
    } catch (e) {
      _showError('Erro ao vincular paciente: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final birthDate = FormatUtils.parseDate(_birthDateController.text);
      if (birthDate == null) {
        _showError('Data de nascimento inválida');
        return;
      }

      await _patientService.createNewPatient(
        name: _nameController.text,
        email: _emailController.text,
        birthDate: birthDate,
        cpf: _cpfController.text.isNotEmpty ? _cpfController.text : null,
      );

      // Após criar, tentar vincular
      final user = await _patientService.searchUserByEmail(_emailController.text);
      if (user != null) {
        await _patientService.linkPatientToDoctor(
          doctorId: widget.doctorId,
          patientUserId: user.id,
          patientEmail: _emailController.text,
          patientName: _nameController.text,
        );
      }

      if (mounted) {
        _showSuccess('Paciente criado e solicitação enviada!');
        context.pop();
      }
    } catch (e) {
      _showError('Erro ao criar paciente: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _birthDateController.text = FormatUtils.formatDate(date);
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Adicionar Paciente'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Identificação do Paciente',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Tipo de usuário
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Usuário Existente'),
                        subtitle: const Text('Vincular uma conta existente via email.'),
                        value: true,
                        groupValue: _isExistingUser,
                        onChanged: (value) {
                          setState(() {
                            _isExistingUser = value ?? true;
                            _clearForm();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Nova Conta'),
                        subtitle: const Text('Criar conta com CPF como senha.'),
                        value: false,
                        groupValue: _isExistingUser,
                        onChanged: (value) {
                          setState(() {
                            _isExistingUser = value ?? true;
                            _clearForm();
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Email field
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                        enabled: !_isLoading,
                      ),
                    ),
                    if (_isExistingUser) ...[
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        onPressed: _isLoading ? null : _searchUser,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        tooltip: 'Buscar usuário',
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.validateName,
                  enabled: !_isLoading && (!_isExistingUser || !_emailFound),
                ),

                const SizedBox(height: AppSpacing.md),

                // Birth date field
                TextFormField(
                  controller: _birthDateController,
                  decoration: InputDecoration(
                    labelText: 'Data de Nascimento',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: _isLoading ? null : _selectDate,
                      icon: const Icon(Icons.calendar_today),
                    ),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Data de nascimento é obrigatória';
                    }
                    return null;
                  },
                  enabled: !_isLoading && (!_isExistingUser || !_emailFound),
                ),

                // CPF field (apenas para novos usuários)
                if (!_isExistingUser) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _cpfController,
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      border: OutlineInputBorder(),
                      helperText: 'Será usado como senha inicial',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_isLoading,
                  ),
                ],

                const Spacer(),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_getButtonText()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearForm() {
    _emailController.clear();
    _nameController.clear();
    _birthDateController.clear();
    _cpfController.clear();
    _emailFound = false;
    _foundUser = null;
  }

  void _handleSubmit() {
    if (_isExistingUser) {
      if (_emailFound && _foundUser != null) {
        _linkExistingPatient();
      } else {
        _showError('Busque um usuário válido primeiro');
      }
    } else {
      _createNewPatient();
    }
  }

  String _getButtonText() {
    if (_isExistingUser) {
      return _emailFound ? 'Vincular' : 'Buscar Usuário';
    } else {
      return 'Registrar';
    }
  }
}