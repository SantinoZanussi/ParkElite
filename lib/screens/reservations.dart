import 'package:flutter/material.dart';
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
  List<dynamic> occupancyStats = [];
  final ApiService apiService = ApiService();

  // mes actual + 1
  DateTime get maxDate => DateTime(currentDate.year, DateTime.now().month + 2);

  @override
  void initState() {
    super.initState();
    _loadReservations();
    _loadOccupancyStats();
  }

  Future<void> _loadReservations() async {
    setState(() {
      isLoading = true;
    });
    try {
      final reservations = await apiService.getUserReservations();
      setState(() {
        userReservations = reservations;
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar reservas: $e');
      setState(() {
        userReservations = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las reservas: $e')),
      );
    }
  }

  Future<void> _loadOccupancyStats() async {
    try {
      final selectedDate = DateTime(currentDate.year, currentDate.month, selectedDay);
      final stats = await apiService.getOccupancyStats(selectedDate);
      setState(() {
        occupancyStats = stats;
      });
    } catch (e) {
      print('Error al cargar estadísticas: $e');
      setState(() {
        occupancyStats = [];
      });
    }
  }

  void nextMonth() {
    final next = DateTime(currentDate.year, currentDate.month + 1);
    if (next.isBefore(maxDate)) {
      setState(() {
        currentDate = next;
        selectedDay = 1;
      });
      _loadOccupancyStats();
    }
  }

  void previousMonth() {
    final now = DateTime.now();
    if (currentDate.month > now.month || currentDate.year > now.year) {
      setState(() {
        currentDate = DateTime(currentDate.year, currentDate.month - 1);
        selectedDay = 1;
      });
      _loadOccupancyStats();
    }
  }

  void selectDay(int day) {
    setState(() {
      selectedDay = day;
    });
    _loadOccupancyStats();
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
      backgroundColor: const Color(0xFFF5F5F5),
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
                        // fechas
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

                        // domingo
                        if (DateTime(currentDate.year, currentDate.month, selectedDay).weekday == DateTime.sunday)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No hay reservas disponibles los domingos.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF5a5d61),
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
          BottomNavBar(currentPage: 'reservas'),
        ],
      ),
    );
  }

  List<Widget> _generateReservationCards() {
    final List<Widget> cards = [];
    final now = DateTime.now().toLocal();
    final selectedDate = DateTime(currentDate.year, currentDate.month, selectedDay);
    final isToday = selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;

    //debugPrint('=== _generateReservationCards ===');
    //debugPrint('now: $now');
    //debugPrint('selectedDate: $selectedDate  (isToday: $isToday)');

    // tarjetas para cada hora del día (6 AM a 10 PM)
    for (int hour = 6; hour <= 22; hour++) {
      final slotTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour);
      //debugPrint('  hour=$hour  slotTime=$slotTime  isBefore(now)? ${slotTime.isBefore(now)}');
      if (isToday && slotTime.isBefore(now)) {
        // si es hoy y la hora ya pasó, no muestra la tarjeta
        continue;
      }

      final availability = _getAvailabilityForHour(hour);
      final isAvailable = (availability['available'] ?? 0) > 0;
      final hasUserReservation = _hasUserReservationAtHour(hour);

      cards.add(
        GestureDetector(
          onTap: isAvailable && !hasUserReservation ? () => _showDurationDialog(hour) : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Card(
              elevation: 10,
              color: hasUserReservation ? Colors.blue[50] : (isAvailable ? Colors.white : Colors.grey[200]),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: hasUserReservation ? Color(0xFF37F097) : Color(0xFF4A90E2),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // horario
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasUserReservation ? const Color(0xFF37F097) : const Color(0xFF4A90E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (hasUserReservation) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF37F097),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'TU RESERVA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    // disponibilidad
                    Text(
                      hasUserReservation 
                          ? 'Tu reserva confirmada' 
                          : 'Disponibilidad: ${availability['occupied']}/${availability['total']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      hasUserReservation
                          ? _getUserReservationInfo(hour)
                          : (isAvailable ? 'Lugares disponibles' : 'Sin lugares disponibles'),
                      style: TextStyle(
                        color: hasUserReservation ? const Color(0xFF59806e) : Color(0xFF154e91),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 7),
                    // barra de progreso
                    LinearProgressIndicator(
                      value: (availability['total'] ?? 0) > 0 ? (availability['occupied'] ?? 0) / (availability['total'] ?? 1) : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hasUserReservation ? Color(0xFF37F097) : (isAvailable ? Colors.green : Colors.red),
                      ),
                    ),
                    // cancelar reserva
                    if (hasUserReservation) ...[
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _cancelUserReservation(hour),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancelar Reserva'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return cards;
  }

  Map<String, int> _getAvailabilityForHour(int hour) {
    // estadísticas de ocupación
    final stat = occupancyStats.firstWhere(
      (stat) => stat['hour'] == hour,
      orElse: () => {'occupied': 0, 'available': 4, 'total': 4},
    );
    
    return {
      'occupied': stat['occupied'] ?? 0,
      'available': stat['available'] ?? 4,
      'total': 4,
    };
  }

  bool _hasUserReservationAtHour(int hour) {
    final selectedDate = DateTime(currentDate.year, currentDate.month, selectedDay);
    
    return userReservations.any((reservation) {
      final reservationDate = DateTime.parse(reservation['reservationDate']).toLocal();
      final startTime = DateTime.parse(reservation['startTime']).toLocal();
      final endTime = DateTime.parse(reservation['endTime']).toLocal();
      
      // verificar si es el mismo día
      if (reservationDate.year != selectedDate.year ||
          reservationDate.month != selectedDate.month ||
          reservationDate.day != selectedDate.day) {
        return false;
      }
      
      // verificar si la hora está dentro del rango de la reserva
      final hourDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour);
      return hourDateTime.isAfter(startTime.subtract(const Duration(minutes: 1))) &&
             hourDateTime.isBefore(endTime);
    });
  }

  String _getUserReservationInfo(int hour) {
    final selectedDate = DateTime(currentDate.year, currentDate.month, selectedDay);
    
    final reservation = userReservations.firstWhere((reservation) {
      final reservationDate = DateTime.parse(reservation['reservationDate']).toLocal();
      final startTime = DateTime.parse(reservation['startTime']).toLocal();
      final endTime = DateTime.parse(reservation['endTime']).toLocal();
      
      if (reservationDate.year != selectedDate.year ||
          reservationDate.month != selectedDate.month ||
          reservationDate.day != selectedDate.day) {
        return false;
      }
      
      final hourDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour);
      return hourDateTime.isAfter(startTime.subtract(const Duration(minutes: 1))) &&
             hourDateTime.isBefore(endTime);
    });

    final startTime = DateTime.parse(reservation['startTime']).toLocal();
    final endTime = DateTime.parse(reservation['endTime']).toLocal();
    final spotName = reservation['parkingSpotId']['name'];
    
    return '$spotName - ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} a ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showDurationDialog(int hour) async {
    final durations = {
      '1 hora': const Duration(hours: 1),
      '2 horas': const Duration(hours: 2),
      '3 horas': const Duration(hours: 3),
      '4 horas': const Duration(hours: 4),
      '6 horas': const Duration(hours: 6),
      '8 horas': const Duration(hours: 8),
    };

    final selectedDuration = await showDialog<Duration>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona la duración'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: durations.keys.map((key) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(durations[key]);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(key),
                ),
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
      setState(() {
        isLoading = true;
      });
      final reservationDate = DateTime(currentDate.year, currentDate.month, selectedDay);
      final startTime = DateTime(reservationDate.year, reservationDate.month, reservationDate.day, hour, 0, 0);
      final endTime = startTime.add(duration);
      // verificar que no exceda las 22:00
      if (endTime.weekday == DateTime.sunday) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El estacionamiento no abre los domingos.')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      } else if (endTime.hour > 22 || endTime.hour < 06) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La reserva no puede extenderse más allá de las 22:00')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      await apiService.createReservation(reservationDate, startTime, endTime);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva creada exitosamente')),
      );

      await _loadReservations();
      await _loadOccupancyStats();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cancelUserReservation(int hour) async {
    final selectedDate = DateTime(currentDate.year, currentDate.month, selectedDay);
    
    // encontrar la reserva del usuario para esa hora
    final reservation = userReservations.firstWhere((reservation) {
      final reservationDate = DateTime.parse(reservation['reservationDate']);
      final startTime = DateTime.parse(reservation['startTime']);
      final endTime = DateTime.parse(reservation['endTime']);
      
      if (reservationDate.year != selectedDate.year ||
          reservationDate.month != selectedDate.month ||
          reservationDate.day != selectedDate.day) {
        return false;
      }
      
      final hourDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour);
      return hourDateTime.isAfter(startTime.subtract(const Duration(minutes: 1))) &&
             hourDateTime.isBefore(endTime);
    });

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Reserva'),
          content: const Text('¿Estás seguro de que quieres cancelar esta reserva?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sí, Cancelar'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      try {
        setState(() {
          isLoading = true;
        });

        await apiService.cancelReservation(reservation['_id']);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada exitosamente')),
        );

        await _loadReservations();
        await _loadOccupancyStats();
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar: $e')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}