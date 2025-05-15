import 'package:flutter/material.dart';
import '../screens/home.dart';
import '../screens/register.dart';
import '../screens/login.dart';
import '../screens/profile.dart';
import '../screens/notifications.dart';
import '../screens/reservations.dart';

void navigateTo(BuildContext context, String screenName) {
  if (screenName == "home") {
    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    ScaffoldMessenger.of(
      context,
    );
  } else if (screenName == "registrarse") { //* registrarseCheck = Formulario para registrarse | Registrarse = Screen
    Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
    ScaffoldMessenger.of(
      context,
    );
  } else if (screenName == "backLogin") {
    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    ScaffoldMessenger.of(
      context,
    );
  } else if (screenName == "perfil") {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
    ScaffoldMessenger.of(
      context,
    );
  } else if (screenName == "notificaciones") {
    Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()));
    ScaffoldMessenger.of(
      context,
    );
  } else if (screenName == "reservas") {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ReservationsScreen()));
    ScaffoldMessenger.of(
      context,
    );
  } else if (["desarrolladores", "config", "contacto", "tarifas"].contains(screenName)) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navegando a: $screenName (Pantalla no implementada)')));
  }
}