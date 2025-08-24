import 'package:flutter/material.dart';
import 'package:test_app/app/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:test_app/features/auth/presentation/pages/login_page.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userProvider.isAuthenticated) {
          return const LoginPage();
        }

        return child;
      },
    );
  }
}
