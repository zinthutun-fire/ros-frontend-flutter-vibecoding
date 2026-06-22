import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/table_model.dart';
import '../../../shared/widgets/cart_item_tile.dart';
import '../../orders/providers/order_provider.dart';
import '../../table_detail/providers/table_detail_provider.dart';
import '../../tables/providers/table_provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  final int tableId;

  const CartScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider(tableId));
    final orderNotifier = ref.read(orderProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider(tableId).notifier).clear(),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cartState.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Cart is empty', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Add items from the menu', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartState.items.length,
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      return CartItemTile(
                        item: item,
                        onIncrement: () {
                          ref.read(cartProvider(tableId).notifier).updateQuantity(
                            item.menuItemId,
                            item.qty + 1,
                          );
                        },
                        onDecrement: () {
                          ref.read(cartProvider(tableId).notifier).updateQuantity(
                            item.menuItemId,
                            item.qty - 1,
                          );
                        },
                        onRemove: () {
                          ref.read(cartProvider(tableId).notifier).removeItem(item.menuItemId);
                        },
                        onNoteChanged: (note) {
                          ref.read(cartProvider(tableId).notifier).updateNote(
                            item.menuItemId,
                            note,
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal (${cartState.itemCount} items)',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              '${cartState.subtotal.toStringAsFixed(2)} Ks',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () async {
                            final items = cartState.items.map((e) => e.toJson()).toList();

                            // Get current order from tableDetailProvider (has full order data from API)
                            // or fall back to tableProvider list
                            final detailState = ref.read(tableDetailProvider(tableId));
                            final orderFromDetail = detailState.table?.currentOrder;
                            final tableFromList = ref.read(tableProvider).tables.where((t) => t.id == tableId).firstOrNull;
                            final currentOrder = orderFromDetail ?? tableFromList?.currentOrder;

                            if (currentOrder != null) {
                              try {
                                await orderNotifier.addItemsToOrder(
                                  orderId: currentOrder.id,
                                  items: items,
                                );
                              } catch (_) {
                                await orderNotifier.createOrder(
                                  tableId: tableId,
                                  items: items,
                                );
                              }
                            } else {
                              await orderNotifier.createOrder(
                                tableId: tableId,
                                items: items,
                              );
                            }
                            final lastOrder = ref.read(orderProvider).lastCreatedOrder;
                            if (lastOrder != null) {
                              await ref.read(tableProvider.notifier).assignOrderToTable(
                                tableId,
                                CurrentOrder(
                                  id: lastOrder.id,
                                  orderNo: lastOrder.orderNo,
                                  total: lastOrder.total,
                                ),
                              );
                            }
                            ref.read(cartProvider(tableId).notifier).clear();
                            if (context.mounted) {
                              context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order submitted to kitchen')),
                              );
                            }
                          },
                          child: const Text('Submit Order'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
