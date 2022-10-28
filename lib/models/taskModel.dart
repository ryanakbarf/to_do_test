class TaskModel {
  final int id;
  final String title;
  final String desc;
  final String pic;
  final String start;
  final String due;
  final String end;
  final int priority;

  TaskModel({
    required this.id,
    required this.title,
    required this.desc,
    required this.pic,
    required this.start,
    required this.due,
    required this.end,
    required this.priority,
  });

  // Convert a Task into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'desc': desc,
      'pic': pic,
      'start': start,
      'due': due,
      'end': end,
      'priority': priority,
    };
  }

  // Implement toString to make it easier to see information about
  // each tast when using the print statement.
  @override
  String toString() {
    return 'Task{id: $id, title: $title, desc: $desc, pic: $pic, start: $start, due: $due, end: $end, priority: $priority}';
  }
}
