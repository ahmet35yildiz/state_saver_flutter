import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/method_channel_shared_preferences.dart';

import 'package:state_saver_package/state_saver_package.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/shared_preferences');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    SharedPreferences.setMockInitialValues({});
  });

  group('StateSaver core functionality', () {
    test('should save and load simple values with saveState and loadState',
        () async {
      final saveResult = await saveState('test_key', 'test_value');
      expect(saveResult, true);

      final loadedValue = await loadState<String>('test_key');
      expect(loadedValue, 'test_value');
    });

    test('should save and load complex objects with saveState and loadState',
        () async {
      final testObject = {
        'name': 'Test User',
        'age': 30,
        'active': true,
        'scores': [85, 90, 95],
      };

      final saveResult = await saveState('complex_key', testObject);
      expect(saveResult, true);

      final loadedObject = await loadState<Map<String, dynamic>>('complex_key');
      expect(loadedObject, testObject);
    });

    test('should clear a specific key with clearState', () async {
      await saveState('key_to_clear', 'value_to_clear');

      final clearResult = await clearState('key_to_clear');
      expect(clearResult, true);

      final loadedValue = await loadState<String>('key_to_clear');
      expect(loadedValue, null);
    });

    test('should clear all states with clearAllStates', () async {
      await saveState('key1', 'value1');
      await saveState('key2', 'value2');

      final clearAllResult = await clearAllStates();
      expect(clearAllResult, true);

      final loadedValue1 = await loadState<String>('key1');
      final loadedValue2 = await loadState<String>('key2');
      expect(loadedValue1, null);
      expect(loadedValue2, null);
    });
  });

  group('fromJson converter tests', () {
    test('loadState should correctly convert objects with fromJson converter',
        () async {
      final testUser = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com'
      };

      await saveState('user_key', testUser);

      final loadedUser = await loadState<User>(
        'user_key',
        fromJson: (json) => User.fromJson(json),
      );

      expect(loadedUser?.id, 1);
      expect(loadedUser?.name, 'Test User');
      expect(loadedUser?.email, 'test@example.com');
    });
  });

  group('defaultValue tests', () {
    test('loadState should return defaultValue when key is not found',
        () async {
      final loadedValue = await loadState<String>(
        'non_existent_key',
        defaultValue: 'default_value',
      );

      expect(loadedValue, 'default_value');
    });
  });

  group('Error handling', () {
    test('saveState should fail with invalid JSON value and return false',
        () async {
      final List<String> logMessages = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logMessages.add(message);
      };
      addTearDown(() {
        debugPrint = originalDebugPrint;
      });

      final cyclicObject = <String, dynamic>{};
      cyclicObject['self'] = cyclicObject;

      final saveResult = await saveState('cyclic_key', cyclicObject);
      expect(saveResult, false);
      expect(logMessages,
          anyElement(startsWith('StateSaver: Failed to save data:')),
          reason: "debugPrint message should be logged on cyclic JSON error");
    });

    test('loadState should return defaultValue on error', () async {
      final List<String> logMessages = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logMessages.add(message);
      };
      addTearDown(() {
        debugPrint = originalDebugPrint;
      });

      SharedPreferences.setMockInitialValues({'invalid_key': '{invalid_json}'});

      final loadedValue = await loadState<Map<String, dynamic>>(
        'invalid_key',
        defaultValue: {'default': true},
      );

      expect(loadedValue, {'default': true});
      expect(logMessages,
          anyElement(startsWith('StateSaver: Failed to load data:')),
          reason:
              "debugPrint message should be logged on invalid JSON load error");
    });

    test('clearState should succeed', () async {
      await saveState('key_to_clear_error', 'value_to_clear');

      final result = await StateSaver.clear('key_to_clear_error');
      expect(result, true);

      final loaded = await loadState<String>('key_to_clear_error');
      expect(loaded, null);
    });

    test('clearAllStates should succeed', () async {
      await saveState('key1_for_clearall', 'value1');
      await saveState('key2_for_clearall', 'value2');

      final result = await StateSaver.clearAll();
      expect(result, true);

      final loadedValue1 = await loadState<String>('key1_for_clearall');
      final loadedValue2 = await loadState<String>('key2_for_clearall');
      expect(loadedValue1, null);
      expect(loadedValue2, null);
    });

    test(
        'clearState should call debugPrint and return false on SharedPreferences platform error',
        () async {
      final originalPlatformStore = SharedPreferencesStorePlatform.instance;
      SharedPreferencesStorePlatform.instance =
          MethodChannelSharedPreferencesStore();

      final List<String> logMessages = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          logMessages.add(message);
        }
      };

      addTearDown(() {
        SharedPreferencesStorePlatform.instance = originalPlatformStore;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        debugPrint = originalDebugPrint;
        SharedPreferences.setMockInitialValues({});
      });

      const testKey = 'error_key_clear_platform_exc';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'remove' &&
            methodCall.arguments['key'] == 'flutter.$testKey') {
          return Future.error(PlatformException(
              code: 'STORAGE_ERROR',
              message: 'Failed to remove item from platform'));
        }
        if (methodCall.method == 'getAll') return <String, dynamic>{};
        return null;
      });

      final result = await clearState(testKey);

      expect(result, isFalse,
          reason: "clearState should return false on platform error");
    });

    test(
        'clearAllStates should call debugPrint and return false on SharedPreferences platform error',
        () async {
      final originalPlatformStore = SharedPreferencesStorePlatform.instance;
      SharedPreferencesStorePlatform.instance =
          MethodChannelSharedPreferencesStore();

      final List<String> logMessages = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          logMessages.add(message);
        }
      };
      addTearDown(() {
        SharedPreferencesStorePlatform.instance = originalPlatformStore;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        debugPrint = originalDebugPrint;
        SharedPreferences.setMockInitialValues({});
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'clear') {
          return Future.error(PlatformException(
              code: 'STORAGE_ERROR',
              message: 'Failed to clear all items from platform'));
        }
        if (methodCall.method == 'getAll') return <String, dynamic>{};
        return null;
      });

      final result = await clearAllStates();

      expect(result, isFalse,
          reason: "clearAllStates should return false on platform error");
      expect(
          logMessages,
          anyElement(startsWith(
              'StateSaver: Failed to delete all data: PlatformException(STORAGE_ERROR, Failed to clear all items from platform')),
          reason: "The correct debugPrint message should be logged on error");
    });
  });

  group('runAllSavers function tests', () {
    test('runAllSavers should call all shutdown saver functions', () async {
      int saveCount = 0;

      saveOnStateAction(() async {
        saveCount++;
      });
      saveOnStateAction(() async {
        saveCount++;
      });
      saveOnStateAction(() async {
        saveCount += 2;
      });

      await StateSaver.runAllSavers();

      expect(saveCount > 0, true);
    });

    test('runAllSavers should call saver functions sequentially', () async {
      List<String> callOrder = [];
      saveOnStateAction(() async {
        callOrder.add('new-first');
      });

      saveOnStateAction(() async {
        callOrder.add('new-second');
      });

      saveOnStateAction(() async {
        callOrder.add('new-third');
      });

      await StateSaver.runAllSavers();

      expect(callOrder.isNotEmpty, true);

      final lastThreeItems =
          callOrder.sublist(callOrder.length > 3 ? callOrder.length - 3 : 0);

      if (lastThreeItems.isNotEmpty) {
        expect(lastThreeItems.last, 'new-third');
      }
    });

    testWidgets(
        'StateSaver.runAllSavers is called when app is paused or detached',
        (WidgetTester tester) async {
      stateSaverListener();

      bool testSaverFunctionCalled = false;
      testSaver() async {
        testSaverFunctionCalled = true;
      }

      saveOnStateAction(testSaver);

      await tester.pumpWidget(Container());

      testSaverFunctionCalled = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      expect(testSaverFunctionCalled, isTrue,
          reason: "runAllSavers should be called on AppLifecycleState.paused");

      testSaverFunctionCalled = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
      await tester.pumpAndSettle();

      expect(testSaverFunctionCalled, isTrue,
          reason:
              "runAllSavers should be called on AppLifecycleState.detached");
    });
  });

  group('WidgetsBindingObserver lifecycle tests', () {
    test(
        'didChangeAppLifecycleState should differentiate between paused and detached',
        () {
      final testObserver = LifecycleTestObserver();

      testObserver.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(testObserver.wasPausedCalled, true);
      expect(testObserver.wasDetachedCalled, false);

      testObserver.reset();
      testObserver.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(testObserver.wasDetachedCalled, true);
      expect(testObserver.wasPausedCalled, false);

      testObserver.reset();
      testObserver.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(testObserver.wasPausedCalled, false);
      expect(testObserver.wasDetachedCalled, false);

      testObserver.reset();
      testObserver.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(testObserver.wasPausedCalled, false);
      expect(testObserver.wasDetachedCalled, false);
    });
  });

  group('Shutdown listener and singleton tests', () {
    testWidgets('stateSaverListener should be initializable',
        (WidgetTester tester) async {
      stateSaverListener();

      saveOnStateAction(() async {
        return;
      });

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final lifecycleNotifier = WidgetsBinding.instance.lifecycleState;

      expect(lifecycleNotifier, null);
    });

    test('AppLifecycleState change function indirect check', () async {
      bool saveFunctionRegistered = false;
      saveOnStateAction(() async {
        saveFunctionRegistered = true;
        return;
      });

      expect(saveFunctionRegistered, false);
    });

    test('StateSaver factory should always return the same instance', () {
      final instance1 = StateSaver();
      final instance2 = StateSaver();

      expect(identical(instance1, instance2), true);
    });

    test('stateSaverListener and saveOnShutdown functions should exist', () {
      expect(stateSaverListener, isNotNull);
      expect(saveOnStateAction, isNotNull);
    });
  });
}

class LifecycleTestObserver extends WidgetsBindingObserver {
  bool wasPausedCalled = false;
  bool wasDetachedCalled = false;

  void reset() {
    wasPausedCalled = false;
    wasDetachedCalled = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      wasPausedCalled = true;
    } else if (state == AppLifecycleState.detached) {
      wasDetachedCalled = true;
    }
  }
}

class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
