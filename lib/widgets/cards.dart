import 'package:flutter/material.dart';
import '../utils/navigateTo.dart';

class CustomButton extends StatelessWidget {
  final BuildContext context;
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const CustomButton({
    required this.context,
    required this.text,
    required this.icon,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1D2130), size: 30),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ConfigCustomButton extends StatelessWidget {
  final BuildContext context;
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const ConfigCustomButton({
    required this.context,
    required this.text,
    required this.icon,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9B59B6).withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF9B59B6), size: 30),
              const SizedBox(width: 20),
              Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class buildNavItem extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String name;

  const buildNavItem({
    required this.context,
    required this.icon,
    required this.name,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => navigateTo(context, name),
      child: SizedBox(
        width: 60,
        child: Icon(icon, color: const Color(0xFF888888), size: 24),
      ),
    );
  }
}
