import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';
import '../utils/connectivity_service.dart';

class CodeScreen extends StatefulWidget {
  const CodeScreen({Key? key}) : super(key: key);

  @override
  _CodeScreen createState() => _CodeScreen();
}

class _CodeScreen extends State<CodeScreen> {
  final ApiService api = ApiService();
  bool isLoading = true;
  bool hasError = false;
  String? codigo;

  @override
  void initState() {
    loadUserCode();
    loadConnectionStatus();
    super.initState();
  }

  Future<void> loadUserCode() async {
    try {
      final code = await api.getToken();
      if (code == null) {
        throw Exception('Respuesta inválida del servidor');
      }
      codigo = code;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar usuario: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  } 

  Future<void> loadConnectionStatus() async {
    await checkServerConnection(
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
  }

  @override
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
                  loadConnectionStatus(); // Reintenta la carga
                },
                child: const Text('Reintentar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Screen'),
      ),
      body: Center(
        child: Text('Code Screen Content' + codigo.toString()),
      ),
      bottomNavigationBar: const BottomNavBar(currentPage: "code"),
    );
  }
}