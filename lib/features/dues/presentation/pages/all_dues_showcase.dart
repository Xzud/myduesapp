import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart'
    show Due, MonthlyDue;
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_drawer.dart';
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

  String _loanGroupKey(Due due) => due.loanId ?? 'single:${due.id}';

  Map<String, List<Due>> _groupByLoan(List<Due> dues) {
    final out = <String, List<Due>>{};
    for (final due in dues) {
      final key = _loanGroupKey(due);
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

  bool _loanComplete(List<Due> dues) =>
      dues.isNotEmpty && dues.every((due) => due.paid);

  int _paidCount(List<Due> dues) => dues.where((due) => due.paid).length;

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
                    if (name.isEmpty || amount == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a valid name and amount.'),
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
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
                          Text('$paid/$total'),
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
                          Text(
                            complete ? 'Fully paid' : 'Not yet complete',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Text(
                            formatPhp(_totalAmount(dues)),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Top border: green = paid, gray = not yet.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Dues'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.fetchDues,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      drawer: const AppDrawer(current: '/all-dues'),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          if (controller.isLoading && controller.dues.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null && controller.dues.isEmpty) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }

          final allDues = _flattenDues(controller.dues);
          if (allDues.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No dues found yet.'),
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
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grouped dues',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${allDues.length} total due(s) across ${groupedDues.length} group(s). Tap a group to open its full payable segmentation.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final entry in groupEntries) ...[
                  _DueGroupCard(
                    dues: entry.value,
                    title: _loanTitle(entry.value),
                    paid: _paidCount(entry.value),
                    total: entry.value.length,
                    complete: _loanComplete(entry.value),
                    onTap: () => _openSegmentationSheet(
                      groupKey: entry.key,
                      title: _loanTitle(entry.value),
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
  final VoidCallback onTap;

  const _DueGroupCard({
    required this.dues,
    required this.title,
    required this.paid,
    required this.total,
    required this.complete,
    required this.onTap,
  });

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
    final topBorderColor = complete ? Colors.green : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: topBorderColor, width: 4)),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
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
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$paid/$total'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  minHeight: 3,
                  value: total == 0 ? 0 : paid / total,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _rangeLabel(dues),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef TogglePaid = Future<void> Function(Due due, bool paid);
typedef EditDue = Future<void> Function(Due due);
typedef DeleteDue = Future<bool> Function(Due due);

class _SegmentationDueCard extends StatelessWidget {
  final Due due;
  final TogglePaid onTogglePaid;
  final EditDue onEditDue;
  final DeleteDue onDeleteDue;

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
    final topBorderColor = due.paid ? Colors.green : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: topBorderColor, width: 4)),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Checkbox(
            value: due.paid,
            onChanged: due.id <= 0
                ? null
                : (value) => onTogglePaid(due, value ?? false),
          ),
          title: Text(due.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(_subtitle(due)),
          trailing: PopupMenuButton<String>(
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
