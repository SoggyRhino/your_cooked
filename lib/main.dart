import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:your_cooked/firebase_options.dart';
import 'package:your_cooked/services/auth/auth_service.dart';
import 'package:your_cooked/services/profile/profile_service.dart';
import 'package:your_cooked/state/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthenticationService().initialize();
  await ProfileService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: FlexThemeData.light(scheme: FlexScheme.deepBlue),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.deepBlue),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
