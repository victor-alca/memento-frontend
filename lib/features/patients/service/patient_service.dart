import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient_model.dart';
import '../../auth/models/user_model.dart';
import 'dart:math';

class PatientService {
  final SupabaseClient _client;

  PatientService(this._client);

  /// Busca um usuário existente pelo email
  Future<UserModel?> searchUserByEmail(String email) async {
    try {
      // Usar RPC para buscar usuário por email
      final response = await _client.rpc('search_user_by_email', params: {
        'user_email': email,
      });

      if (response == null || response.isEmpty) return null;

      final userData = response[0];
      return UserModel(
        id: userData['id'] as String,
        name: userData['name'] as String,
        email: userData['email'] as String,
        birthDate: userData['birth_date'] != null 
            ? DateTime.parse(userData['birth_date'] as String)
            : null,
        role: UserRole.patient,
      );
    } catch (e) {
      print('Erro ao buscar usuário: $e');
      return null;
    }
  }

  /// Cria um novo paciente no sistema
  Future<bool> createNewPatient({
    required String name,
    required String email,
    required DateTime birthDate,
    String? cpf,
  }) async {
    try {
      // Criar senha padrão com o CPF (sem pontos e traços)
      final password = cpf?.replaceAll(RegExp(r'[^\d]'), '') ?? '123456';

      // Criar usuário no Supabase Auth
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'birth_date': birthDate.toIso8601String().split('T')[0],
        },
      );

      if (authResponse.user == null) {
        throw Exception('Falha ao criar usuário');
      }

      return true;
    } catch (e) {
      print('Erro ao criar paciente: $e');
      throw Exception('Erro ao criar paciente: $e');
    }
  }

  /// Vincula um paciente existente ao médico
  Future<bool> linkPatientToDoctor({
    required String doctorId,
    required String patientUserId,
  }) async {
    try {
      // Primeiro, buscar o ID do médico na tabela doctors
      final doctorResponse = await _client
          .from('doctors')
          .select('id')
          .eq('user_id', doctorId)
          .single();

      final doctorTableId = doctorResponse['id'] as int;

      // Buscar o ID do paciente na tabela patients
      final patientResponse = await _client
          .from('patients')
          .select('id')
          .eq('user_id', patientUserId)
          .single();

      final patientTableId = patientResponse['id'] as int;

      // Gerar token de confirmação
      final confirmationToken = _generateConfirmationToken();
      final expiresAt = DateTime.now().add(const Duration(days: 7));

      // Criar entrada na tabela doctor_access
      await _client.from('doctor_access').insert({
        'doctor_id': doctorTableId,
        'patient_id': patientTableId,
        'confirmed': false,
        'confirmation_token': confirmationToken,
        'token_expires_at': expiresAt.toIso8601String(),
      });

      // TODO: Enviar email de confirmação aqui
      await _sendConfirmationEmail(patientUserId, confirmationToken);

      return true;
    } catch (e) {
      print('Erro ao vincular paciente: $e');
      throw Exception('Erro ao vincular paciente: $e');
    }
  }

  /// Busca pacientes vinculados ao médico
  Future<List<PatientModel>> getDoctorPatients(String doctorId) async {
    try {
      // Usar RPC para buscar pacientes do médico
      final response = await _client.rpc('get_doctor_patients', params: {
        'doctor_user_id': doctorId,
      });

      final List<PatientModel> patients = [];

      for (final item in response) {
        patients.add(PatientModel(
          id: item['patient_id'] as int,
          userId: item['user_id'] as String,
          name: item['name'] as String,
          email: item['email'] as String,
          birthDate: item['birth_date'] != null 
              ? DateTime.parse(item['birth_date'] as String)
              : null,
          isConfirmed: item['confirmed'] as bool? ?? false,
          confirmationToken: item['confirmation_token'] as String?,
          tokenExpiresAt: item['token_expires_at'] != null
              ? DateTime.parse(item['token_expires_at'] as String)
              : null,
        ));
      }

      return patients;
    } catch (e) {
      print('Erro ao buscar pacientes: $e');
      return [];
    }
  }

  /// Gera um token de confirmação aleatório
  String _generateConfirmationToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(32, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// Envia email de confirmação usando RPC do Supabase
  Future<void> _sendConfirmationEmail(String patientUserId, String token) async {
    try {
      // Obter o ID do médico atual
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('Usuário não autenticado');

      await _client.rpc('send_confirmation_email', params: {
        'patient_user_id': patientUserId,
        'doctor_user_id': currentUser.id,
        'confirmation_token': token,
      });
    } catch (e) {
      print('Erro ao enviar email de confirmação: $e');
      // Não falha a operação por causa do email
    }
  }

  /// Confirma o acesso do médico aos dados do paciente
  Future<bool> confirmPatientAccess(String token) async {
    try {
      final response = await _client.rpc('confirm_patient_access', params: {
        'token': token,
      });

      return response as bool? ?? false;
    } catch (e) {
      print('Erro ao confirmar acesso: $e');
      return false;
    }
  }
}