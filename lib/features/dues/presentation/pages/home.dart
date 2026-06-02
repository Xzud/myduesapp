import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/domain/entities/dashboard_summary_entity.dart';
import 'package:myduesapp/features/dues/presentation/controllers/dashboard_controller.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_drawer.dart';
import 'package:myduesapp/features/dues/presentation/widgets/formatters.dart';
import 'package:myduesapp/injection_container.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title, this.autoLoadPreview = true});

  final String title;
  final bool autoLoadPreview;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final DashboardController dashboardController;

  @override
  void initState() {
    super.initState();
    dashboardController = sl<DashboardController>();
    if (widget.autoLoadPreview) {
      dashboardController.loadSummary();
    }
  }

  Future<void> _refresh() async {
    await dashboardController.loadSummary();
  }

  Widget _countTile({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 84,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountCard({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountGrid(BuildContext context, DashboardSummary summary) {
    final items = [
      ('Total amount', formatPhp(summary.totalAmount)),
      ('Paid amount', formatPhp(summary.paidAmount)),
      ('Unpaid amount', formatPhp(summary.unpaidAmount)),
      ('Overdue amount', formatPhp(summary.overdueAmount)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 340;
        final cardWidth = twoColumns
            ? (constraints.maxWidth - 8) / 2
            : constraints.maxWidth;

        final cards = [
          for (final item in items)
            SizedBox(
              width: cardWidth,
              child: _amountCard(
                context: context,
                label: item.$1,
                value: item.$2,
              ),
            ),
        ];

        if (!twoColumns) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Wrap(spacing: 8, runSpacing: 8, children: cards);
      },
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String route,
    required bool filled,
  }) {
    if (filled) {
      return FilledButton.icon(
        onPressed: () => Navigator.pushReplacementNamed(context, route),
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => Navigator.pushReplacementNamed(context, route),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, {String? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (trailing != null)
          Text(trailing, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _monthlyCard(BuildContext context, DashboardMonthlySummary summary) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.month,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  formatPhp(summary.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total ${summary.totalCount} • Paid ${summary.paidCount} • Unpaid ${summary.unpaidCount} • Overdue ${summary.overdueCount}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Paid ${formatPhp(summary.paidAmount)} • Unpaid ${formatPhp(summary.unpaidAmount)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Create due',
            onPressed: () => Navigator.pushReplacementNamed(context, '/create'),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/settings'),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      drawer: const AppDrawer(current: '/'),
      body: ListenableBuilder(
        listenable: dashboardController,
        builder: (context, child) {
          final summary = dashboardController.summary;

          if (dashboardController.isLoading &&
              summary == const DashboardSummary.empty()) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboardController.errorMessage != null &&
              summary == const DashboardSummary.empty()) {
            return Center(
              child: Text('Error: ${dashboardController.errorMessage}'),
            );
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.12),
                    ),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track dues, monitor payment health, and jump into the next create flow.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _actionButton(
                            context: context,
                            label: 'Create due',
                            icon: Icons.add_rounded,
                            route: '/create',
                            filled: true,
                          ),
                          _actionButton(
                            context: context,
                            label: 'Overview',
                            icon: Icons.view_list_rounded,
                            route: '/overview',
                            filled: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle(context, 'Amounts'),
                const SizedBox(height: 12),
                _amountGrid(context, summary),
                const SizedBox(height: 20),
                _sectionTitle(
                  context,
                  'Counts',
                  trailing: 'Total ${summary.totalCount}',
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1,
                  children: [
                    _countTile(
                      context: context,
                      label: 'Paid',
                      value: summary.paidCount.toString(),
                    ),
                    _countTile(
                      context: context,
                      label: 'Unpaid',
                      value: summary.unpaidCount.toString(),
                    ),
                    _countTile(
                      context: context,
                      label: 'Overdue',
                      value: summary.overdueCount.toString(),
                    ),
                    _countTile(
                      context: context,
                      label: 'Due today',
                      value: summary.dueTodayCount.toString(),
                    ),
                    _countTile(
                      context: context,
                      label: 'Upcoming',
                      value: summary.upcomingCount.toString(),
                    ),
                    _countTile(
                      context: context,
                      label: 'Recurring',
                      value: summary.recurringCount.toString(),
                    ),
                    _countTile(
                      context: context,
                      label: 'One-time',
                      value: summary.oneTimeCount.toString(),
                    ),
                    _countTile(
                      context: context,
                      label: 'Complete',
                      value: summary.completeCount.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionTitle(
                  context,
                  'Monthly breakdown',
                  trailing: '${summary.monthlySummaries.length} months',
                ),
                const SizedBox(height: 8),
                if (summary.monthlySummaries.isEmpty)
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No monthly analytics yet. Create dues to populate this view.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final monthly in summary.monthlySummaries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _monthlyCard(context, monthly),
                        ),
                    ],
                  ),
                if (summary.totalCount == 0) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You currently have no dues.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first split due to start filling the dashboard.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.72),
                                ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/create',
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create due'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
