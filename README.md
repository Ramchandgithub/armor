# 🛡️ Armor

**Bulletproof protection for Flutter apps. Automatically handles crashes, errors, and failures with graceful recovery.**

[![Pub Version](https://img.shields.io/pub/v/armor)](https://pub.dev/packages/armor)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- 🚫 **Prevents crashes** - No more red error screens
- 🔄 **Automatic recovery** - Graceful fallbacks for failed operations  
- 📐 **Render overflow protection** - Eliminates yellow/black overflow stripes
- 🌐 **Network error handling** - Retry logic with intelligent fallbacks
- 🖼️ **Safe image loading** - Automatic placeholder and error widgets
- ⚡ **Performance monitoring** - Built-in performance tracking
- 🧹 **Resource management** - Automatic cleanup of timers and subscriptions
- 🎯 **Zero configuration** - Works out of the box

## 🚀 Quick Start

### 1. Add Armor to your pubspec.yaml

```yaml
dependencies:
  armor: ^1.0.0
```

### 2. Initialize Armor (one-time setup)

```dart
import 'package:armor/armor.dart';

void main() {
  ArmorInterceptor.initialize(); // Enable global error protection
  runApp(MyApp());
}
```

### 3. Add ArmorMixin to your widgets

```dart
import 'package:armor/armor.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with ArmorMixin {
  // Your widget is now protected against all common Flutter errors!
  
  @override
  Widget build(BuildContext context) {
    return safeBuild(
      () => YourActualWidget(),
      fallback: Text('Content temporarily unavailable'),
    );
  }
}
```

That's it! Your app is now armored against crashes. 🎉

## 💡 Core Methods

### `safeExecute()` - Execute any code safely
```dart
final name = safeExecute(
  () => userData!['name'] as String,
  fallback: 'Unknown User',
  cacheKey: 'user_name',
);
```

### `safeSetState()` - Prevent setState after dispose
```dart
safeSetState(() {
  counter++;
});
```

### `safeAsync()` - Safe async operations
```dart
final result = await safeAsync(() async {
  final data = await api.fetchData();
  safeSetState(() => this.data = data);
  return data;
});
```

### `safeBuild()` - Build widgets with fallback UI
```dart
return safeBuild(
  () => ComplexWidget(data: complexData),
  fallback: Text('Content temporarily unavailable'),
);
```

### `armorImage()` - Load images safely
```dart
armorImage(
  'https://example.com/image.jpg',
  width: 100,
  height: 100,
  cacheKey: 'profile_image',
)
```

### `armorNetworkRequest()` - Network calls with retry
```dart
final data = await armorNetworkRequest(
  () => api.fetchUserData(),
  fallback: cachedData,
  maxRetries: 3,
  cacheKey: 'user_data',
);
```

### `armorTimer()` - Managed timers
```dart
armorTimer(
  Duration(seconds: 5),
  () => safeSetState(() => showMessage = false),
  key: 'hide_message_timer',
);
```

## 🎯 What Armor Protects Against

| Error Type | Example | Armor Solution |
|------------|---------|----------------|
| **Null Safety** | `userData!['name']` | Returns fallback value |
| **setState after dispose** | Timer callbacks | Automatically prevented |
| **Render Overflow** | Yellow/black stripes | Responsive fallback layouts |
| **Image Loading** | Broken image URLs | Automatic placeholder widgets |
| **Network Failures** | API timeouts | Retry logic + cached fallbacks |
| **Platform Errors** | Native method calls | Graceful error handling |
| **File Operations** | Permission denied | Safe file access |
| **Memory Leaks** | Undisposed timers | Automatic resource cleanup |

## 📊 Real-World Example

Here's a complete example showing Armor protecting a user profile widget:

```dart
class UserProfile extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const UserProfile({Key? key, this.userData}) : super(key: key);
  
  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> with ArmorMixin {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: safeBuild(
          () => _buildUserContent(),
          fallback: _buildPlaceholder(),
        ),
      ),
    );
  }
  
  Widget _buildUserContent() {
    // These would normally crash with null data, but Armor provides fallbacks
    final name = safeExecute(
      () => widget.userData!['name'] as String,
      fallback: 'Unknown User',
      cacheKey: 'user_name',
    );
    
    final email = safeExecute(
      () => widget.userData!['email'] as String,
      fallback: 'no-email@example.com',
      cacheKey: 'user_email',
    );
    
    return Column(
      children: [
        armorImage(
          widget.userData?['avatar_url'] ?? '',
          width: 80,
          height: 80,
          cacheKey: 'user_avatar',
        ),
        SizedBox(height: 16),
        Text(name!, style: Theme.of(context).textTheme.headlineSmall),
        Text(email!, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
  
  Widget _buildPlaceholder() {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[300],
          child: Icon(Icons.person, size: 40),
        ),
        SizedBox(height: 16),
        Container(
          height: 20,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
```

## 📈 Monitoring & Analytics

Armor provides built-in monitoring to track protection effectiveness:

```dart
// Get protection statistics
final stats = getArmorStats();
print('Cached values: ${stats['cached_values']}');
print('Active timers: ${stats['active_timers']}');

// Monitor global error interception
final interceptor = ArmorInterceptor.instance;
print('Total errors intercepted: ${interceptor.totalIntercepted}');
print('Total errors healed: ${interceptor.totalHealed}');
print('Heal rate: ${(interceptor.healRate * 100).toStringAsFixed(1)}%');

// Listen to error stream for analytics
ArmorInterceptor.instance.errorStream.listen((error) {
  // Send to your analytics service
  analytics.recordError(error);
});
```

## 🔧 Advanced Configuration

### Custom Error Handling
```dart
// Listen to all intercepted errors
ArmorInterceptor.instance.errorStream.listen((error) {
  if (error.wasHealed) {
    print('✅ Armor healed: ${error.error}');
  } else {
    print('❌ Unhealed error: ${error.error}');
  }
});
```

### Performance Monitoring
```dart
final result = armorPerformanceOperation(
  () => expensiveComputation(),
  operationName: 'data_processing',
  warningThreshold: Duration(milliseconds: 500),
);
```

### Cache Management
```dart
// Clear cache when needed (e.g., user logout)
clearArmorCache();

// Check cache size
final stats = getArmorStats();
if (stats['cached_values'] > 1000) {
  clearArmorCache();
}
```

## 🏗️ Architecture

Armor consists of three main components:

1. **ArmorMixin** - The main protection system for widgets
2. **ArmorInterceptor** - Global error catching and healing
3. **ArmorRegistry** - Tracking and statistics for healed errors

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Your Widget   │    │   ArmorMixin     │    │ ArmorInterceptor│
│                 │───▶│  (Protection)    │───▶│ (Global Errors) │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │ Safe Operations  │    │ ArmorRegistry   │
                       │ (Fallbacks)      │    │ (Statistics)    │
                       └──────────────────┘    └─────────────────┘
```

## 🧪 Testing

Armor includes comprehensive test coverage and provides utilities for testing:

```dart
// Test your armored widgets
testWidgets('should recover from null data error', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: UserProfile(userData: null), // Null data
    ),
  );
  
  // Should show placeholder instead of crashing
  expect(find.byIcon(Icons.person), findsOneWidget);
});
```

## 🚦 Migration Guide

### From Manual Error Handling
```dart
// Before: Manual try-catch everywhere
try {
  setState(() => counter++);
} catch (e) {
  print('Error: $e');
}

// After: Armor handles it automatically
safeSetState(() => counter++);
```

### From Other Error Packages
```dart
// Before: Complex setup
SomeErrorPackage.configure(/* lots of config */);

// After: One line setup
ArmorInterceptor.initialize();
```

## 📝 Best Practices

1. **Always use ArmorMixin** for StatefulWidgets
2. **Provide meaningful fallbacks** instead of generic error messages
3. **Use cache keys** for expensive operations
4. **Monitor error statistics** to identify problem areas
5. **Clear cache periodically** to prevent memory growth

## ❓ FAQ

**Q: Does Armor add performance overhead?**
A: Minimal. Armor uses efficient error handling and caching strategies. Performance monitoring is built-in to detect any issues.

**Q: Can I use Armor with other error handling packages?**
A: Yes! Armor works alongside other packages and can complement existing error handling.

**Q: What happens to errors that can't be healed?**
A: They're logged for monitoring but won't crash your app. In debug mode, you'll still see them in the console.

**Q: Is Armor production-ready?**
A: Absolutely! Armor is designed for production use with comprehensive testing and proven patterns.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Documentation](https://pub.dev/documentation/armor/latest/)
- [Example App](example/)
- [Issue Tracker](https://github.com/your-username/armor/issues)
- [Changelog](CHANGELOG.md)

---

**Made with ❤️ for the Flutter community**

*Armor up your Flutter apps!* 🛡️