import 'package:myduesapp/features/dues/domain/entities/recurring_template_entity.dart';

class RecurringTemplateModel extends RecurringTemplateEntity {
  const RecurringTemplateModel({
    required super.id,
    required super.name,
    required super.amount,
    required super.billingDay,
    required super.intervalMonths,
    required super.startDate,
    super.active = true,
    super.createdAt,
    super.updatedAt,
  });

  factory RecurringTemplateModel.fromEntity(RecurringTemplateEntity entity) {
    return RecurringTemplateModel(
      id: entity.id,
      name: entity.name,
      amount: entity.amount,
      billingDay: entity.billingDay,
      intervalMonths: entity.intervalMonths,
      startDate: entity.startDate,
      active: entity.active,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory RecurringTemplateModel.fromMap(Map<String, dynamic> map) {
    return RecurringTemplateModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      billingDay: map['billing_day'] as int? ?? 1,
      intervalMonths: map['interval_months'] as int? ?? 1,
      startDate: map['start_date'] as String? ?? '',
      active: (map['active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'billing_day': billingDay,
      'interval_months': intervalMonths,
      'start_date': startDate,
      'active': active ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  RecurringTemplateEntity toEntity() {
    return RecurringTemplateEntity(
      id: id,
      name: name,
      amount: amount,
      billingDay: billingDay,
      intervalMonths: intervalMonths,
      startDate: startDate,
      active: active,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
