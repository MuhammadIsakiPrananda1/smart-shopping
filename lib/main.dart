import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/shopping_list/domain/entities.dart';
import 'features/splash/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/shopping_list/presentation/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Hive.initFlutter();
  
  // Registrasi Hive Adapters
  Hive.registerAdapter(ShoppingListAdapter());
  Hive.registerAdapter(ShoppingItemAdapter());
  
  // Buka semua box yang diperlukan
  await Hive.openBox<ShoppingList>('shopping_lists');
  await Hive.openBox<ShoppingItem>('shopping_items');
  await Hive.openBox('settings');
  await Hive.openBox('purchase_history');
  await Hive.openBox('shopping_plans');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Playful Premium Pastel Color Palette
    const mintGreen = Color(0xFF00D2D3);
    const softCoral = Color(0xFFFF9F43);
    const warmWhite = Color(0xFFFDFCFB);
    const deepOceanBg = Color(0xFF10141D);
    const slateSurface = Color(0xFF1C222E);

    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return MaterialApp(
      title: 'Belanja Pintar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: mintGreen,
          primary: mintGreen,
          secondary: softCoral,
          surface: Colors.white,
          background: warmWhite,
        ),
        textTheme: GoogleFonts.itimTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: warmWhite,
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: mintGreen.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // More bubbly
          ),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.itim(
            color: mintGreen,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: mintGreen),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: softCoral,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: mintGreen,
          primary: mintGreen,
          secondary: softCoral,
          surface: slateSurface,
          background: deepOceanBg,
        ),
        textTheme: GoogleFonts.itimTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: deepOceanBg,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.03), width: 1),
          ),
          color: slateSurface,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.itim(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
