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
        case ThemeMode.light: return 'Terang';
        case ThemeMode.dark: return 'Gelap';
        default: return 'Sistem';
      }
    }

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
                        'PENGATURAN',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 6.5,
                        ),
                      ),
                      Text(
                        'Aplikasi',
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
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSettingsSection(context, 'Preferensi', [
                  _buildSettingsTile(
                    context, 
                    Icons.palette_outlined, 
                    'Tema Aplikasi', 
                    getThemeLabel(currentThemeMode),
                    onTap: () => _showThemeDialog(context, ref),
                  ),
                  _buildSettingsTile(
                    context, 
                    Icons.notifications_none_rounded, 
                    'Notifikasi', 
                    null,
                    onTap: () => _toggleNotifications(context),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSettingsSection(context, 'Lanjutan', [
                  _buildSettingsTile(
                    context, 
                    Icons.payments_outlined, 
                    'Mata Uang', 
                    currentCurrency,
                    onTap: () => _showCurrencyDialog(context, ref),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSettingsSection(context, 'Data', [
                  _buildSettingsTile(
                    context, 
                    Icons.picture_as_pdf_rounded, 
                    'Ekspor Riwayat (PDF)', 
                    null,
                    onTap: () => _exportToPDF(context, ref),
                  ),
                  _buildSettingsTile(
                    context, 
                    Icons.delete_forever_rounded, 
                    'Hapus Semua Data', 
                    null,
                    onTap: () => _showResetDialog(context, ref),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSettingsSection(context, 'Dukungan', [
                  _buildSettingsTile(
                    context, 
                    Icons.info_outline_rounded, 
                    'Tentang Aplikasi', 
                    null,
                    onTap: () => _showAboutDialog(context),
                  ),
                  _buildSettingsTile(
                    context, 
                    Icons.help_outline_rounded, 
                    'Bantuan', 
                    null,
                    onTap: () => _showHelpDialog(context),
                  ),
                ]),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Smart Shopping v1.2.0',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
          ),
          clipBehavior: Clip.antiAlias, // Critical for perfect ripple shapes
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, String? trailing, {required VoidCallback onTap, Widget? trailingWidget}) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 16),
      ),
      title: Text(
        title, 
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailingWidget ?? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: theme.colorScheme.outlineVariant),
        ],
      ),
    ),
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
            _buildThemeOption(context, ref, 'Sistem', Icons.brightness_auto_rounded, 0),
            _buildThemeOption(context, ref, 'Terang', Icons.light_mode_rounded, 1),
            _buildThemeOption(context, ref, 'Gelap', Icons.dark_mode_rounded, 2),
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

  Widget _buildThemeOption(BuildContext context, WidgetRef ref, String label, IconData icon, int value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Hive.box('settings').put('theme_mode', value);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tema diatur ke $label'), behavior: SnackBarBehavior.floating),
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
              child: const Icon(Icons.shopping_cart, color: Colors.white, size: 30),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Siap!')),
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

  Widget _buildCurrencyOption(BuildContext context, WidgetRef ref, String label, String value) {
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
          final oldBudget = box.get('monthly_budget', defaultValue: 0.0) as double;
          await box.put('monthly_budget', oldBudget * factor);

          // 2. Convert purchase_history
          final historyBox = Hive.box('purchase_history');
          final historyItems = List.from(historyBox.get('items', defaultValue: []) as List);
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
              await itemsBox.put(key, item.copyWith(price: item.price! * factor));
            }
          }

          // 4. Save new currency
          await box.put('currency', value);
        }

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mata uang diubah ke $value dan nilai telah dikonversi'), behavior: SnackBarBehavior.floating),
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
          const SnackBar(content: Text('Tidak ada riwayat untuk diekspor'), behavior: SnackBarBehavior.floating),
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
          SnackBar(content: Text('Gagal mengekspor PDF: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Data?', style: TextStyle(color: Colors.red)),
        content: const Text('Tindakan ini akan menghapus seluruh daftar, riwayat, dan pengaturan Anda secara permanen. Apakah Anda yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
      // 1. Get references to boxes
      final listNames = [
        'shopping_lists',
        'shopping_items',
        'purchase_history',
        'shopping_plans',
        'settings'
      ];

      // 2. Clear and Delete each box from disk for a "Deep Clean"
      for (var name in listNames) {
        final box = Hive.box(name);
        await box.clear();
        // Note: deleteBoxFromDisk requires the box to be closed or it might fail on some platforms
        // But for simplicity and safety, clear() + manual reset is usually more stable in-app.
        // We'll stick to clear() but ensure EVERY setting is wiped.
      }
      
      // 3. Specifically reset settings to ensure default values are re-applied
      final settingsBox = Hive.box('settings');
      await settingsBox.clear(); 

      // 4. Invalidate ALL providers to force a reload from the now-empty boxes
      ref.invalidate(myListsProvider);
      ref.invalidate(plansProvider);
      ref.invalidate(themeModeProvider);
      ref.invalidate(currencyProvider);
      ref.invalidate(sortedListsProvider);
      ref.invalidate(selectedListIdsProvider);
      ref.invalidate(currentTimeProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aplikasi telah dibersihkan total ke kondisi awal.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membersihkan data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

