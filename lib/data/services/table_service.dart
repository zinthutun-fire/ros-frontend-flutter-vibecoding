import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/table_model.dart';
import '../repositories/table_repository.dart';

final tableServiceProvider = Provider<TableRepository>((ref) {
  return TableService(ref.read(dioProvider));
});

class TableService implements TableRepository {
  final Dio _dio;

  TableService(this._dio);

  @override
  Future<List<TableModel>> getTables() async {
    final response = await _dio.get(ApiConstants.tables, queryParameters: {'per_page': 100});
    final data = ApiConstants.parseResponse(response.data);
    final list = data['data'] as List<dynamic>? ?? <dynamic>[];
    return list
        .map((e) => TableModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TableModel> getTable(int id) async {
    final response = await _dio.get('${ApiConstants.tables}/$id');
    final data = ApiConstants.parseResponse(response.data);
    final item = data['data'] as Map<String, dynamic>? ?? data;
    return TableModel.fromJson(item);
  }

  @override
  Future<void> transferTable(int fromTableId, int toTableId, int orderId) async {
    await _dio.post(ApiConstants.tableTransfer, data: {
      'from_table_id': fromTableId,
      'to_table_id': toTableId,
      'order_id': orderId,
    });
  }

  @override
  Future<void> mergeTables(List<int> tableIds) async {
    await _dio.post(ApiConstants.tableMerge, data: {
      'table_ids': tableIds,
    });
  }

  @override
  Future<void> requestBill(int tableId, int orderId) async {
    await _dio.get('${ApiConstants.orders}/$orderId/bill');
  }

  @override
  Future<void> assignOrderToTable(int tableId, CurrentOrder order) async {
    // Server handles this via order creation
  }

  @override
  Future<void> closeTable(int tableId) async {
    await _dio.patch('${ApiConstants.tables}/$tableId/close');
  }
}
