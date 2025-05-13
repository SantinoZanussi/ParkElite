import 'package:flutter/material.dart';

class BuildInputField extends StatelessWidget {
  final String hintText;
  final Widget icon;
  final TextInputType keyboardType;
  final bool obscureText;

  const BuildInputField({
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child: TextField(
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 16),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
          ),
          suffixIcon: icon,
        ),
      ),
    );
  }
}

class PasswordInputField extends StatefulWidget {
  // Para login
  const PasswordInputField({Key? key}) : super(key: key);

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return BuildInputField(
      hintText: 'Contraseña',
      obscureText: _obscurePassword,
      icon: GestureDetector(
        onTap: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        child: Icon(
          _obscurePassword
              ? Icons.remove_red_eye
              : Icons.remove_red_eye_outlined,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

class PasswordRegisterInputField extends StatefulWidget {
  // Para registrarse
  const PasswordRegisterInputField({Key? key}) : super(key: key);

  @override
  State<PasswordRegisterInputField> createState() =>
      _PasswordRegisterInputFieldState();
}

class _PasswordRegisterInputFieldState
    extends State<PasswordRegisterInputField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return BuildInputField(
      hintText: 'Confirmar contraseña',
      obscureText: _obscurePassword,
      icon: GestureDetector(
        onTap: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        child: Icon(
          _obscurePassword
              ? Icons.remove_red_eye
              : Icons.remove_red_eye_outlined,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
