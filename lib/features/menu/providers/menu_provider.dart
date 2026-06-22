import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/menu_item_model.dart';
import '../../../data/repositories/menu_repository.dart';
import '../../../data/services/menu_service.dart';

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  return MenuNotifier(ref.read(menuServiceProvider));
});

class MenuState {
  final List<MenuItemModel> items;
  final List<MenuItemModel> filteredItems;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;
  final String searchQuery;

  const MenuState({
    this.items = const [],
    this.filteredItems = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
    this.searchQuery = '',
  });

  MenuState copyWith({
    List<MenuItemModel>? items,
    List<MenuItemModel>? filteredItems,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return MenuState(
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<String> get categories {
    final cats = items.map((e) => e.category).toSet().toList();
    cats.sort();
    return cats;
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final MenuRepository _repository;

  MenuNotifier(this._repository) : super(const MenuState());

  Future<void> loadMenuItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repository.getMenuItems();
      state = MenuState(items: items, filteredItems: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void filterByCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
    _applyFilters();
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<MenuItemModel>.from(state.items);
    if (state.selectedCategory != null) {
      filtered = filtered.where((e) => e.category == state.selectedCategory).toList();
    }
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      filtered = filtered.where((e) => e.name.toLowerCase().contains(q)).toList();
    }
    state = state.copyWith(filteredItems: filtered);
  }
}
