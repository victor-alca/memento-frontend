import 'package:flutter/services.dart';

class FormatUtils {
  /// Converte data do formato DD/MM/YYYY para YYYY-MM-DD
  static String formatDateForDatabase(String dateString) {
    final parts = dateString.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
    }
    return dateString;
  }

  /// Converte data do formato YYYY-MM-DD para DD/MM/YYYY
  static String formatDateForDisplay(String dateString) {
    final parts = dateString.split('-');
    if (parts.length == 3) {
      return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
    }
    return dateString;
  }

  /// Formata data selecionada no DatePicker
  static String formatPickedDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class CrmFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.toUpperCase();
    
    // Remove tudo que não seja letra ou número
    text = text.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    String formatted = '';
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Começar sempre com CRM
    if (!text.startsWith('CRM')) {
      if (text.isNotEmpty) {
        text = 'CRM$text';
      }
    }
    
    if (text.length <= 3) {
      // Apenas "CRM"
      formatted = text;
    } else if (text.length <= 5) {
      // "CRM" + até 2 letras do estado (ex: "CRMSP")
      formatted = '${text.substring(0, 3)}/${text.substring(3)}';
    } else {
      // "CRM" + estado + números
      String crm = text.substring(0, 3); // CRM
      String remaining = text.substring(3);
      
      // Separar letras (estado) e números
      String estado = '';
      String numeros = '';
      
      for (int i = 0; i < remaining.length; i++) {
        if (RegExp(r'[A-Z]').hasMatch(remaining[i]) && estado.length < 2) {
          estado += remaining[i];
        } else if (RegExp(r'[0-9]').hasMatch(remaining[i]) && numeros.length < 6) {
          numeros += remaining[i];
        }
      }
      
      // Garantir que temos pelo menos 2 letras para o estado
      if (estado.length < 2 && numeros.isNotEmpty) {
        // Se começou a digitar números mas não tem estado completo,
        // não formatar ainda
        formatted = '$crm/$estado$numeros';
      } else {
        formatted = numeros.isEmpty ? '$crm/$estado' : '$crm/$estado $numeros';
      }
    }
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
