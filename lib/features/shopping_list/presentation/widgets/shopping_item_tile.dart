import 'package:flutter/material.dart';
import '../../domain/entities.dart';
import 'package:intl/intl.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Dapur':
        return Icons.restaurant_rounded;
      case 'Kamar Mandi':
        return Icons.bathtub_rounded;
      case 'Elektronik':
        return Icons.devices_other_rounded;
      case 'Kesehatan':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Dapur':
        return Colors.orange;
      case 'Kamar Mandi':
        return Colors.blue;
      case 'Elektronik':
        return Colors.purple;
      case 'Kesehatan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(item.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.horizontal,
        background: _buildDismissBackground(
          Alignment.centerLeft,
          theme.colorScheme.primary.withOpacity(0.8),
          Icons.check_circle_outline,
        ),
        secondaryBackground: _buildDismissBackground(
          Alignment.centerRight,
          theme.colorScheme.error.withOpacity(0.8),
          Icons.delete_outline_rounded,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onToggle();
            return false;
          } else {
            onDelete();
            return true;
          }
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: item.isChecked ? 0.6 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: item.isChecked 
                  ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.isChecked 
                    ? theme.colorScheme.outlineVariant.withOpacity(0.2)
                    : theme.colorScheme.outlineVariant.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              leading: GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isChecked 
                        ? theme.colorScheme.primary 
                        : Colors.transparent,
                    border: Border.all(
                      color: item.isChecked 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.outline.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: item.isChecked ? Colors.white : Colors.transparent,
                  ),
                ),
              ),
              title: Text(
                item.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: item.isChecked ? TextDecoration.lineThrough : null,
                  color: item.isChecked ? theme.colorScheme.outline : theme.colorScheme.onSurface,
                ),
              ),
              subtitle: Row(
                children: [
                  Icon(
                    _getCategoryIcon(item.category),
                    size: 10,
                    color: categoryColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: categoryColor.withOpacity(0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (item.quantity != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.quantity} ${item.unit ?? ""}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (item.price != null) ...[
                     const SizedBox(width: 8),
                     Text(
                      '• Rp ${item.price!.toInt()}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (item.targetDate != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 8,
                      color: theme.colorScheme.primary.withOpacity(0.6),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      DateFormat('d/M/yy').format(item.targetDate!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.6),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.error.withOpacity(0.5),
                ),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground(Alignment alignment, Color color, IconData icon) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
