import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

final mockAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

class MockAuthRepository implements AuthRepository {
  String? _token;
  UserModel? _user;

  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (email == 'waiter1@restaurant.com' && password == 'password123') {
      _token = 'mock_token_abc123';
      _user = UserModel(
        id: 1,
        name: 'John Waiter',
        email: email,
        role: 'waiter',
      );
      return _user!;
    }
    throw Exception('Invalid credentials');
  }

  @override
  Future<void> logout() async {
    _token = null;
    _user = null;
  }

  @override
  Future<String?> getStoredToken() async => _token;

  @override
  Future<void> storeToken(String token) async {
    _token = token;
  }

  @override
  Future<void> storeUser(UserModel user) async {
    _user = user;
  }

  @override
  Future<UserModel?> getStoredUser() async => _user;

  @override
  Future<void> clearSession() async {
    _token = null;
    _user = null;
  }
}
