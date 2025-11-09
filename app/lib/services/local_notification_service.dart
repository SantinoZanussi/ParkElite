import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'api_service.dart';
import '../main.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final api = ApiService();
      await api.initBaseUrl();

      final data = await api.getNotifications();

      if (data['success'] == true) {
        final notifications = data['notifications'] as List;
        final unreadNotifications =
            notifications.where((n) => n['read'] == false).toList();

        for (var notification in unreadNotifications) {
          await LocalNotificationService()
              .showNotificationFromData(notification);
        }
      }

      return Future.value(true);
    } catch (e) {
      print('❌ Error en tarea de fondo: $e');
      return Future.value(false);
    }
  });
}

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // evitar repetir notificaciones
  String? _lastNotificationId;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const androidChannel = AndroidNotificationChannel(
      'parkelite_notifications',
      'ParkElite Notificaciones',
      description: 'Notificaciones importantes del estacionamiento',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _requestPermissions();

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    await Workmanager().registerPeriodicTask(
      'check_notifications',
      'checkNotifications',
      frequency: Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('👆 Notificación tocada: ${response.payload}');

    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _navigateFromNotification(data);
    }
  }

  void _navigateFromNotification(Map<String, dynamic> data) {
    navigatorKey.currentState
        ?.pushNamed('notificaciones', arguments: data);
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    Color notificationColor = Color(0xFF4A90E2);
    String icon = '🔔';

    if (type == 'vehicle_retention') {
      notificationColor = Color(0xFFFF6B6B);
      icon = '⚠️';
    } else if (type == 'spot_occupied') {
      notificationColor = Color(0xFFFFA500);
      icon = '⏳';
    } else if (type == 'reservation_cancelled') {
      notificationColor = Color(0xFFFF6B6B);
      icon = '❌';
    }

    final int notificationId =
        DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notifications.show(
      notificationId,
      '$icon $title',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'parkelite_notifications',
          'ParkElite Notificaciones',
          channelDescription:
              'Notificaciones importantes del estacionamiento',
          importance: Importance.high,
          priority: Priority.high,
          color: notificationColor,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: notificationColor,
          ledOnMs: 1000,
          ledOffMs: 500,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: '$icon $title',
            summaryText: 'ParkElite',
          ),
          ticker: title,
        ),
      ),
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  Future<void> showNotificationFromData(
      Map<String, dynamic> notificationData) async {
    await showNotification(
      title: notificationData['title'] ?? 'Notificación',
      body: notificationData['message'] ?? '',
      type: notificationData['type'],
      data: {
        'notificationId': notificationData['_id'],
        'type': notificationData['type'],
        'spotNumber': notificationData['spotNumber']?.toString() ?? '',
        'reservationId':
            notificationData['reservationId']?.toString() ?? '',
      },
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> checkForNewNotifications() async {
    try {
      final api = ApiService();
      await api.initBaseUrl();

      final data = await api.getNotifications();

      if (data['success'] == true) {
        final notifications = data['notifications'] as List;

        // ordenar de más reciente a más vieja
        notifications.sort((a, b) => DateTime.parse(b['createdAt'])
            .compareTo(DateTime.parse(a['createdAt'])));

        if (notifications.isNotEmpty) {
          final newest = notifications.first;

          if (newest['_id'] != _lastNotificationId &&
              newest['read'] == false) {
            await showNotificationFromData(newest);

            _lastNotificationId = newest['_id'];
          }
        }
      }
    } catch (e) {
      print('❌ Error al verificar notificaciones: $e');
    }
  }

  Future<void> schedulePeriodicCheck() async {
    await Workmanager().registerPeriodicTask(
      'check_notifications',
      'checkNotifications',
      frequency: Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  Future<void> cancelPeriodicCheck() async {
    await Workmanager().cancelByUniqueName('check_notifications');
  }
}
