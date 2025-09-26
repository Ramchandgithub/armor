import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

import 'armor_interceptor.dart';

/// Armor mixin that provides bulletproof protection for Flutter widgets
///
/// Add this mixin to any StatefulWidget to automatically handle:
/// - Null safety errors
/// - setState after dispose
/// - Render overflow
/// - Network failures
/// - Image loading errors
/// - Platform channel errors
/// - File system errors
/// - Performance issues
///
/// Example:
/// ```dart
/// class MyWidget extends StatefulWidget with ArmorMixin {
///   // Your widget is now protected against all common Flutter errors
/// }
/// ```
mixin ArmorMixin<T extends StatefulWidget> on State<T> {
  bool _mounted = true;
  final Map<String, dynamic> _armorCache = {};
  final Set<String> _executedOperations = {}; // Track executed operations
  final Map<String, Timer> _activeTimers = {}; // Track timers for cleanup
  final Map<String, StreamSubscription> _activeSubscriptions =
      {}; // Track subscriptions

  @override
  void dispose() {
    _mounted = false;

    // Clean up all tracked resources
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();

    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();

    super.dispose();
  }

  /// Safely execute code that might throw errors
  ///
  /// Automatically provides fallback values and caches successful results.
  ///
  /// Example:
  /// ```dart
  /// final name = safeExecute(
  ///   () => userData!['name'] as String,
  ///   fallback: 'Unknown User',
  ///   cacheKey: 'user_name',
  /// );
  /// ```
  R? safeExecute<R>(R? Function() operation, {R? fallback, String? cacheKey}) {
    // Create a unique key for this operation
    final operationKey = cacheKey ?? operation.hashCode.toString();

    // If we have a cached value for this exact operation, return it
    if (cacheKey != null && _armorCache.containsKey(cacheKey)) {
      return _armorCache[cacheKey] as R?;
    }

    try {
      final result = operation();

      // Cache successful results
      if (cacheKey != null && result != null) {
        _armorCache[cacheKey] = result;
      }

      // Mark this operation as successfully executed
      _executedOperations.add(operationKey);

      return result;
    } catch (e, stack) {
      // Only log the error once per operation
      if (!_executedOperations.contains('${operationKey}_error')) {
        ArmorInterceptor.instance.handleError(e, stack);
        _executedOperations.add('${operationKey}_error');
      }

      // Try to return cached value
      if (cacheKey != null && _armorCache.containsKey(cacheKey)) {
        debugPrint('🔄 Armor: Returning cached value for $cacheKey');
        return _armorCache[cacheKey] as R?;
      }

      // Return fallback
      return fallback;
    }
  }

  /// Safe setState that checks mounted status
  ///
  /// Prevents setState after dispose errors automatically.
  ///
  /// Example:
  /// ```dart
  /// safeSetState(() {
  ///   counter++;
  /// });
  /// ```
  void safeSetState(VoidCallback fn) {
    if (_mounted && mounted) {
      setState(fn);
    } else {
      debugPrint('⚠️ Armor: Prevented setState after dispose');
    }
  }

  /// Safe async operation wrapper
  ///
  /// Handles async operations with automatic mounted checks.
  ///
  /// Example:
  /// ```dart
  /// final result = await safeAsync(() async {
  ///   final data = await api.fetchData();
  ///   safeSetState(() => this.data = data);
  ///   return data;
  /// });
  /// ```
  Future<R?> safeAsync<R>(
    Future<R> Function() operation, {
    R? fallback,
    VoidCallback? onError,
  }) async {
    try {
      final result = await operation();

      // Check if still mounted before returning
      if (!_mounted || !mounted) {
        debugPrint('⚠️ Armor: Widget disposed during async operation');
        return fallback;
      }

      return result;
    } catch (e, stack) {
      ArmorInterceptor.instance.handleError(e, stack);
      onError?.call();
      return fallback;
    }
  }

  /// Build a widget safely with fallback
  ///
  /// Automatically catches build errors and provides fallback UI.
  ///
  /// Example:
  /// ```dart
  /// return safeBuild(
  ///   () => ComplexWidget(data: complexData),
  ///   fallback: Text('Content temporarily unavailable'),
  /// );
  /// ```
  Widget safeBuild(Widget Function() builder, {Widget? fallback}) {
    try {
      return builder();
    } catch (e, stack) {
      // Only report each unique error once
      final errorKey = '${e.runtimeType}_build';
      if (!_executedOperations.contains(errorKey)) {
        ArmorInterceptor.instance.handleError(e, stack);
        _executedOperations.add(errorKey);
      }

      return fallback ??
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Content protected by Armor',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          );
    }
  }

  /// Safe image loading with automatic fallbacks
  ///
  /// Handles image loading errors with proper placeholder and error widgets.
  ///
  /// Example:
  /// ```dart
  /// armorImage(
  ///   'https://example.com/image.jpg',
  ///   width: 100,
  ///   height: 100,
  ///   cacheKey: 'profile_image',
  /// )
  /// ```
  Widget armorImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    String? cacheKey,
  }) {
    return safeBuild(
      () => Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          // Cache error state to avoid repeated loading attempts
          if (cacheKey != null) {
            _armorCache['image_error_$cacheKey'] = true;
          }
          ArmorInterceptor.instance
              .handleError(error, stackTrace ?? StackTrace.current);

          return errorWidget ??
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: (width != null && width < 50) ? 16 : 24,
                      color: Colors.grey.shade500,
                    ),
                    if (width == null || width > 60) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Image unavailable',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              );
        },
      ),
      fallback: errorWidget ??
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey.shade400,
            ),
          ),
    );
  }

  /// Safe network request with retry and fallback
  ///
  /// Automatically retries failed requests and provides cached fallbacks.
  ///
  /// Example:
  /// ```dart
  /// final data = await armorNetworkRequest(
  ///   () => api.fetchUserData(),
  ///   fallback: cachedUserData,
  ///   maxRetries: 3,
  ///   cacheKey: 'user_data',
  /// );
  /// ```
  Future<R?> armorNetworkRequest<R>(
    Future<R> Function() request, {
    R? fallback,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    String? cacheKey,
  }) async {
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        final result = await request();

        // Cache successful result
        if (cacheKey != null && result != null) {
          _armorCache['network_$cacheKey'] = result;
        }

        return result;
      } catch (e, stack) {
        ArmorInterceptor.instance.handleError(e, stack);

        retryCount++;

        if (retryCount > maxRetries) {
          // Return cached value if available
          if (cacheKey != null &&
              _armorCache.containsKey('network_$cacheKey')) {
            debugPrint('🔄 Armor: Using cached network data for $cacheKey');
            return _armorCache['network_$cacheKey'] as R?;
          }

          return fallback;
        }

        // Wait before retry
        await Future.delayed(retryDelay * retryCount);

        // Check if still mounted before retrying
        if (!_mounted || !mounted) {
          return fallback;
        }
      }
    }

    return fallback;
  }

  /// Safe timer creation with automatic cleanup
  ///
  /// Creates timers that are automatically cleaned up on dispose.
  ///
  /// Example:
  /// ```dart
  /// armorTimer(
  ///   Duration(seconds: 5),
  ///   () => safeSetState(() => showMessage = false),
  ///   key: 'hide_message_timer',
  /// );
  /// ```
  Timer? armorTimer(
    Duration duration,
    VoidCallback callback, {
    String? key,
    bool periodic = false,
  }) {
    try {
      final timerKey = key ?? 'timer_${DateTime.now().millisecondsSinceEpoch}';

      // Cancel existing timer with same key
      _activeTimers[timerKey]?.cancel();

      final timer = periodic
          ? Timer.periodic(duration, (_) {
              if (_mounted && mounted) {
                safeExecute(callback);
              } else {
                _activeTimers[timerKey]?.cancel();
                _activeTimers.remove(timerKey);
              }
            })
          : Timer(duration, () {
              if (_mounted && mounted) {
                safeExecute(callback);
              }
              _activeTimers.remove(timerKey);
            });

      _activeTimers[timerKey] = timer;
      return timer;
    } catch (e, stack) {
      ArmorInterceptor.instance.handleError(e, stack);
      return null;
    }
  }

  /// Safe stream subscription with automatic cleanup
  ///
  /// Creates stream subscriptions that are automatically cleaned up on dispose.
  ///
  /// Example:
  /// ```dart
  /// armorStreamListen(
  ///   userStream,
  ///   (user) => safeSetState(() => currentUser = user),
  ///   key: 'user_stream',
  /// );
  /// ```
  StreamSubscription<R>? armorStreamListen<R>(
    Stream<R> stream,
    void Function(R) onData, {
    Function? onError,
    VoidCallback? onDone,
    String? key,
  }) {
    try {
      final subKey = key ?? 'stream_${DateTime.now().millisecondsSinceEpoch}';

      // Cancel existing subscription with same key
      _activeSubscriptions[subKey]?.cancel();

      final subscription = stream.listen(
        (data) {
          if (_mounted && mounted) {
            safeExecute(() => onData(data));
          }
        },
        onError: (error, stack) {
          ArmorInterceptor.instance
              .handleError(error, stack ?? StackTrace.current);
          if (onError != null) {
            safeExecute(() => onError(error, stack));
          }
        },
        onDone: () {
          _activeSubscriptions.remove(subKey);
          if (onDone != null) {
            safeExecute(onDone);
          }
        },
      );

      _activeSubscriptions[subKey] = subscription;
      return subscription;
    } catch (e, stack) {
      ArmorInterceptor.instance.handleError(e, stack);
      return null;
    }
  }

  /// Safe platform channel calls
  ///
  /// Handles platform method channel calls with proper error handling.
  ///
  /// Example:
  /// ```dart
  /// final result = await armorPlatformCall(
  ///   () => platform.invokeMethod('getBatteryLevel'),
  ///   fallback: 'Unknown',
  ///   methodName: 'getBatteryLevel',
  /// );
  /// ```
  Future<R?> armorPlatformCall<R>(
    Future<R> Function() platformCall, {
    R? fallback,
    String? methodName,
  }) async {
    try {
      return await platformCall();
    } on PlatformException catch (e, stack) {
      debugPrint(
          '🔧 Armor: Platform method "$methodName" failed: ${e.message}');
      ArmorInterceptor.instance.handleError(e, stack);
      return fallback;
    } catch (e, stack) {
      ArmorInterceptor.instance.handleError(e, stack);
      return fallback;
    }
  }

  /// Safe file operations
  ///
  /// Handles file system operations with proper error handling.
  ///
  /// Example:
  /// ```dart
  /// final content = await armorFileOperation(
  ///   () => File(path).readAsString(),
  ///   fallback: '',
  ///   operationType: 'read_config',
  /// );
  /// ```
  Future<R?> armorFileOperation<R>(
    Future<R> Function() fileOperation, {
    R? fallback,
    String? operationType,
  }) async {
    try {
      return await fileOperation();
    } on FileSystemException catch (e, stack) {
      debugPrint(
          '📁 Armor: File operation "$operationType" failed: ${e.message}');
      ArmorInterceptor.instance.handleError(e, stack);
      return fallback;
    } catch (e, stack) {
      ArmorInterceptor.instance.handleError(e, stack);
      return fallback;
    }
  }

  /// Performance monitoring wrapper
  ///
  /// Wraps operations with performance monitoring and automatic warnings.
  ///
  /// Example:
  /// ```dart
  /// final result = armorPerformanceOperation(
  ///   () => expensiveComputation(),
  ///   operationName: 'data_processing',
  ///   warningThreshold: Duration(milliseconds: 500),
  /// );
  /// ```
  R? armorPerformanceOperation<R>(
    R Function() operation, {
    String? operationName,
    Duration? warningThreshold,
  }) {
    final stopwatch = Stopwatch()..start();

    try {
      final result = operation();
      stopwatch.stop();

      // Log performance warnings
      final threshold = warningThreshold ?? const Duration(milliseconds: 100);
      if (stopwatch.elapsed > threshold) {
        debugPrint(
            '⚠️ Armor: Performance warning: ${operationName ?? 'Operation'} took ${stopwatch.elapsedMilliseconds}ms');
      }

      return result;
    } catch (e, stack) {
      stopwatch.stop();
      ArmorInterceptor.instance.handleError(e, stack);
      return null;
    }
  }

  /// Get armor protection statistics
  ///
  /// Returns information about the current armor protection status.
  ///
  /// Example:
  /// ```dart
  /// final stats = getArmorStats();
  /// print('Cached values: ${stats['cached_values']}');
  /// ```
  Map<String, dynamic> getArmorStats() {
    return {
      'cached_values': _armorCache.length,
      'executed_operations': _executedOperations.length,
      'active_timers': _activeTimers.length,
      'active_subscriptions': _activeSubscriptions.length,
      'widget_mounted': _mounted && mounted,
    };
  }

  /// Clear armor cache (useful for testing)
  ///
  /// Clears all cached values and operation tracking.
  void clearArmorCache() {
    _armorCache.clear();
    _executedOperations.clear();
  }
}
