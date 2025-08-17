import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  Future<bool> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Credenciais inválidas');
      }

      return true;
    } on AuthException catch (e) {
      throw Exception('Erro de autenticação: ${e.message}');
    } on SocketException catch (e) {
      throw Exception('Erro de conexão. Verifique sua internet.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<bool> signUp(String email, String password, {Map<String, dynamic>? metadata}) async {
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
        throw Exception('Erro interno do servidor. Tente novamente em alguns minutos.');
      }
      throw Exception('Erro de autenticação: ${e.message}');
    } on SocketException catch (e) {
      throw Exception('Erro de conexão. Verifique sua internet.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

}
