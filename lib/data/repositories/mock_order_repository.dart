import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_enums.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

final mockOrderRepositoryProvider = Provider<OrderRepository>((ref) {
  return MockOrderRepository();
});

class MockOrderRepository implements OrderRepository {
  final List<OrderModel> _orders = [];

  MockOrderRepository() {
    _seedOrders();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _yesterday() {
    final d = DateTime.now().subtract(const Duration(days: 1));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _seedOrders() {
    final today = _today();
    final yesterday = _yesterday();
    _orders.addAll([
      OrderModel(
        id: 1,
        orderNo: 'ORD-1001',
        tableNo: 'T02',
        tableId: 2,
        status: OrderStatus.preparing,
        total: 21.50,
        grandTotal: 24.69,
        createdAt: today,
        items: [
          OrderItemModel(id: 1, orderId: 1, name: 'Cheese Burger', qty: 2, price: 8.50, subtotal: 17.00, kitchenId: 1, kitchen: 'Main Kitchen', status: ItemStatus.cooking),
          OrderItemModel(id: 2, orderId: 1, name: 'Coca Cola', qty: 1, price: 2.00, subtotal: 2.00, kitchenId: 2, kitchen: 'Bar', status: ItemStatus.served),
        ],
      ),
      OrderModel(
        id: 2,
        orderNo: 'ORD-1002',
        tableNo: 'T05',
        tableId: 5,
        status: OrderStatus.cooking,
        total: 14.50,
        grandTotal: 16.63,
        createdAt: today,
        items: [
          OrderItemModel(id: 3, orderId: 2, name: 'Margherita Pizza', qty: 1, price: 12.00, subtotal: 12.00, kitchenId: 1, kitchen: 'Main Kitchen', status: ItemStatus.cooking),
          OrderItemModel(id: 4, orderId: 2, name: 'French Fries', qty: 1, price: 4.50, subtotal: 4.50, kitchenId: 1, kitchen: 'Main Kitchen', status: ItemStatus.pending),
          OrderItemModel(id: 5, orderId: 2, name: 'Lemonade', qty: 1, price: 2.50, subtotal: 2.50, kitchenId: 2, kitchen: 'Bar', status: ItemStatus.served),
        ],
      ),
      OrderModel(
        id: 3,
        orderNo: 'ORD-1003',
        tableNo: 'T08',
        tableId: 8,
        status: OrderStatus.ready,
        total: 17.00,
        grandTotal: 19.55,
        createdAt: yesterday,
        items: [
          OrderItemModel(id: 6, orderId: 3, name: 'Grilled Chicken', qty: 1, price: 11.00, subtotal: 11.00, kitchenId: 1, kitchen: 'Main Kitchen', status: ItemStatus.ready),
          OrderItemModel(id: 7, orderId: 3, name: 'Ice Cream', qty: 2, price: 3.50, subtotal: 7.00, kitchenId: 3, kitchen: 'Pastry', status: ItemStatus.ready),
        ],
      ),
    ]);
  }

  @override
  Future<OrderModel> createOrder({
    required int tableId,
    required List<Map<String, dynamic>> items,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final nextId = _orders.length + 1;
    final orderNo = 'ORD-${1000 + nextId}';
    final tableNo = 'T${tableId.toString().padLeft(2, '0')}';
    double total = 0;
    final orderItems = items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final qty = item['qty'] as int;
      final price = (item['price'] as num?)?.toDouble() ?? 8.0;
      total += qty * price;
      final name = item['name'] as String? ?? 'Item #${item['menu_item_id']}';
      return OrderItemModel(
        id: 10 + i,
        orderId: nextId,
        name: name,
        qty: qty,
        price: price,
        subtotal: qty * price,
        kitchenId: item['kitchen_id'] as int? ?? 1,
        status: ItemStatus.pending,
      );
    }).toList();
    final order = OrderModel(
      id: nextId,
      orderNo: orderNo,
      tableNo: tableNo,
      tableId: tableId,
      status: OrderStatus.new_,
      total: total,
      grandTotal: total,
      items: orderItems,
      createdAt: _today(),
    );
    _orders.add(order);
    return order;
  }

  @override
  Future<OrderModel> addItemsToOrder({
    required int orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index < 0) throw Exception('Order not found');
    final existing = _orders[index];
    final startId = existing.items.length > 0
        ? existing.items.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1
        : 10;
    double total = existing.total;
    final newItems = items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final qty = item['qty'] as int;
      final price = (item['price'] as num?)?.toDouble() ?? 8.0;
      total += qty * price;
      return OrderItemModel(
        id: startId + i,
        orderId: orderId,
        name: item['name'] as String? ?? 'Item #${item['menu_item_id']}',
        qty: qty,
        price: price,
        subtotal: qty * price,
        kitchenId: item['kitchen_id'] as int? ?? 1,
        status: ItemStatus.pending,
      );
    }).toList();
    final updated = existing.copyWith(
      total: total,
      grandTotal: total,
      items: [...existing.items, ...newItems],
    );
    _orders[index] = updated;
    return updated;
  }

  @override
  Future<List<OrderModel>> getOrders(int waiterId, {DateTime? date}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (date == null) return List.from(_orders);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _orders.where((o) => o.createdAt == dateStr).toList();
  }

  @override
  Future<OrderModel> getOrder(String orderNo) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _orders.firstWhere((o) => o.orderNo == orderNo);
  }
}
