import 'package:flutter/material.dart';
import '../widgets/cards.dart';
import '../utils/navigateTo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Hola Santino!', // Aca iria una util (función) que obtenga el nombre del usuario
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

              // Shortcuts grid - Con tamaño fijo y ubicación exacta
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
                          ),
                          const SizedBox(height: 15),
                          CustomButton(
                            context: context,
                            text: 'Notificaciones',
                            icon: Icons.notifications,
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
                          ),
                          const SizedBox(height: 15),
                          CustomButton(
                            context: context,
                            text: 'Contacto',
                            icon: Icons.local_phone,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Empty space - El resto queda en blanco
              const Expanded(child: SizedBox()),
            ],
          ),

          // Bottom navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D2130),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          buildNavItem(
                            context: context,
                            icon: Icons.person_outline,
                            name: 'Perfil',
                          ),
                          buildNavItem(
                            context: context,
                            icon: Icons.calendar_today_outlined,
                            name: 'Reservas',
                          ),
                          const SizedBox(width: 60), // Space for center button
                          buildNavItem(
                            context: context,
                            icon: Icons.people_outlined,
                            name: 'Desarrolladores',
                          ),
                          buildNavItem(
                            context: context,
                            icon: Icons.settings,
                            name: 'Configuración',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Home button
          Positioned(
            bottom: 45,
            left: 0,
            right: 0,
            child: Center(
              child: InkWell(
                onTap: () => navigateTo(context, 'Inicio'),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D2130).withOpacity(1),
                        spreadRadius: 5,
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home,
                    color: const Color(0xFF1D2130),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
