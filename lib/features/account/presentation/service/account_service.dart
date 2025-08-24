import 'package:supabase_flutter/supabase_flutter.dart';

class AccountService {
  final _supabase = Supabase.instance.client;

  Future<void> updateUserData({
    required String name,
    required String birthDate,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    await _supabase
        .from('profiles')
        .update({'name': name, 'birth_date': birthDate})
        .eq('id', userId);
  }

  Future<void> changeEmail(String newEmail) async {
    await _supabase.auth.updateUser(UserAttributes(email: newEmail));
  }

  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
