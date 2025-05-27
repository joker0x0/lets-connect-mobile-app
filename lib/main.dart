// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/announcement_provider.dart';
import 'services/firebase_service.dart';
import 'services/fcm_service.dart';
import 'routes.dart';
import 'services/navigation_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize FCM service
  final fcmService = FCMService();
  await fcmService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        Provider(create: (_) => FirebaseService()),
        Provider(create: (_) => FCMService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GovConnect',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        navigatorKey: NavigationService.navigatorKey,
        initialRoute: '/',
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
