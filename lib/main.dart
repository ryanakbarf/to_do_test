import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:to_do/pages/my_home_page.dart';
import 'package:to_do/pages/splash.dart';

// This App is made by Ryan Akbar for Coding Test Purpose
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Here I use Cupertino App with auto Theme (Dark/Non) mode used in the device
    // I use imported external library/repo as minimal as it can. Can be checked under pubspec/dependencies. So it should boost this app performance.
    final Brightness platformBrightness =
        WidgetsBinding.instance.window.platformBrightness;
    return Theme(
        data: ThemeData(brightness: platformBrightness),
        child: CupertinoApp(
          title: 'Flutter TO-DO Test',
          theme: CupertinoThemeData(
            brightness: platformBrightness,
          ),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        ));
  }
}
