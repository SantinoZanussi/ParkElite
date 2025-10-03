import 'package:flutter/material.dart';
import '../utils/navigateTo.dart';
import '../widgets/inputFields.dart';
import '../services/api_service.dart';
import '../utils/connectivity_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  ApiService? api;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController last_nameController = TextEditingController();
  final TextEditingController phone_numberController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController home_addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    initializeAndLoad();
  }

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

  Future<void> initializeAndLoad() async {
    try {
      api = ApiService();
      await api!.initBaseUrl();
      await checkServerConnection(
        apiService: api!,
        onSuccess: () {
          setState(() {
            isLoading = false;
            hasError = false;
          });
        },
        onError: () {
          setState(() {
            isLoading = false;
            hasError = true;
          });
        },
      );
    } catch (e) {
      print('Error en inicialización: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              const Text(
                '❌ No se pudo conectar con el servidor.\nVerificá tu conexión o intentá más tarde.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    hasError = false;
                  });
                  initializeAndLoad(); // Reintenta la carga
                },
                child: const Text('Reintentar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 25),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: SizedBox(
                      height: 100,
                      child: Image.asset(
                        'assets/images/logo_entero_premium.png',
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              height: 100,
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
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: [
                      const Text(
                        'Registrate',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF3e4a77)),
                      ),
                      const SizedBox(height: 30),
                    ],
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
                        icon: Icon(Icons.person, color: Color(0xFF3e4a77)),
                        keyboardType: TextInputType.name,
                        controller: nameController,
                      ),
                      const SizedBox(height: 30),
                      BuildInputField(
                        hintText: 'Apellido',
                        icon: Icon(Icons.person, color: Color(0xFF3e4a77)),
                        keyboardType: TextInputType.name,
                        controller: last_nameController,
                      ),
                      const SizedBox(height: 30),
                      BuildInputField(
                        hintText: 'Celular',
                        icon: Icon(Icons.local_phone, color: Color(0xFF3e4a77)),
                        keyboardType: TextInputType.phone,
                        controller: phone_numberController,
                      ),
                      const SizedBox(height: 30),
                      BuildInputField(
                        hintText: 'Fecha de nacimiento (DD/MM/AAAA)',
                        icon: Icon(Icons.calendar_month, color: Color(0xFF3e4a77)),
                        keyboardType: TextInputType.phone,
                        controller: birthdayController,
                      ),
                      const SizedBox(height: 30),
                      BuildInputField(
                        hintText: 'Domicilio',
                        icon: Icon(Icons.home, color: Color(0xFF3e4a77)),
                        keyboardType: TextInputType.streetAddress,
                        controller: home_addressController,
                      ),
                      const SizedBox(height: 30),
                      BuildInputField(
                        hintText: 'Email',
                        icon: Icon(Icons.email, color: Color(0xFF3e4a77)),
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                      ),
                      const SizedBox(height: 30),
                      PasswordInputField(controller: passwordController),
                      const SizedBox(height: 30),
                      PasswordRegisterInputField(controller: confirmPasswordController),
                      const SizedBox(height: 50),
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
                                  SnackBar(
                                    content: Text('Error: ${error.toString()}'),
                                  ),
                                );
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3e4a77),
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
                            '¿Ya tenes una cuenta? ',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              navigateTo(context, 'backLogin');
                            },
                            child: const Text(
                              'Inicia sesión',
                              style: TextStyle(
                                color: Color(0xFF3e4a77),
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
                      const SizedBox(height: 10),
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
