import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static Future<bool> hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    return await InternetConnectionChecker().hasConnection;
  }
}

Future<void> checkServerConnection({
  required VoidCallback onSuccess,
  required VoidCallback onError,
}) async {
  final api = ApiService();
  try {
    final data = await api.checkServerStatus();
    //print('🟢 checkServerConnection success: $data');
    if (data['message'] == 'OK') {
      onSuccess();
    } else {
      //print('⚠️ Mensaje inesperado del servidor: ${data['message']}');
      onError();
    }
  } catch (e) {
    //print('🔴 Error en checkServerConnection: $e');
    onError();
  }
}