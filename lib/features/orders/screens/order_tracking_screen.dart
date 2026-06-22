import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/order_provider.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(orderProvider.notifier).loadOrders(1, date: DateTime.now()));
  }

  String _displayDate(DateTime d) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    return '${d.month}/${d.day}/${d.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(orderProvider).selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked != null) {
      ref.read(orderProvider.notifier).filterByDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final theme = Theme.of(context);
    final notifier = ref.read(orderProvider.notifier);
    final selectedDate = state.selectedDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadOrders(1, date: selectedDate ?? DateTime.now()),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text('Date:', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedDate != null ? _displayDate(selectedDate) : 'Today',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (selectedDate != null)
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                    onPressed: () => notifier.loadOrders(1, date: DateTime.now()),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildBody(state, theme)),
        ],
      ),
    );
  }

  Widget _buildBody(OrderState state, ThemeData theme) {
    if (state.isLoading && state.orders.isEmpty) {
      return const ShimmerList();
    }
    if (state.error != null && state.orders.isEmpty) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(orderProvider.notifier).loadOrders(1, date: state.selectedDate ?? DateTime.now()),
      );
    }
    if (state.orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No orders for this date', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(orderProvider.notifier).loadOrders(1, date: state.selectedDate ?? DateTime.now()),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.orders.length,
        itemBuilder: (context, index) {
          final order = state.orders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => context.push('/orders/${order.orderNo}'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.orderNo,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      StatusBadge(status: order.status.label, type: StatusBadgeType.order),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (order.tableNo != null) ...[
                        Icon(Icons.table_restaurant, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('Table ${order.tableNo}', style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 16),
                      ],
                      Icon(Icons.receipt, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('${order.total.toStringAsFixed(2)} Ks',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Spacer(),
                      Text('Tap for details',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}
