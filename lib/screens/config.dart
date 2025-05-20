import 'package:flutter/material.dart';
import '../widgets/cards.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/navigateTo.dart';
import '../services/api_service.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(
                  left: 20.0, // 20
                  right: 20.0, // 20
                  top: 60.0, // 20
                  bottom: 20.0, // 15
                ),
                child: Text(
                  'Configuración',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),

              // Shortcuts grid - Con tamaño fijo y ubicación exacta
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          ConfigCustomButton(
                            context: context,
                            text: 'Cerrar sesión',
                            icon: Icons.gpp_bad_sharp,
                            onTap: () async {
                              try {
                              final api = ApiService();
                              await api.unlogout();
                              navigateTo(context, 'backLogin');             
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error al cerrar sesión')),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          ConfigCustomButton(
                            context: context,
                            text: 'WhatsApp',
                            icon: Icons.whatshot,
                            onTap: () {
                              //navigateTo(context, 'notificaciones');
                            },
                          ),
                          const SizedBox(height: 20),
                          ConfigCustomButton(
                            context: context,
                            text: 'Desarrolladores',
                            icon: Icons.code,
                            onTap: () async {
                              try {
                              //final api = ApiService();
                              //await api.getUser();
                              //navigateTo(context, 'backLogin');             
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error al asdasd')),
                                );
                              }
                              //navigateTo(context, 'tarifas');
                            },
                          ),
                          const SizedBox(height: 20),
                          ConfigCustomButton(
                            context: context,
                            text: '???',
                            icon: Icons.copyright,
                            onTap: () {
                              //navigateTo(context, 'contacto');
                            },
                          ),
                        ],
                      ),
                    ),
                    /*
                    */
                  ],
                ),
              ),

              // Empty space - El resto queda en blanco
              const Expanded(child: SizedBox()),
            ],
          ),

          BottomNavBar(currentPage: 'config'),
        ],
      ),
    );
  }
}
