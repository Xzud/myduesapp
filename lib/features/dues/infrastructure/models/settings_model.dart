import 'dart:convert';

import 'package:myduesapp/features/dues/domain/entities/settings_entity.dart';

class SettingsModel extends SettingsEntity {
  const SettingsModel({required super.key, required super.value});

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(key: map['key'], value: map['value']);
  }

  Map<String, dynamic> toMap() {
    return {'key': key, 'value': value};
  }

  static SettingsModel create({required String key, required dynamic value}) {
    return SettingsModel(key: key, value: jsonEncode(value));
  }

  dynamic getDecodedValue() {
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }

  SettingsEntity toEntity() {
    return SettingsEntity(key: key, value: value);
  }
}
