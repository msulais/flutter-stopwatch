import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SettingsKey {
    theme,
    color,
}

class Settings extends ChangeNotifier {
    static late SharedPreferences prefs;

    final Map<SettingsKey, dynamic> _settings = {
        SettingsKey.color: Colors.yellow.value,
        SettingsKey.theme: ThemeMode.system,
    };

    Color
    get color => Color(_settings[SettingsKey.color]);
    set color(Color value) => _update(SettingsKey.color, value.value);

    ThemeMode
    get theme => _settings[SettingsKey.theme];
    set theme(ThemeMode value) => _update(SettingsKey.theme, value);

    bool
    get isDarkMode =>
        _settings[SettingsKey.theme] == ThemeMode.dark ||
        (
            _settings[SettingsKey.theme] == ThemeMode.system &&
            SchedulerBinding.instance.window.platformBrightness == Brightness.dark
        )
    ;

    void _update(SettingsKey key, dynamic value, [bool notify = true]){
        _settings[key] = value;
        if (notify) notifyListeners();
        Settings.set(key, value);
    }

    Future<void> readFile() async {
        prefs = await SharedPreferences.getInstance();
        try {
            color = Color(Settings.get(SettingsKey.color) ?? Colors.yellow.value);
            theme = ThemeMode.values.byName(Settings.get(SettingsKey.theme) ?? ThemeMode.system.name);
        } catch (e) {
            debugPrint('ERROR READ FILE SETTINGS: $e');
        }
    }

    static
    dynamic get(SettingsKey key) {
        return prefs.get(key.name);
    }

    /// `value.runtimeType` must be:
    /// * `int`
    /// * `String`
    /// * `bool`
    /// * `double`
    /// * `Enum`
    static
    Future<void> set(SettingsKey key, dynamic value) async {
        switch(value.runtimeType){
            case int   : prefs.setInt   (key.name, value); break;
            case String: prefs.setString(key.name, value); break;
            case bool  : prefs.setBool  (key.name, value); break;
            case double: prefs.setDouble(key.name, value); break;
            default    :
                if (value is! Enum) throw Exception('Data type not supported [value: $value, value.runtimeType: ${value.runtimeType}]');
                prefs.setString(key.name, value.name);
        }
    }
}