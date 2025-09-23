import 'package:flutter/material.dart';
import 'package:armor/armor.dart';
import 'dart:async';

void main() {
  // Initialize Armor error interception
  ArmorInterceptor.initialize();

  runApp(const ArmorExampleApp());
}

class ArmorExampleApp extends StatelessWidget {
  const ArmorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Armor Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ArmorDemoScreen(),
    );
  }
}

class ArmorDemoScreen extends StatefulWidget {
  const ArmorDemoScreen({super.key});

  @override
  State<ArmorDemoScreen> createState() => _ArmorDemoScreenState();
}

class _ArmorDemoScreenState extends State<ArmorDemoScreen> with ArmorMixin {
  Map<String, dynamic>? userData;
  int counter = 0;
  bool showCrashyWidget = false;

  @override
  Widget build(BuildContext context) {
    final interceptor = ArmorInterceptor.instance;
    final stats = getArmorStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ Armor Demo'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Armor Status Card
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield,
                          color: Colors.green.shade700, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'Armor Protection Status',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                      'Errors Intercepted',
                      interceptor.totalIntercepted,
                      Icons.bug_report,
                      Colors.orange),
                  _buildStatRow('Errors Healed', interceptor.totalHealed,
                      Icons.healing, Colors.green),
                  _buildStatRow(
                      'Heal Rate',
                      '${(interceptor.healRate * 100).toStringAsFixed(1)}%',
                      Icons.percent,
                      Colors.blue),
                  _buildStatRow('Cached Values', stats['cached_values'],
                      Icons.storage, Colors.purple),
                  _buildStatRow('Active Timers', stats['active_timers'],
                      Icons.timer, Colors.indigo),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Demo 1: Null Safety Protection
          _buildDemoCard(
            title: '🚫 Null Safety Protection',
            description: 'Show how Armor handles null data gracefully',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        safeSetState(() {
                          showCrashyWidget = true;
                          userData = null; // This would normally crash
                        });
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Trigger Null Error'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        safeSetState(() {
                          userData = {
                            'name': 'John Doe',
                            'email': 'john@example.com',
                            'avatar': 'https://i.pravatar.cc/150?img=3',
                          };
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('Add Valid Data'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (showCrashyWidget) const ArmoredUserCard(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Demo 2: Image Loading
          _buildDemoCard(
            title: '🖼️ Safe Image Loading',
            description: 'Armor automatically handles broken images',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Working Image:',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    armorImage(
                      'https://i.pravatar.cc/100?img=1',
                      width: 80,
                      height: 80,
                      cacheKey: 'working_image',
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Broken Image:', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    armorImage(
                      'https://invalid-url.com/broken.jpg',
                      width: 80,
                      height: 80,
                      cacheKey: 'broken_image',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Demo 3: Async Safety
          _buildDemoCard(
            title: '⏱️ Async Operation Safety',
            description: 'Safe timers and async operations',
            child: Column(
              children: [
                Text('Counter: $counter', style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Safe timer that won't leak
                        armorTimer(
                          const Duration(seconds: 1),
                          () => safeSetState(() => counter++),
                          key: 'counter_timer',
                          periodic: true,
                        );
                      },
                      child: const Text('Start Safe Timer'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        safeSetState(() => counter = 0);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Demo 4: Network Request Simulation
          _buildDemoCard(
            title: '🌐 Network Safety',
            description: 'Network requests with retry and fallback',
            child: const NetworkDemo(),
          ),

          const SizedBox(height: 16),

          // Demo 5: Render Overflow Protection
          _buildDemoCard(
            title: '📐 Overflow Protection',
            description: 'Automatic handling of render overflow',
            child: const OverflowDemo(),
          ),

          const SizedBox(height: 24),

          // Error Log
          if (interceptor.interceptedErrors.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Intercepted Errors',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ...interceptor.interceptedErrors.reversed.take(3).map(
                          (error) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: error.wasHealed
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: error.wasHealed
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  error.wasHealed ? Icons.shield : Icons.error,
                                  color: error.wasHealed
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getErrorSummary(error.error.toString()),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                if (error.wasHealed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'HEALED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
      String label, dynamic value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  String _getErrorSummary(String error) {
    if (error.contains('Null check operator')) {
      return 'Null Safety Error - Healed with fallback value';
    } else if (error.contains('setState() called after dispose')) {
      return 'setState After Dispose - Prevented automatically';
    } else if (error.contains('RenderFlex overflowed')) {
      return 'Render Overflow - Layout adapted automatically';
    } else {
      return error.split('\n').first;
    }
  }
}

// Example of a widget using ArmorMixin
class ArmoredUserCard extends StatefulWidget {
  const ArmoredUserCard({super.key});

  @override
  State<ArmoredUserCard> createState() => _ArmoredUserCardState();
}

class _ArmoredUserCardState extends State<ArmoredUserCard> with ArmorMixin {
  @override
  Widget build(BuildContext context) {
    // This widget intentionally accesses null data to demonstrate armor protection
    final userData =
        context.findAncestorStateOfType<_ArmorDemoScreenState>()?.userData;

    return safeBuild(
      () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(userData!['avatar']),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(userData['email']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      fallback: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User data unavailable',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Armor provided fallback UI'),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PROTECTED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Network demo widget
class NetworkDemo extends StatefulWidget {
  const NetworkDemo({super.key});

  @override
  State<NetworkDemo> createState() => _NetworkDemoState();
}

class _NetworkDemoState extends State<NetworkDemo> with ArmorMixin {
  String status = 'Ready';
  bool isLoading = false;

  Future<void> _simulateNetworkCall(bool shouldFail) async {
    safeSetState(() {
      isLoading = true;
      status = 'Loading...';
    });

    final result = await armorNetworkRequest<String>(
      () async {
        await Future.delayed(const Duration(seconds: 2));
        if (shouldFail) {
          throw Exception('Network error');
        }
        return 'Success! Data loaded';
      },
      fallback: 'Failed - using cached data',
      maxRetries: 2,
      cacheKey: 'demo_data',
    );

    safeSetState(() {
      isLoading = false;
      status = result ?? 'No data available';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(status, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        if (isLoading) const CircularProgressIndicator(),
        if (!isLoading)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _simulateNetworkCall(false),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Success Call'),
              ),
              ElevatedButton(
                onPressed: () => _simulateNetworkCall(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Fail Call'),
              ),
            ],
          ),
      ],
    );
  }
}

// Overflow demo widget
class OverflowDemo extends StatefulWidget {
  const OverflowDemo({super.key});

  @override
  State<OverflowDemo> createState() => _OverflowDemoState();
}

class _OverflowDemoState extends State<OverflowDemo> with ArmorMixin {
  bool forceOverflow = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => safeSetState(() => forceOverflow = !forceOverflow),
          child: Text(forceOverflow ? 'Fix Layout' : 'Trigger Overflow'),
        ),
        const SizedBox(height: 16),
        safeBuild(
          () => forceOverflow
              ? const Row(
                  children: [
                    // This would normally overflow
                    Text(
                        'This is a very long text that would normally cause overflow'),
                    Text('More text that definitely overflows'),
                    Text('Even more overflowing text'),
                  ],
                )
              : const Text('Normal text that fits'),
          fallback: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: const Text(
              'Layout overflow detected - Armor provided safe fallback',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ),
      ],
    );
  }
}
