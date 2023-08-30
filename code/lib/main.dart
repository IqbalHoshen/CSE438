import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import './files/signup.dart';
import './files/driver-home.dart';
import 'package:firebase_auth/firebase_auth.dart';

late FirebaseApp app;
late FirebaseAuth auth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  app = await Firebase.initializeApp();
  auth = FirebaseAuth.instanceFor(app: app);

  //await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(),
        debugShowCheckedModeBanner: false,
        title: 'Base',
        // home: Home(),
        initialRoute: './',
        routes: {
          '/': (context) => signup(),
          //'/home':(context) =>Home(),
          '/driver-home': (context) => BusTrackingScreen()
        });
  }
}
