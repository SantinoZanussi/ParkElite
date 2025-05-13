import 'package:flutter/material.dart';

class ProfileContainer extends StatelessWidget {
  const ProfileContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: const [
            ProfileHeader(),
            SectionHeader(),
            PersonalInfoContent(),
            InfoCredits(),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              // foto
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    spreadRadius: 0,
                    blurRadius: 14,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF32809E),
                  size: 42,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 18),
        const Text(
          'Francisco Aiello',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D2130),
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Información personal',
              style: TextStyle(fontSize: 22, color: Color(0xFF1D2130)),
            ),
          ],
        ),
      ),
    );
  }
}

class PersonalInfoContent extends StatelessWidget {
  const PersonalInfoContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Column(
        children: const [
          InfoItem(icon: '📍', label: 'Domicilio', value: 'Av. dawdawd 325'),
          InfoItem(icon: '📱', label: 'Celular', value: '21342352345'),
          InfoItem(
            icon: '📅',
            label: 'Fecha de Nacimiento',
            value: '19/04/9111',
          ),
          InfoItem(icon: '✉️', label: 'Email', value: 'wadwadwad@gmail.com'),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF1D2130),
                  spreadRadius: 0,
                  blurRadius: 7,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0, top: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "ParkElite",
                  style: TextStyle(fontSize: 18, color: Color(0xFF999999)),
                ),
                SizedBox(height: 1),
                Text(
                  "Versión 1.0",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
