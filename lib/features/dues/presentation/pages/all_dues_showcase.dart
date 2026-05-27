import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/presentation/widgets/app_drawer.dart';
import 'package:myduesapp/features/dues/presentation/widgets/formatters.dart';

class AllDuesShowcasePage extends StatelessWidget {
  const AllDuesShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Dues')),
      drawer: const AppDrawer(current: '/all-dues'),
      body: const SafeArea(child: _AllDuesShowcaseBody()),
    );
  }
}

class _AllDuesShowcaseBody extends StatelessWidget {
  const _AllDuesShowcaseBody();

  @override
  Widget build(BuildContext context) {
    final dues = _mockDues;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'All Dues',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '${dues.length} items',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'A due-level view with total amount, payment progress, and monthly segmentation.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        for (final due in dues) ...[
          _AllDueCard(
            due: due,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => DueOverviewPage(due: due),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class DueOverviewPage extends StatelessWidget {
  final AllDueShowcase due;

  const DueOverviewPage({super.key, required this.due});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topColor = due.isComplete ? Colors.green.shade600 : cs.outlineVariant;

    return Scaffold(
      appBar: AppBar(title: Text(due.title)),
      drawer: const AppDrawer(current: '/all-dues'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 4, color: topColor),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    due.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    due.note,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _StatusChip(due: due),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          formatPhp(due.totalAmount),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${due.paidMonths}/${due.totalMonths} months paid',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          minHeight: 4,
                          value: due.progress,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _InfoPill(
                              label: 'Monthly amount',
                              value: formatPhp(due.monthlyAmount),
                            ),
                            _InfoPill(
                              label: 'Remaining',
                              value: formatPhp(due.remainingAmount),
                            ),
                            _InfoPill(
                              label: 'Start date',
                              value: formatYmd(due.startDate),
                            ),
                            _InfoPill(
                              label: 'Next due',
                              value: formatYmd(due.nextDueDate),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Monthly segmentation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final segment in due.segments) ...[
              _SegmentCard(segment: segment),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _AllDueCard extends StatelessWidget {
  final AllDueShowcase due;
  final VoidCallback onTap;

  const _AllDueCard({required this.due, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final topColor = due.isComplete
        ? Colors.green.shade600
        : Colors.grey.shade400;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 4, color: topColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          due.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StatusChip(due: due),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatPhp(due.totalAmount),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Months to pay',
                          value: '${due.totalMonths}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Metric(
                          label: 'Months paid',
                          value: '${due.paidMonths}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(minHeight: 4, value: due.progress),
                  const SizedBox(height: 8),
                  Text(
                    due.isComplete
                        ? 'Completed'
                        : '${due.remainingMonths} month(s) left',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentCard extends StatelessWidget {
  final MonthlySegment segment;

  const _SegmentCard({required this.segment});

  @override
  Widget build(BuildContext context) {
    final topColor = segment.paid
        ? Colors.green.shade600
        : Colors.grey.shade400;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, color: topColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Month ${segment.monthIndex}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due ${formatYmd(segment.dueDate)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (segment.paidOn != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Paid on ${formatYmd(segment.paidOn!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatPhp(segment.amount)),
                    const SizedBox(height: 4),
                    _StatusChipText(paid: segment.paid),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AllDueShowcase due;

  const _StatusChip({required this.due});

  @override
  Widget build(BuildContext context) {
    final bg = due.isComplete ? Colors.green.shade100 : Colors.grey.shade200;
    final fg = due.isComplete ? Colors.green.shade900 : Colors.grey.shade800;
    final label = due.isComplete ? 'Completed' : 'To pay';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
        ),
      ),
    );
  }
}

class _StatusChipText extends StatelessWidget {
  final bool paid;

  const _StatusChipText({required this.paid});

  @override
  Widget build(BuildContext context) {
    final bg = paid ? Colors.green.shade100 : Colors.grey.shade200;
    final fg = paid ? Colors.green.shade900 : Colors.grey.shade800;
    final label = paid ? 'Paid' : 'Pending';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
        ),
      ),
    );
  }
}

class AllDueShowcase {
  final String id;
  final String title;
  final double totalAmount;
  final int totalMonths;
  final int paidMonths;
  final DateTime startDate;
  final String note;
  final List<MonthlySegment> segments;

  const AllDueShowcase({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.totalMonths,
    required this.paidMonths,
    required this.startDate,
    required this.note,
    required this.segments,
  });

  double get monthlyAmount => totalAmount / totalMonths;

  double get paidAmount => monthlyAmount * paidMonths;

  double get remainingAmount => totalAmount - paidAmount;

  int get remainingMonths =>
      totalMonths > paidMonths ? totalMonths - paidMonths : 0;

  bool get isComplete => paidMonths >= totalMonths;

  double get progress => totalMonths == 0 ? 0 : paidMonths / totalMonths;

  DateTime get nextDueDate {
    for (final segment in segments) {
      if (!segment.paid) return segment.dueDate;
    }
    return segments.isNotEmpty ? segments.last.dueDate : startDate;
  }
}

class MonthlySegment {
  final int monthIndex;
  final DateTime dueDate;
  final double amount;
  final bool paid;
  final DateTime? paidOn;

  const MonthlySegment({
    required this.monthIndex,
    required this.dueDate,
    required this.amount,
    required this.paid,
    this.paidOn,
  });
}

final List<AllDueShowcase> _mockDues = [
  AllDueShowcase(
    id: 'mc-001',
    title: 'Motorcycle loan',
    totalAmount: 5000,
    totalMonths: 5,
    paidMonths: 5,
    startDate: DateTime(2026, 1, 15),
    note: 'Fully settled installment loan for transport.',
    segments: [
      MonthlySegment(
        monthIndex: 1,
        dueDate: DateTime(2026, 1, 15),
        amount: 1000,
        paid: true,
        paidOn: DateTime(2026, 1, 15),
      ),
      MonthlySegment(
        monthIndex: 2,
        dueDate: DateTime(2026, 2, 15),
        amount: 1000,
        paid: true,
        paidOn: DateTime(2026, 2, 14),
      ),
      MonthlySegment(
        monthIndex: 3,
        dueDate: DateTime(2026, 3, 15),
        amount: 1000,
        paid: true,
        paidOn: DateTime(2026, 3, 15),
      ),
      MonthlySegment(
        monthIndex: 4,
        dueDate: DateTime(2026, 4, 15),
        amount: 1000,
        paid: true,
        paidOn: DateTime(2026, 4, 16),
      ),
      MonthlySegment(
        monthIndex: 5,
        dueDate: DateTime(2026, 5, 15),
        amount: 1000,
        paid: true,
        paidOn: DateTime(2026, 5, 15),
      ),
    ],
  ),
  AllDueShowcase(
    id: 'pl-002',
    title: 'Phone plan balance',
    totalAmount: 7200,
    totalMonths: 6,
    paidMonths: 3,
    startDate: DateTime(2026, 2, 5),
    note: 'Ongoing balance with partial payments recorded.',
    segments: [
      MonthlySegment(
        monthIndex: 1,
        dueDate: DateTime(2026, 2, 5),
        amount: 1200,
        paid: true,
        paidOn: DateTime(2026, 2, 5),
      ),
      MonthlySegment(
        monthIndex: 2,
        dueDate: DateTime(2026, 3, 5),
        amount: 1200,
        paid: true,
        paidOn: DateTime(2026, 3, 4),
      ),
      MonthlySegment(
        monthIndex: 3,
        dueDate: DateTime(2026, 4, 5),
        amount: 1200,
        paid: true,
        paidOn: DateTime(2026, 4, 5),
      ),
      MonthlySegment(
        monthIndex: 4,
        dueDate: DateTime(2026, 5, 5),
        amount: 1200,
        paid: false,
      ),
      MonthlySegment(
        monthIndex: 5,
        dueDate: DateTime(2026, 6, 5),
        amount: 1200,
        paid: false,
      ),
      MonthlySegment(
        monthIndex: 6,
        dueDate: DateTime(2026, 7, 5),
        amount: 1200,
        paid: false,
      ),
    ],
  ),
  AllDueShowcase(
    id: 'ed-003',
    title: 'Emergency fund loan',
    totalAmount: 3000,
    totalMonths: 3,
    paidMonths: 1,
    startDate: DateTime(2026, 4, 10),
    note: 'Short-term loan with remaining monthly payments.',
    segments: [
      MonthlySegment(
        monthIndex: 1,
        dueDate: DateTime(2026, 4, 10),
        amount: 1000,
        paid: true,
        paidOn: DateTime(2026, 4, 10),
      ),
      MonthlySegment(
        monthIndex: 2,
        dueDate: DateTime(2026, 5, 10),
        amount: 1000,
        paid: false,
      ),
      MonthlySegment(
        monthIndex: 3,
        dueDate: DateTime(2026, 6, 10),
        amount: 1000,
        paid: false,
      ),
    ],
  ),
];
