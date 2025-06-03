// (lib/screens/reservations.dart (base))
import 'package:flutter/material.dart';
import '../widgets/class_card_reservations.dart'; // ./lib/widgets/...
import '../widgets/date_selector.dart'; // ./lib/widgets/...
import '../widgets/bottom_nav_bar.dart'; // ./lib/widgets/...

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  DateTime currentDate = DateTime.now();
  int selectedDay = DateTime.now().day;

  // Máximo: mes actual + 1
  DateTime get maxDate => DateTime(currentDate.year, DateTime.now().month + 2);

  void nextMonth() {
    final next = DateTime(currentDate.year, currentDate.month + 1);
    if (next.isBefore(maxDate)) {
      setState(() {
        currentDate = next;
        selectedDay = 1;
      });
    }
  }

  void previousMonth() {
    final now = DateTime.now();
    if (currentDate.month > now.month || currentDate.year > now.year) {
      setState(() {
        currentDate = DateTime(currentDate.year, currentDate.month - 1);
        selectedDay = 1;
      });
    }
  }

  void selectDay(int day) {
    setState(() {
      selectedDay = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthText = "${getMonthName(currentDate.month)} ${currentDate.year}";

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 25.0, top: 25.0),
              child: const Text(
                'Reservas',
                style: TextStyle(color: Colors.black, fontSize: 22),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 100), // espacio para la nav bar
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: previousMonth),
                      Text(monthText, style: const TextStyle(fontSize: 16)),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: nextMonth),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DateSelector(
                    date: currentDate,
                    selectedDay: selectedDay,
                    onDaySelected: selectDay,
                  ),
                  const SizedBox(height: 20),
                  const ClassCard(
                    time: "07:00",
                    title: "Estacionamiento 1",
                    room: "Dirección 1",
                  ),
                  const ClassCard(
                    time: "08:00",
                    title: "Estacionamiento 2",
                    room: "Dirección 2",
                  ),
                  const ClassCard(
                    time: "08:00",
                    title: "Estacionamiento 3",
                    room: "Dirección 3",
                  ),
                  const ClassCard(
                    time: "09:00",
                    title: "Estacionamiento 4",
                    room: "Dirección 4",
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          const BottomNavBar(currentPage: 'reservas'),
        ],
      ),
    );

  }

  String getMonthName(int month) {
    const names = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return names[month];
  }
}