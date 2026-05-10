class DuedateModel {
  final int id;
  final String dayOfMonth;

  DuedateModel({required this.id, required this.dayOfMonth});

  factory DuedateModel.fromMap(Map<String, dynamic> map) {
    return DuedateModel(id: map['id'], dayOfMonth: map['date']);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'date': dayOfMonth};
  }
}
