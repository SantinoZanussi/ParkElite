import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileContainer extends StatelessWidget {
  const ProfileContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
      ),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            PersonalInfoContentFuture(),
            SizedBox(height: 20),
            InfoCredits(),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final String nombre;

  const ProfileHeader({Key? key, required this.nombre}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3D4BF0),
            const Color(0xFF3D4BF0).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF3D4BF0),
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Información personal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const InfoItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF32809E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3D4BF0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D2130),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCredits extends StatelessWidget {
  const InfoCredits({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                "ParkElite",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Versión 1.0",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PersonalInfoContentFuture extends StatefulWidget {
  const PersonalInfoContentFuture({Key? key}) : super(key: key);

  @override
  _PersonalInfoContentFutureState createState() => _PersonalInfoContentFutureState();
}

class _PersonalInfoContentFutureState extends State<PersonalInfoContentFuture> {
  final api = ApiService();
  Map<String, dynamic>? userData;
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
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar usuario: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatFecha(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF32809E)),
          ),
        ),
      );
    }

    if (userData == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            'Error al cargar datos del usuario',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    var telefono = userData!['phone_number'].toString();

    return Column(
      children: [
        ProfileHeader(nombre: userData!['name'] ?? 'Nombre no disponible'),
        const SizedBox(height: 24),
        InfoItem(
          icon: '📍',
          label: 'Domicilio',
          value: userData!['home_address'] ?? 'N/A',
        ),
        InfoItem(
          icon: '📱',
          label: 'Celular',
          value: telefono,
        ),
        InfoItem(
          icon: '📅',
          label: 'Fecha de Nacimiento',
          value: formatFecha(userData!['birthday']),
        ),
        InfoItem(
          icon: '✉️',
          label: 'Email',
          value: userData!['email'] ?? 'N/A',
        ),
      ],
    );
  }
}