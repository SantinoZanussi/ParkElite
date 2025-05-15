import 'package:flutter/material.dart';
import '../utils/navigateTo.dart';
import '../widgets/inputFields.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
                  margin: const EdgeInsets.only(bottom: 75),
                  child: ClipRRect(
                    child: SizedBox(
                      height: 280,
                      child: Image.asset(
                        'assets/images/login.png',
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              height: 280,
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
                      // Email
                      BuildInputField(
                        hintText: 'Email',
                        icon: Icon(Icons.email, color: Colors.grey[700]),
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                      ),

                      const SizedBox(height: 20),

                      // Contraseña
                      PasswordInputField(controller: passwordController),

                      const SizedBox(height: 40),

                      // Botón de login
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final email = emailController.text;
                            final password = passwordController.text;
                            if (email.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor completa todos los campos'),
                                ),
                              );
                              return;
                            } else {
                              ApiService().login(email, password).then((value) {
                                if (value['status'] == 'success') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Inicio de sesión exitoso'),
                                    ),
                                  );
                                  navigateTo(context, 'home');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Error al iniciar sesión'),
                                    ),
                                  );
                                }
                              }).catchError((error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error de conexión'),
                                  ),
                                );
                              });
                            }
                            navigateTo(context, 'Login');
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
                            'Ingresar',
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
                            '¿No tienes una cuenta? ',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              navigateTo(context, 'registrarse');
                            },
                            child: const Text(
                              'Regístrate',
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
