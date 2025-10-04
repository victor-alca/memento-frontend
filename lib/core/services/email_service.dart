import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // Configurações SMTP do Gmail
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _username = 'tadssmtp@gmail.com';
  static const String _password = 'yuoa cqmj scjs ojnw'; // App password

  late final SmtpServer _smtpServer;

  EmailService() {
    _smtpServer = gmail(_username, _password);
  }

  /// Envia email de confirmação para o paciente
  Future<bool> sendPatientConfirmationEmail({
    required String patientEmail,
    required String patientName,
    required String doctorName,
    required String confirmationToken,
  }) async {
    try {
      // Deep link para abrir diretamente no app
      final confirmationUrl = 'memento://confirm?token=$confirmationToken';
      
      final message = Message()
        ..from = Address(_username, 'Sistema Memento')
        ..recipients.add(patientEmail)
        ..subject = 'Confirmação de Acesso - Dr. $doctorName'
        ..html = _buildConfirmationEmailHtml(
          patientName: patientName,
          doctorName: doctorName,
          confirmationUrl: confirmationUrl,
        );

      final sendReport = await send(message, _smtpServer);
      
      print('Email enviado com sucesso para $patientEmail');
      print('Report: ${sendReport.toString()}');
      
      return true;
    } catch (e) {
      print('Erro ao enviar email: $e');
      return false;
    }
  }

  /// Envia email de boas-vindas para novo paciente
  Future<bool> sendWelcomeEmail({
    required String patientEmail,
    required String patientName,
    required String temporaryPassword,
  }) async {
    try {
      final message = Message()
        ..from = Address(_username, 'Sistema Memento')
        ..recipients.add(patientEmail)
        ..subject = 'Bem-vindo ao Sistema Memento - Sua conta foi criada'
        ..html = _buildWelcomeEmailHtml(
          patientName: patientName,
          email: patientEmail,
          temporaryPassword: temporaryPassword,
        );

      final sendReport = await send(message, _smtpServer);
      
      print('Email de boas-vindas enviado para $patientEmail');
      print('Report: ${sendReport.toString()}');
      
      return true;
    } catch (e) {
      print('Erro ao enviar email de boas-vindas: $e');
      return false;
    }
  }

  /// Template HTML para email de confirmação
  String _buildConfirmationEmailHtml({
    required String patientName,
    required String doctorName,
    required String confirmationUrl,
  }) {
    return '''
    <h2>Confirme o acesso do médico / Confirm doctor access</h2>

    <p>Olá $patientName, bem-vindo ao <strong>Memento</strong>,</p>
    <p><strong>Dr. $doctorName</strong> está solicitando acesso aos seus dados.</p>
    <p>Para confirmar este acesso, clique no link abaixo:</p>
    <p><a href="$confirmationUrl">Confirmar acesso / Confirm access</a></p>

    <hr>

    <p>Hello $patientName, welcome to <strong>Memento</strong>,</p>
    <p><strong>Dr. $doctorName</strong> is requesting access to your data.</p>
    <p>To confirm this access, click the link below:</p>
    <p><a href="$confirmationUrl">Confirm access</a></p>
    ''';
  }

  /// Template HTML para email de boas-vindas
  String _buildWelcomeEmailHtml({
    required String patientName,
    required String email,
    required String temporaryPassword,
  }) {
    return '''
    <h2>Bem-vindo ao Memento / Welcome to Memento</h2>

    <p>Olá $patientName, bem-vindo ao <strong>Memento</strong>,</p>
    <p>Sua conta foi criada com sucesso!</p>
    <p><strong>Email:</strong> $email</p>
    <p><strong>Senha Temporária:</strong> $temporaryPassword</p>
    <p>Altere sua senha no primeiro acesso.</p>

    <hr>

    <p>Hello $patientName, welcome to <strong>Memento</strong>,</p>
    <p>Your account has been created successfully!</p>
    <p><strong>Email:</strong> $email</p>
    <p><strong>Temporary Password:</strong> $temporaryPassword</p>
    <p>Please change your password on first login.</p>
    ''';
  }
}