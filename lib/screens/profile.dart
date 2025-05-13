import 'package:flutter/material.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
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
                          const SizedBox(
                            height: 120,
                          ), // Espacio para no tapar la navbar
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
