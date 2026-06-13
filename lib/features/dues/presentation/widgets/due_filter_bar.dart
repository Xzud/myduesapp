import 'package:flutter/material.dart';
import 'package:myduesapp/features/dues/domain/entities/due_filter_state.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_ui.dart';

class DueFilterBar extends StatelessWidget {
  final String scope;
  final TextEditingController searchController;
  final DueFilterState filterState;
  final List<String> availableMonths;
  final bool enabled;
  final String? helperMessage;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onClearFilters;
  final Future<void> Function(DueQuickView value) onQuickViewChanged;
  final Future<void> Function(DueStatusFilter value) onStatusChanged;
  final Future<void> Function(DueTypeFilter value) onTypeChanged;
  final Future<void> Function(String? value) onMonthChanged;

  const DueFilterBar({
    super.key,
    required this.scope,
    required this.searchController,
    required this.filterState,
    required this.availableMonths,
    required this.enabled,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onClearFilters,
    required this.onQuickViewChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onMonthChanged,
    this.helperMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: Key('${scope}_search_field'),
            controller: searchController,
            enabled: enabled,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Search dues',
              hintText: 'Search by name',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      key: Key('${scope}_clear_search'),
                      tooltip: 'Clear search',
                      onPressed: enabled ? onClearSearch : null,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: Key('${scope}_clear_filters'),
              onPressed: enabled ? onClearFilters : null,
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Clear filters'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick views',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final quickView in DueQuickView.values)
                ChoiceChip(
                  key: Key('${scope}_quick_view_${quickView.name}'),
                  label: Text(_quickViewLabel(quickView)),
                  selected: filterState.quickView == quickView,
                  onSelected: enabled
                      ? (selected) {
                          if (selected) {
                            onQuickViewChanged(quickView);
                          }
                        }
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final useColumn = constraints.maxWidth < 760;
              final children = [
                _DropdownField<DueStatusFilter>(
                  key: Key('${scope}_status_filter'),
                  label: 'Status',
                  value: filterState.status,
                  enabled: enabled,
                  items: DueStatusFilter.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_statusLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onStatusChanged(value);
                    }
                  },
                ),
                _DropdownField<DueTypeFilter>(
                  key: Key('${scope}_type_filter'),
                  label: 'Type',
                  value: filterState.type,
                  enabled: enabled,
                  items: DueTypeFilter.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_typeLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onTypeChanged(value);
                    }
                  },
                ),
                _DropdownField<String?>(
                  key: Key('${scope}_month_filter'),
                  label: 'Month',
                  value: filterState.month,
                  enabled: enabled,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All months'),
                    ),
                    for (final month in availableMonths)
                      DropdownMenuItem<String?>(
                        value: month,
                        child: Text(month),
                      ),
                  ],
                  onChanged: onMonthChanged,
                ),
              ];

              if (useColumn) {
                return Column(
                  children: [
                    for (var index = 0; index < children.length; index++) ...[
                      children[index],
                      if (index < children.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children[0]),
                  const SizedBox(width: 12),
                  Expanded(child: children[1]),
                  const SizedBox(width: 12),
                  Expanded(child: children[2]),
                ],
              );
            },
          ),
          if (helperMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              helperMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final bool enabled;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: enabled ? onChanged : null,
    );
  }
}

String _quickViewLabel(DueQuickView value) {
  switch (value) {
    case DueQuickView.all:
      return 'All';
    case DueQuickView.overdue:
      return 'Overdue';
    case DueQuickView.dueToday:
      return 'Due today';
    case DueQuickView.upcoming:
      return 'Upcoming';
    case DueQuickView.unpaid:
      return 'Unpaid';
    case DueQuickView.recurring:
      return 'Recurring';
  }
}

String _statusLabel(DueStatusFilter value) {
  switch (value) {
    case DueStatusFilter.all:
      return 'All statuses';
    case DueStatusFilter.paid:
      return 'Paid';
    case DueStatusFilter.unpaid:
      return 'Unpaid';
    case DueStatusFilter.overdue:
      return 'Overdue';
    case DueStatusFilter.dueToday:
      return 'Due today';
    case DueStatusFilter.upcoming:
      return 'Upcoming';
  }
}

String _typeLabel(DueTypeFilter value) {
  switch (value) {
    case DueTypeFilter.all:
      return 'All types';
    case DueTypeFilter.recurring:
      return 'Recurring';
    case DueTypeFilter.installment:
      return 'Installment';
    case DueTypeFilter.single:
      return 'Single due';
  }
}
