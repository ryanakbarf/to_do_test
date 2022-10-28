import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import 'myHomePage/home_body.dart';
import '../globals.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var ctime;

  @override
  void initState() {
    initSP();

    super.initState();
  }

  void initSP() async {
    Globals.prefs = await SharedPreferences.getInstance();

    Globals.firstUse = Globals.prefs.getBool('firstUse') != null ? false : true;
    if (Globals.firstUse) await Globals.prefs.setBool('firstUse', false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        DateTime now = DateTime.now();
        if (ctime == null ||
            now.difference(ctime) > const Duration(seconds: 2)) {
          ctime = now;
          Globals.showAlertDialog(context, 'Exit App?');
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.title),
        ),
        // Here we apply guide to New User on how to use the app.
        child: ShowCaseWidget(
          onStart: (index, key) {
            log('onStart: $index, $key');
          },
          onComplete: (index, key) {
            log('onComplete: $index, $key');
            if (index == 4) {
              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle.light.copyWith(
                  statusBarIconBrightness: Brightness.dark,
                  statusBarColor: Colors.white,
                ),
              );
            }
          },
          blurValue: 1,
          autoPlayDelay: const Duration(seconds: 3),
          builder: Builder(builder: (context) => const HomeBody()),
        ),
      ),
    );
  }
}
