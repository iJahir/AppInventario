import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _notifications.initialize(initSettings);
  }

  static Future<void> showLowStockNotification({
    required int id,
    required String name,
    required int stock,
    required int minStock,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'low_stock_channel',
      'Alertas de Stock Bajo',
      channelDescription: 'Notifica cuando el stock cae por debajo del mínimo',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFA770EF),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _notifications.show(
      id,
      '⚠️ ALERTA: Stock Bajo',
      'El producto "$name" está en stock crítico ($stock u., mínimo es $minStock).',
      details,
    );
  }

  static Future<void> showDailySummaryNotification({
    required int id,
    required int criticalCount,
    required int outOfStockCount,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_summary_channel',
      'Resumen de Inventario',
      channelDescription: 'Resumen diario de stock crítico',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFF3A7BD5),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      id,
      '📈 Resumen de Almacén',
      'Tienes $criticalCount productos con stock bajo y $outOfStockCount agotados hoy.',
      details,
    );
  }
}
