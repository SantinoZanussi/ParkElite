import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';
import '../utils/connectivity_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  ApiService? api;
  bool isLoading = true;
  bool hasError = false;
  List<dynamic> notifications = [];
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    initializeAndLoad();
  }

  Future<void> initializeAndLoad() async {
    try {
      api = ApiService();
      await api!.initBaseUrl();
      
      await checkServerConnection(
        apiService: api!,
        onSuccess: () async {
          await loadNotifications();
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

  Future<void> loadNotifications() async {
    try {
      final data = await api!.getNotifications();
      setState(() {
        notifications = data['notifications'] ?? [];
        unreadCount = data['unreadCount'] ?? 0;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      print('Error al cargar notificaciones: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await api!.markNotificationAsRead(notificationId);
      await loadNotifications();
    } catch (e) {
      print('Error al marcar como leída: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await api!.deleteNotification(notificationId);
      await loadNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación eliminada')),
      );
    } catch (e) {
      print('Error al eliminar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar notificación')),
      );
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'vehicle_retention':
        return const Color(0xFFFF6B6B);
      case 'spot_occupied':
        return const Color(0xFFFFA500);
      case 'reservation_cancelled':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF4A90E2);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'vehicle_retention':
        return Icons.warning_amber_rounded;
      case 'spot_occupied':
        return Icons.access_time_rounded;
      case 'reservation_cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
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
                  initializeAndLoad();
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
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notificaciones',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$unreadCount nuevas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Lista de notificaciones
                Expanded(
                  child: notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.notifications_none,
                                size: 80,
                                color: Color(0xFF808387),
                              ),
                              SizedBox(height: 20),
                              Text(
                                "No hay notificaciones",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xff808387),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: loadNotifications,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(15),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              final isRead = notification['read'] ?? false;
                              final type = notification['type'] ?? 'general';
                              final color = _getNotificationColor(type);
                              
                              return Dismissible(
                                key: Key(notification['_id']),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  deleteNotification(notification['_id']);
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    if (!isRead) {
                                      markAsRead(notification['_id']);
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: isRead ? Colors.white : color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isRead ? const Color(0xFFE0E0E0) : color.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            _getNotificationIcon(type),
                                            color: color,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      notification['title'],
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: isRead ? const Color(0xFF666666) : const Color(0xFF1D2130),
                                                      ),
                                                    ),
                                                  ),
                                                  if (!isRead)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color: color,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                notification['message'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isRead ? const Color(0xFF999999) : const Color(0xFF4A5568),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _formatTime(notification['createdAt']),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF999999),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          BottomNavBar(currentPage: 'notificaciones'),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Ahora';
      } else if (difference.inHours < 1) {
        return 'Hace ${difference.inMinutes} min';
      } else if (difference.inDays < 1) {
        return 'Hace ${difference.inHours} h';
      } else if (difference.inDays < 7) {
        return 'Hace ${difference.inDays} días';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}