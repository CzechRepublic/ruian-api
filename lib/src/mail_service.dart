import 'dart:async';
import 'package:logging/logging.dart';
import 'package:mailer/mailer.dart';

class MailService {
  static final Logger _log = new Logger('MailService');

  static var _localhostOptions = new SmtpOptions()
    ..hostName = 'localhost'
    ..port = 25;

  static const String logMail = 'admin@fnx.io';

  /// Send email to [email], with [subject] and [text].
  Future send({String email = logMail, String subject = 'RUIAN', String text = 'No message'}) async {
    _log.info("Sending an email to $email with a subject '$subject' and with a text '$text'.");

    var emailTransport = new SmtpTransport(_localhostOptions);

    var envelope = new Envelope()
      ..from = 'ruian@fnx.io'
      ..recipients.add(email)
      ..subject = subject
      ..text = text;

    // Email it.
    await emailTransport
        .send(envelope)
        .then((envelope) => _log.fine('Email to $email sent!'))
        .catchError((e) => _log.warning('Error occured while sending an email to $email: $e'));

    // Until they fix bcc https://github.com/kaisellgren/mailer/issues/21
    if (email != logMail) {
      var envelope = new Envelope()
        ..from = 'ruian@fnx.io'
        ..recipients.add(logMail)
        ..subject = subject
        ..text = text;

      // Email it.
      await emailTransport
          .send(envelope)
          .catchError((e) => _log.warning('Error occured while sending an email to $logMail: $e'));
    }
  }
}
