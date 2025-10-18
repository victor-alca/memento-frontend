import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/features/auth/models/user_model.dart';
import 'package:test_app/features/auth/service/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authSubscription;

  UserProvider(this._authService) {
    _initializeUser();
    _listenToAuthChanges();
  }

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isDoctor {
    if (_user == null) return false;
    return _user!.role == UserRole.doctor;
  }

  bool get isPatient {
    if (_user == null) return false;
    return _user!.role == UserRole.patient;
  }

  Future<void> _initializeUser() async {
    _setLoading(true);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _user = await _authService.getUserData(currentUser.id);
      }
    } catch (e) {
      _user = null;
    }

    _setLoading(false);
  }

  void _listenToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      AuthState data,
    ) async {
      if (data.event == AuthChangeEvent.signedIn &&
          data.session?.user != null) {
        try {
          _user = await _authService.getUserData(data.session!.user.id);
          notifyListeners();
        } catch (e) {
          await signOut();
        }
      } else if (data.event == AuthChangeEvent.signedOut) {
        _user = null;
        notifyListeners();
      }
    });
  }

  // Sign in
  Future<void> signIn(String email, String password) async {
    _setLoading(true);

    try {
      _user = await _authService.signIn(email, password);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }

    _setLoading(false);
  }

  // Sign up
  Future<void> signUp(
    String email,
    String password, {
    Map<String, dynamic>? metadata,
  }) async {
    _setLoading(true);

    try {
      await _authService.signUp(email, password, metadata: metadata);

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        _user = await _authService.getUserData(currentUser.id);
      }
    } catch (e) {
      _setLoading(false);
      rethrow;
    }

    _setLoading(false);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      try {
        _user = await _authService.getUserData(currentUser.id);
        notifyListeners();
      } catch (e) {
        throw Exception('Erro ao atualizar dados do usuário: $e');
      }
    }
  }

  // Update user profile metadata
  Future<void> updateProfile({
    String? name,
    DateTime? birthDate,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (birthDate != null) {
        updates['birth_date'] = birthDate.toIso8601String();
      }
      if (additionalData != null) updates.addAll(additionalData);

      if (updates.isNotEmpty) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: updates),
        );

        await refreshUser();
      }
    } catch (e) {
      throw Exception('Erro ao atualizar perfil: $e');
    }
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Erro ao enviar email de recuperação: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
