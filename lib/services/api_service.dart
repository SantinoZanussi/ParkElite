import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/navigateTo.dart';

class ApiService {
  final String localNetworkIP = "181.230.199.209";
  late final String baseUrl = Platform.isAndroid 
      ? 'http://10.0.2.2:5000/api' // Para emulador Android (10.0.2.2 apunta a localhost de la máquina host)
      : 'http://$localNetworkIP:5000/api'; // Para iOS o dispositivos físicos, ajustar según necesidad
      
  final storage = FlutterSecureStorage();
  // token
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  // login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await storage.write(key: 'auth_token', value: token);
        return { 'dataUser': data['user'], 'status': 'success', 'statusCode': response.statusCode };
      } else {
        throw Exception('Error al iniciar sesión: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión en login: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // register
  Future<Map<String, dynamic>> register(
    String name,
    String last_name,
    String email, 
    String password,
    String phone_number,
    String birthday,
    String home_address,
    ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'last_name': last_name, 'email': email, 'password': password, 'phone_number': phone_number, 'birthday': birthday, 'home_address': home_address,}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await storage.write(key: 'auth_token', value: token);
        return { 'dataUser': data['user'], 'status': 'success', 'statusCode': response.statusCode };
      } else {
        throw Exception('Error al registrarse: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión en register: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // obtener datos del usuario
  Future<Map<String, dynamic>> getUser() async {
    try {
      final token = await getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/auth/getUser'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener las reservas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión en getUser: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // obtener reservas del usuario
  Future<List<dynamic>> getUserReservations() async {
    try {
      final token = await getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/reservas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener las reservas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión en getUserReservations: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // crear una reserva
  Future<Map<String, dynamic>> createReservation(
    String parkingSpotId, 
    DateTime startTime, 
    DateTime endTime
  ) async {
    try {
      final token = await getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/reservas'),
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
        throw Exception('Error al crear la reserva: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión en createReservation: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  //unlogout
  Future<void> unlogout() async {
    try {
      await storage.delete(key: 'auth_token');
    } catch (e) {
      print('Error de conexión en unlogout: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}