import 'package:flutter/material.dart';

import 'my_home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    goToHome();
    super.initState();
  }

  void goToHome() async {
    await Future.delayed(const Duration(seconds: 3), (() {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'Flutter TO-DO Test')));
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: const [
          Expanded(
              child: Center(
                  child: Text(
            'Hi!',
            style: TextStyle(fontSize: 100),
          ))),
          Text(
            'This is Demo App is for Code Test.\nMade by Ryan Akbar.',
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}
