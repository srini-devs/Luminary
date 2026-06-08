import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while the user is viewing a screen launched from the dev screen index.
final devFromIndexProvider = StateProvider<bool>((ref) => false);

/// The state/range param associated with the current dev screen navigation.
final devStateProvider = StateProvider<String?>((ref) => null);
