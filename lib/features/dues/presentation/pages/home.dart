import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/domain/usecases/get_all_dues.dart'
    show Due;
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_form_controller.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_drawer.dart';
import 'package:myduesapp/features/dues/presentation/widgets/formatters.dart';
import 'package:myduesapp/injection_container.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    this.autoLoadPreview = true,
  });

  final String title;
  final bool autoLoadPreview;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final DueFormController controller;
  late final DueController dueController;

  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _installmentsCtrl = TextEditingController(text: '3');

  DateTime? _startDate;
  List<int> _billingDays = const [];
  bool _loadingBillingDays = true;

  @override
  void initState() {
    super.initState();
    controller = sl<DueFormController>();
    dueController = sl<DueController>();
    _refreshBillingDays();
    if (widget.autoLoadPreview) {
      dueController.fetchDues();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _principalCtrl.dispose();
    _installmentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshBillingDays() async {
    setState(() {
      _loadingBillingDays = true;
    });

    final days = await controller.loadBillingDays();
    if (!mounted) return;

    setState(() {
      _billingDays = days;
      _loadingBillingDays = false;
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([_refreshBillingDays(), dueController.fetchDues()]);
  }

  double _principalAmount() => double.tryParse(_principalCtrl.text.trim()) ?? 0;

  int _installmentCount() => int.tryParse(_installmentsCtrl.text.trim()) ?? 0;

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _startDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: DateTime(now.year + 10, 12, 31),
    );

    if (!mounted) return;
    if (picked == null) return;

    setState(() {
      _startDate = picked;
    });
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_billingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set at least one billing day in Settings first.'),
        ),
      );
      return;
    }

    try {
      await controller.submitSplitDue(
        name: _titleCtrl.text.trim(),
        amount: _principalAmount(),
        installmentCount: _installmentCount(),
        billingDays: _billingDays,
        startDate: _startDate,
      );

      if (!mounted) return;

      _titleCtrl.clear();
      _principalCtrl.clear();
      _installmentsCtrl.text = '3';
      setState(() {
        _startDate = null;
      });

      Navigator.pushReplacementNamed(context, '/overview');
    } catch (_) {
      if (!mounted) return;
      final msg = controller.errorMessage ?? 'Failed to create loan split.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  List<Due> _duePreviewItems() {
    final all = <Due>[];
    for (final month in dueController.dues) {
      all.addAll(month.dues);
    }

    all.sort((a, b) {
      final ad = DateTime.tryParse(a.dueDate ?? '') ?? DateTime(0);
      final bd = DateTime.tryParse(b.dueDate ?? '') ?? DateTime(0);
      final c = ad.compareTo(bd);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });

    return all.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final duesPreview = _duePreviewItems();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Refresh billing days',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh_rounded),
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
        listenable: Listenable.merge([controller, dueController]),
        builder: (context, child) {
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Create loan split',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (controller.isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            key: const Key('titleField'),
                            controller: _titleCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'e.g., Motorcycle loan',
                              prefixIcon: Icon(Icons.title_rounded),
                            ),
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'Title is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('principalField'),
                            controller: _principalCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Principal amount (PHP)',
                              hintText: 'e.g., 5000',
                              prefixIcon: Icon(Icons.payments_rounded),
                            ),
                            validator: (v) {
                              final amt = double.tryParse((v ?? '').trim());
                              if (amt == null || amt <= 0)
                                return 'Enter a valid amount';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: const Key('installmentsField'),
                                  controller: _installmentsCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: false,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Installments',
                                    hintText: 'e.g., 3',
                                    prefixIcon: Icon(
                                      Icons.format_list_numbered_rounded,
                                    ),
                                  ),
                                  validator: (v) {
                                    final n = int.tryParse((v ?? '').trim());
                                    if (n == null || n < 1)
                                      return 'Must be at least 1';
                                    if (n > 120) return 'Too many installments';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickStartDate,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Start date (optional)',
                                      prefixIcon: Icon(Icons.event_rounded),
                                    ),
                                    child: Text(
                                      _startDate == null
                                          ? 'Today'
                                          : formatYmd(_startDate!),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Billing days',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.pushReplacementNamed(
                                  context,
                                  '/settings',
                                ),
                                icon: const Icon(Icons.tune_rounded),
                                label: const Text('Edit'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_loadingBillingDays)
                            const LinearProgressIndicator(minHeight: 3),
                          if (!_loadingBillingDays && _billingDays.isEmpty)
                            Text(
                              'No billing days set. Add at least one in Settings.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          if (!_loadingBillingDays && _billingDays.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final d in _billingDays)
                                  Chip(
                                    label: Text(d.toString()),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: controller.isLoading ? null : _submit,
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              label: const Text('Create'),
                            ),
                          ),
                          if (controller.errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              controller.errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Preview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (duesPreview.isNotEmpty)
                      Text(
                        '${duesPreview.length} items',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (dueController.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                if (duesPreview.isEmpty)
                  Text(
                    'You currently have no dues',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final d in duesPreview)
                          ListTile(
                            dense: true,
                            title: Text(d.name),
                            subtitle: Text(_dueSubtitle(d)),
                            trailing: Text(formatPhp(d.price)),
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

  String _dueSubtitle(Due due) {
    final dt = DateTime.tryParse(due.dueDate ?? '');
    if (dt == null) return 'No due date';

    if (due.installmentIndex != null && due.installmentCount != null) {
      return 'Installment ${due.installmentIndex}/${due.installmentCount} • Due ${formatYmd(dt)}';
    }

    return 'Due ${formatYmd(dt)}';
  }
}
