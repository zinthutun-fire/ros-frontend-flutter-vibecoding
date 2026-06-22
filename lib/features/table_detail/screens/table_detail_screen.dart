import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_enums.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/table_model.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../tables/providers/table_provider.dart';
import '../../orders/providers/order_provider.dart';
import '../providers/table_detail_provider.dart';

class TableDetailScreen extends ConsumerStatefulWidget {
  final int tableId;

  const TableDetailScreen({super.key, required this.tableId});

  @override
  ConsumerState<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends ConsumerState<TableDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(tableDetailProvider(widget.tableId).notifier).loadTable(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableDetailProvider(widget.tableId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Table ${state.table?.tableNo ?? ''}'),
        actions: [
          if (state.table?.status == TableStatus.occupied ||
              state.table?.status == TableStatus.ordering ||
              state.table?.status == TableStatus.payment ||
              state.table?.status == TableStatus.paid)
            PopupMenuButton<String>(
              onSelected: (v) => _handleAction(v),
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[];
                if (state.table?.status == TableStatus.occupied ||
                    state.table?.status == TableStatus.ordering) {
                  items.addAll([
                    const PopupMenuItem(value: 'add', child: Text('Add Items')),
                    const PopupMenuItem(
                      value: 'transfer',
                      child: Text('Transfer Table'),
                    ),
                    const PopupMenuItem(value: 'merge', child: Text('Merge Table')),
                    const PopupMenuItem(value: 'bill', child: Text('Request Bill')),
                  ]);
                }
                if (state.table?.status == TableStatus.payment ||
                    state.table?.status == TableStatus.paid) {
                  items.add(
                    const PopupMenuItem(value: 'close', child: Text('Close Table')),
                  );
                }
                return items;
              },
            ),
        ],
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(TableDetailState state, ThemeData theme) {
    if (state.isLoading) {
      return const ShimmerDetail();
    }
    if (state.error != null) {
      return ErrorState(
        message: state.error!,
        onRetry: () =>
            ref.read(tableDetailProvider(widget.tableId).notifier).loadTable(),
      );
    }

    final table = state.table;
    if (table == null) return const SizedBox.shrink();

    // No active order - show menu prompt
    if (table.currentOrder == null && table.status == TableStatus.available) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Table ${table.tableNo}',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Capacity: ${table.capacity} guests',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            StatusBadge(status: 'Available', type: StatusBadgeType.table),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                ref
                    .read(tableProvider.notifier)
                    .updateTableStatus(widget.tableId, TableStatus.ordering);
                await context.push('/menu?tableId=${widget.tableId}');
                ref
                    .read(tableDetailProvider(widget.tableId).notifier)
                    .loadTable();
              },
              icon: const Icon(Icons.add),
              label: const Text('Start Order'),
            ),
          ],
        ),
      );
    }

    // Has active order
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
                      Text(
                        'Table ${table.tableNo}',
                        style: theme.textTheme.titleLarge,
                      ),
                      StatusBadge(
                        status: table.status.label,
                        type: StatusBadgeType.table,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capacity: ${table.capacity} guests',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (table.currentOrder != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Order: ${table.currentOrder!.orderNo}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (table.currentOrder!.duration != null)
                      Text(
                        'Duration: ${table.currentOrder!.duration}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: \$${table.currentOrder!.total.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (table.paymentStatus != null) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.payment,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Payment: ${table.paymentStatus!.label}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Items',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildItemsSection(state, table, theme),
        ],
      ),
    );
  }

  Widget _buildItemsSection(TableDetailState state, TableModel table, ThemeData theme) {
    final currentOrder = table.currentOrder != null
        ? state.orders.where((o) => o.orderNo == table.currentOrder!.orderNo).firstOrNull
        : null;

    if (currentOrder != null) {
      return _buildOrderSection(currentOrder, isCurrent: true, theme: theme);
    }

    // Fallback for backward compat (no orders from API)
    if (state.items.isNotEmpty) {
      return Column(
        children: state.items.map((item) => _buildItemCard(item, theme)).toList(),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text('No items in this order', style: TextStyle(color: Colors.grey[600])),
        ),
      ),
    );
  }

  Widget _buildOrderSection(OrderModel order, {required bool isCurrent, required ThemeData theme}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCurrent)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.receipt_long, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Current Order (${order.orderNo})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
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
          ...order.items.map((item) => _buildItemCard(item, theme)),
      ],
    );
  }

  Widget _buildItemCard(OrderItemModel item, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4, height: 40,
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
                  Text(
                    '${item.qty}x ${item.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.status.label,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            StatusBadge(status: item.status.label, type: StatusBadgeType.item),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(String action) async {
    switch (action) {
      case 'add':
        await context.push('/menu?tableId=${widget.tableId}');
        final lastOrder = ref.read(orderProvider).lastCreatedOrder;
        debugPrint(
          '[_handleAction add] lastOrder.orderNo=${lastOrder?.orderNo}, items=${lastOrder?.items.length}',
        );
        if (lastOrder?.items != null) {
          for (final item in lastOrder!.items) {
            debugPrint(
              '  - item: id=${item.id}, menuItemId=${item.menuItemId}, name=${item.name}, qty=${item.qty}, status=${item.status}',
            );
          }
        }
        ref
            .read(tableDetailProvider(widget.tableId).notifier)
            .loadTable(orderNo: lastOrder?.orderNo, items: lastOrder?.items);
        break;
      case 'transfer':
        _showTransferDialog();
        break;
      case 'merge':
        _showMergeDialog();
        break;
      case 'bill':
        _showBillConfirmation();
        break;
      case 'close':
        _showCloseConfirmation();
        break;
    }
  }

  void _showCloseConfirmation() {
    final table = ref.read(tableDetailProvider(widget.tableId)).table;
    if (table == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Table'),
        content: Text(
          'Mark Table ${table.tableNo} as available? '
          'This will close the current session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(tableProvider.notifier).closeTable(widget.tableId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Table ${table.tableNo} is now available')),
              );
            },
            child: const Text('Close Table'),
          ),
        ],
      ),
    );
  }

  void _showBillConfirmation() {
    final table = ref.read(tableDetailProvider(widget.tableId)).table;
    final orderId = table?.currentOrder?.id;
    if (orderId == null || table?.currentOrder == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No active order to bill')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Invoice'),
        content: Text(
          'Send invoice request for Table ${table!.tableNo} '
          '(${table.currentOrder!.orderNo} - \$${table.currentOrder!.total.toStringAsFixed(2)}) to cashier?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              ref
                  .read(tableDetailProvider(widget.tableId).notifier)
                  .requestBill(orderId);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Invoice request sent to cashier'),
                ),
              );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog() {
    final tableState = ref.read(tableProvider);
    final currentTable = ref.read(tableDetailProvider(widget.tableId)).table;
    final orderId = currentTable?.currentOrder?.id;
    final availableTables = tableState.tables
        .where(
          (t) => t.status == TableStatus.available && t.id != widget.tableId,
        )
        .toList();

    if (availableTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available tables to transfer to')),
      );
      return;
    }

    TableModel? selectedTable;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Transfer Table'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select target table for ${currentTable?.tableNo}:'),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedTable?.id,
                  decoration: const InputDecoration(
                    labelText: 'Target table',
                    border: OutlineInputBorder(),
                  ),
                  items: availableTables.map((t) {
                    return DropdownMenuItem(
                      value: t.id,
                      child: Text('${t.tableNo} (Cap: ${t.capacity})'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      selectedTable = availableTables.firstWhere(
                        (t) => t.id == v,
                      );
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedTable == null
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        ref
                            .read(tableProvider.notifier)
                            .transferTable(
                              widget.tableId,
                              selectedTable!.id,
                              orderId ?? 0,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Transferred to ${selectedTable!.tableNo}',
                            ),
                          ),
                        );
                      },
                child: const Text('Transfer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMergeDialog() {
    final tableState = ref.read(tableProvider);
    final currentTable = ref.read(tableDetailProvider(widget.tableId)).table;
    final mergeableTables = tableState.tables
        .where(
          (t) =>
              (t.status == TableStatus.occupied ||
                  t.status == TableStatus.ordering) &&
              t.id != widget.tableId,
        )
        .toList();

    if (mergeableTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active tables to merge with')),
      );
      return;
    }

    TableModel? selectedTable;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Merge Tables'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select table to merge with ${currentTable?.tableNo}:'),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedTable?.id,
                  decoration: const InputDecoration(
                    labelText: 'Target table',
                    border: OutlineInputBorder(),
                  ),
                  items: mergeableTables.map((t) {
                    return DropdownMenuItem(
                      value: t.id,
                      child: Text('${t.tableNo} (Cap: ${t.capacity})'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      selectedTable = mergeableTables.firstWhere(
                        (t) => t.id == v,
                      );
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedTable == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        try {
                          await ref.read(tableProvider.notifier).mergeTables(
                            [widget.tableId, selectedTable!.id],
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Merged ${currentTable?.tableNo} with ${selectedTable!.tableNo}',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Merge failed: $e')),
                            );
                          }
                        }
                      },
                child: const Text('Merge'),
              ),
            ],
          );
        },
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
