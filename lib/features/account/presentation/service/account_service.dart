import 'package:supabase_flutter/supabase_flutter.dart';

class AccountService {
  final _supabase = Supabase.instance.client;

  Future<void> updateUserData({
    required String name,
    required String birthDate,
  }) async {
    final userId = _supabase.auth.currentUser;
    if (userId == null) throw Exception('Usuário não autenticado');

    await _supabase
        .from('users')
        .update({'name': name, 'birth_date': birthDate})
        .eq('id', userId.id);
  }

  Future<void> changeEmail(String newEmail) async {
    await _supabase.auth.updateUser(UserAttributes(email: newEmail));
  }

  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final session = _supabase.auth.currentSession;

    try {
      final response = await _supabase.rpc('delete_user_account');

      await _supabase.auth.signOut();

      return {'success': true, 'data': response};
    } on PostgrestException catch (e) {
      throw Exception('Erro ao deletar conta: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao deletar conta: $e');
    }
  }
}
