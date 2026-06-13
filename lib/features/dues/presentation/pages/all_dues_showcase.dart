import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart'
    show Due, MonthlyDue;
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_scaffold.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_ui.dart';
import 'package:myduesapp/features/dues/presentation/widgets/formatters.dart';
import 'package:myduesapp/injection_container.dart';

class AllDuesShowcasePage extends StatefulWidget {
  const AllDuesShowcasePage({super.key});

  @override
  State<AllDuesShowcasePage> createState() => _AllDuesShowcasePageState();
}

class _AllDuesShowcasePageState extends State<AllDuesShowcasePage> {
  late final DueController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<DueController>();
    controller.fetchDues();
  }

  List<Due> _flattenDues(List<MonthlyDue> months) {
    return months.expand((month) => month.dues).toList();
  }

  String _dueGroupKey(Due due) {
    if (due.recurring) {
      return _recurringGroupKey(due);
    }

    final groupId = due.loanId?.trim();
    if (groupId != null && groupId.isNotEmpty) {
      return 'loan:$groupId';
    }

    return 'single:${due.id}';
  }

  String _recurringGroupKey(Due due) {
    final groupId = due.loanId?.trim();
    if (groupId != null && groupId.isNotEmpty) {
      return 'recurring:$groupId';
    }

    final name = due.name.trim().toLowerCase();
    final amount = due.price.toStringAsFixed(2);
    final created = _createdAtGroupKey(due);
    return 'recurring:$name|$amount|${_billingDayFor(due)}|${due.recurringInterval}|$created';
  }

  String _createdAtGroupKey(Due due) {
    final createdAt = due.createdAt?.trim();
    if (createdAt == null || createdAt.isEmpty) {
      return 'legacy';
    }

    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) {
      return createdAt;
    }

    return [
      parsed.year.toString().padLeft(4, '0'),
      parsed.month.toString().padLeft(2, '0'),
      parsed.day.toString().padLeft(2, '0'),
      parsed.hour.toString().padLeft(2, '0'),
      parsed.minute.toString().padLeft(2, '0'),
      parsed.second.toString().padLeft(2, '0'),
    ].join('-');
  }

  Map<String, List<Due>> _groupByLoan(List<Due> dues) {
    final out = <String, List<Due>>{};
    for (final due in dues) {
      final key = _dueGroupKey(due);
      out.putIfAbsent(key, () => []);
      out[key]!.add(due);
    }

    for (final entry in out.entries) {
      entry.value.sort((a, b) {
        final ad = DateTime.tryParse(a.dueDate ?? '') ?? DateTime(0);
        final bd = DateTime.tryParse(b.dueDate ?? '') ?? DateTime(0);
        final c = ad.compareTo(bd);
        if (c != 0) return c;
        return a.id.compareTo(b.id);
      });
    }

    return out;
  }

  int _billingDayFor(Due due) {
    if (due.dayOfMonth > 0) return due.dayOfMonth;
    final dt = DateTime.tryParse(due.dueDate ?? '');
    return dt?.day ?? 0;
  }

  bool _loanComplete(List<Due> dues) =>
      dues.isNotEmpty && dues.every((due) => due.paid);

  int _paidCount(List<Due> dues) => dues.where((due) => due.paid).length;

  int _unpaidCount(List<Due> dues) => dues.where((due) => !due.paid).length;

  bool _isRecurringGroup(List<Due> dues) =>
      dues.isNotEmpty && dues.every((due) => due.recurring);

  String _progressLabel(List<Due> dues) {
    final paid = _paidCount(dues);
    final total = dues.length;
    if (_isRecurringGroup(dues)) {
      return '$paid/$total+';
    }
    return _loanComplete(dues) ? 'Paid' : '$paid/$total';
  }

  String _loanTitle(List<Due> dues) {
    if (dues.isEmpty) return '';
    return dues.first.name;
  }

  double _totalAmount(List<Due> dues) {
    return dues.fold<double>(0, (sum, due) => sum + due.price);
  }

  Future<void> _togglePaid(Due due, bool paid) async {
    await controller.togglePaid(dueId: due.id, paid: paid);
    if (!mounted) return;
    _showErrorIfAny();
  }

  Future<void> _editDue(Due due) async {
    final nameCtrl = TextEditingController(text: due.name);
    final amountCtrl = TextEditingController(
      text: due.price.toStringAsFixed(2),
    );
    bool paid = due.paid;

    final updated = await showDialog<DueEntity>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit due'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: paid,
                      title: const Text('Paid'),
                      onChanged: (value) => setState(() => paid = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (name.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a valid name and amount greater than zero.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      _buildUpdatedEntity(
                        due,
                        name: name,
                        amount: amount,
                        paid: paid,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    amountCtrl.dispose();

    if (!mounted || updated == null) return;
    await controller.updateDueItem(updated);
    if (!mounted) return;
    _showErrorIfAny();
  }

  Future<bool> _deleteDue(Due due) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete due?'),
          content: Text(
            'This will permanently delete ${due.name}. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return false;
    }

    await controller.deleteDueItem(due.id);
    if (!mounted) {
      return false;
    }

    _showErrorIfAny();
    return controller.errorMessage == null;
  }

  Future<bool> _endRecurringPayment(List<Due> dues) async {
    final unpaidIds = dues
        .where((due) => due.recurring && !due.paid && due.id > 0)
        .map((due) => due.id)
        .toList();
    if (unpaidIds.isEmpty) {
      return false;
    }

    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('End recurring payment?'),
          content: Text(
            'This will delete ${unpaidIds.length} unpaid scheduled occurrence(s) for ${_loanTitle(dues)} and keep paid history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('End recurring'),
            ),
          ],
        );
      },
    );

    if (shouldEnd != true || !mounted) {
      return false;
    }

    await controller.deleteDueItems(unpaidIds);
    if (!mounted) {
      return false;
    }

    _showErrorIfAny();
    return controller.errorMessage == null;
  }

  Future<bool> _deleteDueGroup(List<Due> dues) async {
    final validIds = dues
        .where((due) => due.id > 0)
        .map((due) => due.id)
        .toList();
    if (validIds.isEmpty) {
      return false;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete due group?'),
          content: Text(
            'This will permanently delete ${validIds.length} due(s) in this payable segmentation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete all'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return false;
    }

    await controller.deleteDueItems(validIds);
    if (!mounted) {
      return false;
    }

    _showErrorIfAny();
    return controller.errorMessage == null;
  }

  DueEntity _buildUpdatedEntity(
    Due due, {
    required String name,
    required double amount,
    required bool paid,
  }) {
    final now = DateTime.now().toIso8601String();
    return DueEntity(
      id: due.id,
      name: name,
      amount: amount,
      recurring: due.recurring,
      recurringInterval: due.recurringInterval,
      dayOfMonth: due.dayOfMonth,
      loanId: due.loanId,
      installmentIndex: due.installmentIndex,
      installmentCount: due.installmentCount,
      dueDate: due.dueDate,
      paid: paid,
      complete: due.complete,
      createdAt: due.createdAt,
      updatedAt: now,
    );
  }

  void _showErrorIfAny() {
    final message = controller.errorMessage;
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSegmentationSheet({
    required String groupKey,
    required String title,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, child) {
                  final grouped = _groupByLoan(_flattenDues(controller.dues));
                  final dues = grouped[groupKey] ?? <Due>[];

                  if (dues.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text('This due group no longer exists.'),
                        const Spacer(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    );
                  }

                  final paid = _paidCount(dues);
                  final total = dues.length;
                  final complete = _loanComplete(dues);
                  final recurring = _isRecurringGroup(dues);
                  final unpaid = _unpaidCount(dues);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Text(_progressLabel(dues)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        minHeight: 4,
                        value: total == 0 ? 0 : paid / total,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AppStatusPill(
                            label: recurring
                                ? 'Recurring payment'
                                : complete
                                ? 'Fully paid'
                                : 'Not yet complete',
                            icon: recurring
                                ? Icons.repeat_rounded
                                : complete
                                ? Icons.check_circle_outline_rounded
                                : Icons.pending_actions_outlined,
                            emphasized: complete || recurring,
                          ),
                          const Spacer(),
                          Text(
                            formatPhp(_totalAmount(dues)),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: dues.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final due = dues[index];
                            return _SegmentationDueCard(
                              due: due,
                              onTogglePaid: _togglePaid,
                              onEditDue: _editDue,
                              onDeleteDue: _deleteDue,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (recurring) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: unpaid == 0
                                ? null
                                : () async {
                                    final ended = await _endRecurringPayment(
                                      dues,
                                    );
                                    if (ended &&
                                        mounted &&
                                        sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                  },
                            icon: const Icon(Icons.event_busy_rounded),
                            label: const Text('End recurring payment'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final deleted = await _deleteDueGroup(dues);
                            if (deleted && mounted && sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          icon: const Icon(Icons.delete_forever_rounded),
                          label: const Text('Delete Whole Due Group'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: '/all-dues',
      title: const Text('All Dues'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: controller.fetchDues,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          if (controller.isLoading && controller.dues.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null && controller.dues.isEmpty) {
            return AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'All dues unavailable',
              message: 'Error: ${controller.errorMessage}',
              action: FilledButton.icon(
                onPressed: controller.fetchDues,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            );
          }

          final allDues = _flattenDues(controller.dues);
          if (allDues.isEmpty) {
            return AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No dues found yet.',
              message: 'Create dues to see grouped payable segments here.',
              action: FilledButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/create'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create due'),
              ),
            );
          }

          final groupedDues = _groupByLoan(allDues);
          final groupEntries = groupedDues.entries.toList()
            ..sort((a, b) {
              final ad =
                  DateTime.tryParse(a.value.first.dueDate ?? '') ?? DateTime(0);
              final bd =
                  DateTime.tryParse(b.value.first.dueDate ?? '') ?? DateTime(0);
              return ad.compareTo(bd);
            });

          return RefreshIndicator(
            onRefresh: controller.fetchDues,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: appWideContentMaxWidth,
                    ),
                    child: AppSurface(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      side: BorderSide.none,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grouped dues',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${allDues.length} total due(s) across ${groupedDues.length} group(s). Tap a group to open its full payable segmentation.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.78),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final entry in groupEntries) ...[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: appWideContentMaxWidth,
                      ),
                      child: _DueGroupCard(
                        dues: entry.value,
                        title: _loanTitle(entry.value),
                        paid: _paidCount(entry.value),
                        total: entry.value.length,
                        complete: _loanComplete(entry.value),
                        recurring: _isRecurringGroup(entry.value),
                        onTap: () => _openSegmentationSheet(
                          groupKey: entry.key,
                          title: _loanTitle(entry.value),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DueGroupCard extends StatelessWidget {
  final List<Due> dues;
  final String title;
  final int paid;
  final int total;
  final bool complete;
  final bool recurring;
  final VoidCallback onTap;

  const _DueGroupCard({
    required this.dues,
    required this.title,
    required this.paid,
    required this.total,
    required this.complete,
    required this.recurring,
    required this.onTap,
  });

  String get _statusLabel {
    if (recurring) return '$paid/$total+';
    return complete ? 'Paid' : '$paid/$total';
  }

  String _rangeLabel(List<Due> dues) {
    if (dues.isEmpty) return 'No due dates';

    final dates =
        dues
            .map((due) => DateTime.tryParse(due.dueDate ?? ''))
            .whereType<DateTime>()
            .toList()
          ..sort();

    if (dates.isEmpty) return 'No due dates';

    final start = formatYmd(dates.first);
    final end = formatYmd(dates.last);
    if (start == end) return 'Due $start';
    return '$start to $end';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurface(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppStatusPill(
                    label: _statusLabel,
                    icon: recurring
                        ? Icons.repeat_rounded
                        : complete
                        ? Icons.check_circle_outline_rounded
                        : Icons.pending_actions_outlined,
                    emphasized: complete || recurring,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                minHeight: 4,
                borderRadius: BorderRadius.circular(999),
                value: total == 0 ? 0 : paid / total,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _rangeLabel(dues),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef TogglePaid = Future<void> Function(Due due, bool paid);
typedef EditDue = Future<void> Function(Due due);
typedef DeleteDueCallback = Future<bool> Function(Due due);

class _SegmentationDueCard extends StatelessWidget {
  final Due due;
  final TogglePaid onTogglePaid;
  final EditDue onEditDue;
  final DeleteDueCallback onDeleteDue;

  const _SegmentationDueCard({
    required this.due,
    required this.onTogglePaid,
    required this.onEditDue,
    required this.onDeleteDue,
  });

  String _subtitle(Due d) {
    final dt = DateTime.tryParse(d.dueDate ?? '');
    final dueDateLabel = dt == null ? 'No due date' : 'Due ${formatYmd(dt)}';
    if (d.installmentIndex != null && d.installmentCount != null) {
      return 'Installment ${d.installmentIndex}/${d.installmentCount} • $dueDateLabel';
    }
    return dueDateLabel;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurface(
      padding: EdgeInsets.zero,
      child: Opacity(
        opacity: due.paid ? 0.72 : 1,
        child: ListTile(
          onTap: due.id <= 0 ? null : () => onTogglePaid(due, !due.paid),
          leading: Checkbox(
            value: due.paid,
            onChanged: due.id <= 0
                ? null
                : (value) => onTogglePaid(due, value ?? false),
          ),
          title: Text(
            due.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(_subtitle(due)),
          trailing: PopupMenuButton<String>(
            tooltip: 'Due actions',
            onSelected: (value) async {
              if (value == 'edit') {
                await onEditDue(due);
              } else if (value == 'delete') {
                await onDeleteDue(due);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }
}
