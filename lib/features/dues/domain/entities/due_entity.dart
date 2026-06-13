import 'package:equatable/equatable.dart';

class DueEntity extends Equatable {
  final int? id;
  final String name;
  final double amount;
  final bool recurring;
  final int recurringInterval;
  final String? recurringTemplateId;
  final bool generatedFromTemplate;
  final int dayOfMonth;
  final String? loanId;
  final int? installmentIndex;
  final int? installmentCount;
  final String? dueDate;
  final bool paid;
  final bool complete;
  final String? createdAt;
  final String? updatedAt;

  const DueEntity({
    this.id,
    required this.name,
    required this.amount,
    this.recurring = false,
    this.recurringInterval = 1,
    this.recurringTemplateId,
    this.generatedFromTemplate = false,
    required this.dayOfMonth,
    this.loanId,
    this.installmentIndex,
    this.installmentCount,
    this.dueDate,
    this.paid = false,
    this.complete = false,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    amount,
    recurring,
    recurringInterval,
    recurringTemplateId,
    generatedFromTemplate,
    dayOfMonth,
    loanId,
    installmentIndex,
    installmentCount,
    dueDate,
    paid,
    complete,
    createdAt,
    updatedAt,
  ];

  @override
  bool get stringify => true;
}
