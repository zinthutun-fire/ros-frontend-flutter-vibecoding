import 'package:flutter/material.dart';
import '../../core/constants/app_enums.dart';
import '../../data/models/table_model.dart';

class TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  const TableCard({super.key, required this.table, required this.onTap, this.onClose});

  Color _statusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.red;
      case TableStatus.ordering:
        return Colors.amber;
      case TableStatus.payment:
        return Colors.blue;
      case TableStatus.paid:
        return Colors.teal;
      case TableStatus.reserved:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(table.status);

    final showClose = onClose != null && table.status == TableStatus.paid;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: color, width: 4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            table.status.label,
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      table.tableNo,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Text(
                          '${table.capacity}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (table.currentOrder != null)
                      Text(
                        '\$${table.currentOrder!.total.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                      ),
                    if (table.isMerged)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          table.mergedWithTables != null && table.mergedWithTables!.isNotEmpty
                              ? 'w/ ${table.mergedWithTables!.join(' + ')}'
                              : 'Merged',
                          style: TextStyle(color: Colors.purple.shade700, fontSize: 9, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (showClose)
            Positioned(
              right: 6,
              top: 6,
              child: Material(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(6),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: onClose,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Close',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
