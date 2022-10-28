import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class Globals {
  static late bool firstUse;
  static bool loading = false;
  static var database;
  static var prefs;

  static void showAlertDialog(BuildContext context, String content) async {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Alert'),
        content: Text(content),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(content == 'Exit App?' ? 'No' : 'Okay'),
          ),
          if (content == 'Exit App?')
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                SystemNavigator.pop();
              },
              child: const Text('Yes'),
            ),
        ],
      ),
    );
  }

  static Future<bool> initDB() async {
    loading = true;
    WidgetsFlutterBinding.ensureInitialized();

    database = openDatabase(
      path.join(await getDatabasesPath(), 'tasks_database2.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY, title TEXT not null, desc TEXT,pic TEXT,start DATE,due DATE,end DATETIME,priority INTEGER)',
        );
      },
      version: 1,
    );
    loading = false;
    return true;
  }

  static Future<int> updateDB(table, colval, condition) async {
    final db = await database;

    String query = 'UPDATE $table SET $colval where $condition';

    await db.rawQuery(query);

    return 1;
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  static final DateFormat formatter = DateFormat('yyyy-MM-dd');
}
