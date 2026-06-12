import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/domain/entities/dashboard_summary_entity.dart';
import 'package:myduesapp/features/dues/presentation/controllers/dashboard_controller.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_scaffold.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_ui.dart';
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

    return AppSurface(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              value,
              textAlign: TextAlign.start,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountGrid(BuildContext context, DashboardSummary summary) {
    final items = [
      (
        'Total amount',
        formatPhp(summary.totalAmount),
        Icons.account_balance_wallet_outlined,
        false,
      ),
      (
        'Paid amount',
        formatPhp(summary.paidAmount),
        Icons.verified_outlined,
        false,
      ),
      (
        'Unpaid amount',
        formatPhp(summary.unpaidAmount),
        Icons.payments_outlined,
        true,
      ),
      (
        'Overdue amount',
        formatPhp(summary.overdueAmount),
        Icons.warning_amber_rounded,
        false,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 4
            : constraints.maxWidth >= 460
            ? 2
            : 1;
        final spacing = columns == 1 ? 0.0 : 12.0;
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        final cards = [
          for (final item in items)
            SizedBox(
              width: cardWidth,
              child: AppMetricCard(
                label: item.$1,
                value: item.$2,
                icon: item.$3,
                emphasized: item.$4,
              ),
            ),
        ];

        if (columns == 1) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Wrap(spacing: spacing, runSpacing: 12, children: cards);
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
    return AppSectionHeader(
      title: title,
      trailing: trailing == null
          ? null
          : AppStatusPill(
              label: trailing,
              emphasized: true,
              icon: Icons.stacked_line_chart_rounded,
            ),
    );
  }

  Widget _monthlyCard(BuildContext context, DashboardMonthlySummary summary) {
    final theme = Theme.of(context);

    return AppSurface(
      child: Padding(
        padding: EdgeInsets.zero,
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Paid ${formatPhp(summary.paidAmount)} • Unpaid ${formatPhp(summary.unpaidAmount)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countGrid(BuildContext context, DashboardSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 760
            ? 4
            : constraints.maxWidth >= 520
            ? 3
            : 2;

        return GridView.count(
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: count == 2 ? 1.55 : 1.35,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      currentRoute: '/',
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
      ],
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
            return AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Dashboard unavailable',
              message: 'Error: ${dashboardController.errorMessage}',
              action: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            );
          }

          return AppListView(
            maxWidth: appWideContentMaxWidth,
            children: [
              AppSurface(
                color: theme.colorScheme.primaryContainer,
                side: BorderSide.none,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppStatusPill(
                      label: 'Total ${summary.totalCount}',
                      icon: Icons.receipt_long_rounded,
                      emphasized: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Dashboard',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track dues, monitor payment health, and jump into the next create flow.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.78,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
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
              const SizedBox(height: 22),
              _sectionTitle(context, 'Amounts'),
              const SizedBox(height: 12),
              _amountGrid(context, summary),
              const SizedBox(height: 22),
              _sectionTitle(
                context,
                'Counts',
                trailing: 'Total ${summary.totalCount}',
              ),
              const SizedBox(height: 12),
              _countGrid(context, summary),
              const SizedBox(height: 22),
              _sectionTitle(
                context,
                'Monthly breakdown',
                trailing: '${summary.monthlySummaries.length} months',
              ),
              const SizedBox(height: 12),
              if (summary.monthlySummaries.isEmpty)
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No monthly analytics yet.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create dues to populate this view.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    for (final monthly in summary.monthlySummaries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _monthlyCard(context, monthly),
                      ),
                  ],
                ),
              if (summary.totalCount == 0) ...[
                const SizedBox(height: 10),
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You currently have no dues.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first split due to start filling the dashboard.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/create'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create due'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
