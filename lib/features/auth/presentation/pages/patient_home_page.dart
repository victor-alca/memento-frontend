import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/features/auth/models/user_model.dart';
import 'package:test_app/features/auth/service/auth_service.dart';
import 'package:test_app/app/provider/supabase_provider.dart';

class PatientHomePage extends StatefulWidget {
  final UserModel user;

  const PatientHomePage({
    super.key,
    required this.user,
  });

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(supabase.client);
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Olá, ${widget.user.name}!'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Navegar para perfil
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Bem-vindo à página inicial!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),

              // Testes Disponíveis
              Expanded(
                child: GridView.count(
                  crossAxisCount: 1,
                  childAspectRatio: 4,
                  mainAxisSpacing: 16,
                  children: [
                    _buildTestCard(
                      title: 'Trail Making Test',
                      icon: Icons.extension,
                      color: Colors.orange.shade200,
                      iconColor: Colors.brown,
                      onTap: () {
                        // TODO: Navegar para Trail Making Test
                      },
                    ),
                    _buildTestCard(
                      title: 'Stroop Test',
                      icon: Icons.psychology,
                      color: Colors.green.shade200,
                      iconColor: Colors.green.shade700,
                      onTap: () {
                        // TODO: Navegar para Stroop Test
                      },
                    ),
                    _buildTestCard(
                      title: 'Teste Memória Verbal',
                      icon: Icons.memory,
                      color: Colors.pink.shade200,
                      iconColor: Colors.purple,
                      onTap: () {
                        context.go(AppRoutes.testeMemoria);
                      },
                    ),
                    _buildTestCard(
                      title: 'Histórico e Gráficos',
                      icon: Icons.analytics,
                      color: Colors.blue.shade200,
                      iconColor: Colors.blue.shade700,
                      onTap: () {
                        // TODO: Navegar para histórico
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              icon,
              size: 32,
              color: iconColor,
            ),
          ],
        ),
      ),
    );
  }
}
