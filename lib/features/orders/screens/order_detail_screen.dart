import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_enums.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderNo;

  const OrderDetailScreen({super.key, required this.orderNo});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(orderProvider.notifier).getOrder(widget.orderNo));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.orderNo)),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(OrderState state, ThemeData theme) {
    if (state.isLoading) {
      return const ShimmerDetail();
    }

    final order = state.selectedOrder;
    if (order == null) {
      return const Center(child: Text('Order not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order.orderNo, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      StatusBadge(status: order.status.label, type: StatusBadgeType.order),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (order.tableNo != null) ...[
                    Row(
                      children: [
                        Icon(Icons.table_restaurant, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text('Table ${order.tableNo}', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Icon(Icons.receipt, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('Total: \$${order.total.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (order.items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text('No items in this order', style: TextStyle(color: Colors.grey[600])),
                ),
              ),
            )
          else
            ...order.items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _statusColor(item.status),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.qty}x ${item.name}',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(item.status.label,
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        StatusBadge(status: item.status.label, type: StatusBadgeType.item),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Color _statusColor(ItemStatus status) {
    return switch (status) {
      ItemStatus.pending => Colors.grey,
      ItemStatus.accepted => Colors.blue,
      ItemStatus.started => Colors.orange,
      ItemStatus.cooking => Colors.amber,
      ItemStatus.ready => Colors.teal,
      ItemStatus.served => Colors.green,
      ItemStatus.completed => Colors.green,
    };
  }
}
