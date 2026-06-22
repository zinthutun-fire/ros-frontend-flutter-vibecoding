import '../../core/constants/app_enums.dart';
import 'order_model.dart';

class CurrentOrder {
  final int id;
  final String orderNo;
  final double total;
  final double grandTotal;
  final String? duration;

  const CurrentOrder({
    required this.id,
    required this.orderNo,
    required this.total,
    this.grandTotal = 0.0,
    this.duration,
  });

  factory CurrentOrder.fromJson(Map<String, dynamic> json) {
    return CurrentOrder(
      id: json['id'] as int? ?? 0,
      orderNo: json['order_no'] as String,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_no': orderNo,
      'total': total,
      'grand_total': grandTotal,
      'duration': duration,
    };
  }
}

class TableModel {
  final int id;
  final String tableNo;
  final String? name;
  final int capacity;
  final TableStatus status;
  final int? sortOrder;
  final CurrentOrder? currentOrder;
  final PaymentStatus? paymentStatus;
  final List<OrderModel>? orders;
  final int? areaId;
  final String? areaName;
  final bool isMerged;
  final String? mergedGroupCode;
  final List<String>? mergedWithTables;

  const TableModel({
    required this.id,
    required this.tableNo,
    this.name,
    required this.capacity,
    required this.status,
    this.sortOrder,
    this.currentOrder,
    this.paymentStatus,
    this.orders,
    this.areaId,
    this.areaName,
    this.isMerged = false,
    this.mergedGroupCode,
    this.mergedWithTables,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] as int,
      tableNo: json['table_no'] as String,
      name: json['name'] as String?,
      capacity: json['capacity'] as int,
      status: TableStatus.fromString(json['status'] as String),
      sortOrder: json['sort_order'] as int?,
      currentOrder: json['current_order'] != null
          ? CurrentOrder.fromJson(json['current_order'] as Map<String, dynamic>)
          : json['active_orders'] != null && (json['active_orders'] as List).isNotEmpty
              ? CurrentOrder.fromJson((json['active_orders'] as List).first as Map<String, dynamic>)
              : null,
      paymentStatus: json['payment_status'] != null
          ? PaymentStatus.fromString(json['payment_status'] as String)
          : null,
      orders: (json['orders'] as List<dynamic>?)
          ?.map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      areaId: (json['area'] as Map<String, dynamic>?)?
          ['id'] as int?,
      areaName: (json['area'] as Map<String, dynamic>?)?
          ['name'] as String?,
      isMerged: json['is_merged'] as bool? ?? false,
      mergedGroupCode: json['merged_group_code'] as String?,
      mergedWithTables: (json['merged_with_tables'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_no': tableNo,
      'name': name,
      'capacity': capacity,
      'status': status.name,
      'sort_order': sortOrder,
      'current_order': currentOrder?.toJson(),
      'payment_status': paymentStatus?.name,
      'orders': orders?.map((e) => e.toJson()).toList(),
      'area_id': areaId,
      'area_name': areaName,
      'is_merged': isMerged,
      'merged_group_code': mergedGroupCode,
      'merged_with_tables': mergedWithTables,
    };
  }

  TableModel copyWith({
    TableStatus? status,
    CurrentOrder? currentOrder,
    PaymentStatus? paymentStatus,
    List<OrderModel>? orders,
    int? areaId,
    String? areaName,
    bool? isMerged,
    String? mergedGroupCode,
    List<String>? mergedWithTables,
  }) {
    return TableModel(
      id: id,
      tableNo: tableNo,
      name: name,
      capacity: capacity,
      status: status ?? this.status,
      sortOrder: sortOrder,
      currentOrder: currentOrder ?? this.currentOrder,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orders: orders ?? this.orders,
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      isMerged: isMerged ?? this.isMerged,
      mergedGroupCode: mergedGroupCode ?? this.mergedGroupCode,
      mergedWithTables: mergedWithTables ?? this.mergedWithTables,
    );
  }
}
