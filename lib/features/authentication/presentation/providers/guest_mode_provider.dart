import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../features/reader/presentation/providers/theme_providers.dart';
import 'auth_providers.dart';

/// Provider for managing guest mode state
///
/// Tracks whether the user is browsing as a guest or authenticated user.
/// Guest users can read books but need to login for save/favorite features.
final guestModeProvider = StateNotifierProvider<GuestModeNotifier, bool>((ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  return GuestModeNotifier(sharedPrefs);
});

/// Notifier for guest mode state management
class GuestModeNotifier extends StateNotifier<bool> {
  static const String _guestModeKey = 'is_guest_mode';
  final SharedPreferences _sharedPrefs;

  GuestModeNotifier(this._sharedPrefs) : super(false) {
    _loadGuestMode();
  }

  /// Load guest mode preference from storage
  void _loadGuestMode() {
    final isGuest = _sharedPrefs.getBool(_guestModeKey) ?? false;
    state = isGuest;
  }

  /// Enable guest mode
  Future<void> enableGuestMode() async {
    await _sharedPrefs.setBool(_guestModeKey, true);
    state = true;
  }

  /// Disable guest mode (when user logs in)
  Future<void> disableGuestMode() async {
    await _sharedPrefs.setBool(_guestModeKey, false);
    state = false;
  }

  /// Toggle guest mode
  Future<void> toggleGuestMode() async {
    if (state) {
      await disableGuestMode();
    } else {
      await enableGuestMode();
    }
  }
}

/// Provider that combines authentication and guest mode to determine app access
final appAccessModeProvider = Provider<AppAccessMode>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final isGuestMode = ref.watch(guestModeProvider);

  // Check if user is authenticated
  final isAuthenticated = authState.hasValue && authState.value != null;

  if (isAuthenticated) {
    return AppAccessMode.authenticated;
  } else if (isGuestMode) {
    return AppAccessMode.guest;
  } else {
    return AppAccessMode.requiresAuth;
  }
});

/// Enum representing different app access modes
enum AppAccessMode {
  /// User is fully authenticated
  authenticated,
  
  /// User is browsing as guest (limited features)
  guest,
  
  /// User needs to authenticate to access app
  requiresAuth,
}

/// Extension methods for AppAccessMode
extension AppAccessModeExtension on AppAccessMode {
  /// Whether user can read books
  bool get canReadBooks => this != AppAccessMode.requiresAuth;

  /// Whether user can save/favorite books
  bool get canSaveBooks => this == AppAccessMode.authenticated;

  /// Whether user can access profile features
  bool get canAccessProfile => this == AppAccessMode.authenticated;

  /// Whether user can sync across devices
  bool get canSync => this == AppAccessMode.authenticated;

  /// Whether user is in guest mode
  bool get isGuest => this == AppAccessMode.guest;

  /// Whether user is authenticated
  bool get isAuthenticated => this == AppAccessMode.authenticated;
}
