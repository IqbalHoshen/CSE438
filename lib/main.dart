import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:demo8/screen1/run_main_page.dart';
import 'package:demo8/screen1/registation_page.dart';
import 'package:demo8/Theme/theme_pro.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.system,
      theme: Mytheme.lightTheme,
      darkTheme: Mytheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: RegistarPage(),
    );
  }
}
