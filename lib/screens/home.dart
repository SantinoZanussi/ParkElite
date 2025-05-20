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

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final data = await api.getUser();
      setState(() {
        userName = data['name'];
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar usuario: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User header section
              Padding(
                padding: const EdgeInsets.only(
                  top: 50.0,
                  left: 20.0,
                  right: 20.0,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9D423),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Center(
                          child: Container(
                            child: const Icon(
                              Icons.person_outline,
                              color: const Color(0xFF1D2130),
                              size: 55,
                            ),
                            /**
                             * 
                            margin: const EdgeInsets.only(top: 10),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(55),
                              ),
                            ),
                             */
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Shortcuts title
              const Padding(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 20.0,
                  bottom: 15.0,
                ),
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

              //El resto queda en blanco
              const Expanded(child: SizedBox()),
            ],
          ),

          BottomNavBar(currentPage: 'home'),
        ],
      ),
    );
  }
}
