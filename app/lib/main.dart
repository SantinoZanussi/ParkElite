import 'package:flutter/material.dart';
import './screens/login.dart';
import './screens/home.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import './services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  await api.initBaseUrl();
  runApp(MyApp(apiService: api));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  const MyApp({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkElite',
      theme: ThemeData(fontFamily: 'SanFrancisco', useMaterial3: true),
      home: AuthWrapper(apiService: apiService),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final ApiService apiService;
  const AuthWrapper({Key? key, required this.apiService}) : super(key: key);

  Future<bool> isLoggedIn() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    return token != null;
  }

  Future<bool> hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error al verificar sesión: ${snapshot.error}")),
          );
        }

        if (snapshot.data == true) {
          // si está logueado, verificamos la conexión a internet
          return FutureBuilder<bool>(
            future: hasInternet(),
            builder: (context, internetSnapshot) {
              if (internetSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (internetSnapshot.data == false) {
                return const Scaffold(
                  backgroundColor: const Color(0xFFF5F5F5),
                  body: Center(
                    child: Text(
                      '❎ No hay conexión a internet.\nConéctate para continuar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                );
              }

              return const HomeScreen();
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
