import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
      
  // For handling notification when the app is in terminated state
  static RemoteMessage? initialMessage;

  // Initialize the FCM service
  Future<void> initialize() async {
    // Request permission for notifications
    await requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure FCM
    await _configureFCM();
  }

  // Request permission for notifications
  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  // Initialize local notifications for displaying when app is in foreground
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
    // You can add navigation logic here
  }

  // Configure FCM for different app states
  Future<void> _configureFCM() async {
    // Get the initial message if the app was launched from a notification
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    // If the app was launched from a notification
    if (initialMessage != null) {
      _handleMessage(initialMessage!);
    }

    // Handle notification when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Handle notification when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  void _handleMessage(RemoteMessage message) {
    // This handles when user taps on notification
    print('Got a message: ${message.notification?.title}');
    // You can add navigation logic here
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    // This handles when app is in foreground
    print('Got a foreground message: ${message.notification?.title}');

    // Display a notification using local notifications
    if (message.notification != null) {
      await _showLocalNotification(
        message.notification!.title ?? 'New Notification',
        message.notification!.body ?? '',
        message.data,
      );
    }
  }

  // Show a local notification
  Future<void> _showLocalNotification(
      String title, String body, Map<String, dynamic> payload) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
    );

    DarwinNotificationDetails iOSPlatformChannelSpecifics =
        const DarwinNotificationDetails();

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload.toString(),
    );
  }

  // Get FCM token for the device
  Future<String?> getToken() async {
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    return token;
  }

  // Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }
  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
  
  // Send a test notification (for admin testing only)
  // In a real application, this would be handled by a server
  Future<void> sendTestNotification({
    required String title,
    required String body,
    String? topic,
    String? token,
    Map<String, dynamic>? extraData,
  }) async {
    // This is just a placeholder as FCM requires a server key
    // In a real application, you would make an HTTP request to your backend
    // which would then use Firebase Admin SDK to send the notification
    
    if (topic != null) {
      // First subscribe to the topic to receive the test notification
      await subscribeToTopic(topic);
      print('Subscribed to topic: $topic for testing');
    }
    
    // Simulate a notification for testing
    if (topic != null || token != null) {
      // For actual implementation, this would come from the server
      // This just simulates the payload structure
      final payload = {
        'notification': {
          'title': title,
          'body': body,
        },
        'data': extraData ?? {},
        'to': topic != null ? '/topics/$topic' : token,
      };
      
      print('Test notification payload: $payload');
      
      // For testing purposes, show a local notification
      await _showLocalNotification(title, body, extraData ?? {});
    }
  }
}