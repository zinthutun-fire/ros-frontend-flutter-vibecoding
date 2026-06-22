import '../models/table_model.dart';

abstract class TableRepository {
  Future<List<TableModel>> getTables();
  Future<TableModel> getTable(int id);
  Future<void> transferTable(int fromTableId, int toTableId, int orderId);
  Future<void> mergeTables(List<int> tableIds);
  Future<void> requestBill(int tableId, int orderId);
  Future<void> assignOrderToTable(int tableId, CurrentOrder order);
  Future<void> closeTable(int tableId);
}
