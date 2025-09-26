import 'dart:async';
import 'package:flutter/foundation.dart';
import 'armor_registry.dart';

/// Central error interceptor for Armor protection system
///
/// Automatically intercepts and handles Flutter errors before they can crash the app.
/// Works in conjunction with ArmorMixin to provide comprehensive error protection.
class ArmorInterceptor {
  static ArmorInterceptor? _instance;
  static ArmorInterceptor get instance => _instance!;

  final List<InterceptedError> interceptedErrors = [];
  final _errorStreamController = StreamController<InterceptedError>.broadcast();
  final Set<String> _handledErrorKeys = {}; // Prevent duplicate handling
  final List<Timer> _cleanupTimers = []; // Track timers for proper disposal

  /// Stream of intercepted errors for monitoring and analytics
  Stream<InterceptedError> get errorStream => _errorStreamController.stream;

  ArmorInterceptor._();

  /// Initialize the Armor error interception system
  ///
  /// Call this once in your main() function before runApp():
  /// ```dart
  /// void main() {
  ///   ArmorInterceptor.initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  static void initialize() {
    _instance = ArmorInterceptor._();

    // Override Flutter's error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      instance._interceptFlutterError(details);
    };
  }

  void _interceptFlutterError(FlutterErrorDetails details) {
    // Create a unique key for this error to prevent loops
    final errorKey =
        '${details.exception.runtimeType}_${details.stack.toString().split('\n').take(3).join('_')}';

    // Skip if we've already handled this exact error recently
    if (_handledErrorKeys.contains(errorKey)) {
      return;
    }

    _handledErrorKeys.add(errorKey);

    // Clear old error keys after a delay to allow re-handling later
    final timer = Timer(const Duration(seconds: 5), () {
      _handledErrorKeys.remove(errorKey);
    });
    _cleanupTimers.add(timer);

    final error = InterceptedError(
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.current,
      context: details.context?.toString() ?? 'Unknown',
      timestamp: DateTime.now(),
      wasHealed: false,
    );

    // Try to heal the error
    final healed = _attemptHeal(error);
    error.wasHealed = healed;

    interceptedErrors.add(error);
    _errorStreamController.add(error);

    // If we couldn't heal it, report it (in debug mode only)
    if (!healed && kDebugMode) {
      // Use presentError but don't let it cause loops
      Future.microtask(() {
        FlutterError.presentError(details);
      });
    }
  }

  /// Handle errors from async operations or manual reporting
  ///
  /// This method is called automatically by ArmorMixin methods
  /// but can also be used manually for custom error handling.
  void handleError(Object error, StackTrace stack) {
    final errorKey =
        '${error.runtimeType}_${stack.toString().split('\n').take(3).join('_')}';

    if (_handledErrorKeys.contains(errorKey)) {
      return;
    }

    _handledErrorKeys.add(errorKey);
    final timer = Timer(const Duration(seconds: 5), () {
      _handledErrorKeys.remove(errorKey);
    });
    _cleanupTimers.add(timer);

    final intercepted = InterceptedError(
      error: error,
      stackTrace: stack,
      context: 'Async error',
      timestamp: DateTime.now(),
      wasHealed: false,
    );

    final healed = _attemptHeal(intercepted);
    intercepted.wasHealed = healed;

    interceptedErrors.add(intercepted);
    _errorStreamController.add(intercepted);

    if (!healed && kDebugMode) {
      debugPrint('Armor: Unhealed error: $error');
    }
  }

  bool _attemptHeal(InterceptedError error) {
    final errorString = error.error.toString();

    // Real healing strategies based on error type
    if (errorString.contains('Null check operator used on a null value')) {
      debugPrint('🛡️ Armor: Healing null check error');
      ArmorRegistry.registerNullCheckHealing();
      return true;
    }

    if (errorString.contains('setState() called after dispose()')) {
      debugPrint('🛡️ Armor: Healing setState after dispose');
      ArmorRegistry.registerSetStateHealing();
      return true;
    }

    if (errorString.contains('Looking up a deactivated widget')) {
      debugPrint('🛡️ Armor: Healing deactivated widget access');
      ArmorRegistry.registerDeactivatedWidgetHealing();
      return true;
    }

    if (errorString.contains('RenderFlex overflowed')) {
      debugPrint('🛡️ Armor: Healing render overflow');
      ArmorRegistry.registerRenderOverflowHealing();
      return true;
    }

    return false;
  }

  /// Total number of errors intercepted
  int get totalIntercepted => interceptedErrors.length;

  /// Total number of errors successfully healed
  int get totalHealed => interceptedErrors.where((e) => e.wasHealed).length;

  /// Success rate of error healing (0.0 to 1.0)
  double get healRate =>
      totalIntercepted > 0 ? totalHealed / totalIntercepted : 0;

  /// Clear all intercepted errors (useful for testing)
  void clearErrors() {
    interceptedErrors.clear();
    _handledErrorKeys.clear();
    // Cancel all pending cleanup timers
    for (final timer in _cleanupTimers) {
      timer.cancel();
    }
    _cleanupTimers.clear();
  }

  /// Dispose of the error interceptor
  void dispose() {
    // Cancel all pending cleanup timers
    for (final timer in _cleanupTimers) {
      timer.cancel();
    }
    _cleanupTimers.clear();
    _errorStreamController.close();
  }
}

/// Represents an error that was intercepted by the Armor system
class InterceptedError {
  /// The original error object
  final Object error;

  /// Stack trace when the error occurred
  final StackTrace stackTrace;

  /// Context information about where the error occurred
  final String context;

  /// When the error was intercepted
  final DateTime timestamp;

  /// Whether the error was successfully healed
  bool wasHealed;

  InterceptedError({
    required this.error,
    required this.stackTrace,
    required this.context,
    required this.timestamp,
    required this.wasHealed,
  });

  @override
  String toString() {
    return 'InterceptedError(error: $error, healed: $wasHealed, context: $context)';
  }
}
