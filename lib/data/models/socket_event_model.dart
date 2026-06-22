class SocketEventModel {
  final String orderNo;
  final String table;
  final int? kitchenId;
  final List<SocketItemModel> items;

  const SocketEventModel({
    required this.orderNo,
    required this.table,
    this.kitchenId,
    required this.items,
  });

  factory SocketEventModel.fromJson(Map<String, dynamic> json) {
    return SocketEventModel(
      orderNo: json['order_no'] as String,
      table: json['table'] as String,
      kitchenId: json['kitchen_id'] as int?,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => SocketItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SocketItemModel {
  final String name;
  final int qty;
  final String status;

  const SocketItemModel({
    required this.name,
    required this.qty,
    required this.status,
  });

  factory SocketItemModel.fromJson(Map<String, dynamic> json) {
    return SocketItemModel(
      name: json['name'] as String,
      qty: json['qty'] as int,
      status: json['status'] as String,
    );
  }
}
