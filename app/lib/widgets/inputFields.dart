import 'package:flutter/material.dart';

  class BuildInputField extends StatelessWidget {
    final String hintText;
    final Widget icon;
    final TextInputType keyboardType;
    final bool obscureText;
    final TextEditingController controller;

    const BuildInputField({
      required this.hintText,
      required this.icon,
      required this.controller,
      this.keyboardType = TextInputType.text,
      this.obscureText = false,
      Key? key,
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
      return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), 
          boxShadow: [
            BoxShadow(
              color: Color(0xFF3e4a77).withOpacity(0.8),
              spreadRadius: 0.5,
              blurRadius: 13,
              offset: const Offset(0, 3),
            ),
          ]
        ),
        child: TextField(
          controller: controller,
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
              borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 0.05),
            ),
            suffixIcon: icon,
          ),
        ),
      );
    }
  }

  class PasswordInputField extends StatefulWidget {
    // Para login
    final TextEditingController controller;
    const PasswordInputField({Key? key, required this.controller}) : super(key: key);

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
        controller: widget.controller,
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
            color: Color(0xFF3e4a77),
          ),
        ),
      );
    }
  }

class PasswordRegisterInputField extends StatefulWidget {
  // Para registrarse
  final TextEditingController controller;
  const PasswordRegisterInputField({Key? key, required this.controller}) : super(key: key);

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
      controller: widget.controller,
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
          color: Color(0xFF3e4a77),
        ),
      ),
    );
  }
}
