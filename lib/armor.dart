/// Armor - Bulletproof protection for Flutter apps
///
/// Automatically handles crashes, errors, and failures with graceful recovery.
///
/// ## Quick Start
///
/// Add the ArmorMixin to any StatefulWidget:
///
/// ```dart
/// import 'package:armor/armor.dart';
///
/// class MyWidget extends StatefulWidget with ArmorMixin {
///   // Your widget is now protected against all common Flutter errors
/// }
/// ```
///
/// Initialize error interception in your main function:
///
/// ```dart
/// void main() {
///   ArmorInterceptor.initialize(); // Enable global error protection
///   runApp(MyApp());
/// }
/// ```
///
/// ## Features
///
/// - 🚫 Prevents crashes and red error screens
/// - 🔄 Automatic error recovery with graceful fallbacks
/// - 📐 Handles render overflow (yellow/black stripes)
/// - 🌐 Network error handling with retry logic
/// - 🖼️ Safe image loading with automatic fallbacks
/// - ⚡ Performance monitoring
/// - 🧹 Automatic resource cleanup
///
/// ## Core Methods
///
/// - `safeExecute()` - Execute any code safely with fallbacks
/// - `safeSetState()` - Prevent setState after dispose errors
/// - `safeAsync()` - Safe async operations with mounted checks
/// - `safeBuild()` - Build widgets with automatic fallback UI
/// - `armorImage()` - Load images with error handling
/// - `armorNetworkRequest()` - Network calls with retry logic
/// - `armorTimer()` - Managed timers with auto cleanup
/// - `armorStreamListen()` - Protected stream subscriptions
///
library;

export 'src/core/armor_mixin.dart';
export 'src/core/armor_interceptor.dart';
export 'src/core/armor_registry.dart';
