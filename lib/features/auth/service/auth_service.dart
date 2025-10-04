import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  Future<UserModel> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Credenciais inválidas');
      }

      // Buscar dados completos do usuário
      final userData = await getUserData(response.user!.id);

      return userData;
    } on AuthException catch (e) {
      throw Exception('Erro de autenticação: ${e.message}');
    } on SocketException {
      throw Exception('Erro de conexão. Verifique sua internet.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<bool> signUp(
    String email,
    String password, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      if (response.user == null) {
        throw Exception('Falha ao criar conta');
      }

      return true;
    } on AuthException catch (e) {
      if (e.statusCode == '500') {
        throw Exception(
          'Erro interno do servidor. Tente novamente em alguns minutos.',
        );
      }
      throw Exception('Erro de autenticação: ${e.message}');
    } on SocketException {
      throw Exception('Erro de conexão. Verifique sua internet.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<bool> signOut() async {
    try {
      await _client.auth.signOut();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Busca dados completos do usuário após login
  Future<UserModel> getUserData(String userId) async {
    try {
      UserRole userRole = UserRole.patient;
      String? crm;
      String? userName;
      DateTime? birthDate;

      try {
        // Verificar se é médico
        final doctorResponse =
            await _client
                .from('doctors')
                .select('crm')
                .eq('user_id', userId)
                .maybeSingle();

        if (doctorResponse != null) {
          userRole = UserRole.doctor;
          crm = doctorResponse['crm'] as String?;
        }
      } catch (e) {
        // Se erro, continua como paciente
      }

      // Usar dados do auth.user
      userName =
          _client.auth.currentUser?.userMetadata?['name'] as String? ??
          'Usuário';
      final email = _client.auth.currentUser?.email ?? '';

      // Obter birth_date do metadata
      final birthDateStr =
          _client.auth.currentUser?.userMetadata?['birth_date'] as String?;
      if (birthDateStr != null) {
        try {
          birthDate = DateTime.parse(birthDateStr);
        } catch (e) {
          // Ignore parsing error
        }
      }

      return UserModel(
        id: userId,
        name: userName,
        email: email,
        birthDate: birthDate,
        role: userRole,
        crm: crm,
      );
    } catch (e) {
      // Fallback: usuário básico
      return UserModel(
        id: userId,
        name:
            _client.auth.currentUser?.userMetadata?['name'] as String? ??
            'Usuário',
        email: _client.auth.currentUser?.email ?? '',
        birthDate: null,
        role: UserRole.patient,
        crm: null,
        createdAt: DateTime.now(),
      );
    }
  }
}
