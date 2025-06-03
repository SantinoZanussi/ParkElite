import 'package:flutter/material.dart';
import '../widgets/class_card_reservations.dart';
import '../widgets/date_selector.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  DateTime currentDate = DateTime.now();
  int selectedDay = DateTime.now().day;
  bool isLoading = false;
  List<dynamic> userReservations = [];
  final ApiService apiService = ApiService();

  // Máximo: mes actual + 1
  DateTime get maxDate => DateTime(currentDate.year, DateTime.now().month + 2);

  @override
  void initState() {
    super.initState();
  }

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

  String getMonthName(int month) {
    const names = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return names[month];
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
            padding: const EdgeInsets.only(bottom: 100),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selector de fecha existente
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: previousMonth),
                            Text(monthText,
                                style: const TextStyle(fontSize: 16)),
                            IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: nextMonth),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DateSelector(
                          date: currentDate,
                          selectedDay: selectedDay,
                          onDaySelected: selectDay,
                        ),
                        const SizedBox(height: 20),

                        // Mostrar mensaje si es domingo
                        if (DateTime(currentDate.year, currentDate.month, selectedDay).weekday == DateTime.sunday)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No hay reservas disponibles los domingos',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._generateReservationCards(),
                      ],
                    ),
                  ),
          ),
          const BottomNavBar(currentPage: 'reservas'),
        ],
      ),
    );
  }

  List<Widget> _generateReservationCards() {
    final List<Widget> cards = [];
    for (int hour = 7; hour <= 20; hour++) {
      final availability = _calculateAvailability(hour);

      cards.add(
        GestureDetector(
          onTap: (availability['available'] ?? 0) > 0 ? () => _showDurationDialog(hour) : null,
          child: ClassCard(
            time: '$hour:00',
            title: 'Disponibilidad: ${availability['occupied']}/${availability['total']}',
            room: (availability['available'] ?? 0) > 0 ? 'Lugares disponibles' : 'Sin lugares disponibles',
          ),
        ),
      );
      cards.add(const SizedBox(height: 10));
    }
    return cards;
  }

  Map<String, int> _calculateAvailability(int hour) {
    final DateTime reservationDate = DateTime(
      currentDate.year,
      currentDate.month,
      selectedDay,
      hour,
    );

    final DateTime endTime = reservationDate.add(const Duration(hours: 1));

    final List<int> occupiedSpots = userReservations
        .where((reservation) {
          final DateTime startTime = DateTime.parse(reservation['startTime']);
          final DateTime reservationEndTime = DateTime.parse(reservation['endTime']);
          return (reservationDate.isBefore(reservationEndTime) &&
              endTime.isAfter(startTime));
        })
        .map((reservation) => int.parse(reservation['parkingSpotId']['name'].split(' ')[1]))
        .toList();

    const int totalSpots = 4;
    final int occupied = occupiedSpots.length;
    final int available = totalSpots - occupied;

    return {
      'total': totalSpots,
      'occupied': occupied,
      'available': available,
    };
  }

  Future<void> _showDurationDialog(int hour) async {
    final durations = {
      '1 hora': const Duration(hours: 1),
      '3 horas': const Duration(hours: 3),
      '1 día': const Duration(days: 1),
    };

    final selectedDuration = await showDialog<Duration>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona la duración de la reserva'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: durations.keys.map((key) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(durations[key]);
                },
                child: Text(key),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selectedDuration != null) {
      await _handleReservation(hour, selectedDuration);
    }
  }

  Future<void> _handleReservation(int hour, Duration duration) async {
    try {
      final DateTime reservationDate = DateTime(
        currentDate.year,
        currentDate.month,
        selectedDay,
        hour,
      );

      final DateTime endTime = reservationDate.add(duration);

      // Verificar disponibilidad de lugares
      final List<int> occupiedSpots = userReservations
          .where((reservation) {
            final DateTime startTime = DateTime.parse(reservation['startTime']);
            final DateTime reservationEndTime = DateTime.parse(reservation['endTime']);
            return (reservationDate.isBefore(reservationEndTime) &&
                endTime.isAfter(startTime));
          })
          .map((reservation) => int.parse(reservation['parkingSpotId']['name'].split(' ')[1]))
          .toList();

      int availableSpot = -1;
      for (int i = 1; i <= 4; i++) {
        if (!occupiedSpots.contains(i)) {
          availableSpot = i;
          break;
        }
      }

      if (availableSpot == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay lugares disponibles para este horario')),
        );
        return;
      }

      // Crear reserva
      await apiService.createReservation(
        availableSpot.toString(),
        reservationDate,
        endTime,
      );

      // Recargar las reservas
      //await _loadReservations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al realizar la reserva: $e')),
      );
    }
  }
}