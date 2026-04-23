import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/entities.dart';
import 'providers.dart';
import 'widgets/shopping_item_tile.dart';
import 'widgets/barcode_scanner_view.dart';
import '../../../core/utils/export_service.dart';

class ListDetailPage extends ConsumerWidget {
  final ShoppingList list;
  const ListDetailPage({super.key, required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingItemsProvider(list.id));
    final theme = Theme.of(context);
    final currencyAsync = ref.watch(currencyProvider);
    final currentCurrency = currencyAsync.value ?? 'Rp';
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, ref),
          SliverToBoxAdapter(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Calculate progress
                final total = items.length;
                final done = items.where((i) => i.isChecked).length;
                final progress = total > 0 ? done / total : 0.0;

                return Column(
                  children: [
                    _buildProgressBar(context, progress, done, total),
                    _buildItemList(context, ref, items),
                    const SizedBox(height: 120),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(context, ref, currentCurrency),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Barang',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showAddItemSheet(
    BuildContext context,
    WidgetRef ref,
    String currentCurrency,
  ) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final unitController = TextEditingController();
    final customCatController = TextEditingController();

    final priceController = TextEditingController();

    String selectedCategory = 'Dapur';
    DateTime? selectedDate;
    final categories = [
      'Dapur',
      'Kamar Mandi',
      'Elektronik',
      'Kesehatan',
      'Lainnya',
    ];

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            0.3,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detail Barang',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceVariant
                                .withOpacity(0.3),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Name Field
                    _buildFieldLabel(context, 'NAMA BARANG'),
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: _buildInputDecoration(
                        theme,
                        'Nama barang',
                        Icons.shopping_bag_outlined,
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 8),
                    // Price Field
                    _buildFieldLabel(context, 'HARGA'),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      decoration: _buildInputDecoration(
                        theme,
                        'Harga',
                        Icons.payments_outlined,
                      ).copyWith(
                        prefixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 10),
                            Icon(Icons.payments_outlined, color: theme.colorScheme.primary, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Rp',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                      inputFormatters: [CurrencyInputFormatter()],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Harga wajib diisi' : null,
                    ),
                    const SizedBox(height: 8),
                    // Qty & Unit Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context, 'JUMLAH'),
                              TextFormField(
                                controller: qtyController,
                                keyboardType: TextInputType.number,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: _buildInputDecoration(
                                  theme,
                                  '1',
                                  Icons.tag_rounded,
                                ),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (value) => value == null || value.isEmpty
                                    ? 'Wajib'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(context, 'SATUAN'),
                              TextFormField(
                                controller: unitController,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: _buildInputDecoration(
                                  theme,
                                  'Satuan',
                                  Icons.scale_rounded,
                                ),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (value) => value == null || value.isEmpty
                                    ? 'Satuan wajib'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Category Dropdown
                    _buildFieldLabel(context, 'KATEGORI'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          dropdownColor: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          items: categories.map((String cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(cat),
                                    size: 18,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
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

                    // Custom Category Field (Conditional)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: selectedCategory == 'Lainnya'
                          ? Padding(
                              key: const ValueKey('custom_cat'),
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel(context, 'KATEGORI KUSTOM'),
                                  TextFormField(
                                    controller: customCatController,
                                    decoration: _buildInputDecoration(
                                      theme,
                                      'Contoh: Hobi, Kebun',
                                      Icons.edit_note_rounded,
                                    ),
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    validator: (value) =>
                                        selectedCategory == 'Lainnya' &&
                                                (value == null || value.isEmpty)
                                            ? 'Kategori wajib diisi'
                                            : null,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 8),
                    // Date Picker Field
                    _buildFieldLabel(context, 'TANGGAL BELI (OPSIONAL)'),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme:
                                    Theme.of(context).colorScheme.copyWith(
                                          primary: theme.colorScheme.primary,
                                          onPrimary: theme.colorScheme.onPrimary,
                                          surface: theme.colorScheme.surface,
                                          onSurface: theme.colorScheme.onSurface,
                                        ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: theme.colorScheme.primary, size: 18),
                            const SizedBox(width: 12),
                            Text(
                              selectedDate == null
                                  ? 'Pilih Tanggal'
                                  : DateFormat('d MMMM yyyy', 'id_ID')
                                      .format(selectedDate!),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: selectedDate == null
                                    ? theme.colorScheme.outline.withOpacity(0.5)
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            if (selectedDate != null)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () =>
                                    setState(() => selectedDate = null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final finalCategory = selectedCategory == 'Lainnya' &&
                                    customCatController.text.isNotEmpty
                                ? customCatController.text
                                : selectedCategory;

                            ref
                                .read(shoppingControllerProvider.notifier)
                                .addItem(
                                  list.id,
                                  nameController.text,
                                  quantity: int.tryParse(qtyController.text),
                                  unit: unitController.text.isNotEmpty
                                      ? unitController.text
                                      : null,
                                  category: finalCategory,
                                  price: double.tryParse(priceController.text
                                      .replaceAll('.', '')),
                                  targetDate: selectedDate,
                                );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'TAMBAHKAN KE DAFTAR',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.0,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.outline,
          fontSize: 8.5,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    ThemeData theme,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 16),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
      errorStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.error,
        fontSize: 10,
      ),
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.outline.withOpacity(0.5),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 60,
      floating: true,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        list.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
          onPressed: () async {
            final String? barcode = await Navigator.of(context).push<String>(
              MaterialPageRoute(
                builder: (context) => const BarcodeScannerView(),
              ),
            );
            if (barcode != null) {
              ref
                  .read(shoppingControllerProvider.notifier)
                  .addItem(list.id, 'Produk: $barcode');
            }
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Hapus Daftar?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus daftar "${list.name}"? Semua barang di dalamnya akan ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              ref.read(shoppingControllerProvider.notifier).deleteList(list.id);
              ref.invalidate(myListsProvider);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to Home
            },
            child: const Text(
              'Hapus Sekarang',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildProgressBar(
    BuildContext context,
    double progress,
    int done,
    int total,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROGRES BELANJA',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.outline,
                  letterSpacing: 1.0,
                  fontSize: 9,
                ),
              ),
              Text(
                '$done / $total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.05,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingItem> items,
  ) {
    final categories = items.map((e) => e.category).toSet().toList();
    final theme = Theme.of(context);

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, catIndex) {
        final category = categories[catIndex];
        final catItems = items.where((e) => e.category == category).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 11,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.primary,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...catItems.map(
              (item) => ShoppingItemTile(
                item: item,
                onToggle: () => ref
                    .read(shoppingControllerProvider.notifier)
                    .toggleItem(list.id, item),
                onDelete: () => ref
                    .read(shoppingControllerProvider.notifier)
                    .deleteItem(list.id, item.id),
              ),
            ),
          ],
        );
      },
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
            Icons.playlist_add_rounded,
            size: 72,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          Text(
            'Daftar ini masih kosong',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ayo tambah barang belanjaan pertama Anda di daftar ini.',
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
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hanya ambil angka
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final int value = int.parse(digits);
    final formatter = NumberFormat.decimalPattern('id_ID');
    String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
