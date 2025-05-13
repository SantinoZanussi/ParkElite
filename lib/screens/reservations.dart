/*
// (lib/screens/reservations.dart (base))
import 'package:flutter/material.dart';
import '../widgets/class_card_reservations.dart';
import '../widgets/date_selector.dart';
import '../widgets/bottom_nav_bar.dart';

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
*/

// lib/screens/reservations.dart (completo)
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
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Para pruebas: usar datos de prueba cuando no hay conexión a la API
      try {
        final reservations = await apiService.getUserReservations();
        setState(() {
          userReservations = reservations;
          isLoading = false;
        });
      } catch (apiError) {
        print('Error al conectar con la API: $apiError');
        // Usar datos de reserva de ejemplo para desarrollo
        setState(() {
          userReservations = _getMockReservations();
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usando datos de prueba (sin conexión a API)'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las reservas: $e')),
      );
    }
  }
  
  // Datos de ejemplo para desarrollo sin backend
  List<Map<String, dynamic>> _getMockReservations() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      {
        'startTime': DateTime(today.year, today.month, today.day, 7, 0).toIso8601String(),
        'endTime': DateTime(today.year, today.month, today.day, 8, 0).toIso8601String(),
        'parkingSpotId': {
          'name': 'Estacionamiento 1',
          'location': 'Sección 1',
        }
      },
      {
        'startTime': DateTime(today.year, today.month, today.day, 14, 30).toIso8601String(),
        'endTime': DateTime(today.year, today.month, today.day, 16, 0).toIso8601String(),
        'parkingSpotId': {
          'name': 'Estacionamiento 2',
          'location': 'Sección 2',
        }
      },
      {
        'startTime': DateTime(today.year, today.month, today.day + 1, 9, 0).toIso8601String(),
        'endTime': DateTime(today.year, today.month, today.day + 1, 10, 30).toIso8601String(),
        'parkingSpotId': {
          'name': 'Estacionamiento 3',
          'location': 'Sección 3',
        }
      }
    ];
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
                        
                        // Mostrar reservas desde la API
                        if (userReservations.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No tienes reservas para esta fecha',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          ...userReservations
                              .where((reservation) {
                                final reservationDate = DateTime.parse(
                                    reservation['startTime']);
                                return reservationDate.day == selectedDay &&
                                    reservationDate.month == currentDate.month &&
                                    reservationDate.year == currentDate.year;
                              })
                              .map((reservation) {
                                final startTime = DateTime.parse(
                                    reservation['startTime']);
                                final spotName = reservation['parkingSpotId']
                                    ['name'];
                                final location = reservation['parkingSpotId']
                                    ['location'];
                                
                                return ClassCard(
                                  time: "${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}",
                                  title: spotName,
                                  room: location,
                                );
                              })
                              .toList(),
                        
                        const SizedBox(height: 20),
                        // Botón para crear nueva reserva
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _showReservationDialog();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D2130),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text('Crear nueva reserva'),
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
          ),
          const BottomNavBar(currentPage: 'reservas'),
        ],
      ),
    );
  }

  void _showReservationDialog() {
    // Selección de estacionamiento y horario
    showDialog(
      context: context,
      builder: (context) {
        TimeOfDay selectedTime = TimeOfDay.now();
        String selectedParkingSpot = '';
        List<dynamic> parkingSpots = [
          {'id': '1', 'name': 'Estacionamiento 1', 'location': 'Nivel 1, Sección A'},
          {'id': '2', 'name': 'Estacionamiento 2', 'location': 'Nivel 1, Sección B'},
          {'id': '3', 'name': 'Estacionamiento 3', 'location': 'Nivel 2, Sección A'},
        ];
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nueva Reserva'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fecha seleccionada
                  Text(
                    'Fecha: ${selectedDay} de ${getMonthName(currentDate.month)} ${currentDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Selector de estacionamiento
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Estacionamiento',
                      border: OutlineInputBorder(),
                    ),
                    items: parkingSpots.map((spot) {
                      return DropdownMenuItem(
                        value: spot['id'].toString(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              fit: FlexFit.loose,
                              child: Text(spot['location']),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedParkingSpot = value!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  // Selector de hora
                  ElevatedButton(
                    onPressed: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    },
                    child: Text('Seleccionar hora: ${selectedTime.format(context)}'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedParkingSpot.isNotEmpty) {
                      // Crear reserva
                      _createReservation(selectedParkingSpot, selectedTime);
                      // Cerrar el diálogo
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor selecciona un estacionamiento')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D2130),
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _createReservation(String spotId, TimeOfDay time) async {
    try {
      // Crear fechas para la reserva
      final DateTime reservationDate = DateTime(
        currentDate.year,
        currentDate.month,
        selectedDay,
        time.hour,
        time.minute,
      );
      
      // Por defecto, la reserva dura 1 hora
      final DateTime endTime = reservationDate.add(const Duration(hours: 1));
      
      try {
        // Intentar crear la reserva en la API
        await apiService.createReservation(spotId, reservationDate, endTime);
        
        // Recargar las reservas
        await _loadReservations();
        
        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva creada correctamente')),
        );
      } catch (e) {
        // Si falla la API, agregar localmente para fines de demostración
        print('Error al crear reserva en API: $e');
        
        // Buscar el spot seleccionado para la vista (sólo para demostración)
        final mockSpots = [
          {'id': '1', 'name': 'Estacionamiento 1', 'location': 'Nivel 1, Sección A'},
          {'id': '2', 'name': 'Estacionamiento 2', 'location': 'Nivel 1, Sección B'},
          {'id': '3', 'name': 'Estacionamiento 3', 'location': 'Nivel 2, Sección A'},
        ];
        
        final selectedSpot = mockSpots.firstWhere((spot) => spot['id'] == spotId);
        
        // Agregar la nueva reserva al estado local
        setState(() {
          userReservations.add({
            'startTime': reservationDate.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'parkingSpotId': {
              'name': selectedSpot['name'],
              'location': selectedSpot['location'],
            }
          });
        });
        
        // Notificar al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modo sin conexión: Reserva agregada localmente'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la reserva: $e')),
      );
    }
  }
}