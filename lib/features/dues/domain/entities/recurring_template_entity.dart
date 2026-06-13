import 'package:equatable/equatable.dart';

class RecurringTemplateEntity extends Equatable {
  final String id;
  final String name;
  final double amount;
  final int billingDay;
  final int intervalMonths;
  final String startDate;
  final bool active;
  final String? createdAt;
  final String? updatedAt;

  const RecurringTemplateEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingDay,
    required this.intervalMonths,
    required this.startDate,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  RecurringTemplateEntity copyWith({
    String? id,
    String? name,
    double? amount,
    int? billingDay,
    int? intervalMonths,
    String? startDate,
    bool? active,
    String? createdAt,
    String? updatedAt,
  }) {
    return RecurringTemplateEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingDay: billingDay ?? this.billingDay,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      startDate: startDate ?? this.startDate,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    amount,
    billingDay,
    intervalMonths,
    startDate,
    active,
    createdAt,
    updatedAt,
  ];

  @override
  bool get stringify => true;
}
