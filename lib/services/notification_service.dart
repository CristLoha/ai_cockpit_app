import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // DITAMBAHKAN: Minta izin notifikasi sebelum inisialisasi
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // DIUBAH: Minta izin di iOS saat inisialisasi
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

    await _notificationsPlugin.initialize(
      initializationSettings,
      // Aksi saat notifikasi di-tap
      onDidReceiveNotificationResponse: (details) async {
        // Simpan payload ke variabel lokal untuk menghindari "property promotion" warning.
        final String? payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          OpenFilex.open(payload);
        }
      },
    );

    // DITAMBAHKAN: Tangani notifikasi yang meluncurkan aplikasi dari state terminated
    await _handleNotificationLaunch();
  }

  // DITAMBAHKAN: Method untuk memeriksa apakah aplikasi dibuka dari notifikasi
  Future<void> _handleNotificationLaunch() async {
    final NotificationAppLaunchDetails? launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final String? payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        OpenFilex.open(payload);
      }
    }
  }

  Future<void> showDownloadCompleteNotification({
    required String fileName,
    required String filePath,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'download_channel', // ID channel
          'Downloads', // Nama channel
          channelDescription: 'Notifikasi untuk download yang telah selesai.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0, // ID notifikasi
      'Download Selesai',
      'File "$fileName" telah disimpan.',
      platformChannelSpecifics,
      payload: filePath, // Kirim path file agar bisa dibuka saat di-tap
    );
  }
}
