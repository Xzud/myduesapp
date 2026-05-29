import 'package:equatable/equatable.dart';

enum InterestMode { percentage, monthlyFixedAmount, totalAmountDividedPerMonth }

class InterestPlan extends Equatable {
  final InterestMode mode;
  final double value;

  const InterestPlan({required this.mode, required this.value});

  @override
  List<Object?> get props => [mode, value];

  @override
  bool get stringify => true;
}
