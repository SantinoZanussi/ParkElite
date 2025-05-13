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
                        GestureDetector(
                          onTap: () => navigateTo(context, 'perfil'),
                          child: Icon(
                            Icons.person_outline,
                            color:
                                currentPage == 'perfil'
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                            size: 24,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => navigateTo(context, 'reservas'),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            color:
                                currentPage == 'reservas'
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 60), // Space for center button
                        GestureDetector(
                          onTap: () => navigateTo(context, 'desarrolladores'),
                          child: Icon(
                            Icons.people_outlined,
                            color:
                                currentPage == 'desarrolladores'
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                            size: 24,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => navigateTo(context, 'config'),
                          child: Icon(
                            Icons.settings,
                            color:
                                currentPage == 'config'
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
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

        // Home button
        Positioned(
          bottom: 45,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                navigateTo(context, 'home');
              },
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
                  color: Color(0xFF1D2130),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
