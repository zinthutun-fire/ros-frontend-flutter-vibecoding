class MenuItemModifier {
  final int id;
  final int menuItemId;
  final String name;
  final double priceAdjustment;
  final int sortOrder;
  final bool isActive;

  const MenuItemModifier({
    required this.id,
    required this.menuItemId,
    required this.name,
    this.priceAdjustment = 0.0,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory MenuItemModifier.fromJson(Map<String, dynamic> json) {
    return MenuItemModifier(
      id: json['id'] as int,
      menuItemId: json['menu_item_id'] as int,
      name: json['name'] as String,
      priceAdjustment: (json['price_adjustment'] as num?)?.toDouble() ?? 0.0,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_item_id': menuItemId,
      'name': name,
      'price_adjustment': priceAdjustment,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}

class MenuItemModel {
  final int id;
  final String name;
  final double price;
  final String? image;
  final String? description;
  final String category;
  final int categoryId;
  final int kitchenId;
  final bool hasModifiers;
  final int sortOrder;
  final String status;
  final List<MenuItemModifier> modifiers;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    this.description,
    required this.category,
    required this.categoryId,
    required this.kitchenId,
    this.hasModifiers = false,
    this.sortOrder = 0,
    this.status = 'active',
    this.modifiers = const [],
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String?,
      description: json['description'] as String?,
      category: json['category'] is String ? json['category'] as String : (json['category'] as Map?)?['name'] as String? ?? '',
      categoryId: json['category_id'] as int? ?? 0,
      kitchenId: json['kitchen_id'] as int,
      hasModifiers: json['has_modifiers'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => MenuItemModifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'description': description,
      'category': category,
      'category_id': categoryId,
      'kitchen_id': kitchenId,
      'has_modifiers': hasModifiers,
      'sort_order': sortOrder,
      'status': status,
      'modifiers': modifiers.map((e) => e.toJson()).toList(),
    };
  }
}
