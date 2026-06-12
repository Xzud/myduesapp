import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart'
    show Due;
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';
import 'package:myduesapp/features/dues/presentation/widgets/formatters.dart';
import 'package:myduesapp/injection_container.dart';

class DueDetailPage extends StatefulWidget {
  final List<Due> dues;
  final DueController? controller;

  const DueDetailPage({super.key, required this.dues, this.controller});

  @override
  State<DueDetailPage> createState() => _DueDetailPageState();
}

class _DueDetailPageState extends State<DueDetailPage> {
  late final DueController controller;
  late final List<Due> dues;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? sl<DueController>();
    dues = [...widget.dues]..sort(_compareDues);
  }

  int _compareDues(Due a, Due b) {
    final ad = DateTime.tryParse(a.dueDate ?? '') ?? DateTime(0);
    final bd = DateTime.tryParse(b.dueDate ?? '') ?? DateTime(0);
    final c = ad.compareTo(bd);
    if (c != 0) return c;
    return a.id.compareTo(b.id);
  }

  List<int> get _ids =>
      dues.map((due) => due.id).where((id) => id > 0).toList();

  String get _title => dues.isEmpty ? 'Due details' : dues.first.name;

  int get _paidCount => dues.where((due) => due.paid).length;

  int get _unpaidCount => dues.length - _paidCount;

  double get _totalAmount =>
      dues.fold<double>(0, (sum, due) => sum + due.price);

  double get _paidAmount => dues
      .where((due) => due.paid)
      .fold<double>(0, (sum, due) => sum + due.price);

  double get _remainingAmount => _totalAmount - _paidAmount;

  DateTime? get _nextDueDate {
    final unpaid = dues.where((due) => !due.paid).toList()..sort(_compareDues);
    for (final due in unpaid) {
      final parsed = DateTime.tryParse(due.dueDate ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  Future<void> _setAllPaid(bool paid) async {
    await controller.setDueItemsPaid(_ids, paid);
    if (!mounted) return;

    final message = controller.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    setState(() {
      for (final due in dues) {
        due.paid = paid;
      }
    });
  }

  Future<void> _toggleOne(Due due, bool paid) async {
    await controller.togglePaid(dueId: due.id, paid: paid);
    if (!mounted) return;

    final message = controller.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    setState(() {
      due.paid = paid;
    });
  }

  Future<void> _deleteAll() async {
    final label = dues.length == 1 ? 'this due' : 'this loan';
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete $label?'),
          content: Text(
            dues.length == 1
                ? 'This will permanently delete $_title. This action cannot be undone.'
                : 'This will permanently delete all ${dues.length} installments for $_title. This action cannot be undone.',
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

    await controller.deleteDueItems(_ids);
    if (!mounted) return;

    final message = controller.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    Navigator.pop(context, true);
  }

  Widget _metricCard({
    required BuildContext context,
    required String label,
    required String value,
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.68,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryGrid(BuildContext context) {
    final nextDue = _nextDueDate;
    final nextDueLabel = nextDue == null ? 'All paid' : formatYmd(nextDue);
    final items = [
      ('Total', formatPhp(_totalAmount), Icons.receipt_long_rounded),
      (
        'Remaining',
        formatPhp(_remainingAmount),
        Icons.account_balance_wallet_rounded,
      ),
      (
        'Paid installments',
        '$_paidCount/${dues.length}',
        Icons.check_circle_rounded,
      ),
      ('Next due', nextDueLabel, Icons.event_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 420;
        final width = twoColumns
            ? (constraints.maxWidth - 8) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _metricCard(
                  context: context,
                  label: item.$1,
                  value: item.$2,
                  icon: item.$3,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _actions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: _unpaidCount == 0 || controller.isLoading
              ? null
              : () => _setAllPaid(true),
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Mark all paid'),
        ),
        OutlinedButton.icon(
          onPressed: _paidCount == 0 || controller.isLoading
              ? null
              : () => _setAllPaid(false),
          icon: const Icon(Icons.remove_done_rounded),
          label: const Text('Mark all unpaid'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          onPressed: controller.isLoading ? null : _deleteAll,
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(dues.length == 1 ? 'Delete due' : 'Delete loan'),
        ),
      ],
    );
  }

  Widget _installmentTile(Due due) {
    final theme = Theme.of(context);
    final dueDate = DateTime.tryParse(due.dueDate ?? '');
    final subtitleParts = <String>[
      if (due.installmentIndex != null && due.installmentCount != null)
        'Installment ${due.installmentIndex}/${due.installmentCount}',
      dueDate == null ? 'No due date' : 'Due ${formatYmd(dueDate)}',
      formatPhp(due.price),
    ];

    return CheckboxListTile(
      value: due.paid,
      onChanged: due.id <= 0 || controller.isLoading
          ? null
          : (value) => _toggleOne(due, value ?? false),
      title: Text(
        due.installmentIndex != null && due.installmentCount != null
            ? 'Installment ${due.installmentIndex}/${due.installmentCount}'
            : due.name,
      ),
      subtitle: Text(subtitleParts.join(' • ')),
      secondary: Icon(
        due.paid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        color: due.paid
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.54),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan details')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_unpaidCount unpaid • ${formatPhp(_remainingAmount)} remaining',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _summaryGrid(context),
                const SizedBox(height: 16),
                _actions(context),
                if (controller.isLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(minHeight: 3),
                ],
                const SizedBox(height: 20),
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < dues.length; i++) ...[
                        _installmentTile(dues[i]),
                        if (i != dues.length - 1) const Divider(height: 1),
                      ],
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
