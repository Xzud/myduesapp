import 'package:equatable/equatable.dart';

enum DueQuickView { all, overdue, dueToday, upcoming, unpaid, recurring }

enum DueStatusFilter { all, paid, unpaid, overdue, dueToday, upcoming }

enum DueTypeFilter { all, recurring, installment, single }

const _monthSentinel = Object();

DueQuickView dueQuickViewFromValue(Object? value) {
  for (final item in DueQuickView.values) {
    if (item.name == value) {
      return item;
    }
  }
  return DueQuickView.all;
}

DueStatusFilter dueStatusFilterFromValue(Object? value) {
  for (final item in DueStatusFilter.values) {
    if (item.name == value) {
      return item;
    }
  }
  return DueStatusFilter.all;
}

DueTypeFilter dueTypeFilterFromValue(Object? value) {
  for (final item in DueTypeFilter.values) {
    if (item.name == value) {
      return item;
    }
  }
  return DueTypeFilter.all;
}

class DueFilterState extends Equatable {
  final DueQuickView quickView;
  final DueStatusFilter status;
  final DueTypeFilter type;
  final String? month;

  const DueFilterState({
    this.quickView = DueQuickView.all,
    this.status = DueStatusFilter.all,
    this.type = DueTypeFilter.all,
    this.month,
  });

  factory DueFilterState.fromStoredValue(dynamic value) {
    if (value is! Map) {
      return const DueFilterState();
    }

    final rawMonth = value['month'];
    final month = rawMonth is String && rawMonth.trim().isNotEmpty
        ? rawMonth.trim()
        : null;

    return DueFilterState(
      quickView: dueQuickViewFromValue(value['quickView']),
      status: dueStatusFilterFromValue(value['status']),
      type: dueTypeFilterFromValue(value['type']),
      month: month,
    );
  }

  bool get isDefault {
    return quickView == DueQuickView.all &&
        status == DueStatusFilter.all &&
        type == DueTypeFilter.all &&
        (month == null || month!.isEmpty);
  }

  DueFilterState copyWith({
    DueQuickView? quickView,
    DueStatusFilter? status,
    DueTypeFilter? type,
    Object? month = _monthSentinel,
  }) {
    return DueFilterState(
      quickView: quickView ?? this.quickView,
      status: status ?? this.status,
      type: type ?? this.type,
      month: month == _monthSentinel ? this.month : _normalizeMonth(month),
    );
  }

  Map<String, dynamic> toStoredValue() {
    return {
      'quickView': quickView.name,
      'status': status.name,
      'type': type.name,
      'month': month,
    };
  }

  static String? _normalizeMonth(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get props => [quickView, status, type, month];
}
