import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'providers.dart';
import '../../../core/utils/export_service.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  static const List<IconData> _planIcons = [
    Icons.shopping_basket_outlined,
    Icons.kitchen_outlined,
    Icons.calendar_month_outlined,
    Icons.cleaning_services_outlined,
    Icons.health_and_safety_outlined,
    Icons.home_outlined,
    Icons.pets_outlined,
    Icons.construction_outlined,
  ];

  IconData _getIconData(int code) {
    try {
      return _planIcons.firstWhere((icon) => icon.codePoint == code);
    } catch (_) {
      return Icons.shopping_basket_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plansAsync = ref.watch(plansProvider);
    final currencyAsync = ref.watch(currencyProvider);
    final currentCurrency = currencyAsync.value ?? 'Rp';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              centerTitle: false,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LAINNYA',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 6.5,
                        ),
                      ),
                      Text(
                        'Anggaran',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                          height: 1.0,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  _buildHeaderClock(context, ref),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ValueListenableBuilder(
              valueListenable: Hive.box('settings').listenable(),
              builder: (context, settingsBox, _) {
                final budget = settingsBox.get('monthly_budget', defaultValue: 0.0) as double;
                
                return ValueListenableBuilder(
                  valueListenable: Hive.box('purchase_history').listenable(),
                  builder: (context, historyBox, _) {
                    final history = historyBox.get('items', defaultValue: []) as List;
                    final totalSpent = _calculateMonthSpending(history);
                    
                    return Column(
                        children: [
                          _buildBudgetCard(context, budget, totalSpent, currentCurrency),
                          
                          _buildSectionHeader(context, 'FITUR CERDAS'),
                          _buildToolsGrid(context, ref),
                          
                          _buildSectionHeader(context, 'PUSAT DATA'),
                          _buildDataActionCard(
                            context,
                            'Ekspor Riwayat Belanja',
                            'Unduh laporan belanja Anda dalam format PDF',
                            Icons.picture_as_pdf_rounded,
                            Colors.orange,
                            () => _handleExportHistory(context, ref, currentCurrency),
                          ),
                          
                          const SizedBox(height: 120),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

  Widget _buildToolsGrid(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: [
          _buildToolCard(
            context,
            'Kalkulator Diskon',
            'Hitung harga akhir',
            Icons.percent_rounded,
            Colors.indigo,
            () => _showDiscountCalculator(context),
          ),
          _buildToolCard(
            context,
            'Bandingkan Harga',
            'Cari yang termurah',
            Icons.compare_arrows_rounded,
            Colors.teal,
            () => _showPriceComparator(context),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
    );
  }

  void _showDiscountCalculator(BuildContext context) {
    final priceController = TextEditingController();
    final discountController = TextEditingController();
    double result = 0;
    double savings = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              top: 32,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Kalkulator Diskon', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Harga Awal',
                    prefixIcon: Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: const Text(
                        'Rp',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {
                    final p = double.tryParse(priceController.text.replaceAll('.', '')) ?? 0;
                    final d = double.tryParse(discountController.text) ?? 0;
                    savings = p * (d / 100);
                    result = p - savings;
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Diskon (%)', suffixText: '%'),
                  onChanged: (_) => setState(() {
                    final p = double.tryParse(priceController.text.replaceAll('.', '')) ?? 0;
                    final d = double.tryParse(discountController.text) ?? 0;
                    savings = p * (d / 100);
                    result = p - savings;
                  }),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Harga Akhir:'),
                          Text(
                            'Rp ${_formatMoney(result)}',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Anda Hemat:'),
                          Text(
                            'Rp ${_formatMoney(savings)}',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPriceComparator(BuildContext context) {
    final p1Price = TextEditingController();
    final p1Size = TextEditingController();
    final p2Price = TextEditingController();
    final p2Size = TextEditingController();
    
    double unit1 = 0;
    double unit2 = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              top: 32,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bandingkan Harga', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Produk A', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextField(
                            controller: p1Price,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _CurrencyInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Harga',
                              prefixIcon: Container(
                                width: 35,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Rp',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {
                              final p = double.tryParse(p1Price.text.replaceAll('.', '')) ?? 0;
                              final s = double.tryParse(p1Size.text) ?? 1;
                              unit1 = p / s;
                            }),
                          ),
                          TextField(
                            controller: p1Size,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Ukuran/Isi'),
                            onChanged: (_) => setState(() {
                              final p = double.tryParse(p1Price.text.replaceAll('.', '')) ?? 0;
                              final s = double.tryParse(p1Size.text) ?? 1;
                              unit1 = p / s;
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Produk B', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextField(
                            controller: p2Price,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _CurrencyInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Harga',
                              prefixIcon: Container(
                                width: 35,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Rp',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {
                              final p = double.tryParse(p2Price.text.replaceAll('.', '')) ?? 0;
                              final s = double.tryParse(p2Size.text) ?? 1;
                              unit2 = p / s;
                            }),
                          ),
                          TextField(
                            controller: p2Size,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Ukuran/Isi'),
                            onChanged: (_) => setState(() {
                              final p = double.tryParse(p2Price.text.replaceAll('.', '')) ?? 0;
                              final s = double.tryParse(p2Size.text) ?? 1;
                              unit2 = p / s;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (unit1 > 0 && unit2 > 0)
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: (unit1 < unit2 ? Colors.green : Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      unit1 < unit2 ? 'Produk A lebih murah Rp ${_formatMoney(unit2 - unit1)} per unit' : 'Produk B lebih murah Rp ${_formatMoney(unit1 - unit2)} per unit',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: unit1 < unit2 ? Colors.green : Colors.blue),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleExportHistory(BuildContext context, WidgetRef ref, String currency) async {
    try {
      final historyBox = Hive.box('purchase_history');
      final history = historyBox.get('items', defaultValue: []) as List;
      
      if (history.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada riwayat belanja untuk diekspor')),
        );
        return;
      }

      final path = await ExportService.exportHistoryToPDF(history.cast<Map>(), currency);
      
      await Share.shareXFiles([XFile(path)], text: 'Laporan Riwayat Belanja');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor: $e')),
      );
    }
  }

  Widget _buildEmptyPlans(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
        child: Column(
          children: [
            Icon(Icons.dashboard_customize_outlined, 
              size: 48, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Mulai dari Nol!',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Anda belum memiliki rencana kustom. Buat rencana belanja Anda sendiri dengan tombol di bawah.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomPlansGrid(BuildContext context, WidgetRef ref, List<Map> plans) {
    final theme = Theme.of(context);
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.8,
      ),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.08)),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(shoppingControllerProvider.notifier).addList(plan['name'] as String);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Daftar "${plan['name']}" berhasil dibuat!'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_getIconData(plan['iconCode'] as int), 
                              color: theme.colorScheme.primary, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              plan['name'] as String,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                                fontSize: 10,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 1,
                right: 1,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 12, color: Colors.grey),
                  onPressed: () => _confirmDeletePlan(context, ref, plan['id'] as String, plan['name'] as String),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeletePlan(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Rencana?'),
        content: Text('Hapus rencana kustom "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              ref.read(shoppingControllerProvider.notifier).deletePlan(id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddPlanDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    int selectedIconCode = Icons.shopping_basket_outlined.codePoint;
    
    const icons = _planIcons;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buat Rencana Baru', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nama Rencana',
                      hintText: 'Misal: Belanja Bulanan...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Pilih Ikon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: icons.length,
                      itemBuilder: (context, index) {
                        final ic = icons[index];
                        final isSelected = ic.codePoint == selectedIconCode;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIconCode = ic.codePoint),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(ic, color: isSelected ? Colors.black : null),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          ref.read(shoppingControllerProvider.notifier).addPlan(nameController.text, selectedIconCode);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('SIMPAN RENCANA'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _calculateMonthSpending(List history) {
    if (history.isEmpty) return 0.0;
    final now = DateTime.now();
    double total = 0.0;
    
    for (var item in history) {
      final data = item as Map;
      final date = DateTime.parse(data['purchasedAt'] as String);
      if (date.month == now.month && date.year == now.year) {
        final price = data['price'] as double? ?? 0.0;
        total += price;
      }
    }
    return total;
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Container(
            width: 2.5,
            height: 10,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderClock(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeAsync = ref.watch(currentTimeProvider);
    final time = timeAsync.value ?? DateTime.now();
    final timeStr = DateFormat('HH:mm:ss', 'id_ID').format(time);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          timeStr,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          DateFormat('d MMM yyyy', 'id_ID').format(time).toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.bold,
            fontSize: 6,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(BuildContext context, double budget, double spent, String currentCurrency) {
    final theme = Theme.of(context);
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = budget - spent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anggaran Bulan Ini',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline, fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '$currentCurrency ${_formatMoney(budget)}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          onPressed: () => _showBudgetDialog(context, currentCurrency),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(foregroundColor: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(
                ratio > 0.9 ? Colors.redAccent : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBudgetStat(context, 'Terpakai', '$currentCurrency ${_formatMoney(spent)}'),
              _buildBudgetStat(context, 'Sisa', '$currentCurrency ${_formatMoney(remaining)}', isSecondary: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStat(BuildContext context, String label, String value, {bool isSecondary = false}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: isSecondary ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSecondary ? theme.colorScheme.secondary : null,
          ),
        ),
      ],
    );
  }

  void _showBudgetDialog(BuildContext context, String currentCurrency) {
    final box = Hive.box('settings');
    final currentBudget = box.get('monthly_budget', defaultValue: 0.0) as double;
    final controller = TextEditingController(
      text: currentBudget == 0 ? '' : _formatMoney(currentBudget),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atur Anggaran Bulanan'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Target Anggaran ($currentCurrency)',
            prefixText: '$currentCurrency ',
            hintText: '0',
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CurrencyInputFormatter(),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final cleanText = controller.text.replaceAll('.', '');
              final val = double.tryParse(cleanText) ?? 0.0;
              box.put('monthly_budget', val);
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    String cleanText = newValue.text.replaceAll('.', '');
    
    // Simple thousand separator formatting for ID context
    String newText = '';
    int count = 0;
    for (int i = cleanText.length - 1; i >= 0; i--) {
      newText = cleanText[i] + newText;
      count++;
      if (count % 3 == 0 && i != 0) {
        newText = '.' + newText;
      }
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

