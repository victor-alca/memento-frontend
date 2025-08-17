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
