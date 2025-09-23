import 'package:flutter_test/flutter_test.dart';
import 'package:armor/armor.dart';

void main() {
  group('ArmorInterceptor Tests', () {
    setUp(() {
      ArmorInterceptor.initialize();
      ArmorInterceptor.instance.clearErrors();
      ArmorRegistry.clear();
    });

    test('initialize creates singleton instance', () {
      ArmorInterceptor.initialize();
      expect(ArmorInterceptor.instance, isNotNull);
    });

    test('handleError adds to intercepted errors', () {
      final interceptor = ArmorInterceptor.instance;
      expect(interceptor.totalIntercepted, equals(0));

      interceptor.handleError(Exception('Test error'), StackTrace.current);

      expect(interceptor.totalIntercepted, equals(1));
      expect(interceptor.interceptedErrors.length, equals(1));
    });

    test('handleError attempts healing for known error types', () {
      final interceptor = ArmorInterceptor.instance;

      // Test null check error healing
      interceptor.handleError(
        Exception('Null check operator used on a null value'),
        StackTrace.current,
      );

      expect(interceptor.totalHealed, equals(1));
      expect(ArmorRegistry.healedBugs['null_check'], equals(1));
    });

    test('handleError attempts healing for setState error', () {
      final interceptor = ArmorInterceptor.instance;

      interceptor.handleError(
        Exception('setState() called after dispose()'),
        StackTrace.current,
      );

      expect(interceptor.totalHealed, equals(1));
      expect(ArmorRegistry.healedBugs['setState_after_dispose'], equals(1));
    });

    test('handleError attempts healing for deactivated widget error', () {
      final interceptor = ArmorInterceptor.instance;

      interceptor.handleError(
        Exception('Looking up a deactivated widget'),
        StackTrace.current,
      );

      expect(interceptor.totalHealed, equals(1));
      expect(ArmorRegistry.healedBugs['deactivated_widget'], equals(1));
    });

    test('handleError attempts healing for render overflow error', () {
      final interceptor = ArmorInterceptor.instance;

      interceptor.handleError(
        Exception('RenderFlex overflowed'),
        StackTrace.current,
      );

      expect(interceptor.totalHealed, equals(1));
      expect(ArmorRegistry.healedBugs['render_overflow'], equals(1));
    });

    test('healRate calculates correctly', () {
      final interceptor = ArmorInterceptor.instance;

      // No errors initially
      expect(interceptor.healRate, equals(0));

      // Add one healed error
      interceptor.handleError(
        Exception('Null check operator used on a null value'),
        StackTrace.current,
      );
      expect(interceptor.healRate, equals(1.0));

      // Add one unhealed error
      interceptor.handleError(
        Exception('Unknown error type'),
        StackTrace.current,
      );
      expect(interceptor.healRate, equals(0.5));
    });

    test('error stream emits intercepted errors', () async {
      final interceptor = ArmorInterceptor.instance;
      final errorStream = interceptor.errorStream;

      InterceptedError? receivedError;
      final subscription = errorStream.listen((error) {
        receivedError = error;
      });

      interceptor.handleError(Exception('Test error'), StackTrace.current);

      // Wait for stream to emit
      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedError, isNotNull);
      expect(receivedError!.error.toString(), contains('Test error'));

      await subscription.cancel();
    });

    test('duplicate errors are filtered out', () {
      final interceptor = ArmorInterceptor.instance;
      final error = Exception('Duplicate error');
      final stack = StackTrace.current;

      // Add same error multiple times
      interceptor.handleError(error, stack);
      interceptor.handleError(error, stack);
      interceptor.handleError(error, stack);

      // Should only be recorded once
      expect(interceptor.totalIntercepted, equals(1));
    });

    test('clearErrors resets state', () {
      final interceptor = ArmorInterceptor.instance;

      interceptor.handleError(Exception('Test error'), StackTrace.current);
      expect(interceptor.totalIntercepted, equals(1));

      interceptor.clearErrors();
      expect(interceptor.totalIntercepted, equals(0));
      expect(interceptor.interceptedErrors.isEmpty, isTrue);
    });
  });
}
