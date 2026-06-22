import 'package:flutter/material.dart';

enum StatusBadgeType { table, order, item }

class StatusBadge extends StatelessWidget {
  final String status;
  final StatusBadgeType type;

  const StatusBadge({super.key, required this.status, required this.type});

  Color _getColor() {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'occupied':
      case 'new':
        return Colors.red;
      case 'ordering':
        return Colors.amber;
      case 'payment':
      case 'payment requested':
        return Colors.blue;
      case 'paid':
        return Colors.teal;
      case 'reserved':
        return Colors.grey;
      case 'preparing':
      case 'cooking':
      case 'started':
        return Colors.orange;
      case 'ready':
        return Colors.teal;
      case 'served':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
