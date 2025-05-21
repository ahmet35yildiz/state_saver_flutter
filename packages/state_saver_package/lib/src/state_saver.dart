import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StateSaver class is used to save and restore application state.
/// This class converts objects to JSON format and saves them to SharedPreferences,
/// and converts data retrieved from SharedPreferences back to objects.
class StateSaver with WidgetsBindingObserver {
  /// Private constructor used to create a singleton instance
  StateSaver._internal();

  /// Static variable that holds the single instance of the class
  static final StateSaver _instance = StateSaver._internal();

  /// Factory constructor used to access the singleton instance
  factory StateSaver() => _instance;

  /// List to hold functions to be executed during shutdown
  static final List<Future<void> Function()> _stateActionSavers = [];

  /// Starts listening for functions to be executed when the application is closed
  static void startListeningStateAction() {
    // Initialize Flutter binding
    WidgetsFlutterBinding.ensureInitialized();

    // Add observer
    WidgetsBinding.instance.addObserver(_StateActionObserver());
  }

  /// Adds a save function to be executed during shutdown
  static void addStateActionSaver(Future<void> Function() saveFunction) {
    _stateActionSavers.add(saveFunction);
  }

  /// Runs all shutdown save functions
  static Future<void> runAllSavers() async {
    for (final saver in _stateActionSavers) {
      await saver();
    }
  }

  /// Saves any object with the specified key (Object -> JSON -> String -> SP)
  ///
  /// [key]: The key to save the data with
  /// [object]: The object to save
  Future<bool> saveState(String key, Object object) async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Convert object to JSON string
      final jsonString = jsonEncode(object);

      // Save JSON string to SharedPreferences
      return await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('StateSaver: Failed to save data: $e');
      return false;
    }
  }

  /// Loads an object saved with the specified key (SP -> String -> JSON -> Object)
  ///
  /// [key]: The key to retrieve the data from
  /// [defaultValue]: Default value to return if data is not found
  /// [fromJson]: Optional converter function to create a model object from JSON Map
  Future<T?> loadState<T>(
    String key, {
    T? defaultValue,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Get JSON string from SharedPreferences
      final jsonString = prefs.getString(key);
      if (jsonString == null) return defaultValue;

      // Decode JSON string
      final decodedJson = jsonDecode(jsonString);

      // If fromJson function is provided, create and return model object directly
      if (fromJson != null && decodedJson is Map<String, dynamic>) {
        return fromJson(decodedJson);
      }

      // Otherwise cast JSON to type T
      return decodedJson as T;
    } catch (e) {
      debugPrint('StateSaver: Failed to load data: $e');
      return defaultValue;
    }
  }

  /// Deletes data saved with the specified key
  ///
  /// [key]: The key of the data to delete
  Future<bool> clearState(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(key);
    } catch (e) {
      debugPrint('StateSaver: Failed to delete data: $e');
      return false;
    }
  }

  /// Deletes all saved data
  Future<bool> clearAllStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      debugPrint('StateSaver: Failed to delete all data: $e');
      return false;
    }
  }

  /// Adding static methods to allow usage like StateSaver.save(key, object)
  static Future<bool> save(String key, Object object) async {
    return await _instance.saveState(key, object);
  }

  static Future<T?> load<T>(
    String key, {
    T? defaultValue,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return await _instance.loadState<T>(
      key,
      defaultValue: defaultValue,
      fromJson: fromJson,
    );
  }

  static Future<bool> clear(String key) async {
    return await _instance.clearState(key);
  }

  static Future<bool> clearAll() async {
    return await _instance.clearAllStates();
  }
}

/// Special observer class that listens for application shutdown events
class _StateActionObserver with WidgetsBindingObserver {
  _StateActionObserver() {
    // No need to call again, already initialized
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Run all save functions when the application is paused or detached
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      StateSaver.runAllSavers();
    }
  }
}
