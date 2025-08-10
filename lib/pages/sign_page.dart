import 'package:flutter/material.dart';
import 'login_page.dart';

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
  final TextEditingController dataNascimentoController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Paciente', child: Text('Paciente')),
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
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    hintText: 'Nome',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Email', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),

                // CRM (só aparece se for médico)
                if (tipoSelecionado == 'Médico') ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('CRM', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: crmController,
                    decoration: InputDecoration(
                      hintText: 'CRM',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Data de Nascimento
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Data de Nascimento', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: dataNascimentoController,
                  decoration: InputDecoration(
                    hintText: 'dd/mm/aaaa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      dataNascimentoController.text = 
                          '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
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
                TextField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Senha',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirmar Senha
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Confirmar Senha', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: confirmarSenhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirmar Senha',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 24),

                // Registrar-se
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Aqui você pode adicionar a lógica de cadastro
                      print('Cadastro realizado!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Registrar-se', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 8),

                // Já tem uma conta?
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    'Já tem uma conta?',
                    style: TextStyle(color: Colors.black, decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 24),
              ],
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