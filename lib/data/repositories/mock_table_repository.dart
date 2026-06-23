import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_enums.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../repositories/table_repository.dart';

final mockTableRepositoryProvider = Provider<TableRepository>((ref) {
  return MockTableRepository();
});

class MockTableRepository implements TableRepository {
  final List<TableModel> _tables = List.generate(52, (i) {
    final statuses = [
      TableStatus.available,
      TableStatus.occupied,
      TableStatus.ordering,
      TableStatus.payment,
      TableStatus.paid,
      TableStatus.reserved,
    ];
    final status = statuses[i % statuses.length];
    CurrentOrder? order;
    if (status == TableStatus.occupied || status == TableStatus.payment) {
      order = CurrentOrder(
        id: i + 1,
        orderNo: 'ORD-${1001 + i}',
        total: 15.0 + (i * 3.5),
        duration: status == TableStatus.occupied ? '00:${20 + i}' : null,
      );
    }
    final areaNames = ['Main Hall', 'Terrace', 'VIP Room', 'Garden'];
    return TableModel(
      id: i + 1,
      tableNo: 'T${(i + 1).toString().padLeft(2, '0')}',
      capacity: [2, 4, 6, 8][i % 4],
      status: status,
      currentOrder: order,
      paymentStatus: status == TableStatus.payment ? PaymentStatus.pendingPayment : null,
      areaId: (i % 4) + 1,
      areaName: areaNames[i % 4],
      isMerged: i == 6 || i == 7,
      mergedGroupCode: i == 6 || i == 7 ? 'MG-00001' : null,
      mergedWithTables: i == 6 ? ['T08'] : i == 7 ? ['T07'] : null,
    );
  });

  @override
  Future<List<TableModel>> getTables() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_tables);
  }

  List<OrderModel> _generateMockOrders(int tableId, TableModel table) {
    final orders = <OrderModel>[];
    final hasCurrentOrder = table.currentOrder != null;

    if (hasCurrentOrder) {
      orders.add(OrderModel(
        id: tableId,
        orderNo: table.currentOrder!.orderNo,
        tableNo: table.tableNo,
        tableId: tableId,
        status: table.status == TableStatus.payment
            ? OrderStatus.completed
            : OrderStatus.processing,
        total: table.currentOrder!.total,
        grandTotal: table.currentOrder!.total * 1.15,
        items: [
          OrderItemModel(
            id: tableId * 10 + 1, orderId: tableId, name: 'Cheese Burger', qty: 2, price: 8.5,
            subtotal: 17.0, kitchenId: 1, kitchen: 'Main Kitchen', status: ItemStatus.cooking,
          ),
          OrderItemModel(
            id: tableId * 10 + 2, orderId: tableId, name: 'French Fries', qty: 1, price: 4.5,
            subtotal: 4.5, kitchenId: 1, kitchen: 'Main Kitchen', status: ItemStatus.served,
          ),
          OrderItemModel(
            id: tableId * 10 + 3, orderId: tableId, name: 'Coca Cola', qty: 2, price: 2.0,
            subtotal: 4.0, kitchenId: 2, kitchen: 'Bar', status: ItemStatus.served,
          ),
        ],
      ));
    }

    if (tableId == 2 || tableId == 5 || tableId == 8) {
      final pastStatuses = [OrderStatus.completed, OrderStatus.completed, OrderStatus.cancelled];
      final pastIdx = [tableId == 2 ? 0 : tableId == 5 ? 1 : 2][0];
      orders.add(OrderModel(
        id: 100 + tableId,
        orderNo: 'ORD-${2000 + tableId}',
        tableNo: table.tableNo,
        tableId: tableId,
        status: pastStatuses[pastIdx],
        total: 25.0 + (tableId * 2),
        grandTotal: (25.0 + (tableId * 2)) * 1.15,
        items: [
          OrderItemModel(
            id: 200 + tableId * 10 + 1, orderId: 100 + tableId, name: 'Margherita Pizza', qty: 1,
            price: 12.0, subtotal: 12.0, kitchenId: 1, kitchen: 'Main Kitchen', status: ItemStatus.completed,
          ),
          OrderItemModel(
            id: 200 + tableId * 10 + 2, orderId: 100 + tableId, name: 'Caesar Salad', qty: 1,
            price: 8.0, subtotal: 8.0, kitchenId: 1, kitchen: 'Main Kitchen', status: ItemStatus.completed,
          ),
          OrderItemModel(
            id: 200 + tableId * 10 + 3, orderId: 100 + tableId, name: 'Lemonade', qty: 2,
            price: 2.5, subtotal: 5.0, kitchenId: 2, kitchen: 'Bar', status: ItemStatus.completed,
          ),
        ],
      ));
    }

    return orders;
  }

  @override
  Future<TableModel> getTable(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final table = _tables.firstWhere((t) => t.id == id);
    final orders = _generateMockOrders(id, table);
    return table.copyWith(orders: orders);
  }

  @override
  Future<void> transferTable(int fromTableId, int toTableId, int orderId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final fromIndex = _tables.indexWhere((t) => t.id == fromTableId);
    final toIndex = _tables.indexWhere((t) => t.id == toTableId);
    if (fromIndex >= 0 && toIndex >= 0) {
      final sourceOrder = _tables[fromIndex].currentOrder;
      _tables[fromIndex] = _tables[fromIndex].copyWith(
        status: TableStatus.available,
        currentOrder: null,
      );
      _tables[toIndex] = _tables[toIndex].copyWith(
        status: TableStatus.occupied,
        currentOrder: sourceOrder,
      );
    }
  }

  @override
  Future<void> mergeTables(List<int> tableIds) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> requestBill(int tableId, int orderId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index >= 0) {
      _tables[index] = _tables[index].copyWith(
        status: TableStatus.payment,
        paymentStatus: PaymentStatus.pendingPayment,
      );
    }
  }

  @override
  Future<void> assignOrderToTable(int tableId, CurrentOrder order) async {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index >= 0) {
      _tables[index] = _tables[index].copyWith(
        status: TableStatus.occupied,
        currentOrder: order,
      );
    }
  }

  @override
  Future<void> closeTable(int tableId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index >= 0) {
      _tables[index] = _tables[index].copyWith(
        status: TableStatus.available,
        currentOrder: null,
        paymentStatus: null,
        isMerged: false,
        mergedWithTables: null,
      );
    }
  }
}
