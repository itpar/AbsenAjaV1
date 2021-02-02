import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:spo_balaesang/network/api.dart';
import 'package:spo_balaesang/repositories/data_repository.dart';
import 'package:spo_balaesang/screen/splash_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'network/api_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  await initializeDateFormatting();
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterConfig.loadEnvVariables();
  Intl.defaultLocale = 'id_ID';

  var initializedSettingsAndroid =
      AndroidInitializationSettings('ic_stat_onesignal_default');
  var initializationSettings =
      InitializationSettings(android: initializedSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => DataRepository(apiService: ApiService(api: API())),
      child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SIAP Balaesang',
          theme: ThemeData(
              primarySwatch: Colors.blue,
              backgroundColor: Colors.white,
              scaffoldBackgroundColor: Colors.grey[100]),
          home: SplashScreen()),
    );
  }
}

Future<void> scheduleAlarm(
    DateTime scheduledNotificationDateTime, String body) async {
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_id', 'alarm_id', 'Channel alarm',
      icon: 'ic_stat_onesignal_default',
      enableVibration: true,
      enableLights: true,
      playSound: true,
      priority: Priority.high,
      importance: Importance.max,
      vibrationPattern: Int64List.fromList([0, 1000, 5000, 2000]));

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Makassar'));

  var scheduleTime = tz.TZDateTime.from(
      scheduledNotificationDateTime, tz.getLocation('Asia/Makassar'));

  var platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    Random().nextInt(pow(2, 31)),
    'Pengingat',
    body,
    scheduleTime,
    platformChannelSpecifics,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    androidAllowWhileIdle: true,
  );
}
