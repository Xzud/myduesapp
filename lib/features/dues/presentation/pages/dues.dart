import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart'
    show Due, MonthlyDue;
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
    for (final d in dues) {
      final key = d.loanId ?? 'single:${d.id}';
      out.putIfAbsent(key, () => []);
      out[key]!.add(d);
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
      dues.isNotEmpty && dues.every((d) => d.paid);

  int _paidCount(List<Due> dues) => dues.where((d) => d.paid).length;

  String _loanTitle(List<Due> dues) {
    if (dues.isEmpty) return '';
    return dues.first.name;
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
                  loanComplete: _loanComplete,
                  paidCount: _paidCount,
                  loanTitle: _loanTitle,
                  onTogglePaid: (id, paid) =>
                      controller.togglePaid(dueId: id, paid: paid),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

typedef TogglePaid = Future<void> Function(int dueId, bool paid);

typedef GroupByLoan = Map<String, List<Due>> Function(List<Due> dues);

typedef LoanComplete = bool Function(List<Due> dues);

typedef PaidCount = int Function(List<Due> dues);

typedef LoanTitle = String Function(List<Due> dues);

class _MonthSection extends StatelessWidget {
  final MonthlyDue month;
  final GroupByLoan groupByLoan;
  final LoanComplete loanComplete;
  final PaidCount paidCount;
  final LoanTitle loanTitle;
  final TogglePaid onTogglePaid;

  const _MonthSection({
    required this.month,
    required this.groupByLoan,
    required this.loanComplete,
    required this.paidCount,
    required this.loanTitle,
    required this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final groups = groupByLoan(month.dues);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(month.month, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final entry in groups.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LoanCard(
                dues: entry.value,
                title: loanTitle(entry.value),
                complete: loanComplete(entry.value),
                paid: paidCount(entry.value),
                total: entry.value.length,
                onTogglePaid: onTogglePaid,
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

  const _LoanCard({
    required this.dues,
    required this.title,
    required this.complete,
    required this.paid,
    required this.total,
    required this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headerColor = complete
        ? cs.primaryContainer
        : cs.surfaceContainerHighest;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: headerColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
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
                Text(
                  '$paid/$total',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            minHeight: 3,
            value: total == 0 ? 0 : paid / total,
          ),
          const SizedBox(height: 4),
          for (final d in dues)
            CheckboxListTile(
              value: d.paid,
              onChanged: d.id <= 0
                  ? null
                  : (v) => onTogglePaid(d.id, v ?? false),
              title: Text(
                d.installmentIndex != null && d.installmentCount != null
                    ? 'Installment ${d.installmentIndex}/${d.installmentCount}'
                    : 'Due',
              ),
              subtitle: Text(_subtitle(d)),
              secondary: Text(formatPhp(d.price)),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
        ],
      ),
    );
  }

  String _subtitle(Due d) {
    final dt = DateTime.tryParse(d.dueDate ?? '');
    if (dt == null) return 'No due date';
    return 'Due ${formatYmd(dt)}';
  }
}
