import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armor/armor.dart';

void main() {
  setUpAll(() {
    ArmorInterceptor.initialize();
  });

  group('ArmorMixin Tests', () {
    testWidgets('safeExecute returns fallback on error', (tester) async {
      // Clear any existing timers before test
      ArmorInterceptor.instance.clearErrors();

      late _TestArmorWidgetState widget;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestArmorWidget(
              onReady: (w) => widget = w,
            ),
          ),
        ),
      );

      // Test safeExecute with error
      final result = widget.testSafeExecute(
        () => throw Exception('Test error'),
        fallback: 'fallback_value',
      );

      expect(result, equals('fallback_value'));

      // Clean up timers after test
      ArmorInterceptor.instance.clearErrors();
    });

    testWidgets('safeExecute returns actual result on success', (tester) async {
      // Clear any existing timers before test
      ArmorInterceptor.instance.clearErrors();

      late _TestArmorWidgetState widget;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestArmorWidget(
              onReady: (w) => widget = w,
            ),
          ),
        ),
      );

      // Test safeExecute with success
      final result = widget.testSafeExecute(
        () => 'success_value',
        fallback: 'fallback_value',
      );

      expect(result, equals('success_value'));

      // Clean up timers after test
      ArmorInterceptor.instance.clearErrors();
    });

    testWidgets('safeExecute caches successful results', (tester) async {
      // Clear any existing timers before test
      ArmorInterceptor.instance.clearErrors();

      late _TestArmorWidgetState widget;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestArmorWidget(
              onReady: (w) => widget = w,
            ),
          ),
        ),
      );

      // First call should execute and cache
      var callCount = 0;
      final result1 = widget.testSafeExecute(
        () {
          callCount++;
          return 'cached_value';
        },
        cacheKey: 'test_cache',
      );

      // Second call should return cached value without executing
      final result2 = widget.testSafeExecute(
        () {
          callCount++;
          return 'new_value';
        },
        cacheKey: 'test_cache',
      );

      expect(result1, equals('cached_value'));
      expect(result2, equals('cached_value'));
      expect(callCount, equals(1)); // Should only execute once

      // Clean up timers after test
      ArmorInterceptor.instance.clearErrors();
    });

    testWidgets('safeBuild shows fallback on error', (tester) async {
      // Clear any existing timers before test
      ArmorInterceptor.instance.clearErrors();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestArmorWidget(
              shouldThrowInBuild: true,
            ),
          ),
        ),
      );

      // Should show fallback instead of crashing
      expect(find.text('Fallback Widget'), findsOneWidget);

      // Clean up timers after test
      ArmorInterceptor.instance.clearErrors();
    });

    testWidgets('safeBuild shows normal widget on success', (tester) async {
      // Clear any existing timers before test
      ArmorInterceptor.instance.clearErrors();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestArmorWidget(
              shouldThrowInBuild: false,
            ),
          ),
        ),
      );

      // Should show normal widget
      expect(find.text('Normal Widget'), findsOneWidget);

      // Clean up timers after test
      ArmorInterceptor.instance.clearErrors();
    });

    testWidgets('safeSetState prevents setState after dispose', (tester) async {
      // Clear any existing timers before test
      ArmorInterceptor.instance.clearErrors();

      late _TestArmorWidgetState widget;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestArmorWidget(
              onReady: (w) => widget = w,
            ),
          ),
        ),
      );

      // Dispose the widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Try to call setState after dispose - should not crash
      expect(() {
        widget.testSafeSetState(() {
          // This should be ignored
        });
      }, returnsNormally);

      // Clean up timers after test
      ArmorInterceptor.instance.clearErrors();
    });

    test('getArmorStats returns correct information', () {
      final widget = _TestArmorWidgetState();
      final stats = widget.getArmorStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('cached_values'), isTrue);
      expect(stats.containsKey('executed_operations'), isTrue);
      expect(stats.containsKey('active_timers'), isTrue);
      expect(stats.containsKey('active_subscriptions'), isTrue);
      expect(stats.containsKey('widget_mounted'), isTrue);
    });

    test('clearArmorCache clears cached data', () {
      final widget = _TestArmorWidgetState();

      // Add some cached data
      widget.testSafeExecute(() => 'test', cacheKey: 'test_key');

      var stats = widget.getArmorStats();
      expect(stats['cached_values'], greaterThan(0));

      // Clear cache
      widget.clearArmorCache();

      stats = widget.getArmorStats();
      expect(stats['cached_values'], equals(0));
      expect(stats['executed_operations'], equals(0));
    });
  });
}

// Test widget that uses ArmorMixin
class _TestArmorWidget extends StatefulWidget {
  final Function(_TestArmorWidgetState)? onReady;
  final bool shouldThrowInBuild;

  const _TestArmorWidget({
    this.onReady,
    this.shouldThrowInBuild = false,
  });

  @override
  State<_TestArmorWidget> createState() => _TestArmorWidgetState();
}

class _TestArmorWidgetState extends State<_TestArmorWidget> with ArmorMixin {
  @override
  void initState() {
    super.initState();
    widget.onReady?.call(this);
  }

  @override
  Widget build(BuildContext context) {
    return safeBuild(
      () {
        if (widget.shouldThrowInBuild) {
          throw Exception('Build error');
        }
        return const Text('Normal Widget');
      },
      fallback: const Text('Fallback Widget'),
    );
  }

  // Expose protected methods for testing
  T? testSafeExecute<T>(T? Function() operation,
      {T? fallback, String? cacheKey}) {
    return safeExecute(operation, fallback: fallback, cacheKey: cacheKey);
  }

  void testSafeSetState(VoidCallback fn) {
    safeSetState(fn);
  }
}
