import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:to_do/models/taskModel.dart';
import 'package:to_do/pages/add_edit_task.dart';

import '../../globals.dart';

// The Idea of this main page is to make the unlimited swipeable page.
// The next idea is to make task's priority can be changed in main page instead of going to edit page. This is achievable by long press to activate Cupertino context options on task's Card.
// The task's also can be moved to later or earlier date by long press options.

// I added the Person In Charge in the task so User have more information whose task is that for. Even the list of PIC can be updated and grow as long user needed it.

// All the data are stored locally on SQLite. So the fetch and store is SQL compatible.

// Task's Card is equipped with more information after it's name/title, such as how many days its' been overdue, or is it on due date, or is it not been finished for a while. So Users will get more info without needed to open the detail in edit page.

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final GlobalKey _one = GlobalKey();
  final GlobalKey _two = GlobalKey();
  final GlobalKey _three = GlobalKey();
  final GlobalKey _four = GlobalKey();
  bool pageChanging = false;

  final DateTime now = DateTime.now();
  late DateTime currentDate;

  final int _currentIndex = 2;
  late int _newTaskId = -1;

  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  late PageController _pageControllerDate;
  late PageController _pageControllerPage;

  late List<TaskModel> taskList = [];

  List<String> sortBy = ['Default', 'Priority', 'Name'];
  late int sortIndex = 0;

  // Here is the logic of sorting tasks.
  // The default sort is sort the tasks by each Start Date THEN by each Due Date, So the highest order is task that's been overdue, followed by on due date, then by start date.
  // Else user can switch to sort by name or priority
  void changeSort(int index) {
    index < (sortBy.length - 1) ? index += 1 : index = 0;
    sortIndex = index;

    if (index == 0) {
      taskList.sort((a, b) => a.start.compareTo(b.start));
      taskList.sort((a, b) => a.due.compareTo(b.due));
    } else {
      taskList.sort((a, b) => (index == 1)
          ? b.priority.compareTo(a.priority)
          : a.title.compareTo(b.title));
    }
  }

  final List<Color> _colorVariation = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];
  late List<String> picList;

  List<String> dateNavigation() {
    return [
      formatter.format(currentDate.add(const Duration(days: -2))),
      formatter.format(currentDate.add(const Duration(days: -1))),
      formatter.format(currentDate),
      formatter.format(currentDate.add(const Duration(days: 1))),
      formatter.format(currentDate.add(const Duration(days: 2))),
    ];
  }

  String formatedDate(date) {
    if (date == now) {
      return 'Today';
    } else if (date == now.add(const Duration(days: -1))) {
      return 'Yesterday';
    } else if (date == now.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return formatter.format(date);
    }
  }

  @override
  void initState() {
    currentDate = now;
    _pageControllerDate =
        PageController(initialPage: _currentIndex, viewportFraction: .45);
    _pageControllerPage = PageController(initialPage: _currentIndex);

    _initDB();

    super.initState();
  }

  void _initDB() async {
    bool response = await Globals.initDB();
    if (response && taskList.isEmpty) {
      taskList = await tasks(0);
      picList = await getPic();
      setState(() {
        if (Globals.firstUse) {
          ShowCaseWidget.of(context).startShowCase([_one, _two, _three]);
        }
      });
    }
  }

  Future<List<TaskModel>> tasks(int diffDate) async {
    sortIndex = 0;
    DateTime newDate = currentDate.add(Duration(days: diffDate));
    String dateBefore =
        Globals.formatter.format(newDate.add(const Duration(days: -2)));
    String dateAfter =
        Globals.formatter.format(newDate.add(const Duration(days: 2)));

    final db = await Globals.database;

    String query =
        "SELECT * FROM tasks where (start >= '$dateBefore' and start <= '$dateAfter') or (end >= '$dateBefore' and end <= '$dateAfter') or (start < '$dateAfter' and end is null) order by due, start, priority desc, title";
    print(query);

    final List<Map<String, dynamic>> maps = await db.rawQuery(query);

    return List.generate(maps.length, (i) {
      return TaskModel(
          id: maps[i]['id'],
          desc: maps[i]['desc'],
          pic: maps[i]['pic'],
          start: maps[i]['start'],
          due: maps[i]['due'],
          priority: maps[i]['priority'],
          end: (maps[i]['end'] != null) ? maps[i]['end'] : '',
          title: maps[i]['title']);
    });
  }

  Future<List<String>> getPic() async {
    final db = await Globals.database;

    String query = 'SELECT distinct pic FROM tasks';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query);

    return List.generate(maps.length, (i) {
      return maps[i]['pic'];
    });
  }

  Future<int> deleteTask(int id) async {
    final db = await Globals.database;

    var response = await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    return response;
  }

  // Here is the logic to make the unlimited swipeable page.
  // I create 5 pages which initialized to the 3rd page.
  // Each time user swipe the page, App reset the new page to be the 3rd page
  void changeDate(int diffDate) async {
    pageChanging = true;
    taskList = await tasks(diffDate);
    _pageControllerDate.animateToPage(_currentIndex + diffDate,
        duration: const Duration(milliseconds: 190), curve: Curves.ease);
    Future.delayed(const Duration(milliseconds: 200), () async {
      _pageControllerDate.jumpToPage(2);
      _pageControllerPage.jumpToPage(2);
      currentDate = currentDate.add(Duration(days: diffDate));
      setState(() {});
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      pageChanging = false;
    });
  }

  void openAdd(title) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddEditTask(
                id: -1,
                date: currentDate,
                data: TaskModel(
                    id: -1,
                    title: title,
                    desc: '',
                    pic: '',
                    start: '',
                    due: '',
                    end: '',
                    priority: 1),
                picNames: picList,
              )),
    ).then((value) async {
      if (Globals.firstUse) {
        _newTaskId = value;
      } else {
        _newTaskId = -1;
      }
      if (value != null) {
        taskList = await tasks(0);
        picList = await getPic();
        setState(() {
          if (title == "New Task") {
            if (Globals.firstUse) {
              ShowCaseWidget.of(context).startShowCase([_four]);
            }
            Globals.firstUse = false;
          }
          Globals.showAlertDialog(context, 'Task\'s inserted successfully!');
        });
      }
    });
  }

  void changePriority(
      BuildContext context, String content, TaskModel taskListModel) async {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Alert'),
        content: Text(content),
        actions: <CupertinoDialogAction>[
          if (taskListModel.priority > 0)
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.pop(context);
                int resp = await Globals.updateDB(
                    'tasks',
                    "priority=${taskListModel.priority - 1}",
                    "id=${taskListModel.id}");
                if (resp > 0) {
                  taskList = await tasks(0);
                  setState(() {});
                }
              },
              child: const Icon(
                CupertinoIcons.arrow_down_circle,
                color: Colors.green,
              ),
            ),
          if (taskListModel.priority < 2)
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.pop(context);
                int resp = await Globals.updateDB(
                    'tasks',
                    "priority=${taskListModel.priority + 1}",
                    "id=${taskListModel.id}");
                if (resp > 0) {
                  taskList = await tasks(0);
                  setState(() {});
                }
              },
              child: const Icon(
                CupertinoIcons.arrow_up_circle,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageControllerDate.dispose();
    _pageControllerPage.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Center(
          child: Globals.loading
              ? const CupertinoActivityIndicator(
                  radius: 20.0, color: CupertinoColors.activeBlue)
              : Column(
                  children: [
                    IgnorePointer(
                      child: Showcase(
                        key: _one,
                        title: 'Date Header',
                        description:
                            'This is the Date Header for you to see which Date is your tasks on.',
                        child: Container(
                          height: size.height * .05,
                          decoration: BoxDecoration(
                            color: Theme.of(context).backgroundColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: PageView.builder(
                            itemCount: dateNavigation().length,
                            controller: _pageControllerDate,
                            itemBuilder: ((context, index) {
                              return Center(
                                  child: Text(
                                formatedDate(currentDate
                                    .add(Duration(days: (index - 2)))),
                                style: TextStyle(
                                    color: (index - 2 != 0)
                                        ? Theme.of(context).disabledColor
                                        : Theme.of(context).hintColor),
                              ));
                            }),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Showcase(
                        key: _two,
                        title: 'Main Page',
                        description:
                            'This is the main page where all your Task on date is shown, swipe right or left on this area to change the date.',
                        child: PageView.builder(
                          controller: _pageControllerPage,
                          itemCount: 5,
                          onPageChanged: (value) {
                            if (!pageChanging) {
                              int diffDate = value - _currentIndex;
                              changeDate(diffDate);
                            }
                          },
                          itemBuilder: ((context, index) {
                            String currDate = formatter.format(
                                currentDate.add(Duration(days: (index - 2))));

                            bool found = false;
                            int tasksTotal = 0;
                            int tasksCompleted = 0;
                            int diffCurNow = Globals.daysBetween(
                                formatter.parse(currDate), now);
                            for (var element in taskList) {
                              int diffStartCur = Globals.daysBetween(
                                  formatter.parse(element.start),
                                  formatter.parse(currDate));
                              int diffEndCur = (element.end.isNotEmpty)
                                  ? Globals.daysBetween(
                                      formatter.parse(element.end),
                                      formatter.parse(currDate))
                                  : 9999;
                              if (element.start == currDate ||
                                  (diffCurNow >= 0 &&
                                      diffStartCur > 0 &&
                                      element.end.isEmpty) ||
                                  diffEndCur == 0) {
                                found = true;
                                tasksTotal += 1;
                                if (element.end.isNotEmpty) {
                                  tasksCompleted += 1;
                                }
                              }
                            }
                            if (found) {
                              return Card(
                                elevation: 5,
                                color: Theme.of(context).cardColor,
                                child: Column(
                                  children: [
                                    if (diffCurNow == 0)
                                      Card(
                                        elevation: 5,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  "$tasksCompleted/$tasksTotal Tasks' Completed Today"),
                                            ),
                                            TextButton(
                                                onPressed: (() {
                                                  changeSort(sortIndex);
                                                  setState(() {});
                                                }),
                                                child: Text(
                                                    "Sort by ${sortBy[sortIndex]}"))
                                          ],
                                        ),
                                      ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: taskList.length,
                                        itemBuilder: ((context2, index2) {
                                          int diffStartCur =
                                              Globals.daysBetween(
                                                  formatter.parse(
                                                      taskList[index2].start),
                                                  formatter.parse(currDate));
                                          int diffStartNow =
                                              Globals.daysBetween(
                                                  formatter.parse(
                                                      taskList[index2].start),
                                                  now);
                                          int diffDueNow = Globals.daysBetween(
                                              formatter
                                                  .parse(taskList[index2].due),
                                              now);
                                          int diffEndCur =
                                              (taskList[index2].end.isNotEmpty)
                                                  ? Globals.daysBetween(
                                                      formatter.parse(
                                                          taskList[index2].end),
                                                      formatter.parse(currDate))
                                                  : 9999;
                                          if (taskList[index2].start ==
                                                  currDate ||
                                              (diffCurNow >= 0 &&
                                                  diffStartCur > 0 &&
                                                  taskList[index2]
                                                      .end
                                                      .isEmpty) ||
                                              diffEndCur == 0) {
                                            return Showcase(
                                              key: (taskList[index2].id ==
                                                      _newTaskId)
                                                  ? _four
                                                  : GlobalKey(),
                                              title: 'Task Item',
                                              description:
                                                  'Long Press to view options.',
                                              child: CupertinoContextMenu(
                                                actions: [
                                                  if (diffCurNow <= 0)
                                                    CupertinoContextMenuAction(
                                                      onPressed: () async {
                                                        int resp = await Globals
                                                            .updateDB(
                                                                'tasks',
                                                                "end=${taskList[index2].end.isEmpty ? "'${DateTime.now()}'" : null}",
                                                                "id=${taskList[index2].id}");
                                                        if (resp > 0) {
                                                          taskList =
                                                              await tasks(0);
                                                          setState(() {
                                                            Navigator.pop(
                                                                context);
                                                            if (taskList[index2]
                                                                .end
                                                                .isNotEmpty) {
                                                              Globals.showAlertDialog(
                                                                  context,
                                                                  'Great! Task\'s Done!');
                                                            }
                                                          });
                                                        }
                                                      },
                                                      isDefaultAction: true,
                                                      trailingIcon: taskList[
                                                                  index2]
                                                              .end
                                                              .isEmpty
                                                          ? CupertinoIcons
                                                              .checkmark_alt_circle_fill
                                                          : CupertinoIcons
                                                              .clear_circled,
                                                      child: Text(
                                                          taskList[index2]
                                                                  .end
                                                                  .isEmpty
                                                              ? 'Finished'
                                                              : 'Unfinish'),
                                                    ),
                                                  if (diffCurNow <= 0)
                                                    CupertinoContextMenuAction(
                                                      onPressed: () async {
                                                        _newTaskId = -1;
                                                        int resp = await Globals
                                                            .updateDB(
                                                                'tasks',
                                                                "start='${formatter.format(formatter.parse(currDate).add(Duration(days: diffCurNow == 0 ? 1 : -1)))}'",
                                                                "id=${taskList[index2].id}");
                                                        if (resp > 0) {
                                                          taskList =
                                                              await tasks(0);
                                                          setState(() {
                                                            Navigator.pop(
                                                                context);
                                                            Globals.showAlertDialog(
                                                                context,
                                                                'Task\'s moved ${diffCurNow == 0 ? "+1" : "-1"} Day');
                                                          });
                                                        }
                                                      },
                                                      trailingIcon: diffCurNow ==
                                                              0
                                                          ? CupertinoIcons
                                                              .calendar_badge_plus
                                                          : CupertinoIcons
                                                              .calendar_badge_minus,
                                                      child: Text(
                                                          diffCurNow == 0
                                                              ? '+1 Day'
                                                              : '-1 Day'),
                                                    ),
                                                  if (diffCurNow <= 0)
                                                    CupertinoContextMenuAction(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        changePriority(
                                                            context,
                                                            'Change Priority?',
                                                            taskList[index2]);
                                                      },
                                                      trailingIcon: CupertinoIcons
                                                          .arrow_up_arrow_down_circle,
                                                      child: const Text(
                                                          'Priority'),
                                                    ),
                                                  CupertinoContextMenuAction(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    AddEditTask(
                                                                      id: taskList[
                                                                              index2]
                                                                          .id,
                                                                      date:
                                                                          currentDate,
                                                                      data: taskList[
                                                                          index2],
                                                                      picNames:
                                                                          picList,
                                                                    )),
                                                      ).then((value) async {
                                                        if (value != null) {
                                                          taskList =
                                                              await tasks(0);
                                                          picList =
                                                              await getPic();
                                                          setState(() {
                                                            Globals.showAlertDialog(
                                                                context,
                                                                'Task\'s updated successfully!');
                                                          });
                                                        }
                                                      });
                                                    },
                                                    trailingIcon: CupertinoIcons
                                                        .pencil_outline,
                                                    child: const Text('Edit'),
                                                  ),
                                                  if (diffCurNow <= 0)
                                                    CupertinoContextMenuAction(
                                                      onPressed: () async {
                                                        int resp =
                                                            await deleteTask(
                                                                taskList[index2]
                                                                    .id);
                                                        if (resp > 0) {
                                                          taskList =
                                                              await tasks(0);
                                                          setState(() {
                                                            Navigator.pop(
                                                                context);
                                                            Globals.showAlertDialog(
                                                                context,
                                                                'Task\'s deleted successfully!');
                                                          });
                                                        }
                                                      },
                                                      isDestructiveAction: true,
                                                      trailingIcon:
                                                          CupertinoIcons.delete,
                                                      child:
                                                          const Text('Delete'),
                                                    ),
                                                ],
                                                child: Card(
                                                  color: taskList[index2]
                                                              .priority ==
                                                          2
                                                      ? Colors.red[100]
                                                      : taskList[index2]
                                                                  .priority ==
                                                              1
                                                          ? Colors.yellow[100]
                                                          : Colors.green[100],
                                                  child: ListTile(
                                                    leading: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          CupertinoIcons
                                                              .person_alt_circle_fill,
                                                          color: (picList.indexOf(
                                                                      taskList[
                                                                              index2]
                                                                          .pic) <
                                                                  _colorVariation
                                                                      .length)
                                                              ? _colorVariation[
                                                                  picList.indexOf(
                                                                      taskList[
                                                                              index2]
                                                                          .pic)]
                                                              : Colors.grey,
                                                        ),
                                                        Text(
                                                          taskList[index2].pic,
                                                          style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .shadowColor),
                                                        ),
                                                        // Text(diffCurNow.toString())
                                                      ],
                                                    ),
                                                    title: RichText(
                                                      text: TextSpan(
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                            text:
                                                                taskList[index2]
                                                                    .title,
                                                            style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .shadowColor,
                                                                decoration: (diffCurNow <=
                                                                        0)
                                                                    ? TextDecoration
                                                                        .none
                                                                    : TextDecoration
                                                                        .lineThrough,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          if (taskList[index2]
                                                              .end
                                                              .isNotEmpty)
                                                            TextSpan(
                                                                text:
                                                                    " (Finished on ${formatter.format(formatter.parse(taskList[index2].end))})",
                                                                style:
                                                                    TextStyle(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .shadowColor,
                                                                ))
                                                          else if (diffStartNow >
                                                                  0 ||
                                                              diffDueNow >= 0)
                                                            TextSpan(
                                                                text: (diffCurNow >
                                                                        0)
                                                                    ? ' (Unfinished)'
                                                                    : (diffDueNow >
                                                                            0)
                                                                        ? " (It's been Overdue for $diffDueNow day${diffDueNow > 1 ? 's' : ''}!)"
                                                                        : (diffDueNow ==
                                                                                0)
                                                                            ? " (It's Due Date! Let's Go!)"
                                                                            : (diffDueNow < 0 && diffDueNow > -100)
                                                                                ? " (Due on ${formatter.format(formatter.parse(taskList[index2].due))})"
                                                                                : " (It's not finished for $diffStartNow days)",
                                                                style: TextStyle(
                                                                  color: (diffDueNow >
                                                                          0)
                                                                      ? Theme.of(
                                                                              context)
                                                                          .errorColor
                                                                      : (diffDueNow ==
                                                                              0)
                                                                          ? Theme.of(context)
                                                                              .indicatorColor
                                                                          : Theme.of(context)
                                                                              .shadowColor,
                                                                ))
                                                          else if (diffDueNow <
                                                                  0 &&
                                                              diffDueNow > -100)
                                                            TextSpan(
                                                                text:
                                                                    " (Due on ${formatter.format(formatter.parse(taskList[index2].due))})",
                                                                style:
                                                                    TextStyle(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .shadowColor,
                                                                ))
                                                        ],
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                        taskList[index2].desc,
                                                        style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .shadowColor)),
                                                    trailing: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        if (taskList[index2]
                                                            .end
                                                            .isNotEmpty)
                                                          const Icon(
                                                            CupertinoIcons
                                                                .checkmark_alt_circle_fill,
                                                            color: Colors.blue,
                                                          )
                                                        else if (diffStartNow >
                                                                0 ||
                                                            diffDueNow >= 0)
                                                          if (diffCurNow > 0)
                                                            Icon(
                                                              CupertinoIcons
                                                                  .xmark_square_fill,
                                                              color: Colors
                                                                  .red[900],
                                                            )
                                                          else if (diffDueNow >
                                                              0)
                                                            const Icon(
                                                              CupertinoIcons
                                                                  .exclamationmark_octagon_fill,
                                                              color: Colors.red,
                                                            )
                                                          else if (diffDueNow ==
                                                              0)
                                                            const Icon(
                                                              CupertinoIcons
                                                                  .exclamationmark_octagon,
                                                              color: Colors.red,
                                                            )
                                                          else
                                                            const Icon(
                                                              CupertinoIcons
                                                                  .exclamationmark_triangle_fill,
                                                              color:
                                                                  Colors.yellow,
                                                            ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else {
                                            return Container();
                                          }
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return const Card(
                                  child: Center(
                                      child: Text(
                                          "There's no task for this date.")));
                            }
                          }),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Showcase(
                        key: _three,
                        title: 'Add New Task',
                        description: 'Click here to add new task',
                        disposeOnTap: true,
                        onTargetClick: () => openAdd('New Task'),
                        child: CupertinoButton.filled(
                          onPressed: () => openAdd(''),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(CupertinoIcons.add),
                              Text('Add'),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                )),
    );
  }
}
