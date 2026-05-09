import 'package:flutter/material.dart';
import '../notifier/theme.dart';

class GlobalParams {
  // ignore: unused_field
  static final _instance = GlobalParams._internal();
  GlobalParams._internal();

  static MonTheme themeActuel = MonTheme();
}
