import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/connectivity_provider.dart';
import 'providers/dev_index_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class LuminaryApp extends ConsumerWidget {
  const LuminaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize connectivity monitoring
    ref.watch(connectivityProvider);
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Luminary',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: kDebugMode
          ? (ctx, child) => _DevIndexOverlay(router: router, child: child!)
          : null,
    );
  }
}

class _DevIndexOverlay extends ConsumerWidget {
  final GoRouter router;
  final Widget child;

  const _DevIndexOverlay({required this.router, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromIndex = ref.watch(devFromIndexProvider);
    if (!fromIndex) return child;
    final devState = ref.watch(devStateProvider);
    final topPad = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        child,
        // State badge at top of screen
        if (devState != null)
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                color: const Color(0xFF8B6FAE).withAlpha(30),
                child: Text(
                  'DEV STATE · $devState',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8B6FAE),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        // Back-to-index pill at bottom-left
        Positioned(
          left: 24,
          bottom: 50,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(devFromIndexProvider.notifier).state = false;
              ref.read(devStateProvider.notifier).state = null;
              router.go('/dev/screens');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 13, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'All Screens',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
