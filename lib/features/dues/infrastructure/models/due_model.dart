import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';

class DueModel extends DueEntity {
  const DueModel({
    super.id,
    required super.name,
    required super.amount,
    super.recurring = false,
    super.recurringInterval = 1,
    super.recurringTemplateId,
    super.generatedFromTemplate = false,
    required super.dayOfMonth,
    super.loanId,
    super.installmentIndex,
    super.installmentCount,
    super.dueDate,
    super.paid = false,
    super.complete = false,
    super.createdAt,
    super.updatedAt,
  });

  factory DueModel.fromEntity(DueEntity entity) {
    return DueModel(
      id: entity.id,
      name: entity.name,
      amount: entity.amount,
      recurring: entity.recurring,
      recurringInterval: entity.recurringInterval,
      recurringTemplateId: entity.recurringTemplateId,
      generatedFromTemplate: entity.generatedFromTemplate,
      dayOfMonth: entity.dayOfMonth,
      loanId: entity.loanId,
      installmentIndex: entity.installmentIndex,
      installmentCount: entity.installmentCount,
      dueDate: entity.dueDate,
      paid: entity.paid,
      complete: entity.complete,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory DueModel.fromMap(Map<String, dynamic> map) {
    return DueModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      recurring: (map['recurring'] as int? ?? 0) == 1,
      recurringInterval: map['recurring_interval'] as int? ?? 1,
      recurringTemplateId: map['recurring_template_id'] as String?,
      generatedFromTemplate: (map['generated_from_template'] as int? ?? 0) == 1,
      dayOfMonth: map['day_of_month'] as int? ?? 0,
      loanId: map['loan_id'] as String?,
      installmentIndex: map['installment_index'] as int?,
      installmentCount: map['installment_count'] as int?,
      dueDate: map['due_date'] as String?,
      paid: (map['paid'] as int? ?? 0) == 1,
      complete: (map['complete'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'recurring': recurring ? 1 : 0,
      'recurring_interval': recurringInterval,
      'recurring_template_id': recurringTemplateId,
      'generated_from_template': generatedFromTemplate ? 1 : 0,
      'day_of_month': dayOfMonth,
      'loan_id': loanId,
      'installment_index': installmentIndex,
      'installment_count': installmentCount,
      'due_date': dueDate,
      'paid': paid ? 1 : 0,
      'complete': complete ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  DateTime get effectiveDate {
    if (dueDate != null && dueDate!.isNotEmpty) {
      return DateTime.tryParse(dueDate!) ?? DateTime.now();
    }
    if (createdAt != null && createdAt!.isNotEmpty) {
      return DateTime.tryParse(createdAt!) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String getMonthYear() {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final now = effectiveDate;
    return '${months[now.month]} ${now.year}';
  }

  DueEntity toEntity() {
    return DueEntity(
      id: id,
      name: name,
      amount: amount,
      recurring: recurring,
      recurringInterval: recurringInterval,
      recurringTemplateId: recurringTemplateId,
      generatedFromTemplate: generatedFromTemplate,
      dayOfMonth: dayOfMonth,
      loanId: loanId,
      installmentIndex: installmentIndex,
      installmentCount: installmentCount,
      dueDate: dueDate,
      paid: paid,
      complete: complete,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
