import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shopping_list/presentation/providers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../shopping_list/domain/entities.dart';
import '../../core/utils/export_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeModeAsync = ref.watch(themeModeProvider);
    final currentThemeMode = themeModeAsync.value ?? ThemeMode.system;

    final currencyAsync = ref.watch(currencyProvider);
    final currentCurrency = currencyAsync.value ?? 'Rp';

    String getThemeLabel(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return 'Terang';
        case ThemeMode.dark:
          return 'Gelap';
        default:
          return 'Sistem';
      }
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileHeader(context),
                const SizedBox(height: 16),

                _buildSettingsSection(context, 'Preferensi Utama', [
                  _buildSettingsTile(
                    context,
                    Icons.palette_rounded,
                    'Tema Aplikasi',
                    getThemeLabel(currentThemeMode),
                    color: Colors.indigo,
                    onTap: () => _showThemeDialog(context, ref),
                  ),
                  _buildSettingsTile(
                    context,
                    Icons.payments_rounded,
                    'Mata Uang',
                    currentCurrency,
                    color: Colors.teal,
                    onTap: () => _showCurrencyDialog(context, ref),
                  ),
                  _buildSettingsTile(
                    context,
                    Icons.notifications_active_rounded,
                    'Notifikasi',
                    'Aktif',
                    color: Colors.orange,
                    onTap: () => _toggleNotifications(context),
                  ),
                ]),

                const SizedBox(height: 16),
                _buildSettingsSection(context, 'Pusat Data', [
                  _buildSettingsTile(
                    context,
                    Icons.picture_as_pdf_rounded,
                    'Ekspor Riwayat (PDF)',
                    'Laporan',
                    color: Colors.redAccent,
                    onTap: () => _exportToPDF(context, ref),
                  ),
                ]),

                const SizedBox(height: 16),
                _buildSettingsSection(context, 'Dukungan', [
                  _buildSettingsTile(
                    context,
                    Icons.info_rounded,
                    'Tentang',
                    'v1.2.0',
                    color: Colors.blue,
                    onTap: () => _showAboutDialog(context),
                  ),
                  _buildSettingsTile(
                    context,
                    Icons.help_center_rounded,
                    'Pusat Bantuan',
                    'Bantuan',
                    color: Colors.purple,
                    onTap: () => _showHelpDialog(context),
                  ),
                ]),

                const SizedBox(height: 32),
                _buildFooter(context),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
        title: Text(
          'PENGATURAN',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person_rounded,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengguna Setia',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Smart Shopping Premium',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 20,
            ),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: theme.colorScheme.outline,
              fontSize: 9,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.15),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String? trailing, {
    required VoidCallback onTap,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(
                trailing,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: theme.colorScheme.outline.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          Icons.shopping_bag_rounded,
          size: 24,
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
        const SizedBox(height: 8),
        Text(
          'Smart Shopping',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.outline.withOpacity(0.4),
            letterSpacing: 1.0,
            fontSize: 10,
          ),
        ),
        Text(
          'Versi 1.2.0',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline.withOpacity(0.2),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tema Aplikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              ref,
              'Sistem',
              Icons.brightness_auto_rounded,
              0,
            ),
            _buildThemeOption(
              context,
              ref,
              'Terang',
              Icons.light_mode_rounded,
              1,
            ),
            _buildThemeOption(
              context,
              ref,
              'Gelap',
              Icons.dark_mode_rounded,
              2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    int value,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Hive.box('settings').put('theme_mode', value);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tema diatur ke $label'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _toggleNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifikasi berhasil diaktifkan!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang Aplikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Smart Shopping',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text('Versi 1.2.0'),
            const SizedBox(height: 16),
            const Text(
              'Smart Shopping adalah asisten belanja cerdas yang membantu Anda merencanakan dan melacak pengeluaran dengan desain premium.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bantuan'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Buat daftar baru dengan menekan tombol plus.'),
            SizedBox(height: 8),
            Text('2. Atur anggaran Anda di tab Rencana.'),
            SizedBox(height: 8),
            Text('3. Pantau riwayat belanja di tab Aktivitas.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Siap!'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Mata Uang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCurrencyOption(context, ref, 'Rupiah (Rp)', 'Rp'),
            _buildCurrencyOption(context, ref, 'US Dollar (\$)', '\$'),
            _buildCurrencyOption(context, ref, 'Euro (€)', '€'),
            _buildCurrencyOption(context, ref, 'Poundsterling (£)', '£'),
          ],
        ),
      ),
    );
  }

  static const Map<String, double> _conversionRates = {
    'Rp': 1.0,
    '\$': 15000.0,
    '€': 16500.0,
    '£': 19000.0,
  };

  Widget _buildCurrencyOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value,
  ) {
    return ListTile(
      title: Text(label),
      onTap: () async {
        final box = Hive.box('settings');
        final oldCurrency = box.get('currency', defaultValue: 'Rp') as String;

        if (oldCurrency != value) {
          final oldRate = _conversionRates[oldCurrency] ?? 1.0;
          final newRate = _conversionRates[value] ?? 1.0;
          final factor = oldRate / newRate;

          // 1. Convert monthly_budget
          final oldBudget =
              box.get('monthly_budget', defaultValue: 0.0) as double;
          await box.put('monthly_budget', oldBudget * factor);

          // 2. Convert purchase_history
          final historyBox = Hive.box('purchase_history');
          final historyItems = List.from(
            historyBox.get('items', defaultValue: []) as List,
          );
          for (var item in historyItems) {
            if (item is Map && item.containsKey('price')) {
              final oldPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
              item['price'] = oldPrice * factor;
            }
          }
          await historyBox.put('items', historyItems);

          // 3. Convert shopping_items
          final itemsBox = Hive.box<ShoppingItem>('shopping_items');
          for (var key in itemsBox.keys) {
            final item = itemsBox.get(key);
            if (item != null && item.price != null) {
              await itemsBox.put(
                key,
                item.copyWith(price: item.price! * factor),
              );
            }
          }

          // 4. Save new currency
          await box.put('currency', value);
        }

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mata uang diubah ke $value dan nilai telah dikonversi',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _toggleHaptic(WidgetRef ref, bool value) {
    Hive.box('settings').put('haptic_enabled', value);
    if (value) HapticFeedback.mediumImpact();
  }

  Future<void> _exportToPDF(BuildContext context, WidgetRef ref) async {
    try {
      final box = Hive.box('purchase_history');
      final history = (box.get('items', defaultValue: []) as List).cast<Map>();

      if (history.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada riwayat untuk diekspor'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final currency = ref.read(currencyProvider).value ?? 'Rp';
      final path = await ExportService.exportHistoryToPDF(history, currency);

      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(path)],
          text: 'Riwayat Belanja Smart Shopping',
          subject: 'Ekspor Riwayat Belanja (PDF)',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor PDF: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Hapus Semua Data?',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Tindakan ini akan menghapus seluruh daftar, riwayat, dan pengaturan Anda secara permanen. Apakah Anda yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _resetAllData(context, ref);
            },
            child: const Text('HAPUS SEMUANYA'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData(BuildContext context, WidgetRef ref) async {
    try {
      // 1. List of all boxes used in the app
      final boxesToClear = [
        'shopping_lists',
        'shopping_items',
        'purchase_history',
        'shopping_plans',
        'settings',
      ];

      // 2. Perform "Nuclear Clean" (Delete physical files)
      for (var boxName in boxesToClear) {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(
            boxName,
          ).close(); // Must close before deleting disk file
        }
        await Hive.deleteBoxFromDisk(boxName);
      }

      // 3. Clean up exported files (PDF/CSV) from device storage
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final tempDir = await getTemporaryDirectory();

        // Clean documents directory
        if (await docDir.exists()) {
          docDir.listSync().forEach((file) {
            if (file is File &&
                (file.path.contains('export_') ||
                    file.path.endsWith('.csv') ||
                    file.path.endsWith('.pdf'))) {
              try {
                file.deleteSync();
              } catch (_) {}
            }
          });
        }

        // Clean temporary directory
        if (await tempDir.exists()) {
          tempDir.listSync().forEach((file) {
            if (file is File &&
                (file.path.contains('riwayat_belanja_') ||
                    file.path.endsWith('.pdf'))) {
              try {
                file.deleteSync();
              } catch (_) {}
            }
          });
        }
      } catch (e) {
        debugPrint('File cleanup error: $e');
      }

      // 4. Re-open boxes so the app doesn't crash
      await Hive.openBox<ShoppingList>('shopping_lists');
      await Hive.openBox<ShoppingItem>('shopping_items');
      await Hive.openBox('settings');
      await Hive.openBox('purchase_history');
      await Hive.openBox('shopping_plans');

      // 5. Force re-initialization of critical settings
      final settingsBox = Hive.box('settings');
      await settingsBox.put('theme_mode', 0); // System
      await settingsBox.put('currency', 'Rp');
      await settingsBox.put('monthly_budget', 0.0);
      await settingsBox.put('haptic_enabled', true);

      // 6. Invalidate ALL providers for immediate UI update
      ref.invalidate(myListsProvider);
      ref.invalidate(plansProvider);
      ref.invalidate(themeModeProvider);
      ref.invalidate(currencyProvider);
      ref.invalidate(sortedListsProvider);
      ref.invalidate(selectedListIdsProvider);
      ref.invalidate(activeListIdProvider);
      ref.invalidate(searchQueryProvider);
      ref.invalidate(isSearchExpandedProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.auto_delete_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pembersihan Total Berhasil',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Database dan file ekspor telah dimusnahkan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.indigo.shade700,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal pembersihan total: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
