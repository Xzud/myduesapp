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

  Widget _statCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 165,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.month,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  formatPhp(summary.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total ${summary.totalCount} • Paid ${summary.paidCount} • Unpaid ${summary.unpaidCount} • Overdue ${summary.overdueCount}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Paid ${formatPhp(summary.paidAmount)} • Unpaid ${formatPhp(summary.unpaidAmount)}',
              style: Theme.of(context).textTheme.bodySmall,
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
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track dues, monitor payment health, and jump into the next create flow.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
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
                _sectionTitle(
                  context,
                  'Counts',
                  trailing: 'Total ${summary.totalCount}',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statCard(
                      context: context,
                      label: 'Paid',
                      value: summary.paidCount.toString(),
                      icon: Icons.check_circle_rounded,
                    ),
                    _statCard(
                      context: context,
                      label: 'Unpaid',
                      value: summary.unpaidCount.toString(),
                      icon: Icons.pending_actions_rounded,
                    ),
                    _statCard(
                      context: context,
                      label: 'Overdue',
                      value: summary.overdueCount.toString(),
                      icon: Icons.warning_rounded,
                    ),
                    _statCard(
                      context: context,
                      label: 'Due today',
                      value: summary.dueTodayCount.toString(),
                      icon: Icons.today_rounded,
                    ),
                    _statCard(
                      context: context,
                      label: 'Upcoming',
                      value: summary.upcomingCount.toString(),
                      icon: Icons.event_available_rounded,
                    ),
                    _statCard(
                      context: context,
                      label: 'Recurring',
                      value: summary.recurringCount.toString(),
                      icon: Icons.autorenew_rounded,
                    ),
                    _statCard(
                      context: context,
                      label: 'One-time',
                      value: summary.oneTimeCount.toString(),
                      icon: Icons.payments_rounded,
                    ),
                    _statCard(
                      context: context,
                      label: 'Complete',
                      value: summary.completeCount.toString(),
                      icon: Icons.verified_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionTitle(context, 'Amounts'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statCard(
                      context: context,
                      label: 'Total amount',
                      value: formatPhp(summary.totalAmount),
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                    _statCard(
                      context: context,
                      label: 'Paid amount',
                      value: formatPhp(summary.paidAmount),
                      icon: Icons.trending_up_rounded,
                    ),
                    _statCard(
                      context: context,
                      label: 'Unpaid amount',
                      value: formatPhp(summary.unpaidAmount),
                      icon: Icons.trending_down_rounded,
                    ),
                    _statCard(
                      context: context,
                      label: 'Overdue amount',
                      value: formatPhp(summary.overdueAmount),
                      icon: Icons.report_rounded,
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
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No monthly analytics yet. Create dues to populate this view.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final monthly in summary.monthlySummaries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _monthlyCard(context, monthly),
                        ),
                    ],
                  ),
                if (summary.totalCount == 0) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                            style: Theme.of(context).textTheme.bodyMedium,
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
