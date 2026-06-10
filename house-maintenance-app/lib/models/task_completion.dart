class TaskCompletion {
  final int? id;
  final int taskId;
  final String completedDate;
  final double cost;
  final String notes;

  const TaskCompletion({
    this.id,
    required this.taskId,
    required this.completedDate,
    this.cost = 0.0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'task_id': taskId,
    'completed_date': completedDate,
    'cost': cost,
    'notes': notes,
  };

  factory TaskCompletion.fromMap(Map<String, dynamic> m) => TaskCompletion(
    id: m['id'] as int?,
    taskId: m['task_id'] as int,
    completedDate: m['completed_date'] as String,
    cost: (m['cost'] as num?)?.toDouble() ?? 0.0,
    notes: m['notes'] as String? ?? '',
  );
}
