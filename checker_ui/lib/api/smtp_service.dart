import 'dart:convert';
import 'package:http/http.dart' as http;

class SMTPService {
  static const String baseUrl = "http://localhost:8000"; // Change this!

  static Future<Map<String, dynamic>> checkSMTP({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mobile-check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'host': host,
          'port': port,
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check SMTP');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> checkBatchSMTP({
  required List<Map<String, dynamic>> smtpList,
  int threads = 5,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/batch-check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'smtp_list': smtpList,
        'threads': threads,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check batch SMTP');
    }
  } catch (e) {
    throw Exception('Network error: $e');
  }
}
}