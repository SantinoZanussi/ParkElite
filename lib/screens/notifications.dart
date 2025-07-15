import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Notificaciones',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "No hay notificaciones disponibles",
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xff808387),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          BottomNavBar(currentPage: 'notificaciones'),
        ],
      ),
    );
  }
}
