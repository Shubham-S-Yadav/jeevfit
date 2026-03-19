import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, onboarding }

class AuthNotifier extends StateNotifier<AuthData> {
  final ApiService _api = ApiService();

  AuthNotifier() : super(AuthData(state: AuthState.initial)) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = state.copyWith(state: AuthState.loading);
    try {
      final isLoggedIn = await _api.isLoggedIn();
      if (isLoggedIn) {
        final user = await _api.getMe();
        final isOnboarded = user['is_onboarded'] ?? false;
        state = AuthData(
          state: isOnboarded ? AuthState.authenticated : AuthState.onboarding,
          user: user,
        );
      } else {
        state = AuthData(state: AuthState.unauthenticated);
      }
    } catch (e) {
      state = AuthData(state: AuthState.unauthenticated);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(state: AuthState.loading);
    try {
      final data = await _api.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      state = AuthData(state: AuthState.onboarding, user: data['user']);
    } catch (e) {
      state = AuthData(state: AuthState.unauthenticated, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(state: AuthState.loading);
    try {
      final data = await _api.login(email: email, password: password);
      final user = data['user'];
      final isOnboarded = user['is_onboarded'] ?? false;
      state = AuthData(
        state: isOnboarded ? AuthState.authenticated : AuthState.onboarding,
        user: user,
      );
    } catch (e) {
      state = AuthData(state: AuthState.unauthenticated, error: _parseError(e));
      rethrow;
    }
  }

  void completeOnboarding() {
    state = state.copyWith(state: AuthState.authenticated);
  }

  Future<void> logout() async {
    await _api.logout();
    state = AuthData(state: AuthState.unauthenticated);
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      return e.toString().replaceAll('Exception: ', '');
    }
    return 'Something went wrong';
  }
}

class AuthData {
  final AuthState state;
  final Map<String, dynamic>? user;
  final String? error;

  AuthData({required this.state, this.user, this.error});

  AuthData copyWith({AuthState? state, Map<String, dynamic>? user, String? error}) {
    return AuthData(
      state: state ?? this.state,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthData>((ref) {
  return AuthNotifier();
});
