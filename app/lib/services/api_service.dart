import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/connectivity_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:async';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  final String localNetworkIP = "192.168.0.24";
  final String localNetworkIPEscuela = "192.168.2.165";
  final String serverNetworkDomain = "parkelite.onrender.com";
  late final String baseUrl;
  bool _isInitialized = false;

  Future<void> initBaseUrl() async {
    if (_isInitialized) return; // Evitar múltiples inicializaciones
    
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final isEmulator = !androidInfo.isPhysicalDevice;

      baseUrl = isEmulator
          ? 'http://10.0.2.2:3000/api' // Emulador Android
          : 'https://$serverNetworkDomain/api'; // Dispositivo físico Android
    } else {
      baseUrl = 'https://$serverNetworkDomain/api'; // iOS físico o emulador
    }
    
    _isInitialized = true;
  }

  // Verificar si está inicializado antes de usar baseUrl
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('ApiService no ha sido inicializado. Llama a initBaseUrl() primero.');
    }
  }

  final storage = FlutterSecureStorage();
  
  // token
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  // login
  Future<Map<String, dynamic>> login(String email, String password) async {
    _ensureInitialized();
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
    String email, 
    String password,
    String phone_number,
    String birthday,
    String home_address,
    ) async {
    _ensureInitialized();
    try {
      final internet = await ConnectivityService.hasInternet();
      if (!internet) { throw Exception('❎ No hay conexión a internet.'); }

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
    _ensureInitialized();
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
    _ensureInitialized();
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
    _ensureInitialized();
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
    _ensureInitialized();
    try {
      final internet = await ConnectivityService.hasInternet();
      if (!internet) { throw Exception('❎ No hay conexión a internet.'); }

      final token = await getToken();
      
      final queryParams = {
        'date': date.toUtc().toIso8601String(),
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
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
    _ensureInitialized();
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
    _ensureInitialized();
    try {
      final internet = await ConnectivityService.hasInternet();
      if (!internet) { throw Exception('❎ No hay conexión a internet.'); }

      final token = await getToken();
      
      final queryParams = {
        'date': date.toUtc().toIso8601String(),
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
    _ensureInitialized();
    final internet = await ConnectivityService.hasInternet();
    print('🌐 Conexión a internet: $internet');
    if (!internet) throw Exception('❎ No hay conexión a internet.');

    try {
      final url = '$baseUrl/health-check';
      print('➡️ Llamando a: $url');
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 7));
      print('⬅️ Código de respuesta: ${response.statusCode}');
      print('⬅️ Cuerpo: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 Respuesta decodificada: $data');
        if (data['message'] == 'OK') {
          return {'status': 'success', 'message': data['message']};
        } else {
          throw Exception('El servidor no está disponible: ${data['message']}');
        }
      } else {
        throw Exception('Error al verificar estado del servidor: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('⏳ Timeout al verificar estado del servidor: $e');
      throw Exception('El servidor no responde. Inténtalo más tarde.');
    } catch (e) {
      print('🔴 Error al verificar estado del servidor: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<int> getCode() async {
    _ensureInitialized();
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
        final data = jsonDecode(response.body);
        return data['code'];
      } else {
        throw Exception('Error al obtener las reservas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión en getCode: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}