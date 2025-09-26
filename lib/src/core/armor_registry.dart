/// Registry for tracking Armor healing activities
///
/// Keeps track of what types of errors have been successfully healed
/// and provides statistics for monitoring and debugging.
class ArmorRegistry {
  static final Map<String, int> _healedBugs = {};

  /// Get all healed bug types and their counts
  static Map<String, int> get healedBugs => Map.unmodifiable(_healedBugs);

  /// Register that a null check error was successfully healed
  static void registerNullCheckHealing() {
    _healedBugs['null_check'] = (_healedBugs['null_check'] ?? 0) + 1;
  }

  /// Register that a setState after dispose error was successfully healed
  static void registerSetStateHealing() {
    _healedBugs['setState_after_dispose'] =
        (_healedBugs['setState_after_dispose'] ?? 0) + 1;
  }

  /// Register that a deactivated widget access error was successfully healed
  static void registerDeactivatedWidgetHealing() {
    _healedBugs['deactivated_widget'] =
        (_healedBugs['deactivated_widget'] ?? 0) + 1;
  }

  /// Register that a render overflow error was successfully healed
  static void registerRenderOverflowHealing() {
    _healedBugs['render_overflow'] = (_healedBugs['render_overflow'] ?? 0) + 1;
  }

  /// Register that an image loading error was successfully healed
  static void registerImageLoadingHealing() {
    _healedBugs['image_loading'] = (_healedBugs['image_loading'] ?? 0) + 1;
  }

  /// Register that a network error was successfully healed
  static void registerNetworkHealing() {
    _healedBugs['network_error'] = (_healedBugs['network_error'] ?? 0) + 1;
  }

  /// Register that a platform channel error was successfully healed
  static void registerPlatformChannelHealing() {
    _healedBugs['platform_channel'] =
        (_healedBugs['platform_channel'] ?? 0) + 1;
  }

  /// Register that a file operation error was successfully healed
  static void registerFileOperationHealing() {
    _healedBugs['file_operation'] = (_healedBugs['file_operation'] ?? 0) + 1;
  }

  /// Get total number of healed errors across all types
  static int get totalHealed {
    return _healedBugs.values.fold(0, (sum, count) => sum + count);
  }

  /// Get the most common error type that has been healed
  static String? get mostCommonHealedError {
    if (_healedBugs.isEmpty) return null;

    String? mostCommon;
    int maxCount = 0;

    for (final entry in _healedBugs.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommon = entry.key;
      }
    }

    return mostCommon;
  }

  /// Clear all healing records (useful for testing)
  static void clear() {
    _healedBugs.clear();
  }

  /// Get healing statistics as a formatted string
  static String getStatsString() {
    if (_healedBugs.isEmpty) {
      return 'No errors healed yet';
    }

    final buffer = StringBuffer();
    buffer.writeln('Armor Healing Statistics:');
    buffer.writeln('Total healed: $totalHealed');
    buffer.writeln('By type:');

    for (final entry in _healedBugs.entries) {
      final formattedType = _formatErrorType(entry.key);
      buffer.writeln('  $formattedType: ${entry.value}');
    }

    return buffer.toString();
  }

  static String _formatErrorType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
