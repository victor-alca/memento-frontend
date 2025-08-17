class Validators {
  /// Valida formato de email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  /// Valida senha com mínimo de caracteres
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < minLength) {
      return 'Senha deve ter pelo menos $minLength caracteres';
    }
    return null;
  }

  /// Valida se nome não está vazio
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }
    return null;
  }

  /// Valida CRM quando necessário
  static String? validateCRM(String? value, {bool isRequired = false}) {
    if (isRequired) {
      if (value == null || value.isEmpty) {
        return 'CRM é obrigatório para médicos';
      }
    }
    return null;
  }

  /// Valida data de nascimento
  static String? validateBirthDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Data de nascimento é obrigatória';
    }
    return null;
  }

  /// Valida confirmação de senha
  static String? validatePasswordConfirmation(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    if (value != originalPassword) {
      return 'As senhas não coincidem';
    }
    return null;
  }
}
