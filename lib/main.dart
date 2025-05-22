import 'package:flutter/material.dart';
import './screens/login.dart';
import './screens/home.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkElite',
      theme: ThemeData(fontFamily: 'SanFrancisco', useMaterial3: true),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

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
          // Si está logueado, ahora verificamos la conexión a internet
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
