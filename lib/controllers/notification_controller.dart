import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    super.onInit();
    initNotifications();
  }

  // Initialize Notifications
  void initNotifications() async {
    // Request Permissions (iOS)
    await _firebaseMessaging.requestPermission();

    //  Get FCM Token
    _firebaseMessaging.getToken().then((token) {
      print("FCM Token: $token");
    });

    //  Listen for Background & Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Message opened app: ${message.data}");
    });

    _setupLocalNotifications();
  }

  //  Configure Local Notifications
  void _setupLocalNotifications() {
    var androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosSettings = DarwinInitializationSettings();
    var settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    _localNotifications.initialize(settings);
  }

  // 🔹 Show Local Notification
  void _showNotification(RemoteMessage message) async {
    var androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Chat Messages',
      importance: Importance.high,
    );
    var iosDetails = DarwinNotificationDetails();
    var details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      0,
      message.notification?.title ?? "New Message",
      message.notification?.body ?? "You received a new message",
      details,
    );
  }
}
