import '../../core/constants/app_enums.dart';

class OrderItemModifier {
  final int id;
  final String name;
  final double priceAdjustment;

  const OrderItemModifier({
    required this.id,
    required this.name,
    this.priceAdjustment = 0.0,
  });

  factory OrderItemModifier.fromJson(Map<String, dynamic> json) {
    return OrderItemModifier(
      id: json['id'] as int,
      name: json['name'] as String,
      priceAdjustment: (json['price_adjustment'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price_adjustment': priceAdjustment,
    };
  }
}

class OrderItemModel {
  final int id;
  final int orderId;
  final int? menuItemId;
  final String name;
  final int qty;
  final double price;
  final double subtotal;
  final int? kitchenId;
  final String? kitchen;
  final List<OrderItemModifier> modifiers;
  final String? note;
  final ItemStatus status;
  final String? voidReason;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    this.menuItemId,
    required this.name,
    required this.qty,
    required this.price,
    this.subtotal = 0.0,
    this.kitchenId,
    this.kitchen,
    this.modifiers = const [],
    this.note,
    this.status = ItemStatus.pending,
    this.voidReason,
  });

  OrderItemModel copyWith({
    int? id,
    int? orderId,
    int? menuItemId,
    String? name,
    int? qty,
    double? price,
    double? subtotal,
    int? kitchenId,
    String? kitchen,
    List<OrderItemModifier>? modifiers,
    String? note,
    ItemStatus? status,
    String? voidReason,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
      kitchenId: kitchenId ?? this.kitchenId,
      kitchen: kitchen ?? this.kitchen,
      modifiers: modifiers ?? this.modifiers,
      note: note ?? this.note,
      status: status ?? this.status,
      voidReason: voidReason ?? this.voidReason,
    );
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int,
      orderId: json['order_id'] as int? ?? 0,
      menuItemId: json['menu_item_id'] as int?,
      name: json['name'] as String,
      qty: json['qty'] as int,
      price: (json['price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      kitchenId: json['kitchen_id'] as int?,
      kitchen: json['kitchen'] as String?,
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => OrderItemModifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      note: json['note'] as String?,
      status: ItemStatus.fromString(json['status'] as String? ?? 'pending'),
      voidReason: json['void_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'name': name,
      'qty': qty,
      'price': price,
      'subtotal': subtotal,
      'kitchen_id': kitchenId,
      'kitchen': kitchen,
      'modifiers': modifiers.map((e) => e.toJson()).toList(),
      'note': note,
      'status': status.name,
      'void_reason': voidReason,
    };
  }
}

class OrderModel {
  final int id;
  final String orderNo;
  final String? tableNo;
  final int? tableId;
  final OrderStatus status;
  final double total;
  final double taxTotal;
  final double serviceChargeTotal;
  final double discountTotal;
  final double grandTotal;
  final String? notes;
  final List<OrderItemModel> items;
  final String? paidAt;
  final int? createdBy;
  final int? paidBy;
  final String? createdAt;

  const OrderModel({
    required this.id,
    required this.orderNo,
    this.tableNo,
    this.tableId,
    required this.status,
    this.total = 0.0,
    this.taxTotal = 0.0,
    this.serviceChargeTotal = 0.0,
    this.discountTotal = 0.0,
    this.grandTotal = 0.0,
    this.notes,
    this.items = const [],
    this.paidAt,
    this.createdBy,
    this.paidBy,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final table = json['table'] as Map<String, dynamic>?;
    return OrderModel(
      id: json['id'] as int? ?? 0,
      orderNo: json['order_no'] as String,
      tableNo: table?['table_no'] as String? ?? json['table_no'] as String?,
      tableId: table?['id'] as int? ?? json['table_id'] as int?,
      status: OrderStatus.fromString(json['status'] as String? ?? 'new'),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      taxTotal: (json['tax_total'] as num?)?.toDouble() ?? 0.0,
      serviceChargeTotal: (json['service_charge_total'] as num?)?.toDouble() ?? 0.0,
      discountTotal: (json['discount_total'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      paidAt: json['paid_at'] as String?,
      createdBy: json['created_by'] is Map ? (json['created_by'] as Map)['id'] as int? : null,
      paidBy: json['paid_by'] is Map ? (json['paid_by'] as Map)['id'] as int? : null,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_no': orderNo,
      'table_no': tableNo,
      'table_id': tableId,
      'status': status.name,
      'total': total,
      'tax_total': taxTotal,
      'service_charge_total': serviceChargeTotal,
      'discount_total': discountTotal,
      'grand_total': grandTotal,
      'notes': notes,
      'items': items.map((e) => e.toJson()).toList(),
      'paid_at': paidAt,
      'created_at': createdAt,
    };
  }

  OrderModel copyWith({
    OrderStatus? status,
    List<OrderItemModel>? items,
    double? total,
    double? grandTotal,
    String? paidAt,
    String? createdAt,
  }) {
    return OrderModel(
      id: id,
      orderNo: orderNo,
      tableNo: tableNo,
      tableId: tableId,
      status: status ?? this.status,
      total: total ?? this.total,
      taxTotal: taxTotal,
      serviceChargeTotal: serviceChargeTotal,
      discountTotal: discountTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      notes: notes,
      items: items ?? this.items,
      paidAt: paidAt ?? this.paidAt,
      createdBy: createdBy,
      paidBy: paidBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
