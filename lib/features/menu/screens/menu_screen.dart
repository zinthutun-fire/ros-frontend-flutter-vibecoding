import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/order_model.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/menu_item_card.dart';
import '../../cart/providers/cart_provider.dart';
import '../../table_detail/providers/table_detail_provider.dart';
import '../providers/menu_provider.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final int tableId;

  const MenuScreen({super.key, required this.tableId});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(menuProvider.notifier).loadMenuItems());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuProvider);
    final cartState = ref.watch(cartProvider(widget.tableId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/cart?tableId=${widget.tableId}'),
              ),
              if (cartState.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cartState.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search menu...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(menuProvider.notifier).search('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => ref.read(menuProvider.notifier).search(v),
            ),
          ),
          if (state.categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All', style: TextStyle(fontWeight: FontWeight.w600)),
                      selected: state.selectedCategory == null,
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      showCheckmark: true,
                      onSelected: (_) => ref.read(menuProvider.notifier).filterByCategory(null),
                    ),
                    const SizedBox(width: 8),
                    ...state.categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                            selected: state.selectedCategory == cat,
                            selectedColor: Theme.of(context).colorScheme.primaryContainer,
                            checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            showCheckmark: true,
                            onSelected: (_) => ref.read(menuProvider.notifier).filterByCategory(cat),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _buildBody(state, theme),
          ),
        ],
      ),
      floatingActionButton: cartState.itemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/cart?tableId=${widget.tableId}'),
              icon: const Icon(Icons.shopping_cart),
              label: Text('${cartState.subtotal.toStringAsFixed(2)} Ks'),
            )
          : null,
    );
  }

  Widget _buildBody(MenuState state, ThemeData theme) {
    if (state.isLoading) {
      return const ShimmerGrid();
    }
    if (state.error != null) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(menuProvider.notifier).loadMenuItems(),
      );
    }
    if (state.filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No menu items found', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(menuProvider.notifier).loadMenuItems(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: state.filteredItems.length,
        itemBuilder: (context, index) {
          final item = state.filteredItems[index];
          return MenuItemCard(
            item: item,
            onAdd: () {
              final detailState = ref.read(tableDetailProvider(widget.tableId));
              final currentOrderId = detailState.table?.currentOrder?.id;
              final existingItems = currentOrderId != null
                  ? detailState.items.where((e) => e.orderId == currentOrderId).toList()
                  : <OrderItemModel>[];
              final alreadyOrdered = existingItems.any((e) => e.menuItemId == item.id);

              if (alreadyOrdered) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Item Already Ordered'),
                    content: Text('${item.name} was already ordered. Add another portion?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(cartProvider(widget.tableId).notifier).addItem(
                            CartItemModel(
                              menuItemId: item.id,
                              name: item.name,
                              price: item.price,
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} added to cart'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Text('Yes, Add'),
                      ),
                    ],
                  ),
                );
              } else {
                ref.read(cartProvider(widget.tableId).notifier).addItem(
                  CartItemModel(
                    menuItemId: item.id,
                    name: item.name,
                    price: item.price,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} added to cart'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
