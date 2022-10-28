class TaskCreate {
  final String title;
  final String desc;
  final String pic;
  final String start;
  final String due;
  final int priority;

  TaskCreate({
    required this.title,
    required this.desc,
    required this.pic,
    required this.start,
    required this.due,
    required this.priority,
  });

  // Convert a Task into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'desc': desc,
      'pic': pic,
      'start': start,
      'due': due,
      'priority': priority,
    };
  }

  // Implement toString to make it easier to see information about
  // each tast when using the print statement.
  @override
  String toString() {
    return 'Task{title: $title, desc: $desc, pic: $pic, start: $start, due: $due, priority: $priority}';
  }
}
