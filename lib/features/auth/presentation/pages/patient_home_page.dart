import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:test_app/app/provider/user_provider.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/core/widgets/start_dialog.dart';
import 'package:test_app/features/auth/service/auth_service.dart';
import 'package:test_app/app/provider/supabase_provider.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

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
    final success = await _authService.signOut();
    if (mounted) {
      if (success) {
        context.go(AppRoutes.login);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao sair')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Olá, ${user?.name}!'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed:
                () => context.go(
                  '${AppRoutes.accountSettings}?from=patient-home',
                ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
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
                style: TextStyle(fontSize: 18, color: Colors.grey),
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
                        showModernStartDialog(
                          context,
                          titulo: "Instruções do Trail Making Test",
                          textoExplicativo:
                              "Ligue os itens na ordem correta o mais rápido possível. \n\n"
                              "Siga a sequência sem pular nenhum elemento. \n"
                              "TMT-A - conecte os números em ordem crescente (1 -> 2 -> 3 -> ...). \n"
                              "TMT-B - alterne entre números e letras (1 -> A -> 2 -> B -> 3 -> ...). \n"
                              "O teste começará quando você apertar INICIAR.",
                          onStart: () {
                            context.go(AppRoutes.tmtA);
                          },
                        );
                      },
                    ),
                    _buildTestCard(
                      title: 'Stroop Test',
                      icon: Icons.psychology,
                      color: Colors.green.shade200,
                      iconColor: Colors.green.shade700,
                      onTap: () {
                        showModernStartDialog(
                          context,
                          titulo: "Instruções do Stroop Teste",
                          textoExplicativo:
                              "Você verá nomes de cores escritos na tela, mas a cor da palavra pode ser diferente do seu significado. \n\n"
                              "Ignore o que está escrito. \n"
                              "Fale o mais rápido possível apenas a cor em que a palavra está escrita. \n"
                              "O teste começará quando você apertar INICIAR.",
                          onStart: () {
                            context.go(AppRoutes.stroopTest);
                          },
                        );
                      },
                    ),
                    _buildTestCard(
                      title: 'Teste Memória Verbal',
                      icon: Icons.memory,
                      color: Colors.pink.shade200,
                      iconColor: Colors.purple,
                      onTap: () {
                        showModernStartDialog(
                          context,
                          titulo: "Instruções do Teste de Memória Verbal",
                          textoExplicativo:
                              "Você verá palavras na tela, uma por vez. \n\n"
                              "Clique em NOVO quando for a primeira vez que vê a palabra. \n"
                              "Clique em REPETIDO quando ela já tiver aparecido antes. \n"
                              "O teste começará quando você apertar INICIAR.",
                          onStart: () {
                            context.go(AppRoutes.testeMemoria);
                          },
                        );
                      },
                    ),
                    _buildTestCard(
                      title: 'Histórico e Gráficos',
                      icon: Icons.analytics,
                      color: Colors.blue.shade200,
                      iconColor: Colors.blue.shade700,
                      onTap: () {
                        context.push(AppRoutes.lineChart);
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
            Icon(icon, size: 32, color: iconColor),
          ],
        ),
      ),
    );
  }
}
