import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:upd_party/splash_screen.dart';
import 'package:upd_party/event_screen.dart'; // Ensure this import is correct

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  _showEventNotification(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  _initializeNotifications();
  runApp(const MyApp());
}

void _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      _onSelectNotification(response.payload);
    },
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("New foreground notification received: ${message.notification?.title}");
    _showEventNotification(message);
  });
  

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _navigateToEventDetails(message);
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _navigateToEventDetails(initialMessage);
  }
}

void _showEventNotification(RemoteMessage message) {
  final eventData = message.data;
  flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? "New Event",
    message.notification?.body ?? "An event has been created!",
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'event_channel',
        'Event Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: jsonEncode({
      'memberId': eventData['memberId'],
      'district': eventData['district'],
      'districtId': eventData['district_id'],
    }), // Sending as JSON string
  );
}

void _navigateToEventDetails(RemoteMessage message) {
  final String? memberId = message.data['memberId'];
  final String? stateId = message.data['state_id']; // Use state_id instead of district_id

  if (memberId != null && stateId != null) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => EventScreen(
          stateId: int.parse(stateId), // Pass stateId to EventScreen
          memberId: memberId,
        ),
      ),
    );
  }
}

// Handle notification tap when in foreground or background
void _onSelectNotification(String? payload) {
  if (payload != null) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);

      final String? memberId = data['memberId'];
      final String? stateId = data['state_id']; // Use state_id instead of district_id

      if (memberId != null && stateId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => EventScreen(
              stateId: int.parse(stateId), // Pass stateId to EventScreen
              memberId: memberId,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error parsing notification payload: $e");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PP Party',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        ),
      home: const SplashScreen(),
    );
  }
}