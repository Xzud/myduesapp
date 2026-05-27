import 'package:equatable/equatable.dart';

class DuedateModel extends Equatable {
  final int id;
  final String dayOfMonth;

  const DuedateModel({required this.id, required this.dayOfMonth});

  @override
  List<Object?> get props => [id, dayOfMonth];

  @override
  bool get stringify => true;

  factory DuedateModel.fromMap(Map<String, dynamic> map) {
    return DuedateModel(id: map['id'], dayOfMonth: map['date']);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'date': dayOfMonth};
  }
}
