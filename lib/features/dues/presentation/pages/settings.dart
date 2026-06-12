import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/domain/entities/billing_period_mode.dart';
import 'package:myduesapp/features/dues/presentation/controllers/settings_controller.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_scaffold.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_ui.dart';
import 'package:myduesapp/injection_container.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController controller;
  final TextEditingController dayCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = sl<SettingsController>();
    controller.fetchPaymentDates();
  }

  @override
  void dispose() {
    dayCtrl.dispose();
    super.dispose();
  }

  Future<void> _addDay() async {
    final day = int.tryParse(dayCtrl.text.trim());
    if (day == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a number between 1 and 31.')),
      );
      return;
    }

    await controller.addBillingDay(day);
    if (!mounted) return;

    if (controller.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
      return;
    }

    dayCtrl.clear();
  }

  Future<void> _confirmDeleteAllData() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete all data?'),
          content: const Text(
            'This will permanently delete all dues and settings. This action cannot be undone.',
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
              child: const Text('Delete all data'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await controller.resetData();
    if (!mounted) return;

    if (controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset failed: ${controller.errorMessage}')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All data has been deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      currentRoute: '/settings',
      title: const Text('Settings'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: controller.fetchPaymentDates,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          if (controller.isLoading && controller.billingDays.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null &&
              controller.billingDays.isEmpty) {
            return AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Settings unavailable',
              message: 'Error: ${controller.errorMessage}',
              action: FilledButton.icon(
                onPressed: controller.fetchPaymentDates,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            );
          }

          final days = controller.billingDays;

          return AppListView(
            children: [
              AppSectionHeader(
                title: 'Billing days',
                subtitle:
                    'These are the day(s) of the month used to schedule installment due dates.',
              ),
              const SizedBox(height: 12),
              AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingsInputRow(
                      field: TextField(
                        controller: dayCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Add billing day (1-31)',
                          hintText: 'e.g., 15',
                          prefixIcon: Icon(Icons.calendar_month_rounded),
                        ),
                        onSubmitted: (_) => _addDay(),
                      ),
                      action: FilledButton.icon(
                        onPressed: controller.isLoading ? null : _addDay,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (controller.isLoading)
                      const LinearProgressIndicator(minHeight: 3),
                    if (days.isEmpty)
                      Text(
                        'No billing days yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final d in days)
                            InputChip(
                              label: Text(d.toString()),
                              onDeleted: controller.isLoading
                                  ? null
                                  : () => controller.removeBillingDay(d),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppSectionHeader(
                title: 'Create defaults',
                subtitle:
                    'Choose how loan split billing periods are selected when Create opens.',
              ),
              const SizedBox(height: 12),
              AppSurface(
                child: SegmentedButton<BillingPeriodMode>(
                  segments: const [
                    ButtonSegment(
                      value: BillingPeriodMode.single,
                      label: Text('Single'),
                      icon: Icon(Icons.radio_button_checked_rounded),
                    ),
                    ButtonSegment(
                      value: BillingPeriodMode.multiple,
                      label: Text('Multiple'),
                      icon: Icon(Icons.checklist_rounded),
                    ),
                  ],
                  selected: {controller.defaultBillingPeriodMode},
                  showSelectedIcon: false,
                  onSelectionChanged: controller.isLoading
                      ? null
                      : (selection) {
                          if (selection.isEmpty) return;
                          controller.updateDefaultBillingPeriodMode(
                            selection.first,
                          );
                        },
                ),
              ),
              const SizedBox(height: 20),
              AppSurface(
                side: BorderSide(color: theme.colorScheme.errorContainer),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data reset',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Remove all stored dues and billing-day settings.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const Key('deleteAllDataButton'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      onPressed: controller.isLoading
                          ? null
                          : _confirmDeleteAllData,
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text('Delete all data'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsInputRow extends StatelessWidget {
  final Widget field;
  final Widget action;

  const _SettingsInputRow({required this.field, required this.action});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [field, const SizedBox(height: 12), action],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            const SizedBox(width: 12),
            action,
          ],
        );
      },
    );
  }
}
