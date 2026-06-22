import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/providers.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../realtime/providers/realtime_provider.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final String? token;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.token,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    String? token,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  late final AuthRepository _repository;
  late final FlutterSecureStorage _storage;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _repository = _ref.read(authServiceProvider);
    _storage = _ref.read(secureStorageProvider);
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    try {
      final token = await _storage.read(key: ApiConstants.tokenKey);
      final userJsonStr = await _storage.read(key: ApiConstants.userKey);
      if (token == null || userJsonStr == null || token.isEmpty) return;

      final userMap = jsonDecode(userJsonStr) as Map<String, dynamic>;
      final user = UserModel.fromJson(userMap);
      await _repository.storeToken(token);

      final dio = _ref.read(dioProvider);
      final response = await dio.get(ApiConstants.me);
      final meData = ApiConstants.parseResponse(response.data);
      final verifiedUser = UserModel.fromJson(meData['user'] as Map<String, dynamic>);
      state = AuthState(user: verifiedUser, isAuthenticated: true, token: token);
      _connectSocket(token, user.role, user.kitchenId);
    } catch (_) {
      await _storage.delete(key: ApiConstants.tokenKey);
      await _storage.delete(key: ApiConstants.userKey);
      await _repository.clearSession();
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.login(email, password);
      final token = await _repository.getStoredToken() ?? '';

      await _storage.write(key: ApiConstants.tokenKey, value: token);
      await _storage.write(key: ApiConstants.userKey, value: jsonEncode(user.toJson()));

      state = AuthState(user: user, isAuthenticated: true, token: token);
      _connectSocket(token, user.role, user.kitchenId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _connectSocket(String token, String role, int? kitchenId) {
    _ref.read(realtimeProvider.notifier).connect(token);
    _ref.read(realtimeProvider.notifier).subscribeForRole(role, kitchenId: kitchenId);
  }

  Future<void> loginWithToken(String token, UserModel user) async {
    await _repository.storeToken(token);
    await _storage.write(key: ApiConstants.tokenKey, value: token);
    await _storage.write(key: ApiConstants.userKey, value: jsonEncode(user.toJson()));
    state = AuthState(user: user, isAuthenticated: true, token: token);
    _connectSocket(token, user.role, user.kitchenId);
  }

  Future<void> logout() async {
    _ref.read(realtimeProvider.notifier).disconnect();
    await _repository.logout();
    await _storage.delete(key: ApiConstants.tokenKey);
    await _storage.delete(key: ApiConstants.userKey);
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
