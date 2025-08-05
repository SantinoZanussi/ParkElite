import 'package:flutter/material.dart';
import '../utils/navigateTo.dart';

class BottomNavBar extends StatelessWidget {
  final String currentPage;

  const BottomNavBar({Key? key, required this.currentPage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
                  color: Color(0xFF2D3552),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 30,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () => navigateTo(context, 'perfil'),
                          child: Icon(
                            Icons.person_outline,
                            color:
                                currentPage == 'perfil'
                                    ? const Color(0xFF3D4BF0)
                                    : const Color(0xFF3D4BF0).withOpacity(0.5),
                            size: 29,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => navigateTo(context, 'reservas'),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            color:
                                currentPage == 'reservas'
                                    ? const Color(0xFF5EA4f5)
                                    : const Color(0xFF5EA4f5).withOpacity(0.5),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 60),
                        GestureDetector(
                          onTap: () => navigateTo(context, 'code'),
                          child: Icon(
                            Icons.pin,
                            color:
                                currentPage == 'code'
                                    ? const Color(0xFF76E0AC)
                                    : const Color(0xFF76E0AC).withOpacity(0.5),
                            size: 24,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => navigateTo(context, 'config'),
                          child: Icon(
                            Icons.settings,
                            color:
                                currentPage == 'config'
                                    ? const Color(0xFFCF75F3)
                                    : const Color(0xFFCF75F3).withOpacity(0.5),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Floating Home button with enhanced shadow effect
        Positioned(
          bottom: 50, // Ajustado para que flote más arriba
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                navigateTo(context, 'home');
              },
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 0,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.home,
                  color: currentPage == 'home' 
                      ? const Color(0xFF1D2130) 
                      : const Color(0xFF1D2130).withOpacity(0.7),
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}