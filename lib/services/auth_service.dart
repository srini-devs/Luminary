import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> signOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('session_active', false);
    await prefs.remove('first_dashboard_visit');
    await prefs.remove('last_app_open');
    if (context.mounted) {
      GoRouter.of(context).go('/sign-in');
    }
  }
}
