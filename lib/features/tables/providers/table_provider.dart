import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_enums.dart';
import '../../../data/models/table_model.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../data/services/table_service.dart';
import '../../realtime/providers/realtime_provider.dart';

final tableProvider = StateNotifierProvider<TableNotifier, TableState>((ref) {
  final notifier = TableNotifier(ref);
  ref.listen(tableRealtimeProvider, (prev, next) {
    notifier._syncFromRealtime(next);
  });
  return notifier;
});

class TableState {
  final List<TableModel> tables;
  final List<TableModel> filteredTables;
  final bool isLoading;
  final String? error;
  final int? selectedAreaId;

  const TableState({
    this.tables = const [],
    this.filteredTables = const [],
    this.isLoading = false,
    this.error,
    this.selectedAreaId,
  });

  bool get hasFilter => selectedAreaId != null;

  TableState copyWith({
    List<TableModel>? tables,
    List<TableModel>? filteredTables,
    bool? isLoading,
    String? error,
    int? selectedAreaId,
  }) {
    return TableState(
      tables: tables ?? this.tables,
      filteredTables: filteredTables ?? this.filteredTables,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedAreaId: selectedAreaId ?? this.selectedAreaId,
    );
  }
}

class TableNotifier extends StateNotifier<TableState> {
  final Ref _ref;
  late final TableRepository _repository;

  TableNotifier(this._ref) : super(const TableState()) {
    _repository = _ref.read(tableServiceProvider);
  }

  List<Map<String, dynamic>> get areas {
    final seen = <int>{};
    final result = <Map<String, dynamic>>[];
    for (final t in state.tables) {
      if (t.areaId != null && seen.add(t.areaId!)) {
        result.add({'id': t.areaId, 'name': t.areaName});
      }
    }
    result.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return result;
  }

  Future<void> loadTables() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tables = await _repository.getTables();
      state = TableState(tables: tables, filteredTables: tables);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void filterByArea(int? areaId) {
    if (areaId == null) {
      state = state.copyWith(
        selectedAreaId: null,
        filteredTables: List.from(state.tables),
      );
    } else {
      state = state.copyWith(
        selectedAreaId: areaId,
        filteredTables: state.tables.where((t) => t.areaId == areaId).toList(),
      );
    }
  }

  Future<void> transferTable(int fromTableId, int toTableId, int orderId) async {
    try {
      await _repository.transferTable(fromTableId, toTableId, orderId);
      await loadTables();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> mergeTables(List<int> tableIds) async {
    try {
      await _repository.mergeTables(tableIds);
      await loadTables();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> closeTable(int tableId) async {
    await _repository.closeTable(tableId);
    updateTableStatus(tableId, TableStatus.available);
  }

  void updateTableStatus(int tableId, TableStatus status) {
    final tables = state.tables.map((t) {
      if (t.id == tableId) return t.copyWith(status: status);
      return t;
    }).toList();
    _applyFilter(tables);
  }

  Future<void> assignOrderToTable(int tableId, CurrentOrder order) async {
    await _repository.assignOrderToTable(tableId, order);
    final tables = state.tables.map((t) {
      if (t.id == tableId) {
        return t.copyWith(status: TableStatus.occupied, currentOrder: order);
      }
      return t;
    }).toList();
    _applyFilter(tables);
  }

  void handleTableEvent(Map<String, dynamic> event) {
    final tableId = event['table_id'] as int?;
    if (tableId == null) return;
    final status = TableStatus.fromString(event['status'] as String? ?? '');
    updateTableStatus(tableId, status);
  }

  void _syncFromRealtime(TableRealtimeState realtime) {
    if (realtime.needsReload) {
      loadTables();
      return;
    }
    for (final entry in realtime.tables.entries) {
      handleTableEvent(entry.value);
    }
  }

  void _applyFilter(List<TableModel> tables) {
    final filtered = state.selectedAreaId == null
        ? tables
        : tables.where((t) => t.areaId == state.selectedAreaId).toList();
    state = state.copyWith(tables: tables, filteredTables: filtered);
  }
}
