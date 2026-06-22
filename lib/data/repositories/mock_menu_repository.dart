import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';
import '../repositories/menu_repository.dart';

final mockMenuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MockMenuRepository();
});

class MockMenuRepository implements MenuRepository {
  final List<MenuItemModel> _items = [
    MenuItemModel(id: 1, name: 'Cheese Burger', price: 8.50, image: 'burger.jpg', categoryId: 1, category: 'Food', kitchenId: 1, description: 'Juicy beef patty with cheese'),
    MenuItemModel(id: 2, name: 'Coca Cola', price: 2.00, image: 'cola.jpg', categoryId: 2, category: 'Drinks', kitchenId: 2),
    MenuItemModel(id: 3, name: 'Ice Cream', price: 3.50, image: 'icecream.jpg', categoryId: 3, category: 'Dessert', kitchenId: 3),
    MenuItemModel(id: 4, name: 'Margherita Pizza', price: 12.00, image: 'pizza.jpg', categoryId: 1, category: 'Food', kitchenId: 1, description: 'Classic tomato and mozzarella'),
    MenuItemModel(id: 5, name: 'French Fries', price: 4.50, image: 'fries.jpg', categoryId: 1, category: 'Food', kitchenId: 1),
    MenuItemModel(id: 6, name: 'Orange Juice', price: 3.00, image: 'oj.jpg', categoryId: 2, category: 'Drinks', kitchenId: 2),
    MenuItemModel(id: 7, name: 'Tiramisu', price: 5.00, image: 'tiramisu.jpg', categoryId: 3, category: 'Dessert', kitchenId: 3),
    MenuItemModel(id: 8, name: 'Caesar Salad', price: 7.50, image: 'salad.jpg', categoryId: 1, category: 'Food', kitchenId: 1, description: 'Crisp romaine with parmesan'),
    MenuItemModel(id: 9, name: 'Lemonade', price: 2.50, image: 'lemonade.jpg', categoryId: 2, category: 'Drinks', kitchenId: 2),
    MenuItemModel(id: 10, name: 'Chocolate Cake', price: 4.50, image: 'cake.jpg', categoryId: 3, category: 'Dessert', kitchenId: 3),
    MenuItemModel(id: 11, name: 'Grilled Chicken', price: 11.00, image: 'chicken.jpg', categoryId: 1, category: 'Food', kitchenId: 1, description: 'Herb-marinated chicken breast'),
    MenuItemModel(id: 12, name: 'Iced Tea', price: 2.00, image: 'tea.jpg', categoryId: 2, category: 'Drinks', kitchenId: 2),
  ];

  @override
  Future<List<MenuItemModel>> getMenuItems() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_items);
  }
}
