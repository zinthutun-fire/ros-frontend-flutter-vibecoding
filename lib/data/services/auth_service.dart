import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

final authServiceProvider = Provider<AuthRepository>((ref) {
  return AuthService(ref.read(dioProvider), ref);
});

class AuthService implements AuthRepository {
  final Dio _dio;
  String? _storedToken;
  UserModel? _storedUser;

  AuthService(this._dio, Ref ref);

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });
    final data = ApiConstants.parseResponse(response.data);
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    _storedToken = token;
    _storedUser = user;

    final authInterceptor = _dio.interceptors
        .whereType<AuthInterceptor>()
        .firstOrNull;
    authInterceptor?.updateToken(token);

    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (_) {}
    _storedToken = null;
    _storedUser = null;
    final authInterceptor = _dio.interceptors
        .whereType<AuthInterceptor>()
        .firstOrNull;
    authInterceptor?.updateToken(null);
  }

  @override
  Future<String?> getStoredToken() async => _storedToken;

  @override
  Future<void> storeToken(String token) async {
    _storedToken = token;
    final authInterceptor = _dio.interceptors
        .whereType<AuthInterceptor>()
        .firstOrNull;
    authInterceptor?.updateToken(token);
  }

  @override
  Future<void> storeUser(UserModel user) async {
    _storedUser = user;
  }

  @override
  Future<UserModel?> getStoredUser() async => _storedUser;

  @override
  Future<void> clearSession() async {
    _storedToken = null;
    _storedUser = null;
  }
}
