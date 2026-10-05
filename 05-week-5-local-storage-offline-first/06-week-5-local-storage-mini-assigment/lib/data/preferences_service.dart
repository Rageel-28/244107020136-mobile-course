import 'package:shared_preferences/shared_preferences.dart';

/// Wraps SharedPreferences for the two non-domain preferences required by the
/// assignment: dark-mode toggle and last-opened timestamp.
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const String _kDarkMode = 'dark_mode';
  static const String _kLastOpened = 'last_opened';

  static Future<PreferencesService> create() async {
    return PreferencesService(await SharedPreferences.getInstance());
  }

  bool get isDarkMode => _prefs.getBool(_kDarkMode) ?? false;

  Future<void> setDarkMode(bool value) => _prefs.setBool(_kDarkMode, value);

  DateTime? get lastOpened {
    final millis = _prefs.getInt(_kLastOpened);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastOpened(DateTime value) =>
      _prefs.setInt(_kLastOpened, value.millisecondsSinceEpoch);
}
