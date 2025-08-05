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
  ApiService? api;
  bool isLoading = true;
  bool hasError = false;
  String? codigo;

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
        onSuccess: () async {
          await loadUserCode();
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

  Future<void> loadUserCode() async {
    try {
      final data = await api!.getCode();
      if (data == null) {
        throw Exception('Respuesta inválida del servidor');
      }
      setState(() {
        codigo = data.toString();
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      print('Error al cargar código de usuario: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
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
        backgroundColor: const Color(0xFFF5F5F5),
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
                  initializeAndLoad(); // Reintenta todo el proceso
                },
                child: const Text('Reintentar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Código de usuario',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100.0),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32.0,
                          vertical: 24.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: const Color(0xFF76E0AC), // const Color(0xFFE0E0E0)
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF76E0AC).withOpacity(0.08),
                              blurRadius: 16.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Tu código es:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              codigo ?? 'No disponible',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF76E0AC),
                                letterSpacing: 4.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          BottomNavBar(currentPage: 'code'),
        ],
      ),
    );
  }
}