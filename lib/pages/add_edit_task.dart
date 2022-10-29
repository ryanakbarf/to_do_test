import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sqflite/sqflite.dart';
import 'package:to_do/globals.dart';
import 'package:to_do/models/taskCreate.dart';
import 'package:to_do/models/taskModel.dart';

// This is the add AND edit page in 1 file.
// The input implement all Cupertino types of inputs.

const double _kItemExtent = 32.0;

class AddEditTask extends StatefulWidget {
  const AddEditTask(
      {super.key,
      required this.id,
      required this.date,
      required this.data,
      required this.picNames});

  final int id;
  final DateTime date;
  final TaskModel data;
  final List<String> picNames;

  @override
  State<AddEditTask> createState() => _AddEditTaskState();
}

class _AddEditTaskState extends State<AddEditTask> {
  final GlobalKey _one = GlobalKey();
  final GlobalKey _two = GlobalKey();
  BuildContext? myContext;

  late final _picNames = widget.picNames;
  bool _loading = false;
  late TextEditingController _textControllerTitle;
  late TextEditingController _textControllerDesc;
  late TextEditingController _textControllerPic;

  late int _pic = 0;
  double _priority = 1.0;

  late DateTime startDate;
  late bool dueDateBool = false;
  late DateTime dueDate = startDate;

  @override
  void initState() {
    _textControllerTitle = TextEditingController();
    _textControllerDesc = TextEditingController();
    _textControllerPic = TextEditingController();

    _textControllerTitle.text =
        Globals.firstUse ? "New Task" : widget.data.title;

    if (_picNames.isEmpty) {
      _picNames.add('Me');
    }
    if (!_picNames.contains('Add New..')) {
      _picNames.add('Add New..');
    }

    if (widget.id > -1) {
      _textControllerDesc.text = widget.data.desc;
      _textControllerPic.text = widget.data.pic;
      _priority = widget.data.priority.toDouble();
      _pic = _picNames.indexOf(widget.data.pic);
      startDate = Globals.formatter.parse(widget.data.start);
      dueDateBool =
          (daysBetween(Globals.formatter.parse(widget.data.due), startDate) <
                  100 &&
              daysBetween(Globals.formatter.parse(widget.data.due), startDate) >
                  -100);
      if (dueDateBool) dueDate = Globals.formatter.parse(widget.data.due);
    } else {
      _textControllerPic.text = _picNames[_pic];
      startDate =
          DateTime(widget.date.year, widget.date.month, widget.date.day);
    }

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Future.delayed(const Duration(milliseconds: 200), () {
        if (Globals.firstUse) {
          ShowCaseWidget.of(myContext!).startShowCase([_one, _two]);
        }
      }),
    );
  }

  // Here is for INSERT NEW TASK
  Future<int> insertTask(TaskCreate task) async {
    _loading = true;

    final db = await Globals.database;

    int id = await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _loading = false;
    return id;
  }

  // Here is for UPDATE EXISTING TASK
  Future<int> updateTask(TaskCreate task) async {
    _loading = true;
    final db = await Globals.database;

    int id = await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [widget.id],
    );
    _loading = false;
    return id;
  }

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => Container(
              height: 216,
              padding: const EdgeInsets.only(top: 6.0),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: child,
              ),
            ));
  }

  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  void saveTask() async {
    if (dueDateBool && dueDate.compareTo(startDate) < 0) {
      return Globals.showAlertDialog(
          context, 'Sorry, Due Date can\'t be lower than Start Date.');
    }
    TaskCreate taskObj = TaskCreate(
      title: _textControllerTitle.text,
      desc: _textControllerDesc.text,
      pic: _textControllerPic.text,
      start: Globals.formatter.format(startDate),
      due: dueDateBool
          ? Globals.formatter.format(dueDate)
          : Globals.formatter.format(DateTime(9999, 0, 0)),
      priority: _priority.toInt(),
    );
    int id;
    if (widget.id < 0) {
      id = await insertTask(taskObj);
    } else {
      id = await updateTask(taskObj);
    }
    if (id > -1) {
      Navigator.pop(context, id);
    }
  }

  @override
  void dispose() {
    _textControllerTitle.dispose();
    _textControllerDesc.dispose();
    _textControllerPic.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('${widget.id < 0 ? 'Add' : 'Edit'} Task'),
        ),
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
          builder: Builder(builder: (context) {
            myContext = context;
            return Center(
              child: _loading
                  ? const CupertinoActivityIndicator(
                      radius: 20.0, color: CupertinoColors.activeBlue)
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(children: [
                            Showcase(
                              key: _one,
                              title: 'Form',
                              description:
                                  'This is the Form for New Task, You can change the title, description, etc.',
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CupertinoTextField(
                                      placeholder: 'Task',
                                      controller: _textControllerTitle,
                                      onChanged: (value) => setState(() {}),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      height: 75,
                                      child: CupertinoTextField(
                                        placeholder: 'Description',
                                        maxLines: 3,
                                        controller: _textControllerDesc,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            const Text('Person In Charge: '),
                                            CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () => _showDialog(
                                                CupertinoPicker(
                                                  scrollController:
                                                      FixedExtentScrollController(
                                                          initialItem: _pic),
                                                  magnification: 1.22,
                                                  squeeze: 1.2,
                                                  useMagnifier: true,
                                                  itemExtent: _kItemExtent,
                                                  onSelectedItemChanged:
                                                      (int selectedItem) {
                                                    setState(() {
                                                      _pic = selectedItem;
                                                      if (_picNames[_pic] !=
                                                          'Add New..') {
                                                        _textControllerPic
                                                                .text =
                                                            _picNames[_pic];
                                                      } else {
                                                        _textControllerPic
                                                            .text = '';
                                                      }
                                                    });
                                                  },
                                                  children:
                                                      List<Widget>.generate(
                                                          _picNames.length,
                                                          (int index) {
                                                    return Center(
                                                      child: Text(
                                                        _picNames[index],
                                                      ),
                                                    );
                                                  }),
                                                ),
                                              ),
                                              child: Text(
                                                _picNames[_pic],
                                                style: const TextStyle(
                                                  fontSize: 22.0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Here is the logic for User to add new PIC if needed
                                        if (_picNames[_pic] == 'Add New..')
                                          Expanded(
                                            child: SizedBox(
                                              height: 30,
                                              child: CupertinoTextField(
                                                placeholder: 'PIC',
                                                maxLines: 3,
                                                controller: _textControllerPic,
                                              ),
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                  _DatePickerItem(
                                    children: <Widget>[
                                      const Text('Start Date'),
                                      CupertinoButton(
                                        onPressed: () => _showDialog(
                                          CupertinoDatePicker(
                                            initialDateTime: startDate,
                                            mode: CupertinoDatePickerMode.date,
                                            use24hFormat: true,
                                            onDateTimeChanged:
                                                (DateTime newDate) {
                                              setState(() {
                                                startDate = newDate;
                                                dueDate = startDate;
                                              });
                                            },
                                          ),
                                        ),
                                        child: Text(
                                          Globals.formatter.format(startDate),
                                          style: const TextStyle(
                                            fontSize: 22.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      CupertinoSwitch(
                                        value: dueDateBool,
                                        thumbColor: CupertinoColors.systemBlue,
                                        trackColor: CupertinoColors.systemRed
                                            .withOpacity(0.14),
                                        activeColor: CupertinoColors.systemRed
                                            .withOpacity(0.64),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            dueDateBool = value!;
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: _DatePickerItem(
                                          children: <Widget>[
                                            const SizedBox(
                                              height: 60,
                                              child: Center(
                                                child: Text('Due Date'),
                                              ),
                                            ),
                                            if (dueDateBool)
                                              CupertinoButton(
                                                onPressed: () => _showDialog(
                                                  CupertinoDatePicker(
                                                    initialDateTime: dueDate,
                                                    mode:
                                                        CupertinoDatePickerMode
                                                            .date,
                                                    use24hFormat: true,
                                                    onDateTimeChanged:
                                                        (DateTime newDate) {
                                                      setState(() {
                                                        dueDate = newDate;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                child: Text(
                                                  Globals.formatter
                                                      .format(dueDate),
                                                  style: const TextStyle(
                                                    fontSize: 22.0,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        const Text('Priority'),
                                        Expanded(
                                          child: CupertinoSlider(
                                            key: const Key('slider'),
                                            value: _priority,
                                            divisions: 2,
                                            max: 2,
                                            activeColor:
                                                CupertinoColors.systemPurple,
                                            thumbColor:
                                                CupertinoColors.systemPurple,
                                            onChanged: (double value) {
                                              setState(() {
                                                _priority = value;
                                              });
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: size.width / 5,
                                          child: Text(
                                            _priority == 0
                                                ? 'Low'
                                                : _priority == 1
                                                    ? 'Normal'
                                                    : 'High',
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: MaterialButton(
                                  color: Colors.red,
                                  textColor: Colors.white,
                                  minWidth: size.width / 2,
                                  height: 50,
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text('Cancel'),
                                    ],
                                  )),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Showcase(
                                key: _two,
                                title: 'Save',
                                description: 'Click Save to add a new task.',
                                disposeOnTap: true,
                                onTargetClick: () => saveTask(),
                                child: CupertinoButton.filled(
                                    onPressed: _textControllerTitle.text.isEmpty
                                        ? null
                                        : () => saveTask(),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(CupertinoIcons.floppy_disk),
                                        Text('Save'),
                                      ],
                                    )),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
            );
          }),
        ));
  }
}

class _DatePickerItem extends StatelessWidget {
  const _DatePickerItem({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.inactiveGray,
            width: 0.0,
          ),
          bottom: BorderSide(
            color: CupertinoColors.inactiveGray,
            width: 0.0,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      ),
    );
  }
}
