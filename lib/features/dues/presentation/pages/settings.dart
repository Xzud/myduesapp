import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/presentation/controllers/settings_controller.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_drawer.dart';
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
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.fetchPaymentDates,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      drawer: const AppDrawer(current: '/settings'),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          if (controller.isLoading && controller.billingDays.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null &&
              controller.billingDays.isEmpty) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }

          final days = controller.billingDays;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Billing days',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'These are the day(s) of the month used to schedule installment due dates.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: dayCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: false,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Add billing day (1-31)',
                                  hintText: 'e.g., 15',
                                  prefixIcon: Icon(
                                    Icons.calendar_month_rounded,
                                  ),
                                ),
                                onSubmitted: (_) => _addDay(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: controller.isLoading ? null : _addDay,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (controller.isLoading)
                          const LinearProgressIndicator(minHeight: 3),
                        if (days.isEmpty)
                          Text(
                            'No billing days yet.',
                            style: Theme.of(context).textTheme.bodyMedium,
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
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('deleteAllDataButton'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: controller.isLoading
                      ? null
                      : _confirmDeleteAllData,
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('Delete all data'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
