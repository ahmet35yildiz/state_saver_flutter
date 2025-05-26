library state_saver_package;

export 'src/state_saver.dart';

/// Simplified functional interface
import 'src/state_saver.dart';

/// Convenience function for saving
Future<bool> saveState(String key, Object object) =>
    StateSaver.save(key, object);

/// Convenience function for loading
Future<T?> loadState<T>(
  String key, {
  T? defaultValue,
  T Function(Map<String, dynamic>)? fromJson,
}) =>
    StateSaver.load<T>(
      key,
      defaultValue: defaultValue,
      fromJson: fromJson,
    );

/// Convenience function for clearing
Future<bool> clearState(String key) => StateSaver.clear(key);

/// Convenience function for clearing all
Future<bool> clearAllStates() => StateSaver.clearAll();

/// Starts listening for save functions that will run when the application is closed
/// This function should be called in the main() method of the application or before creating MaterialApp.
void stateSaverListener() => StateSaver.startListeningStateAction();

/// Adds a save function that will run automatically when the application is closed
void saveOnStateAction(Future<void> Function() saveFunction) =>
    StateSaver.addStateActionSaver(saveFunction);
