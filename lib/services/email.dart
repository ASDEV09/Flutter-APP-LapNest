import 'dart:convert';
import 'package:http/http.dart' as http;
class EmailService {
  static const String _serviceId = 'service_2arjx6q';
  static const String _publicKey = 'nNjOoW7NHuYkE4PT6';
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  static const String _shippedTemplateId = 'template_n7ecnjk';

static Future<bool> sendShippedConfirmationEmail({
  required String toEmail,
  required String customerName,
  required String orderId,
  required List<Map<String, dynamic>> items,
  required double totalBill,
  required String itemsTable,
    required String status, 
    required String firstline,
    required String secline,

}) async {
  final templateParams = {
    'customer_name': customerName,
    'customer_email': toEmail,
    'status': status,
    'order_id': orderId,
    'items_table': itemsTable, 
    'total_bill': totalBill.toString(),
    'firstline':firstline,
    'secline': secline,
  };

  return await _sendEmail(_shippedTemplateId, templateParams);
}


  static Future<bool> _sendEmail(
      String templateId, Map<String, dynamic> templateParams) async {
    final payload = jsonEncode({
      'service_id': _serviceId,
      'template_id': templateId,
      'user_id': _publicKey,
      'template_params': templateParams,
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      if (response.statusCode == 200) {
        print('Email sent successfully (template: $templateId)');
        return true;
      } else {
        print('Failed to send email: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  static Future<void> sendDeliveredConfirmationEmail({required toEmail, required customerName, required String orderId, required List<Map<String, dynamic>> items, required double totalBill, required String itemsTable, required status}) async {}
}
