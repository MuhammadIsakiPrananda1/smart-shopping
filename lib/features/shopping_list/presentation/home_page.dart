import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'providers.dart';
import 'list_detail_page.dart';
import '../domain/entities.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(sortedListsProvider);
    final selectedIds = ref.watch(selectedListIdsProvider);
    final isSearchExpanded = ref.watch(isSearchExpandedProvider);
    final theme = Theme.of(context);
    final isSelectionMode = selectedIds.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: true,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: isSelectionMode
                ? Text(
                    '${selectedIds.length} Terpilih',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Text(
                    'Shopping List',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -1.0,
                    ),
                  ),
            leading: isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => ref.read(selectedListIdsProvider.notifier).state = {},
                  )
                : null,
            actions: [
              if (isSelectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () async {
                    final confirmed = await _showBulkDeleteConfirm(context, selectedIds.length);
                    if (confirmed == true) {
                      await ref.read(shoppingControllerProvider.notifier).deleteLists(selectedIds.toList());
                      ref.read(selectedListIdsProvider.notifier).state = {};
                      ref.invalidate(myListsProvider);
                    }
                  },
                ),
                const SizedBox(width: 4),
              ] else if (isSearchExpanded) ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        autofocus: true,
                        onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Cari daftar...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              ref.read(isSearchExpandedProvider.notifier).state = false;
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => ref.read(isSearchExpandedProvider.notifier).state = true,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Icon(Icons.search_rounded, size: 18, color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 16,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showSortBottomSheet(context, ref),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Icon(Icons.tune_rounded, size: 18, color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),

          SliverToBoxAdapter(
            child: _buildDetailedDateTimeCard(context, ref),
          ),

          SliverToBoxAdapter(
            child: _buildSectionHeader(context, 'Daftar Belanja'),
          ),
          listsAsync.when(
            data: (lists) {
              if (lists.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyState(context));
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildStreamlinedListCard(context, ref, lists[index]),
                    );
                  }, childCount: lists.length),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(64.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 40, // Reduced height
        child: FloatingActionButton.extended(
          onPressed: () => _showAddListDialog(context, ref),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          label: const Text(
            'Buat List',
            style: TextStyle(
              fontWeight: FontWeight.w900, 
              letterSpacing: 0.5,
              fontSize: 12, // Smaller font
            ),
          ),
          icon: const Icon(Icons.add_shopping_cart_rounded, size: 18), // Smaller icon
        ),
      ),
    );
  }

  Widget _buildDetailedDateTimeCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeAsync = ref.watch(currentTimeProvider);
    final listsAsync = ref.watch(myListsProvider);
    final time = timeAsync.value ?? DateTime.now();
    
    final timeStr = DateFormat('HH:mm:ss').format(time);
    final dayStr = DateFormat('EEEE', 'id_ID').format(time);
    final dateStr = DateFormat('d MMMM yyyy', 'id_ID').format(time);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$dayStr, $dateStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                timeStr,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreamlinedListCard(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(shoppingItemsProvider(list.id));
    final selectedIds = ref.watch(selectedListIdsProvider);
    final isSelected = selectedIds.contains(list.id);
    final isSelectionMode = selectedIds.isNotEmpty;

    return itemsAsync.maybeWhen(
      data: (items) {
        final total = items.length;
        final done = items.where((i) => i.isChecked).length;
        final progress = total > 0 ? done / total : 0.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isSelectionMode) {
                  _toggleSelection(ref, list.id);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ListDetailPage(list: list)),
                  );
                }
              },
              onLongPress: () => _toggleSelection(ref, list.id),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon/Progress Circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 1.0 ? Colors.green : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.primary.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected ? Icons.check_rounded : _getCategoryIcon(list.category ?? 'Umum'),
                            color: isSelected ? Colors.white : theme.colorScheme.primary,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, 
                                  size: 12, color: theme.colorScheme.outline),
                              const SizedBox(width: 4),
                              Text(
                                '$done / $total Barang',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (total > 0)
                                Text(
                                  '${(progress * 100).toInt()}% Selesai',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: progress == 1.0 ? Colors.green : theme.colorScheme.primary,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Trailing Action
                    if (!isSelectionMode)
                      IconButton(
                        icon: Icon(Icons.chevron_right_rounded,
                            color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                        onPressed: () {
                           Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => ListDetailPage(list: list)),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }


  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_shopping_cart_rounded,
            size: 72,
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada daftar belanja',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk membuat daftar belanja pertama Anda.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddListDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final customCatController = TextEditingController();
    String selectedCategory = 'Umum';
    final theme = Theme.of(context);

    final categories = [
      'Umum',
      'Bulanan',
      'Mingguan',
      'Dapur',
      'Kebutuhan Rumah',
      'Elektronik',
      'Pakaian',
      'Hobi',
      'Lainnya',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 12,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.playlist_add_rounded, color: theme.colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Buat Daftar Baru',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900, 
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildFieldLabel(context, 'NAMA DAFTAR'),
              TextField(
                controller: nameController,
                autofocus: true,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                decoration: _buildInputDecoration(
                  theme,
                  'Misal: Belanja Bulanan, Kebutuhan Dapur',
                  Icons.edit_rounded,
                ),
              ),
              const SizedBox(height: 20),
              _buildFieldLabel(context, 'KATEGORI'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                    dropdownColor: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    items: categories.map((String cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(cat),
                              size: 20,
                              color: theme.colorScheme.primary.withOpacity(0.8),
                            ),
                            const SizedBox(width: 14),
                            Text(cat),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => selectedCategory = newValue);
                      }
                    },
                  ),
                ),
              ),
              if (selectedCategory == 'Lainnya') ...[
                const SizedBox(height: 20),
                _buildFieldLabel(context, 'KATEGORI KUSTOM'),
                TextField(
                  controller: customCatController,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  decoration: _buildInputDecoration(
                    theme,
                    'Contoh: Hadiah, Pesta',
                    Icons.category_rounded,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          final finalCategory = selectedCategory == 'Lainnya' &&
                                  customCatController.text.isNotEmpty
                              ? customCatController.text
                              : selectedCategory;

                          ref.read(shoppingControllerProvider.notifier).addList(
                                nameController.text,
                                category: finalCategory,
                              );
                          ref.invalidate(myListsProvider);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Simpan Daftar',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.outline,
              letterSpacing: 1.0,
              fontSize: 9,
            ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(ThemeData theme, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: theme.colorScheme.primary),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
      case 'dapur':
        return Icons.restaurant_rounded;
      case 'minuman':
        return Icons.local_drink_rounded;
      case 'buah':
      case 'sayur':
        return Icons.eco_rounded;
      case 'snack':
        return Icons.cookie_rounded;
      case 'elektronik':
        return Icons.devices_rounded;
      case 'pakaian':
        return Icons.checkroom_rounded;
      case 'kesehatan':
        return Icons.medical_services_rounded;
      case 'hobi':
        return Icons.sports_esports_rounded;
      case 'bulanan':
        return Icons.calendar_month_rounded;
      case 'mingguan':
        return Icons.view_week_rounded;
      case 'kebutuhan rumah':
        return Icons.home_work_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Hapus Daftar?',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        content: const Text(
          'Semua barang di dalam daftar ini akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showBulkDeleteConfirm(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus $count Daftar?',
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        content: Text(
          'Anda akan menghapus $count daftar belanja beserta isinya secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Semua', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(WidgetRef ref, String id) {
    final selected = ref.read(selectedListIdsProvider);
    if (selected.contains(id)) {
      ref.read(selectedListIdsProvider.notifier).state = selected
          .where((i) => i != id)
          .toSet();
    } else {
      ref.read(selectedListIdsProvider.notifier).state = {...selected, id};
    }
  }

  void _showSortBottomSheet(BuildContext context, WidgetRef ref) {
    final criteria = ref.watch(sortCriteriaProvider);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Urutkan Berdasarkan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption(
              context,
              ref,
              'Terbaru Dibuat',
              ListSortCriteria.newest,
              criteria == ListSortCriteria.newest,
              Icons.schedule_rounded,
            ),
            _buildSortOption(
              context,
              ref,
              'Nama (A-Z)',
              ListSortCriteria.name,
              criteria == ListSortCriteria.name,
              Icons.sort_by_alpha_rounded,
            ),
            _buildSortOption(
              context,
              ref,
              'Progres Pembelian',
              ListSortCriteria.progress,
              criteria == ListSortCriteria.progress,
              Icons.trending_up_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    ListSortCriteria criteria,
    bool isSelected,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: () {
              ref.read(sortCriteriaProvider.notifier).state = criteria;
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: isSelected ? Colors.white : theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded,
                        color: theme.colorScheme.primary, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
