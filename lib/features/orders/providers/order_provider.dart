import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_enums.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/services/order_service.dart';
import '../../realtime/providers/realtime_provider.dart';

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final notifier = OrderNotifier(ref);
  ref.listen(orderRealtimeProvider, (prev, next) {
    notifier._syncFromRealtime(next);
  });
  return notifier;
});

class OrderState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? error;
  final OrderModel? lastCreatedOrder;
  final OrderModel? selectedOrder;
  final DateTime? selectedDate;

  const OrderState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.lastCreatedOrder,
    this.selectedOrder,
    this.selectedDate,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? error,
    OrderModel? lastCreatedOrder,
    OrderModel? selectedOrder,
    DateTime? selectedDate,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastCreatedOrder: lastCreatedOrder,
      selectedOrder: selectedOrder ?? this.selectedOrder,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final Ref _ref;
  late final OrderRepository _repository;

  OrderNotifier(this._ref) : super(const OrderState()) {
    _repository = _ref.read(orderServiceProvider);
  }

  Future<void> loadOrders(int waiterId, {DateTime? date}) async {
    state = state.copyWith(isLoading: true, error: null, selectedDate: date);
    try {
      final orders = await _repository.getOrders(waiterId, date: date);
      state = OrderState(orders: orders, selectedDate: date);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void filterByDate(DateTime date) {
    loadOrders(1, date: date);
  }

  void clearDateFilter() {
    loadOrders(1);
  }

  Future<void> createOrder({
    required int tableId,
    required List<Map<String, dynamic>> items,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final order = await _repository.createOrder(tableId: tableId, items: items);
      state = state.copyWith(
        isLoading: false,
        orders: [...state.orders, order],
        lastCreatedOrder: order,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addItemsToOrder({
    required int orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final order = await _repository.addItemsToOrder(orderId: orderId, items: items);
      final orders = state.orders.map((o) {
        if (o.id == orderId) return order;
        return o;
      }).toList();
      state = state.copyWith(
        isLoading: false,
        orders: orders,
        lastCreatedOrder: order,
        selectedOrder: state.selectedOrder?.id == orderId ? order : state.selectedOrder,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearLastOrder() {
    state = state.copyWith(lastCreatedOrder: null);
  }

  Future<void> getOrder(String orderNo) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final order = await _repository.getOrder(orderNo);
      state = state.copyWith(isLoading: false, selectedOrder: order);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateOrderFromRealtime(Map<String, dynamic> event) {
    final orderNo = event['order_no'] as String?;
    if (orderNo == null) return;

    final updated = state.orders.map((o) {
      if (o.orderNo == orderNo) {
        final items = event['items'] as List<dynamic>?;
        return o.copyWith(
          status: OrderStatus.fromString(event['status'] as String? ?? o.status.name),
          total: (event['grand_total'] as num?)?.toDouble() ?? o.total,
          items: items != null
              ? items.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList()
              : null,
        );
      }
      return o;
    }).toList();

    OrderModel? updatedSelected;
    if (state.selectedOrder?.orderNo == orderNo) {
      updatedSelected = updated.firstWhere((o) => o.orderNo == orderNo);
    }

    state = state.copyWith(orders: updated, selectedOrder: updatedSelected);
  }

  void _syncFromRealtime(OrderRealtimeState realtime) {
    for (final entry in realtime.orders.entries) {
      updateOrderFromRealtime(entry.value);
    }
  }
}
