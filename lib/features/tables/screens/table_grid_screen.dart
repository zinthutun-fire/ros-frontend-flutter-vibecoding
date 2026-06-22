import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_enums.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/table_card.dart';
import '../providers/table_provider.dart';

class TableGridScreen extends ConsumerStatefulWidget {
  const TableGridScreen({super.key});

  @override
  ConsumerState<TableGridScreen> createState() => _TableGridScreenState();
}

class _TableGridScreenState extends ConsumerState<TableGridScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tableProvider.notifier).loadTables());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableProvider);
    final theme = Theme.of(context);
    final notifier = ref.read(tableProvider.notifier);
    final areas = notifier.areas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadTables(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (areas.isNotEmpty)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: areas.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final selected = isAll
                      ? state.selectedAreaId == null
                      : state.selectedAreaId == areas[index - 1]['id'];
                  final label = isAll ? 'All' : areas[index - 1]['name'] as String;
                  return FilterChip(
                    label: Text(label),
                    selected: selected,
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.onPrimaryContainer,
                    labelStyle: TextStyle(
                      color: selected ? theme.colorScheme.onPrimaryContainer : null,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                    onSelected: (_) {
                      notifier.filterByArea(isAll ? null : areas[index - 1]['id'] as int);
                    },
                  );
                },
              ),
            ),
          Expanded(child: _buildBody(state, theme)),
        ],
      ),
    );
  }

  Widget _buildBody(TableState state, ThemeData theme) {
    if (state.isLoading && state.tables.isEmpty) {
      return const ShimmerGrid();
    }
    if (state.error != null && state.tables.isEmpty) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(tableProvider.notifier).loadTables(),
      );
    }
    if (state.tables.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No tables configured', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tableProvider.notifier).loadTables(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 5 : 3;
            final items = state.hasFilter ? state.filteredTables : state.tables;
            if (items.isEmpty) {
              return const Center(
                child: Text('No tables in this area', style: TextStyle(color: Colors.grey)),
              );
            }
            return GridView.builder(
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.78,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final table = items[index];
                return TableCard(
                  table: table,
                  onTap: () {
                    if (table.currentOrder != null) {
                      context.push('/orders/${table.currentOrder!.orderNo}');
                    } else {
                      context.push('/tables/${table.id}');
                    }
                  },
                  onClose: table.status == TableStatus.paid
                      ? () async {
                          try {
                            await ref.read(tableProvider.notifier).closeTable(table.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${table.tableNo} is now available')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              final msg = e is DioException && e.message != null
                                  ? e.message!
                                  : e.toString();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to close ${table.tableNo}: $msg'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        }
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }}
