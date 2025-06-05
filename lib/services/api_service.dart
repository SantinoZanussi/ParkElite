import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/connectivity_service.dart';
import 'dart:async';

class ApiService {
  final String localNetworkIP = "181.230.199.209";
  final String localNetworkIPEscuela = "190.139.136.234";
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
      final internet = await ConnectivityService.hasInternet();
      if (!internet) { throw Exception('❎ No hay conexión a internet.'); }

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
    String uid,
    String email, 
    String password,
    String phone_number,
    String birthday,
    String home_address,
    ) async {
    try {
      final internet = await ConnectivityService.hasInternet();
      if (!internet) { throw Exception('❎ No hay conexión a internet.'); }

      final cleanUid = uid.replaceAll(':', '').toUpperCase();

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'last_name': last_name, 'uid_rfid': cleanUid, 'email': email, 'password': password, 'phone_number': phone_number, 'birthday': birthday, 'home_address': home_address,}),
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
      final internet = await ConnectivityService.hasInternet();
      if (!internet) { throw Exception('❎ No hay conexión a internet.'); }

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
      final internet = await ConnectivityService.hasInternet();
      if (!internet) { throw Exception('❎ No hay conexión a internet.'); }

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
  DateTime reservationDate,
  DateTime startTime, 
  DateTime endTime
) async {
  try {
    final internet = await ConnectivityService.hasInternet();
    if (!internet) { throw Exception('❎ No hay conexión a internet.'); }

    final token = await getToken();

    // Convertir a UTC
    final startUtcIso = startTime.toUtc().toIso8601String();
    final endUtcIso = endTime.toUtc().toIso8601String();
    final dateIso = reservationDate.toUtc().toIso8601String();

    final response = await http.post(
      Uri.parse('$baseUrl/reservas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'reservationDate': dateIso,
        'startTime': startUtcIso,
        'endTime': endUtcIso,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error al crear la reserva');
    }
  } catch (e) {
    print('Error de conexión en createReservation: $e');
    throw Exception('Error de conexión: $e');
  }
}

  Future<List<dynamic>> getAvailableSpots(
    DateTime date,
    DateTime startTime,
    DateTime endTime
  ) async {
    try {
      final internet = await ConnectivityService.hasInternet();
      if (!internet) { throw Exception('❎ No hay conexión a internet.'); }

      final token = await getToken();
      
      final queryParams = {
        'date': date.toIso8601String(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      };
      
      final uri = Uri.parse('$baseUrl/reservas/available-spots').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener espacios disponibles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión en getAvailableSpots: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> cancelReservation(String reservationId) async {
    try {
      final internet = await ConnectivityService.hasInternet();
      if (!internet) { throw Exception('❎ No hay conexión a internet.'); }

      final token = await getToken();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/reservas/$reservationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al cancelar la reserva');
      }
    } catch (e) {
      print('Error de conexión en cancelReservation: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<dynamic>> getOccupancyStats(DateTime date) async {
    try {
      final internet = await ConnectivityService.hasInternet();
      if (!internet) { throw Exception('❎ No hay conexión a internet.'); }

      final token = await getToken();
      
      final queryParams = {
        'date': date.toIso8601String(),
      };
      
      final uri = Uri.parse('$baseUrl/reservas/occupancy-stats').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión en getOccupancyStats: $e');
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

Future<Map<String, dynamic>> checkServerStatus() async {
  final internet = await ConnectivityService.hasInternet();
  //print('🌐 Conexión a internet: $internet');
  if (!internet) throw Exception('❎ No hay conexión a internet.');

  try {
  final url = '$baseUrl/health-check';
  //print('➡️ Llamando a: $url');
  final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 7));
  //print('⬅️ Código de respuesta: ${response.statusCode}');
  //print('⬅️ Cuerpo: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    //print('📦 Respuesta decodificada: $data');
    if (data['message'] == 'OK') {
      return {'status': 'success', 'message': data['message']};
    } else {
      throw Exception('El servidor no está disponible: ${data['message']}');
    }
  } else {
    throw Exception('Error al verificar estado del servidor: ${response.statusCode}');
  }
  } on TimeoutException catch (e) {
    //print('⏳ Timeout al verificar estado del servidor: $e');
    throw Exception('El servidor no responde. Inténtalo más tarde.');
  } catch (e) {
    //print('🔴 Error al verificar estado del servidor: $e');
    throw Exception('Error de conexión: $e');
  }

}

}