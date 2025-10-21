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

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.memento://reset-password',
      );
    } on AuthException catch (e) {
      throw Exception('Erro ao enviar email: ${e.message}');
    } on SocketException {
      throw Exception('Erro de conexão. Verifique sua internet.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  /// Busca dados completos do usuário após login
  Future<UserModel> getUserData(String userId) async {
    try {
      UserRole userRole = UserRole.patient;
      String? crm;
      String? userName;
      String? email;
      DateTime? birthDate;

      // Check if user is a doctor
      try {
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
        // If error, continue as patient
      }

      // Fetch user data from 'users' table (or your actual table name)
      try {
        final userResponse =
            await _client
                .from('users') // Replace with your actual table name
                .select('name, birth_date')
                .eq('id', userId)
                .single();

        userName = userResponse['name'] as String?;
        email = _client.auth.currentUser?.email;

        final birthDateStr = userResponse['birth_date'] as String?;
        if (birthDateStr != null) {
          try {
            birthDate = DateTime.parse(birthDateStr);
          } catch (e) {
            // Ignore parsing error
          }
        }
      } catch (e) {
        // If users table doesn't have the data, fallback to auth
        userName = _client.auth.currentUser?.userMetadata?['name'] as String?;
        email = _client.auth.currentUser?.email;

        final birthDateStr =
            _client.auth.currentUser?.userMetadata?['birth_date'] as String?;
        if (birthDateStr != null) {
          try {
            birthDate = DateTime.parse(birthDateStr);
          } catch (e) {
            // Ignore parsing error
          }
        }
      }

      return UserModel(
        id: userId,
        name: userName ?? 'Usuário',
        email: email ?? '',
        birthDate: birthDate,
        role: userRole,
        crm: crm,
      );
    } catch (e) {
      // Fallback: basic user
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
