// lib/core/theme/theme_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

const String _themeBoxName = 'theme_prefs';
const String _darkModeKey = 'is_dark_mode';

class ThemeCubit extends Cubit<ThemeMode> {
  late Box _box;

  ThemeCubit() : super(ThemeMode.dark);

  Future<void> init() async {
    _box = await Hive.openBox(_themeBoxName);
    final saved = _box.get(_darkModeKey);
    if (saved != null) {
      emit(saved as bool ? ThemeMode.dark : ThemeMode.light);
    }
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _box.put(_darkModeKey, next == ThemeMode.dark);
    emit(next);
  }

  bool get isDark => state == ThemeMode.dark;
}
