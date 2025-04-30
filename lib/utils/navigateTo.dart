import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/register_screen.dart';
import '../screens/login_screen.dart';

// Función para navegar a otra pantalla
void navigateTo(BuildContext context, String screenName) {

  if (screenName == "Login") { // Se ejecuta la lógica para checkear login etc etc
    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navegando a: $screenName')));
  } else if (screenName == "Registrarse" || screenName == "RegistrarseButton") { // RegistrarseButton = Formulario | Registrarse = Screen
    Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navegando a: $screenName')));
  } else if (screenName == "backLogin") {
    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navegando a: $screenName')));
  }
  // Aquí más adelante podrías agregar la navegación real a una pantalla específica
  // Navigator.push(context, MaterialPageRoute(builder: (context) => NewScreen()));
}
