import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gizmo_jwt_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gizmo_jwt_token', token);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
    );
    final data = jsonDecode(response.body);
    if (data['accessToken'] != null) {
      await saveToken(data['accessToken']);
    }
    return data;
  }

  Future<Map<String, dynamic>> registerProfile({
    required String displayName,
    required String publicKey,
    String? avatarUrl,
    String? about,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: await _headers(),
      body: jsonEncode({
        'displayName': displayName,
        'publicKey': publicKey,
        'avatarUrl': avatarUrl,
        'about': about,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> resolveByPhone(String phone) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/resolve?phone=${Uri.encodeComponent(phone)}'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getPublicKey(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/public-key'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getMessageHistory(String contactId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/history/$contactId'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }
}
