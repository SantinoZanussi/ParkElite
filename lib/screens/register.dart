import 'package:flutter/material.dart';
import '../utils/navigateTo.dart';
import '../widgets/inputFields.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  margin: const EdgeInsets.only(bottom: 30),
                  child: ClipRRect(
                    child: SizedBox(
                      height: 220,
                      child: Image.asset(
                        'assets/images/login.png',
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              height: 220,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Text('Imagen no disponible'),
                              ),
                            ),
                      ),
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: [
                      // Nombre
                      BuildInputField(
                        hintText: 'Nombre',
                        icon: Icon(Icons.person, color: Colors.grey[700]),
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 20),
                      // Apellido
                      BuildInputField(
                        hintText: 'Apellido',
                        icon: Icon(Icons.person, color: Colors.grey[700]),
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 20),
                      // Celular
                      BuildInputField(
                        hintText: 'Celular',
                        icon: Icon(Icons.local_phone, color: Colors.grey[700]),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      // Fecha de nacimiento
                      BuildInputField(
                        hintText: 'Fecha de nacimiento',
                        icon: Icon(
                          Icons.calendar_month,
                          color: Colors.grey[700],
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                      const SizedBox(height: 20),
                      // Domicilio
                      BuildInputField(
                        hintText: 'Domicilio',
                        icon: Icon(Icons.home, color: Colors.grey[700]),
                        keyboardType: TextInputType.streetAddress,
                      ),
                      const SizedBox(height: 20),
                      // Email
                      BuildInputField(
                        hintText: 'Email',
                        icon: Icon(Icons.email, color: Colors.grey[700]),
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 20),

                      // Contraseña
                      const PasswordInputField(),
                      const SizedBox(height: 20),
                      const PasswordRegisterInputField(),

                      const SizedBox(height: 40),

                      // Botón de registrarse
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            navigateTo(context, 'registerCheck');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D2130),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Registrarse',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Color(0xFFDDDDDD)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'ó',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Color(0xFFDDDDDD)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tienes una cuenta? ',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              navigateTo(context, 'backLogin');
                            },
                            child: const Text(
                              'Inicia sesión',
                              style: TextStyle(
                                color: Colors.black,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Versión 1.0',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
