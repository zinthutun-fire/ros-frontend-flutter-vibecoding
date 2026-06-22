import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<String?> getStoredToken();
  Future<void> storeToken(String token);
  Future<void> storeUser(UserModel user);
  Future<UserModel?> getStoredUser();
  Future<void> clearSession();
}
