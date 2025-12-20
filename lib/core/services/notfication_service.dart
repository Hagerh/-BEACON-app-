import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  // Singleton for NotificationService instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permission (Android 13+)
    await _requestNotificationPermission();
    
    _isInitialized = true;
  }

  Future<void> _requestNotificationPermission() async {
  final status = await Permission.notification.status;
  
  if (status.isPermanentlyDenied) {
  
    print('Please enable notifications in Settings');
    await openAppSettings(); // Opens app settings page
    return;
  }

  if (status.isDenied) {
    await Permission.notification.request();
  }
}
  void _onNotificationTapped(NotificationResponse response) {

    
    //payload is a custom string to pass when showing the notification
    print('Notification tapped: ${response.payload}');

    //Todo 
    //Handle navigation or actions based on the payload

  }

  Future<void> showDeviceJoinedNotification({
    required String deviceName,
    required String deviceId,
  }) async {
    const AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
      'beacon_network_channel',  //Groups similar notifications together by channel id
      'Network Alerts',     //channel name
      channelDescription: 'Notifications for network device activities',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      deviceId.hashCode, // Unique ID per device
      ' New Device Connected',
      '$deviceName has joined the network',
      details,
      payload: deviceId,
    );
  }

  // Future<void> showDeviceLeftNotification({
  //   required String deviceName,
  // }) async {
  //   const AndroidNotificationDetails androidDetails = 
  //       AndroidNotificationDetails(
  //     'beacon_network_channel',
  //     'Network Alerts',
  //     importance: Importance.defaultImportance,
  //     priority: Priority.defaultPriority,
  //     playSound: false,
  //   );

  //   const NotificationDetails details = NotificationDetails(
  //     android: androidDetails,
  //   );

  //   await _notifications.show(
  //     DateTime.now().millisecondsSinceEpoch % 100000,
  //     'Device Disconnected',
  //     '$deviceName has left the network',
  //     details,
  //   );
  // }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}