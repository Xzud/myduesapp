import 'package:equatable/equatable.dart';

class SettingsEntity extends Equatable {
  final String key;
  final String value;

  const SettingsEntity({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];

  @override
  bool get stringify => true;
}
