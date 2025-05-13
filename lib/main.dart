import 'package:flutter/material.dart';
import './screens/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkElite',
      theme: ThemeData(fontFamily: 'SanFrancisco', useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
