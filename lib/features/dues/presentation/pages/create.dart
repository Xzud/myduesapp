import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart'
    show Due;
import 'package:myduesapp/features/dues/domain/entities/billing_period_mode.dart';
import 'package:myduesapp/features/dues/domain/entities/interest_plan.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_form_controller.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_scaffold.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_ui.dart';
import 'package:myduesapp/features/dues/presentation/widgets/formatters.dart';
import 'package:myduesapp/injection_container.dart';

enum _CreateDueMode { loanSplit, recurringBill }

class CreatePage extends StatefulWidget {
  const CreatePage({
    super.key,
    required this.title,
    this.autoLoadPreview = true,
  });

  final String title;
  final bool autoLoadPreview;

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  late final DueFormController controller;
  late final DueController dueController;

  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();
  final _installmentsCtrl = TextEditingController(text: '3');
  final _recurringIntervalCtrl = TextEditingController(text: '1');
  final _occurrencesCtrl = TextEditingController(text: '12');

  _CreateDueMode? _createMode;
  AmountInputMode _amountMode = AmountInputMode.principal;
  bool _includeInterest = false;
  InterestMode _interestMode = InterestMode.percentage;
  DateTime? _startDate;
  List<int> _billingDays = const [];
  final Set<int> _selectedBillingDays = <int>{};
  BillingPeriodMode _billingPeriodSelectionMode = BillingPeriodMode.single;
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
    _amountCtrl.dispose();
    _interestCtrl.dispose();
    _installmentsCtrl.dispose();
    _recurringIntervalCtrl.dispose();
    _occurrencesCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshBillingDays() async {
    setState(() {
      _loadingBillingDays = true;
    });

    final days = await controller.loadBillingDays();
    final defaultMode = await controller.loadDefaultBillingPeriodMode();
    if (!mounted) return;

    setState(() {
      _billingDays = days;
      _billingPeriodSelectionMode = defaultMode;
      _syncSelectedBillingDays(days);
      _loadingBillingDays = false;
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([_refreshBillingDays(), dueController.fetchDues()]);
  }

  double _amountValue() => double.tryParse(_amountCtrl.text.trim()) ?? 0;

  int _installmentCount() => int.tryParse(_installmentsCtrl.text.trim()) ?? 0;

  int _recurringInterval() =>
      int.tryParse(_recurringIntervalCtrl.text.trim()) ?? 0;

  int _occurrenceCount() => int.tryParse(_occurrencesCtrl.text.trim()) ?? 0;

  List<int> _selectedBillingDaysList() {
    final selected = _selectedBillingDays.toList()..sort();
    return selected;
  }

  int? _selectedBillingDay() {
    final selected = _selectedBillingDaysList();
    if (selected.isNotEmpty) return selected.first;
    if (_billingDays.isNotEmpty) return _billingDays.first;
    return null;
  }

  String _billingPeriodSummary() {
    final selected = _selectedBillingDaysList();
    if (selected.isEmpty) return 'Select at least one billing period.';
    if (_billingPeriodSelectionMode == BillingPeriodMode.single ||
        selected.length == 1) {
      return 'Selected period: ${selected.first}';
    }

    return 'Selected periods: ${selected.join(', ')}';
  }

  String _billingPeriodDescription() {
    switch (_billingPeriodSelectionMode) {
      case BillingPeriodMode.single:
        return 'Choose one billing period to populate due dates.';
      case BillingPeriodMode.multiple:
        return 'Choose one or more billing periods to cycle through.';
    }
  }

  void _syncSelectedBillingDays(List<int> days) {
    final available = days.toSet().toList()..sort();
    final preserved = _selectedBillingDays.where(available.contains).toSet();

    if (preserved.isEmpty && available.isNotEmpty) {
      if (_createMode == _CreateDueMode.recurringBill ||
          _billingPeriodSelectionMode == BillingPeriodMode.single) {
        preserved.add(available.first);
      } else {
        preserved.addAll(available);
      }
    }

    _selectedBillingDays
      ..clear()
      ..addAll(preserved);
  }

  void _selectBillingDay(int day) {
    setState(() {
      if (_billingPeriodSelectionMode == BillingPeriodMode.single) {
        _selectedBillingDays
          ..clear()
          ..add(day);
        return;
      }

      if (_selectedBillingDays.contains(day)) {
        _selectedBillingDays.remove(day);
      } else {
        _selectedBillingDays.add(day);
      }
    });
  }

  void _selectSingleBillingDay(int day) {
    setState(() {
      _selectedBillingDays
        ..clear()
        ..add(day);
    });
  }

  void _changeCreateMode(_CreateDueMode mode) {
    setState(() {
      _createMode = mode;
      if (mode == _CreateDueMode.recurringBill) {
        final selected = _selectedBillingDay();
        _selectedBillingDays.clear();
        if (selected != null) {
          _selectedBillingDays.add(selected);
        }
      } else if (_billingDays.isNotEmpty) {
        final selected = _selectedBillingDay();
        _selectedBillingDays.clear();
        if (_billingPeriodSelectionMode == BillingPeriodMode.single) {
          _selectedBillingDays.add(selected ?? _billingDays.first);
        } else {
          _selectedBillingDays.addAll(_billingDays);
        }
      }
    });
  }

  void _clearCreateMode() {
    setState(() {
      _createMode = null;
    });
  }

  String _createModeTitle() {
    switch (_createMode) {
      case _CreateDueMode.loanSplit:
        return 'Create loan split';
      case _CreateDueMode.recurringBill:
        return 'Create recurring bill';
      case null:
        return 'Create due';
    }
  }

  String _interestLabel() {
    switch (_interestMode) {
      case InterestMode.percentage:
        return 'Interest percentage (%)';
      case InterestMode.monthlyFixedAmount:
        return 'Monthly interest amount (PHP)';
      case InterestMode.totalAmountDividedPerMonth:
        return 'Total interest amount (PHP)';
    }
  }

  String _interestHint() {
    switch (_interestMode) {
      case InterestMode.percentage:
        return 'e.g., 10';
      case InterestMode.monthlyFixedAmount:
        return 'e.g., 500';
      case InterestMode.totalAmountDividedPerMonth:
        return 'e.g., 1500';
    }
  }

  String? _interestHelperText() {
    if (!_includeInterest) return null;

    switch (_interestMode) {
      case InterestMode.percentage:
        return 'Applied to the principal before splitting.';
      case InterestMode.monthlyFixedAmount:
        return 'Added to every installment.';
      case InterestMode.totalAmountDividedPerMonth:
        return 'Divided evenly across installments.';
    }
  }

  IconData _interestIcon() {
    switch (_interestMode) {
      case InterestMode.percentage:
        return Icons.percent_rounded;
      case InterestMode.monthlyFixedAmount:
      case InterestMode.totalAmountDividedPerMonth:
        return Icons.payments_rounded;
    }
  }

  InterestPlan? _buildInterestPlan() {
    if (!_includeInterest) return null;

    final value = double.tryParse(_interestCtrl.text.trim());
    if (value == null || value <= 0) return null;

    return InterestPlan(mode: _interestMode, value: value);
  }

  void _changeBillingPeriodMode(BillingPeriodMode mode) {
    setState(() {
      _billingPeriodSelectionMode = mode;

      if (_billingDays.isEmpty) {
        _selectedBillingDays.clear();
        return;
      }

      final current = _selectedBillingDaysList();
      if (mode == BillingPeriodMode.single) {
        final next = current.isNotEmpty ? current.first : _billingDays.first;
        _selectedBillingDays
          ..clear()
          ..add(next);
      } else if (_selectedBillingDays.isEmpty) {
        _selectedBillingDays.addAll(_billingDays);
      }
    });
  }

  Widget _buildBillingDayChip(int day) {
    final selected = _selectedBillingDays.contains(day);
    if (_billingPeriodSelectionMode == BillingPeriodMode.single) {
      return ChoiceChip(
        key: Key('billingPeriodSelectionChip_$day'),
        label: Text(day.toString()),
        selected: selected,
        onSelected: (isSelected) {
          if (isSelected) {
            _selectBillingDay(day);
          }
        },
      );
    }

    return FilterChip(
      key: Key('billingPeriodSelectionChip_$day'),
      label: Text(day.toString()),
      selected: selected,
      onSelected: (_) => _selectBillingDay(day),
    );
  }

  String _amountLabel() {
    if (_createMode == _CreateDueMode.recurringBill) {
      return 'Amount (PHP)';
    }

    return _amountMode == AmountInputMode.monthly
        ? 'Monthly amount to pay (PHP)'
        : 'Principal amount (PHP)';
  }

  String _amountHint() {
    if (_createMode == _CreateDueMode.recurringBill) {
      return 'e.g., 2500';
    }

    return _amountMode == AmountInputMode.monthly ? 'e.g., 1500' : 'e.g., 5000';
  }

  String? _amountHelperText() {
    if (_createMode == _CreateDueMode.recurringBill) {
      return null;
    }

    if (_amountMode == AmountInputMode.monthly) {
      return 'The total loan will be computed from the monthly amount and installments.';
    }
    return null;
  }

  IconData _amountIcon() {
    if (_createMode == _CreateDueMode.recurringBill) {
      return Icons.receipt_long_rounded;
    }

    return _amountMode == AmountInputMode.monthly
        ? Icons.calendar_month_rounded
        : Icons.payments_rounded;
  }

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
    if (_createMode == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a due type first.')));
      return;
    }

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

    if (_createMode == _CreateDueMode.recurringBill) {
      await _submitRecurringBill();
      return;
    }

    await _submitLoanSplit();
  }

  Future<void> _submitLoanSplit() async {
    final selectedBillingDays = _selectedBillingDaysList();
    if (selectedBillingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one billing period.')),
      );
      return;
    }

    try {
      await controller.submitSplitDue(
        name: _titleCtrl.text.trim(),
        inputAmount: _amountValue(),
        installmentCount: _installmentCount(),
        billingDays: selectedBillingDays,
        startDate: _startDate,
        amountMode: _amountMode,
        interestPlan: _buildInterestPlan(),
      );

      if (!mounted) return;

      _resetForm();

      Navigator.pushReplacementNamed(context, '/overview');
    } catch (_) {
      if (!mounted) return;
      final msg = controller.errorMessage ?? 'Failed to create loan split.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _submitRecurringBill() async {
    final selectedBillingDay = _selectedBillingDay();
    if (selectedBillingDay == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a billing day.')));
      return;
    }

    try {
      await controller.submitRecurringDue(
        name: _titleCtrl.text.trim(),
        inputAmount: _amountValue(),
        billingDay: selectedBillingDay,
        recurringInterval: _recurringInterval(),
        occurrenceCount: _occurrenceCount(),
        startDate: _startDate,
      );

      if (!mounted) return;

      _resetForm();

      Navigator.pushReplacementNamed(context, '/overview');
    } catch (_) {
      if (!mounted) return;
      final msg = controller.errorMessage ?? 'Failed to create recurring bill.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _resetForm() {
    _titleCtrl.clear();
    _amountCtrl.clear();
    _interestCtrl.clear();
    _installmentsCtrl.text = '3';
    _recurringIntervalCtrl.text = '1';
    _occurrencesCtrl.text = '12';
    setState(() {
      _createMode = null;
      _amountMode = AmountInputMode.principal;
      _includeInterest = false;
      _interestMode = InterestMode.percentage;
      _startDate = null;
      _syncSelectedBillingDays(_billingDays);
    });
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
    final theme = Theme.of(context);

    return AppScaffold(
      currentRoute: '/create',
      title: Text(widget.title),
      actions: [
        IconButton(
          tooltip: 'Refresh billing days',
          onPressed: _refreshAll,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
      body: ListenableBuilder(
        listenable: Listenable.merge([controller, dueController]),
        builder: (context, child) {
          return AppListView(
            maxWidth: appWideContentMaxWidth,
            children: [
              AppSurface(
                color: theme.colorScheme.primaryContainer,
                side: BorderSide.none,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _createModeTitle(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (controller.isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_createMode == null)
                _DueTypeChooser(onSelected: _changeCreateMode)
              else ...[
                _SelectedDueTypeHeader(
                  mode: _createMode!,
                  onChangeType: _clearCreateMode,
                ),
                const SizedBox(height: 12),
                AppSurface(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          key: const Key('titleField'),
                          controller: _titleCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            hintText: _createMode == _CreateDueMode.loanSplit
                                ? 'e.g., Motorcycle loan'
                                : 'e.g., Internet bill',
                            prefixIcon: const Icon(Icons.title_rounded),
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return 'Title is required';
                            return null;
                          },
                        ),
                        if (_createMode == _CreateDueMode.loanSplit) ...[
                          const SizedBox(height: 12),
                          SegmentedButton<AmountInputMode>(
                            segments: const [
                              ButtonSegment(
                                value: AmountInputMode.principal,
                                label: Text('Principal'),
                              ),
                              ButtonSegment(
                                value: AmountInputMode.monthly,
                                label: Text('Monthly'),
                              ),
                            ],
                            selected: {_amountMode},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) {
                              if (selection.isEmpty) return;
                              setState(() {
                                _amountMode = selection.first;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('amountField'),
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: _amountLabel(),
                            hintText: _amountHint(),
                            helperText: _amountHelperText(),
                            prefixIcon: Icon(_amountIcon()),
                          ),
                          validator: (v) {
                            final amt = double.tryParse((v ?? '').trim());
                            if (amt == null || amt <= 0) {
                              return 'Enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        if (_createMode == _CreateDueMode.loanSplit) ...[
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Include Interest'),
                            value: _includeInterest,
                            onChanged: (value) {
                              setState(() {
                                _includeInterest = value;
                              });
                            },
                          ),
                          if (_includeInterest) ...[
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SegmentedButton<InterestMode>(
                                segments: const [
                                  ButtonSegment(
                                    value: InterestMode.percentage,
                                    label: Text('Percentage'),
                                  ),
                                  ButtonSegment(
                                    value: InterestMode.monthlyFixedAmount,
                                    label: Text('Monthly fixed'),
                                  ),
                                  ButtonSegment(
                                    value:
                                        InterestMode.totalAmountDividedPerMonth,
                                    label: Text('Total interest'),
                                  ),
                                ],
                                selected: {_interestMode},
                                showSelectedIcon: false,
                                onSelectionChanged: (selection) {
                                  if (selection.isEmpty) return;
                                  setState(() {
                                    _interestMode = selection.first;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('interestField'),
                              controller: _interestCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: _interestLabel(),
                                hintText: _interestHint(),
                                helperText: _interestHelperText(),
                                prefixIcon: Icon(_interestIcon()),
                              ),
                              validator: (v) {
                                final value = double.tryParse((v ?? '').trim());
                                if (!_includeInterest) return null;
                                if (value == null || value <= 0) {
                                  return 'Enter a valid interest value';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                        const SizedBox(height: 12),
                        if (_createMode == _CreateDueMode.loanSplit)
                          _TwoColumnFields(
                            first: TextFormField(
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
                                if (n == null || n < 1) {
                                  return 'Must be at least 1';
                                }
                                if (n > 120) {
                                  return 'Too many installments';
                                }
                                return null;
                              },
                            ),
                            second: _StartDateField(
                              startDate: _startDate,
                              onTap: _pickStartDate,
                            ),
                          )
                        else ...[
                          _TwoColumnFields(
                            first: TextFormField(
                              key: const Key('recurringIntervalField'),
                              controller: _recurringIntervalCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Interval (months)',
                                hintText: 'e.g., 1',
                                prefixIcon: Icon(Icons.repeat_rounded),
                              ),
                              validator: (v) {
                                final n = int.tryParse((v ?? '').trim());
                                if (n == null || n < 1) {
                                  return 'Must be at least 1';
                                }
                                if (n > 120) return 'Too large';
                                return null;
                              },
                            ),
                            second: TextFormField(
                              key: const Key('occurrencesField'),
                              controller: _occurrencesCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Occurrences',
                                hintText: 'e.g., 12',
                                prefixIcon: Icon(
                                  Icons.format_list_numbered_rounded,
                                ),
                              ),
                              validator: (v) {
                                final n = int.tryParse((v ?? '').trim());
                                if (n == null || n < 1) {
                                  return 'Must be at least 1';
                                }
                                if (n > 120) {
                                  return 'Too many occurrences';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _StartDateField(
                            startDate: _startDate,
                            onTap: _pickStartDate,
                          ),
                        ],
                        if (_loadingBillingDays) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(minHeight: 3),
                        ],
                        if (!_loadingBillingDays && _billingDays.isEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Set at least one billing day in Settings first.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        if (_createMode == _CreateDueMode.loanSplit) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Billing period selection',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<BillingPeriodMode>(
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
                            selected: {_billingPeriodSelectionMode},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) {
                              if (selection.isEmpty) return;
                              _changeBillingPeriodMode(selection.first);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _billingPeriodDescription(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!_loadingBillingDays && _billingDays.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final d in _billingDays)
                                  _buildBillingDayChip(d),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Text(
                            _billingPeriodSummary(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          Text(
                            'Recurring billing day',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose the day to use for each generated due.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!_loadingBillingDays && _billingDays.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final d in _billingDays)
                                  ChoiceChip(
                                    key: Key('recurringBillingDayChip_$d'),
                                    label: Text(d.toString()),
                                    selected: _selectedBillingDay() == d,
                                    onSelected: (selected) {
                                      if (selected) {
                                        _selectSingleBillingDay(d);
                                      }
                                    },
                                  ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedBillingDay() == null
                                ? 'Select a billing day.'
                                : 'Selected billing day: ${_selectedBillingDay()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: controller.isLoading ? null : _submit,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('Create'),
                          ),
                        ),
                        if (controller.errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            controller.errorMessage!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              AppSectionHeader(
                title: 'Preview',
                trailing: duesPreview.isEmpty
                    ? null
                    : AppStatusPill(label: '${duesPreview.length} items'),
              ),
              const SizedBox(height: 10),
              if (dueController.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              if (duesPreview.isEmpty)
                AppSurface(
                  child: Text(
                    'You currently have no dues',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                AppSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final d in duesPreview)
                        ListTile(
                          dense: true,
                          title: Text(
                            d.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(_dueSubtitle(d)),
                          trailing: Text(formatPhp(d.price)),
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

  String _dueSubtitle(Due due) {
    final dt = DateTime.tryParse(due.dueDate ?? '');
    if (dt == null) return 'No due date';

    if (due.installmentIndex != null && due.installmentCount != null) {
      return 'Installment ${due.installmentIndex}/${due.installmentCount} • Due ${formatYmd(dt)}';
    }

    return 'Due ${formatYmd(dt)}';
  }
}

class _DueTypeChooser extends StatelessWidget {
  final ValueChanged<_CreateDueMode> onSelected;

  const _DueTypeChooser({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final options = [
          _DueTypeOption(
            key: const Key('loanSplitTypeOption'),
            icon: Icons.splitscreen_rounded,
            title: 'Loan split',
            description: 'Installments across one or more billing periods',
            onTap: () => onSelected(_CreateDueMode.loanSplit),
          ),
          _DueTypeOption(
            key: const Key('recurringBillTypeOption'),
            icon: Icons.repeat_rounded,
            title: 'Recurring bill',
            description: 'Repeating payments on one billing day',
            onTap: () => onSelected(_CreateDueMode.recurringBill),
          ),
        ];

        if (constraints.maxWidth < 640) {
          return Column(
            children: [options.first, const SizedBox(height: 12), options.last],
          );
        }

        return Row(
          children: [
            Expanded(child: options.first),
            const SizedBox(width: 12),
            Expanded(child: options.last),
          ],
        );
      },
    );
  }
}

class _DueTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _DueTypeOption({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDueTypeHeader extends StatelessWidget {
  final _CreateDueMode mode;
  final VoidCallback onChangeType;

  const _SelectedDueTypeHeader({
    required this.mode,
    required this.onChangeType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoanSplit = mode == _CreateDueMode.loanSplit;

    return AppSurface(
      child: Row(
        children: [
          Icon(
            isLoanSplit ? Icons.splitscreen_rounded : Icons.repeat_rounded,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isLoanSplit ? 'Loan split' : 'Recurring bill',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          OutlinedButton.icon(
            key: const Key('changeDueTypeButton'),
            onPressed: onChangeType,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Change type'),
          ),
        ],
      ),
    );
  }
}

class _TwoColumnFields extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _TwoColumnFields({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(children: [first, const SizedBox(height: 12), second]);
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _StartDateField extends StatelessWidget {
  final DateTime? startDate;
  final VoidCallback onTap;

  const _StartDateField({required this.startDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Start date (optional)',
          prefixIcon: Icon(Icons.event_rounded),
        ),
        child: Text(
          startDate == null ? 'Today' : formatYmd(startDate!),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
