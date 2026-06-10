import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/maintenance_task.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';

class TaskTile extends ConsumerWidget {
  final MaintenanceTask task;
  final String itemName;
  final VoidCallback? onTap;

  const TaskTile({
    super.key,
    required this.task,
    required this.itemName,
    this.onTap,
  });

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    double cost = 0;
    final costCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text('Mark Complete', style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 4),
            Text(task.title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            TextField(
              controller: costCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cost (optional)',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    cost = double.tryParse(costCtrl.text) ?? 0;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Done'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(tasksProvider.notifier).complete(
        task,
        DateTime.now(),
        cost: cost,
        notes: noteCtrl.text.trim(),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(tasksProvider.notifier).delete(task.id!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priColor = AppTheme.priorityColor(task.priority);
    final isOverdue = task.isOverdue;
    final cs = Theme.of(context).colorScheme;

    String dueDateLabel = '—';
    if (task.nextDue.isNotEmpty) {
      try {
        final due = DateTime.parse(task.nextDue);
        dueDateLabel = DateFormat('MMM d, y').format(due);
      } catch (_) {
        dueDateLabel = task.nextDue;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        key: ValueKey(task.id),
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (ctx) => task.completed ? null : _complete(ctx, ref),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.check_circle_outline,
              label: 'Done',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (ctx) => _delete(ctx, ref),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Delete',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
            ),
          ],
        ),
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: isOverdue ? AppTheme.overdueColor : priColor,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  decoration: task.completed ? TextDecoration.lineThrough : null,
                                  color: task.completed ? cs.onSurface.withOpacity(0.5) : null,
                                ),
                              ),
                            ),
                            if (isOverdue)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.overdueColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.overdueColor.withOpacity(0.3)),
                                ),
                                child: Text('OVERDUE',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.overdueColor)),
                              ),
                          ]),
                          const SizedBox(height: 4),
                          Text(itemName,
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 12,
                                color: isOverdue
                                    ? AppTheme.overdueColor
                                    : cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              dueDateLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isOverdue
                                    ? AppTheme.overdueColor
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: priColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                AppTheme.priorityLabel(task.priority),
                                style: TextStyle(fontSize: 11, color: priColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (task.frequencyDays > 0)
                              Text(
                                'Every ${task.frequencyDays}d',
                                style: Theme.of(context).textTheme.labelSmall,
                              )
                            else
                              Text('One-time',
                                  style: Theme.of(context).textTheme.labelSmall),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
