import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/cart_item_model.dart';

final cartProvider = StateNotifierProvider.family<CartNotifier, CartState, int>((ref, tableId) {
  return CartNotifier();
});

class CartState {
  final List<CartItemModel> items;

  const CartState({this.items = const []});

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  int get itemCount => items.length;

  CartState copyWith({List<CartItemModel>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(CartItemModel item) {
    final existingIndex = state.items.indexWhere((e) => e.menuItemId == item.menuItemId);
    if (existingIndex >= 0) {
      final updated = [...state.items];
      updated[existingIndex] = CartItemModel(
        menuItemId: updated[existingIndex].menuItemId,
        name: updated[existingIndex].name,
        price: updated[existingIndex].price,
        qty: updated[existingIndex].qty + item.qty,
        note: updated[existingIndex].note ?? item.note,
      );
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  void updateQuantity(int menuItemId, int qty) {
    if (qty <= 0) {
      removeItem(menuItemId);
      return;
    }
    final updated = state.items.map((e) {
      if (e.menuItemId == menuItemId) {
        return CartItemModel(
          menuItemId: e.menuItemId,
          name: e.name,
          price: e.price,
          qty: qty,
          note: e.note,
        );
      }
      return e;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void updateNote(int menuItemId, String? note) {
    final updated = state.items.map((e) {
      if (e.menuItemId == menuItemId) {
        return CartItemModel(
          menuItemId: e.menuItemId,
          name: e.name,
          price: e.price,
          qty: e.qty,
          note: note,
        );
      }
      return e;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void removeItem(int menuItemId) {
    state = state.copyWith(
      items: state.items.where((e) => e.menuItemId != menuItemId).toList(),
    );
  }

  void clear() {
    state = const CartState();
  }
}
