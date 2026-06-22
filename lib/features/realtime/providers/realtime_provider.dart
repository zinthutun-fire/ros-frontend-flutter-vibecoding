import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sockets/socket_service.dart';
import '../../../core/sockets/realtime_socket_service.dart';

final realtimeProvider = StateNotifierProvider<RealtimeNotifier, RealtimeState>((ref) {
  return RealtimeNotifier(ref);
});

class RealtimeState {
  final bool isConnected;

  const RealtimeState({this.isConnected = false});
}

class RealtimeNotifier extends StateNotifier<RealtimeState> {
  final Ref _ref;
  SocketService? _socket;
  final Set<String> _subscribedChannels = {};

  RealtimeNotifier(this._ref) : super(const RealtimeState());

  void connect(String token) {
    _socket?.disconnect();
    _socket = RealtimeSocketService();
    _socket!.connect(token);
  }

  void subscribeForRole(String role, {int? kitchenId, int? userId}) {
    _subscribeChannel('orders.*');
    _subscribeChannel('tables.*');
    _subscribeChannel('cashier');
    if (role == 'kitchen' && kitchenId != null) {
      _subscribeChannel('kitchen.$kitchenId');
    }
  }

  void _subscribeChannel(String channel) {
    if (_subscribedChannels.contains(channel)) return;
    _socket?.subscribe(channel, (event) {
      _handleEvent(event);
    });
    _subscribedChannels.add(channel);
  }

  void _handleEvent(Map<String, dynamic> event) {
    final eventName = event['_event'] as String?;
    if (eventName == null) return;

    if (eventName.contains('\\OrderCreated')) {
      _ref.read(orderRealtimeProvider.notifier).onOrderCreated(event);
    } else if (eventName.contains('\\OrderUpdated')) {
      _ref.read(orderRealtimeProvider.notifier).onOrderUpdated(event);
    } else if (eventName.contains('\\ItemStatusUpdated')) {
      _ref.read(orderRealtimeProvider.notifier).onItemStatusUpdated(event);
    } else if (eventName.contains('\\TableStatusChanged') || eventName.contains('\\PaymentCompleted')) {
      _ref.read(tableRealtimeProvider.notifier).onTableEvent(event);
    } else if (eventName.contains('\\TableMerged') || eventName.contains('\\TableTransferred')) {
      _ref.read(tableRealtimeProvider.notifier).requestReload();
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _subscribedChannels.clear();
    state = const RealtimeState();
  }
}

final orderRealtimeProvider = StateNotifierProvider<OrderRealtimeNotifier, OrderRealtimeState>((ref) {
  return OrderRealtimeNotifier();
});

class OrderRealtimeState {
  final Map<String, Map<String, dynamic>> orders;
  const OrderRealtimeState({this.orders = const {}});
}

class OrderRealtimeNotifier extends StateNotifier<OrderRealtimeState> {
  OrderRealtimeNotifier() : super(const OrderRealtimeState());

  void onOrderCreated(Map<String, dynamic> event) {
    final orderNo = event['order_no'] as String?;
    if (orderNo != null) {
      final updated = Map<String, Map<String, dynamic>>.from(state.orders);
      updated[orderNo] = event;
      state = OrderRealtimeState(orders: updated);
    }
  }

  void onOrderUpdated(Map<String, dynamic> event) {
    final orderNo = event['order_no'] as String?;
    if (orderNo != null) {
      final updated = Map<String, Map<String, dynamic>>.from(state.orders);
      updated[orderNo] = event;
      state = OrderRealtimeState(orders: updated);
    }
  }

  void onItemStatusUpdated(Map<String, dynamic> event) {
    final orderNo = event['order_no'] as String?;
    if (orderNo != null) {
      final updated = Map<String, Map<String, dynamic>>.from(state.orders);
      updated[orderNo] = event;
      state = OrderRealtimeState(orders: updated);
    }
  }
}

final tableRealtimeProvider = StateNotifierProvider<TableRealtimeNotifier, TableRealtimeState>((ref) {
  return TableRealtimeNotifier();
});

class TableRealtimeState {
  final Map<int, Map<String, dynamic>> tables;
  final bool needsReload;
  const TableRealtimeState({this.tables = const {}, this.needsReload = false});
}

class TableRealtimeNotifier extends StateNotifier<TableRealtimeState> {
  TableRealtimeNotifier() : super(const TableRealtimeState());

  void onTableEvent(Map<String, dynamic> event) {
    final tableId = event['table_id'] as int?;
    if (tableId != null) {
      final updated = Map<int, Map<String, dynamic>>.from(state.tables);
      updated[tableId] = event;
      state = TableRealtimeState(tables: updated);
    }
  }

  void requestReload() {
    state = const TableRealtimeState(needsReload: true);
  }
}
