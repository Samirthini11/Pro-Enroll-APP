import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the phone dialer, WhatsApp, or SMS for E.164 numbers (+91…).
class ContactLauncher {
  ContactLauncher._();

  static String? _digits(String? phoneE164) {
    if (phoneE164 == null) return null;
    final trimmed = phoneE164.trim();
    if (trimmed.isEmpty) return null;
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : digits;
  }

  static Future<void> call(BuildContext context, String? phoneE164) async {
    final digits = _digits(phoneE164);
    if (digits == null) {
      _snack(context, 'Phone number not available yet');
      return;
    }
    final uri = Uri(scheme: 'tel', path: '+$digits');
    await _open(context, uri, 'Could not open phone dialer');
  }

  static Future<void> chat(BuildContext context, String? phoneE164, {String? message}) async {
    final digits = _digits(phoneE164);
    if (digits == null) {
      _snack(context, 'Phone number not available yet');
      return;
    }

    final waUri = Uri.parse(
      'https://wa.me/$digits${message != null && message.isNotEmpty ? '?text=${Uri.encodeComponent(message)}' : ''}',
    );
    if (await canLaunchUrl(waUri)) {
      await _open(context, waUri, 'Could not open WhatsApp');
      return;
    }

    final smsUri = Uri(
      scheme: 'sms',
      path: '+$digits',
      queryParameters: message != null && message.isNotEmpty ? {'body': message} : null,
    );
    await _open(context, smsUri, 'Could not open chat');
  }

  static Future<void> _open(BuildContext context, Uri uri, String failMessage) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _snack(context, failMessage);
    } catch (_) {
      if (context.mounted) _snack(context, failMessage);
    }
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
