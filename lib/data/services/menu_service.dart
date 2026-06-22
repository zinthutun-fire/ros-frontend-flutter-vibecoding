import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/menu_item_model.dart';
import '../repositories/menu_repository.dart';

final menuServiceProvider = Provider<MenuRepository>((ref) {
  return MenuService(ref.read(dioProvider));
});

class MenuService implements MenuRepository {
  final Dio _dio;

  MenuService(this._dio);

  @override
  Future<List<MenuItemModel>> getMenuItems() async {
    final response = await _dio.get(ApiConstants.menuItems);
    final data = ApiConstants.parseResponse(response.data);
    final list = data['data'] as List<dynamic>? ?? <dynamic>[];
    return list
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
