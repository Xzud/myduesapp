import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart'
    show Due, MonthlyDue;
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_drawer.dart';
import 'package:myduesapp/features/dues/presentation/widgets/formatters.dart';
import 'package:myduesapp/injection_container.dart';

class DuesPage extends StatefulWidget {
  const DuesPage({super.key});

  @override
  State<DuesPage> createState() => _DuesPageState();
}

class _DuesPageState extends State<DuesPage> {
  late final DueController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<DueController>();
    controller.fetchDues();
  }

  Map<String, List<Due>> _groupByLoan(List<Due> dues) {
    final out = <String, List<Due>>{};
    for (final due in dues) {
      final key = due.loanId ?? 'single:${due.id}';
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

  Map<int, List<Due>> _groupByBillingDay(List<Due> dues) {
    final out = <int, List<Due>>{};
    for (final due in dues) {
      final key = _billingDayFor(due);
      out.putIfAbsent(key, () => []);
      out[key]!.add(due);
    }

    final entries = out.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in entries) {
      entry.value.sort((a, b) {
        final ad = DateTime.tryParse(a.dueDate ?? '') ?? DateTime(0);
        final bd = DateTime.tryParse(b.dueDate ?? '') ?? DateTime(0);
        final c = ad.compareTo(bd);
        if (c != 0) return c;
        return a.id.compareTo(b.id);
      });
    }

    return Map<int, List<Due>>.fromEntries(entries);
  }

  int _billingDayFor(Due due) {
    if (due.dayOfMonth > 0) return due.dayOfMonth;
    final dt = DateTime.tryParse(due.dueDate ?? '');
    return dt?.day ?? 0;
  }

  bool _loanComplete(List<Due> dues) =>
      dues.isNotEmpty && dues.every((d) => d.paid);

  int _paidCount(List<Due> dues) => dues.where((d) => d.paid).length;

  String _loanTitle(List<Due> dues) {
    if (dues.isEmpty) return '';
    return dues.first.name;
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
      builder: (context) {
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (name.isEmpty || amount == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a valid name and amount.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      context,
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

  Future<void> _deleteDue(Due due) async {
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

    if (shouldDelete != true || !mounted) return;
    await controller.deleteDueItem(due.id);
    if (!mounted) return;
    _showErrorIfAny();
  }

  DueEntity _buildUpdatedEntity(
    Due due, {
    required String name,
    required double amount,
    required bool paid,
  }) {
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
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  void _showErrorIfAny() {
    final message = controller.errorMessage;
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isMonthPaid(MonthlyDue month) =>
      month.dues.isNotEmpty && month.dues.every((due) => due.paid);

  List<MonthlyDue> _monthsByPaidState(List<MonthlyDue> months, bool paid) {
    if (paid) {
      return months.where(_isMonthPaid).toList();
    }
    return months.where((month) => !_isMonthPaid(month)).toList();
  }

  Widget _buildMonthlyList({
    required List<MonthlyDue> months,
    required String emptyMessage,
  }) {
    if (months.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.fetchDues,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: months.length,
        itemBuilder: (context, index) {
          final month = months[index];
          return _MonthSection(
            month: month,
            groupByLoan: _groupByLoan,
            groupByBillingDay: _groupByBillingDay,
            loanComplete: _loanComplete,
            paidCount: _paidCount,
            loanTitle: _loanTitle,
            onTogglePaid: _togglePaid,
            onEditDue: _editDue,
            onDeleteDue: _deleteDue,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.fetchDues,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      drawer: const AppDrawer(current: '/overview'),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }

          final months = controller.dues;
          if (months.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No dues found. Create a loan split from the Create page.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final payableMonths = _monthsByPaidState(months, false);
          final paidMonths = _monthsByPaidState(months, true);

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const SizedBox(height: 8),
                TabBar(
                  tabs: [
                    Tab(text: 'Payable (${payableMonths.length})'),
                    Tab(text: 'Paid (${paidMonths.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildMonthlyList(
                        months: payableMonths,
                        emptyMessage: 'No payable dues right now.',
                      ),
                      _buildMonthlyList(
                        months: paidMonths,
                        emptyMessage: 'No paid dues yet.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

typedef TogglePaid = Future<void> Function(Due due, bool paid);
typedef EditDue = Future<void> Function(Due due);
typedef DeleteDue = Future<void> Function(Due due);
typedef GroupByLoan = Map<String, List<Due>> Function(List<Due> dues);
typedef GroupByBillingDay = Map<int, List<Due>> Function(List<Due> dues);
typedef LoanComplete = bool Function(List<Due> dues);
typedef PaidCount = int Function(List<Due> dues);
typedef LoanTitle = String Function(List<Due> dues);

class _MonthSection extends StatelessWidget {
  final MonthlyDue month;
  final GroupByLoan groupByLoan;
  final GroupByBillingDay groupByBillingDay;
  final LoanComplete loanComplete;
  final PaidCount paidCount;
  final LoanTitle loanTitle;
  final TogglePaid onTogglePaid;
  final EditDue onEditDue;
  final DeleteDue onDeleteDue;

  const _MonthSection({
    required this.month,
    required this.groupByLoan,
    required this.groupByBillingDay,
    required this.loanComplete,
    required this.paidCount,
    required this.loanTitle,
    required this.onTogglePaid,
    required this.onEditDue,
    required this.onDeleteDue,
  });

  double _monthTotal(List<Due> dues) {
    return dues.fold<double>(0, (sum, due) => sum + due.price);
  }

  @override
  Widget build(BuildContext context) {
    final billingGroups = groupByBillingDay(month.dues);
    final total = _monthTotal(month.dues);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  month.month,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total ${formatPhp(total)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in billingGroups.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key > 0 ? 'Billing day ${entry.key}' : 'Billing day',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  for (final loanEntry in groupByLoan(entry.value).entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _LoanCard(
                        dues: loanEntry.value,
                        title: loanTitle(loanEntry.value),
                        complete: loanComplete(loanEntry.value),
                        paid: paidCount(loanEntry.value),
                        total: loanEntry.value.length,
                        onTogglePaid: onTogglePaid,
                        onEditDue: onEditDue,
                        onDeleteDue: onDeleteDue,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final List<Due> dues;
  final String title;
  final bool complete;
  final int paid;
  final int total;
  final TogglePaid onTogglePaid;
  final EditDue onEditDue;
  final DeleteDue onDeleteDue;

  const _LoanCard({
    required this.dues,
    required this.title,
    required this.complete,
    required this.paid,
    required this.total,
    required this.onTogglePaid,
    required this.onEditDue,
    required this.onDeleteDue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < dues.length; index++)
            Opacity(
              opacity: dues[index].paid ? 0.72 : 1,
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                minLeadingWidth: 24,
                onTap: dues[index].id <= 0
                    ? null
                    : () => onTogglePaid(dues[index], !dues[index].paid),
                leading: Checkbox(
                  value: dues[index].paid,
                  onChanged: dues[index].id <= 0
                      ? null
                      : (v) => onTogglePaid(dues[index], v ?? false),
                ),
                title: Text(
                  dues[index].installmentIndex != null &&
                          dues[index].installmentCount != null
                      ? '$title • Installment ${dues[index].installmentIndex}/${dues[index].installmentCount}'
                      : title,
                ),
                subtitle: Text(
                  _subtitle(dues[index], includeGroupSummary: index == 0),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEditDue(dues[index]);
                    } else if (value == 'delete') {
                      onDeleteDue(dues[index]);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _subtitle(Due d, {required bool includeGroupSummary}) {
    final dt = DateTime.tryParse(d.dueDate ?? '');
    final dueDateLabel = dt == null ? 'No due date' : 'Due ${formatYmd(dt)}';
    final amountLabel = 'Installment ${formatPhp(d.price)}';
    if (!includeGroupSummary) {
      return '$dueDateLabel • $amountLabel';
    }
    final status = complete ? 'Fully paid' : 'Not yet';
    return '$status ($paid/$total) • $dueDateLabel • $amountLabel';
  }
}
