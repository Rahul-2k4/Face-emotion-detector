import 'package:flutter/material.dart';

import 'screens/live_camera_screen.dart';
import 'screens/simulator_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FaceConditionApp());
}

class FaceConditionApp extends StatelessWidget {
  const FaceConditionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Condition Detection',
      theme: AppTheme.darkTheme,
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentIndex == 0
            ? const LiveCameraScreen(key: ValueKey('LiveCamera'))
            : const SimulatorScreen(key: ValueKey('Simulator')),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Simulator',
          ),
        ],
      ),
    );
  }
}
