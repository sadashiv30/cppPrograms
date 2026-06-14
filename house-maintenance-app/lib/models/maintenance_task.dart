class MaintenanceTask {
  final int? id;
  final String title;
  final String itemType; // 'appliance' | 'feature'
  final int itemId;
  final int frequencyDays; // 0 = one-time
  final String lastDone;
  final String nextDue;
  final int priority; // 1=High 2=Medium 3=Low
  final bool completed;
  final String notes;

  const MaintenanceTask({
    this.id,
    required this.title,
    required this.itemType,
    required this.itemId,
    this.frequencyDays = 0,
    this.lastDone = '',
    this.nextDue = '',
    this.priority = 2,
    this.completed = false,
    this.notes = '',
  });

  MaintenanceTask copyWith({
    int? id,
    String? title,
    String? itemType,
    int? itemId,
    int? frequencyDays,
    String? lastDone,
    String? nextDue,
    int? priority,
    bool? completed,
    String? notes,
  }) => MaintenanceTask(
    id: id ?? this.id,
    title: title ?? this.title,
    itemType: itemType ?? this.itemType,
    itemId: itemId ?? this.itemId,
    frequencyDays: frequencyDays ?? this.frequencyDays,
    lastDone: lastDone ?? this.lastDone,
    nextDue: nextDue ?? this.nextDue,
    priority: priority ?? this.priority,
    completed: completed ?? this.completed,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'item_type': itemType,
    'item_id': itemId,
    'frequency_days': frequencyDays,
    'last_done': lastDone,
    'next_due': nextDue,
    'priority': priority,
    'completed': completed ? 1 : 0,
    'notes': notes,
  };

  factory MaintenanceTask.fromMap(Map<String, dynamic> m) => MaintenanceTask(
    id: m['id'] as int?,
    title: m['title'] as String? ?? '',
    itemType: m['item_type'] as String? ?? 'appliance',
    itemId: m['item_id'] as int? ?? 0,
    frequencyDays: m['frequency_days'] as int? ?? 0,
    lastDone: m['last_done'] as String? ?? '',
    nextDue: m['next_due'] as String? ?? '',
    priority: m['priority'] as int? ?? 2,
    completed: (m['completed'] as int? ?? 0) == 1,
    notes: m['notes'] as String? ?? '',
  );

  bool get isOverdue {
    if (completed || nextDue.isEmpty) return false;
    final due = DateTime.tryParse(nextDue);
    return due != null && due.isBefore(DateTime.now());
  }

  bool isDueSoon(int days) {
    if (completed || nextDue.isEmpty) return false;
    final due = DateTime.tryParse(nextDue);
    if (due == null) return false;
    final now = DateTime.now();
    return !due.isBefore(now) && due.isBefore(now.add(Duration(days: days)));
  }

  String get priorityLabel => switch (priority) {
    1 => 'High',
    3 => 'Low',
    _ => 'Medium',
  };
}
