// lib/core/email/email_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../database/business_settings.dart';
import '../../database/daos/settings_dao.dart';

class EmailServiceException implements Exception {
  final String message;
  final bool retryable;
  final int? statusCode;

  const EmailServiceException({
    required this.message,
    required this.retryable,
    this.statusCode,
  });

  @override
  String toString() {
    return message;
  }
}

class EmailService {
  static const String _baseUrl =
      'https://creator-yard-email-api.dawn-feather-6cd6.workers.dev';

  static Future<void> sendSaleEmail({
    required SettingsDao settingsDao,
    required String installationId,
    required int jobId,
    required String recipient,
    required String subject,
    required String body,
  }) async {
    final credential = await settingsDao.getSetting(
      BusinessSettings.emailApiCredential,
    );
    final normalizedCredential = credential?.trim() ?? '';

    if (normalizedCredential.isEmpty) {
      throw const EmailServiceException(
        message: 'Installation credential is not configured.',
        retryable: false,
      );
    }

    if (installationId.trim().isEmpty) {
      throw const EmailServiceException(
        message: 'Installation ID is required.',
        retryable: false,
      );
    }

    if (jobId <= 0) {
      throw const EmailServiceException(
        message: 'Email job ID must be a positive integer.',
        retryable: false,
      );
    }

    final http.Response response;

    try {
      response = await http.post(
        Uri.parse('$_baseUrl/v1/email/sale'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $normalizedCredential',
        },
        body: jsonEncode({
          'installationId': installationId.trim(),
          'jobId': jobId,
          'recipient': recipient.trim(),
          'subject': subject,
          'body': body,
        }),
      );
    } catch (e) {
      throw const EmailServiceException(
        message:
            'Could not reach the email service. '
            'Please retry the email job.',
        retryable: true,
      );
    }

    Map<String, dynamic> responseData;

    try {
      responseData = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      final retryable =
          response.statusCode >= 500 ||
          response.statusCode == 408 ||
          response.statusCode == 429;

      throw EmailServiceException(
        message: 'Email API returned an invalid response.',
        retryable: retryable,
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error =
          responseData['error']?.toString() ?? 'Email API request failed.';

      final retryable =
          responseData['retryable'] == true ||
          response.statusCode == 408 ||
          response.statusCode == 409 ||
          response.statusCode == 429 ||
          response.statusCode >= 500;

      throw EmailServiceException(
        message: error,
        retryable: retryable,
        statusCode: response.statusCode,
      );
    }

    if (responseData['success'] != true) {
      final error =
          responseData['error']?.toString() ??
          'Email API failed to send the email.';

      throw EmailServiceException(
        message: error,
        retryable: responseData['retryable'] == true,
      );
    }
  }

  static Future<void> sendCustomerReceipt({
    required SettingsDao settingsDao,
    required String installationId,
    required int jobId,
    required String recipient,
    required String subject,
    required String body,
    required String filename,
    required String contentBase64,
  }) async {
    final credential = await settingsDao.getSetting(
      BusinessSettings.emailApiCredential,
    );

    final normalizedCredential = credential?.trim() ?? '';

    if (normalizedCredential.isEmpty) {
      throw const EmailServiceException(
        message: 'Installation credential is not configured.',
        retryable: false,
      );
    }

    if (installationId.trim().isEmpty) {
      throw const EmailServiceException(
        message: 'Installation ID is required.',
        retryable: false,
      );
    }

    if (jobId <= 0) {
      throw const EmailServiceException(
        message: 'Receipt job ID must be a positive integer.',
        retryable: false,
      );
    }

    if (recipient.trim().isEmpty) {
      throw const EmailServiceException(
        message: 'Customer email address is required.',
        retryable: false,
      );
    }

    if (filename.trim().isEmpty) {
      throw const EmailServiceException(
        message: 'Receipt filename is required.',
        retryable: false,
      );
    }

    if (contentBase64.trim().isEmpty) {
      throw const EmailServiceException(
        message: 'Receipt PDF content is required.',
        retryable: false,
      );
    }

    final http.Response response;

    try {
      response = await http.post(
        Uri.parse('$_baseUrl/v1/email/customer-receipt'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $normalizedCredential',
        },
        body: jsonEncode({
          'installationId': installationId.trim(),
          'jobId': jobId,
          'recipient': recipient.trim(),
          'subject': subject,
          'body': body,
          'attachment': {
            'filename': filename.trim(),
            'content': contentBase64.trim(),
          },
        }),
      );
    } catch (e) {
      print('CUSTOMER RECEIPT DEBUG: HTTP request exception=$e');

      throw const EmailServiceException(
        message:
            'Could not reach the email service. '
            'Please retry the customer receipt email.',
        retryable: true,
      );
    }

    print('CUSTOMER RECEIPT DEBUG: status=${response.statusCode}');
    print('CUSTOMER RECEIPT DEBUG: response=${response.body}');

    Map<String, dynamic> responseData;

    try {
      responseData = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      final retryable =
          response.statusCode >= 500 ||
          response.statusCode == 408 ||
          response.statusCode == 429;

      throw EmailServiceException(
        message: 'Email API returned an invalid response.',
        retryable: retryable,
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error =
          responseData['error']?.toString() ?? 'Customer receipt email failed.';

      print('CUSTOMER RECEIPT DEBUG: API error=$error');
      print('CUSTOMER RECEIPT DEBUG: retryable=${responseData['retryable']}');

      final retryable =
          responseData['retryable'] == true ||
          response.statusCode == 408 ||
          response.statusCode == 409 ||
          response.statusCode == 429 ||
          response.statusCode >= 500;

      throw EmailServiceException(
        message: error,
        retryable: retryable,
        statusCode: response.statusCode,
      );
    }

    if (responseData['success'] != true) {
      final error =
          responseData['error']?.toString() ??
          'Customer receipt email failed to send.';

      throw EmailServiceException(
        message: error,
        retryable: responseData['retryable'] == true,
      );
    }
  }

  static Future<void> sendReportEmail({
    required SettingsDao settingsDao,
    required String installationId,
    required int reportId,
    required String recipient,
    required String subject,
    required String body,
    required String pdfBase64,
    required String filename,
  }) async {
    final credential = await settingsDao.getSetting(
      BusinessSettings.emailApiCredential,
    );
    final normalizedCredential = credential?.trim() ?? '';

    if (normalizedCredential.isEmpty) {
      throw const EmailServiceException(
        message: 'Installation credential is not configured.',
        retryable: false,
      );
    }

    if (installationId.trim().isEmpty) {
      throw const EmailServiceException(
        message: 'Installation ID is required.',
        retryable: false,
      );
    }

    if (reportId <= 0) {
      throw const EmailServiceException(
        message: 'Report ID must be a positive integer.',
        retryable: false,
      );
    }

    if (recipient.trim().isEmpty) {
      throw const EmailServiceException(
        message: 'Report recipient email address is required.',
        retryable: false,
      );
    }

    if (pdfBase64.trim().isEmpty) {
      throw const EmailServiceException(
        message: 'Report PDF content is required.',
        retryable: false,
      );
    }

    if (filename.trim().isEmpty) {
      throw const EmailServiceException(
        message: 'Report filename is required.',
        retryable: false,
      );
    }

    final http.Response response;

    try {
      response = await http.post(
        Uri.parse('$_baseUrl/v1/email/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $normalizedCredential',
        },
        body: jsonEncode({
          'installationId': installationId.trim(),
          'reportId': reportId.toString(),
          'recipient': recipient.trim(),
          'subject': subject,
          'body': body,
          'pdfBase64': pdfBase64.trim(),
          'filename': filename.trim(),
        }),
      );
    } catch (_) {
      throw const EmailServiceException(
        message:
            'Could not reach the email service. '
            'Please retry the report email.',
        retryable: true,
      );
    }

    Map<String, dynamic> responseData;

    try {
      responseData = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      final retryable =
          response.statusCode >= 500 ||
          response.statusCode == 408 ||
          response.statusCode == 429;

      throw EmailServiceException(
        message: 'Email API returned an invalid response.',
        retryable: retryable,
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = responseData['error']?.toString() ?? 'Report email failed.';

      final retryable =
          responseData['retryable'] == true ||
          response.statusCode == 408 ||
          response.statusCode == 409 ||
          response.statusCode == 429 ||
          response.statusCode >= 500;

      throw EmailServiceException(
        message: error,
        retryable: retryable,
        statusCode: response.statusCode,
      );
    }

    if (responseData['success'] != true) {
      final error =
          responseData['error']?.toString() ?? 'Report email failed to send.';

      throw EmailServiceException(
        message: error,
        retryable: responseData['retryable'] == true,
      );
    }
  }
}
