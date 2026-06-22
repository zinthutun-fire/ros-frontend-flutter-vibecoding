import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/menu_item_model.dart';

String _imageUrl(MenuItemModel item) {
  if (item.image == null) return '';
  if (item.image!.startsWith('http')) return item.image!;
  final base = ApiConstants.baseUrl.replaceAll('/api', '');
  return '$base/storage/${item.image}';
}

class MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onAdd;

  const MenuItemCard({super.key, required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = _imageUrl(item);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(theme),
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : _imagePlaceholder(theme),
                      )
                    : _imagePlaceholder(theme),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              item.category,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.price.toStringAsFixed(2)} Ks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                  color: theme.colorScheme.primary,
                  iconSize: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          _categoryIcon(item.category),
          size: 40,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'drinks':
        return Icons.local_drink;
      case 'dessert':
        return Icons.cake;
      default:
        return Icons.restaurant_menu;
    }
  }
}
