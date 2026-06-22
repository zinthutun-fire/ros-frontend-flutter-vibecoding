import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/table_model.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/services/table_service.dart';
import '../../../data/services/order_service.dart';
import '../../../core/constants/app_enums.dart';
import '../../realtime/providers/realtime_provider.dart';

final tableDetailProvider = StateNotifierProvider.family<TableDetailNotifier, TableDetailState, int>((ref, tableId) {
  final notifier = TableDetailNotifier(ref, tableId);
  ref.listen(tableRealtimeProvider, (prev, next) {
    notifier._syncFromRealtime(next);
  });
  ref.listen(orderRealtimeProvider, (prev, next) {
    notifier._syncOrderFromRealtime(next);
  });
  return notifier;
});

class TableDetailState {
  final TableModel? table;
  final bool isLoading;
  final String? error;
  final bool isBillRequested;
  final List<OrderItemModel> items;
  final List<OrderModel> orders;

  const TableDetailState({
    this.table,
    this.isLoading = false,
    this.error,
    this.isBillRequested = false,
    this.items = const [],
    this.orders = const [],
  });

  TableDetailState copyWith({
    TableModel? table,
    bool? isLoading,
    String? error,
    bool? isBillRequested,
    List<OrderItemModel>? items,
    List<OrderModel>? orders,
  }) {
    return TableDetailState(
      table: table ?? this.table,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isBillRequested: isBillRequested ?? this.isBillRequested,
      items: items ?? this.items,
      orders: orders ?? this.orders,
    );
  }
}

class TableDetailNotifier extends StateNotifier<TableDetailState> {
  late final TableRepository _repository;
  late final OrderRepository _orderRepository;
  final int _tableId;

  TableDetailNotifier(Ref ref, this._tableId) : super(const TableDetailState()) {
    _repository = ref.read(tableServiceProvider);
    _orderRepository = ref.read(orderServiceProvider);
  }

  Future<void> loadTable({String? orderNo, List<OrderItemModel>? items}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      debugPrint('[loadTable] called: orderNo=$orderNo, items=${items?.length}');
      final table = await _repository.getTable(_tableId);

      if (table.orders != null && table.orders!.isNotEmpty) {
        final allOrders = List<OrderModel>.from(table.orders!);
        final currentOrderNo = table.currentOrder?.orderNo;
        allOrders.sort((a, b) {
          if (a.orderNo == currentOrderNo) return -1;
          if (b.orderNo == currentOrderNo) return 1;
          return b.id.compareTo(a.id);
        });
        final displayItems = allOrders.isNotEmpty ? allOrders.first.items : <OrderItemModel>[];
        state = TableDetailState(table: table, items: displayItems, orders: allOrders);
      } else if (items != null) {
        debugPrint('[loadTable] Using passed items: ${items.length} items');
        state = TableDetailState(table: table, items: items);
      } else {
        final targetOrderNo = orderNo ?? table.currentOrder?.orderNo;
        debugPrint('[loadTable] Fetching order: $targetOrderNo');
        if (targetOrderNo != null) {
          try {
            final order = await _orderRepository.getOrder(targetOrderNo);
            debugPrint('[loadTable] Fetched order ${order.orderNo} with ${order.items.length} items');
            state = TableDetailState(table: table, items: order.items, orders: [order]);
          } catch (_) {
            debugPrint('[loadTable] Failed to fetch order $targetOrderNo');
            state = TableDetailState(table: table);
          }
        } else {
          state = TableDetailState(table: table);
        }
      }
    } catch (e) {
      debugPrint('[loadTable] Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> transferTable(int toTableId, int orderId) async {
    try {
      await _repository.transferTable(_tableId, toTableId, orderId);
      await loadTable();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> requestBill(int orderId) async {
    state = state.copyWith(isBillRequested: true, error: null);
    try {
      await _repository.requestBill(_tableId, orderId);
      state = state.copyWith(isBillRequested: false);
      await loadTable();
    } catch (e) {
      state = state.copyWith(isBillRequested: false, error: e.toString());
    }
  }

  void handleTableEvent(Map<String, dynamic> event) {
    final tableId = event['table_id'] as int?;
    if (tableId != _tableId) return;
    final status = TableStatus.fromString(event['status'] as String? ?? '');
    final current = state.table;
    if (current != null) {
      state = state.copyWith(table: current.copyWith(status: status));
    }
  }

  void _syncFromRealtime(TableRealtimeState realtime) {
    for (final entry in realtime.tables.entries) {
      handleTableEvent(entry.value);
    }
  }

  void _syncOrderFromRealtime(OrderRealtimeState realtime) {
    final currentOrderNo = state.table?.currentOrder?.orderNo;
    if (currentOrderNo == null) return;
    for (final entry in realtime.orders.entries) {
      if (entry.key == currentOrderNo) {
        final items = entry.value['items'] as List<dynamic>?;
        if (items != null && items.isNotEmpty) {
          final firstItem = items.first as Map<String, dynamic>;
          final hasPrice = firstItem.containsKey('price');
          if (hasPrice) {
            final currentOrderItems = items
                .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
                .toList();
            final nonCurrentItems = state.items
                .where((item) => item.orderId != currentOrderItems.first.orderId)
                .toList();
            state = state.copyWith(
              items: [...nonCurrentItems, ...currentOrderItems],
              orders: state.orders.map((o) {
                if (o.orderNo == currentOrderNo) {
                  return o.copyWith(items: currentOrderItems);
                }
                return o;
              }).toList(),
            );
          } else {
            final updatedItems = state.items.map((existing) {
              for (final updated in items) {
                final u = updated as Map<String, dynamic>;
                if (existing.id == u['id'] as int) {
                  return existing.copyWith(
                    status: ItemStatus.fromString(u['status'] as String? ?? existing.status.name),
                  );
                }
              }
              return existing;
            }).toList();
            final updatedOrders = state.orders.map((o) {
              if (o.orderNo == currentOrderNo) {
                final updatedOrderItems = o.items.map((existing) {
                  for (final updated in items) {
                    final u = updated as Map<String, dynamic>;
                    if (existing.id == u['id'] as int) {
                      return existing.copyWith(
                        status: ItemStatus.fromString(u['status'] as String? ?? existing.status.name),
                      );
                    }
                  }
                  return existing;
                }).toList();
                return o.copyWith(items: updatedOrderItems);
              }
              return o;
            }).toList();
            state = state.copyWith(items: updatedItems, orders: updatedOrders);
          }
        }
      }
    }
  }
}
