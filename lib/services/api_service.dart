// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final String baseUrl = 'http://tu-api-url.com/api';
  final storage = FlutterSecureStorage();

  // token
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  // login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: 'auth_token', value: data['token']);
      return data;
    } else {
      throw Exception('Error al iniciar sesión');
    }
  }

  // obtener reservas del usuario
  Future<List<dynamic>> getUserReservations() async {
    final token = await getToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/reservations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener las reservas');
    }
  }

  // crear una reserva
  Future<Map<String, dynamic>> createReservation(
    String parkingSpotId, 
    DateTime startTime, 
    DateTime endTime
  ) async {
    final token = await getToken();
    
    final response = await http.post(
      Uri.parse('$baseUrl/reservations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'parkingSpotId': parkingSpotId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al crear la reserva');
    }
  }
}