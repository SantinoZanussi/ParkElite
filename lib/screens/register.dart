import 'package:flutter/material.dart';
import '../utils/navigateTo.dart';
import '../widgets/inputFields.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController last_nameController = TextEditingController();
  final TextEditingController phone_numberController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController home_addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    last_nameController.dispose();
    phone_numberController.dispose();
    birthdayController.dispose();
    home_addressController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                  margin: const EdgeInsets.only(bottom: 30),
                  child: ClipRRect(
                    child: SizedBox(
                      height: 220,
                      child: Image.asset(
                        'assets/images/login.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
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
                      BuildInputField(
                        hintText: 'Nombre',
                        icon: Icon(Icons.person, color: Colors.grey[700]),
                        keyboardType: TextInputType.name,
                        controller: nameController,
                      ),
                      const SizedBox(height: 20),
                      BuildInputField(
                        hintText: 'Apellido',
                        icon: Icon(Icons.person, color: Colors.grey[700]),
                        keyboardType: TextInputType.name,
                        controller: last_nameController,
                      ),
                      const SizedBox(height: 20),
                      BuildInputField(
                        hintText: 'Celular',
                        icon: Icon(Icons.local_phone, color: Colors.grey[700]),
                        keyboardType: TextInputType.phone,
                        controller: phone_numberController,
                      ),
                      const SizedBox(height: 20),
                      BuildInputField(
                        hintText: 'Fecha de nacimiento',
                        icon: Icon(Icons.calendar_month, color: Colors.grey[700]),
                        keyboardType: TextInputType.datetime,
                        controller: birthdayController,
                      ),
                      const SizedBox(height: 20),
                      BuildInputField(
                        hintText: 'Domicilio',
                        icon: Icon(Icons.home, color: Colors.grey[700]),
                        keyboardType: TextInputType.streetAddress,
                        controller: home_addressController,
                      ),
                      const SizedBox(height: 20),
                      BuildInputField(
                        hintText: 'Email',
                        icon: Icon(Icons.email, color: Colors.grey[700]),
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                      ),
                      const SizedBox(height: 20),
                      PasswordInputField(controller: passwordController),
                      const SizedBox(height: 20),
                      PasswordRegisterInputField(controller: confirmPasswordController),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final nombre = nameController.text;
                            final apellido = last_nameController.text;
                            final celular = phone_numberController.text;
                            final fechaNacimiento = birthdayController.text;
                            final domicilio = home_addressController.text;
                            final email = emailController.text;
                            final password = passwordController.text;
                            final confirmPassword = confirmPasswordController.text;
                            if (nombre.isEmpty || apellido.isEmpty || fechaNacimiento.isEmpty || domicilio.isEmpty || confirmPassword.isEmpty || email.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Por favor completa todos los campos'),
                                ),
                              );
                              return;
                            } else if (password != confirmPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Las contraseñas no coinciden'),
                                ),
                              );
                              return;
                            } else {
                              await ApiService().register(
                                nombre,
                                apellido,
                                email,
                                password,
                                celular,
                                fechaNacimiento,
                                domicilio,
                              ).then((value) {
                                if (value['status'] == 'success') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Registro exitoso'),
                                    ),
                                  );
                                  navigateTo(context, 'home');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Error al registrarse'),
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
