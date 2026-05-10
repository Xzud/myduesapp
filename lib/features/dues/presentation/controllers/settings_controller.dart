import 'package:flutter/foundation.dart';

class SettingsController extends ChangeNotifier {
  SettingsController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;


  

}
