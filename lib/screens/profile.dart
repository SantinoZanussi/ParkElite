import 'package:flutter/material.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';
import '../utils/connectivity_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ApiService? api;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    initializeAndLoad();
  }

  Future<void> initializeAndLoad() async {
    try {
      api = ApiService();
      await api!.initBaseUrl();
      await checkServerConnection(
        apiService: api!,
        onSuccess: () {
          setState(() {
            isLoading = false;
            hasError = false;
          });
        },
        onError: () {
          setState(() {
            isLoading = false;
            hasError = true;
          });
        },
      );
    } catch (e) {
      print('Error en inicialización: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  } 

  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              const Text(
                '❌ No se pudo conectar con el servidor.\nVerificá tu conexión o intentá más tarde.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    hasError = false;
                  });
                  initializeAndLoad(); // Reintenta la carga
                },
                child: const Text('Reintentar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20), // Espacio superior
                          const ProfileContainer(),
                          const SizedBox(height: 120), // Espacio para no tapar la navbar
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          BottomNavBar(currentPage: 'perfil'),
        ],
      ),
    );
  }
}
