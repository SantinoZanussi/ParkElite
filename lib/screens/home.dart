import 'package:flutter/material.dart';
import '../widgets/cards.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/navigateTo.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  final api = ApiService();
  String? userName;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final data = await api.getUser();

      if (data == null || data['name'] == null) {
        throw Exception('Respuesta inválida del servidor');
      }

      setState(() {
        userName = data['name'];
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError || userName == null) {
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
                  loadUser(); // Reintenta la carga
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Vista normal si todo salió bien
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del usuario
              Padding(
                padding: const EdgeInsets.only(
                    top: 50.0, left: 20.0, right: 20.0),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9D423),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_outline,
                          color: Color(0xFF1D2130),
                          size: 55,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      userName!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Text(
                  'Tus atajos',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          CustomButton(
                            context: context,
                            text: 'Reservar',
                            icon: Icons.calendar_today,
                            onTap: () {
                              navigateTo(context, 'reservas');
                            },
                          ),
                          const SizedBox(height: 15),
                          CustomButton(
                            context: context,
                            text: 'Notificaciones',
                            icon: Icons.notifications,
                            onTap: () {
                              navigateTo(context, 'notificaciones');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        children: [
                          CustomButton(
                            context: context,
                            text: 'Tarifas',
                            icon: Icons.attach_money,
                            onTap: () {
                              navigateTo(context, 'tarifas');
                            },
                          ),
                          const SizedBox(height: 15),
                          CustomButton(
                            context: context,
                            text: 'Configuración',
                            icon: Icons.settings,
                            onTap: () {
                              navigateTo(context, 'config');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          BottomNavBar(currentPage: 'home'),
        ],
      ),
    );
  }
}
