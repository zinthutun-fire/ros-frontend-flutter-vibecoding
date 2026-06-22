import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

final orderServiceProvider = Provider<OrderRepository>((ref) {
  return OrderService(ref.read(dioProvider));
});

class OrderService implements OrderRepository {
  final Dio _dio;

  OrderService(this._dio);

  @override
  Future<OrderModel> createOrder({
    required int tableId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _dio.post(ApiConstants.orders, data: {
      'table_id': tableId,
      'items': items,
    });
    final data = ApiConstants.parseResponse(response.data);
    final item = data['data'] as Map<String, dynamic>? ?? data;
    return OrderModel.fromJson(item);
  }

  @override
  Future<OrderModel> addItemsToOrder({
    required int orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _dio.post('${ApiConstants.orders}/$orderId/items', data: {
      'items': items,
    });
    final data = ApiConstants.parseResponse(response.data);
    final item = data['data'] as Map<String, dynamic>? ?? data;
    return OrderModel.fromJson(item);
  }

  @override
  Future<List<OrderModel>> getOrders(int waiterId, {DateTime? date}) async {
    final params = <String, dynamic>{};
    if (date != null) {
      params['date'] = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    final response = await _dio.get(ApiConstants.orders, queryParameters: params);
    final data = ApiConstants.parseResponse(response.data);
    final list = data['data'] as List<dynamic>? ?? <dynamic>[];
    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderModel> getOrder(String orderNo) async {
    final response = await _dio.get('${ApiConstants.orders}/by-order-no/$orderNo');
    final data = ApiConstants.parseResponse(response.data);
    final item = data['data'] as Map<String, dynamic>? ?? data;
    return OrderModel.fromJson(item);
  }
}
