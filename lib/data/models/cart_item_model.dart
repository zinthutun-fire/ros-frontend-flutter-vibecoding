class CartItemModel {
  final int menuItemId;
  final String name;
  final double price;
  int qty;
  String? note;

  CartItemModel({
    required this.menuItemId,
    required this.name,
    required this.price,
    this.qty = 1,
    this.note,
  });

  double get subtotal => price * qty;

  Map<String, dynamic> toJson() {
    return {
      'menu_item_id': menuItemId,
      'name': name,
      'price': price,
      'qty': qty,
      if (note != null) 'note': note,
    };
  }
}
