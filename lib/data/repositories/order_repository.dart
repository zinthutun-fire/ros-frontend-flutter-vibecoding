import '../models/order_model.dart';

abstract class OrderRepository {
  Future<OrderModel> createOrder({
    required int tableId,
    required List<Map<String, dynamic>> items,
  });
  Future<OrderModel> addItemsToOrder({
    required int orderId,
    required List<Map<String, dynamic>> items,
  });
  Future<List<OrderModel>> getOrders(int waiterId, {DateTime? date});
  Future<OrderModel> getOrder(String orderNo);
}
