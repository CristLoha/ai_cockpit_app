import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,

      onDidReceiveNotificationResponse: (details) async {
        final String? payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          OpenFilex.open(payload);
        }
      },
    );

    await _handleNotificationLaunch();
  }

  Future<void> _handleNotificationLaunch() async {
    final NotificationAppLaunchDetails? launchDetails =
        await _flutterLocalNotificationsPlugin
            .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final String? payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        OpenFilex.open(payload);
      }
    }
  }

  Future<void> showExportCompleteNotification({
    required String fileName,
    required String filePath,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'export_channel', // ID channel
          'Notifikasi Ekspor', // Nama channel
          channelDescription: 'Notifikasi ketika ekspor file berhasil.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Ekspor Berhasil', // Judul notifikasi
      'File "$fileName" berhasil diekspor. Ketuk untuk membuka.', // Isi notifikasi
      platformChannelSpecifics,
      payload: filePath,
    );
  }
}
