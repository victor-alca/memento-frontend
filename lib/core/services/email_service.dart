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
      // URL do Cloudflare Worker que redireciona para o deep link
      final confirmationUrl = 'https://memento-deeplink-redirect.victoralc887.workers.dev/?token=$confirmationToken';
      
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
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Confirmação de Acesso - Memento</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <h2 style="color: #2563eb;">Confirme o acesso do médico</h2>
    
    <p>Olá $patientName,</p>
    <p><strong>Dr. $doctorName</strong> está solicitando acesso aos seus dados no sistema Memento.</p>
    <p>Para confirmar este acesso, clique no botão abaixo:</p>
    
    <div style="text-align: center; margin: 30px 0;">
        <a href="$confirmationUrl" style="background-color: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">Confirmar Acesso</a>
    </div>
    
    <p style="color: #666; font-size: 14px;">Se você não conseguir clicar no botão, copie e cole este link no seu navegador:</p>
    <p style="color: #666; font-size: 14px; word-break: break-all;">$confirmationUrl</p>
    
    <hr style="border: 1px solid #eee; margin: 30px 0;">
    
    <p style="color: #666; font-size: 12px;">Este é um email automático do sistema Memento. Por favor, não responda.</p>
</body>
</html>
    ''';
  }

  /// Template HTML para email de boas-vindas
  String _buildWelcomeEmailHtml({
    required String patientName,
    required String email,
    required String temporaryPassword,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Bem-vindo ao Memento</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <h2 style="color: #2563eb;">Bem-vindo ao Memento</h2>
    
    <p>Olá $patientName,</p>
    <p>Sua conta foi criada com sucesso no sistema Memento!</p>
    
    <div style="background-color: #f8f9fa; padding: 20px; border-radius: 6px; border-left: 4px solid #2563eb; margin: 20px 0;">
        <h3 style="margin-top: 0; color: #2563eb;">Dados de Acesso</h3>
        <p><strong>Email:</strong> $email</p>
        <p><strong>Senha Temporária:</strong> $temporaryPassword</p>
    </div>
    
    <p style="color: #dc2626; font-weight: bold;">⚠️ Importante: Altere sua senha no primeiro acesso por segurança.</p>
    
    <p>Para acessar o sistema, use o aplicativo Memento instalado no seu dispositivo.</p>
    
    <hr style="border: 1px solid #eee; margin: 30px 0;">
    
    <p style="color: #666; font-size: 12px;">Este é um email automático do sistema Memento. Por favor, não responda.</p>
</body>
</html>
    ''';
  }
}