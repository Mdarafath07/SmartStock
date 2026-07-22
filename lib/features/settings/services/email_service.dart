import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static String get _host => dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
  static int get _port => int.tryParse(dotenv.env['SMTP_PORT'] ?? '') ?? 587;
  static String get _user => dotenv.env['SMTP_USER'] ?? '';
  static String get _pass => dotenv.env['SMTP_PASS'] ?? '';

  static bool get isConfigured => _user.isNotEmpty && _pass.isNotEmpty;

  static Future<void> sendOtp(String recipientEmail, String otp) async {
    if (!isConfigured) throw Exception('SMTP not configured');

    final smtpServer = SmtpServer(_host, port: _port, username: _user, password: _pass);

    final message = Message()
      ..from = Address(_user, 'SmartStock')
      ..recipients.add(recipientEmail)
      ..subject = 'Email Verification OTP - SmartStock'
      ..text = 'Your OTP is: $otp. It expires in 5 minutes.'
      ..html = '''
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>SmartStock Email Verification</h2>
          <p>Your OTP code is:</p>
          <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px; text-align: center; padding: 20px; background: #f5f5f5; border-radius: 8px; margin: 20px 0;">$otp</div>
          <p>This code expires in <strong>5 minutes</strong>.</p>
        </div>
      ''';

    await send(message, smtpServer);
  }

  static Future<void> sendChangeOtp(String recipientEmail, String otp) async {
    if (!isConfigured) throw Exception('SMTP not configured');

    final smtpServer = SmtpServer(_host, port: _port, username: _user, password: _pass);

    final message = Message()
      ..from = Address(_user, 'SmartStock')
      ..recipients.add(recipientEmail)
      ..subject = 'Email Change OTP - SmartStock'
      ..text = 'Your OTP is: $otp. It expires in 5 minutes.'
      ..html = '''
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>SmartStock Email Change</h2>
          <p>Your OTP code is:</p>
          <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px; text-align: center; padding: 20px; background: #f5f5f5; border-radius: 8px; margin: 20px 0;">$otp</div>
          <p>This code expires in <strong>5 minutes</strong>.</p>
        </div>
      ''';

    await send(message, smtpServer);
  }
}
