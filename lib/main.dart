// Bu satır, Flutter'ın Material Design widget'larını kullanabilmemiz için gerekli.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sozluk_app/features/dictionary/presentation/pages/home_page.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();


// Uygulamanın ana giriş noktası. Flutter uygulamaları burada başlar.
Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}



// lib/main.dart içinde

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Modern bir renk şeması tanımlayalım
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF007A7C), // Sakin, profesyonel bir turkuaz/teal rengi
      brightness: Brightness.light,
      primary: const Color(0xFF007A7C),
      onPrimary: Colors.white,
      secondary: const Color(0xFF52606D),
      onSecondary: Colors.white,
      surface: const Color(0xFFF8F9FA), // Hafif kirli beyaz bir arka plan
      onSurface: const Color(0xFF1F2937), // Koyu gri metin rengi
      background: const Color(0xFFF8F9FA),
      onBackground: const Color(0xFF1F2937),
    );

    return MaterialApp(
      title: 'Tıp Terimleri Sözlüğü',
      // YENİ VE DETAYLI TEMA
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: colorScheme.background, // Scaffold arka planı

        // AppBar (Başlık Çubuğu) Teması
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface, // Arka plan rengi
          foregroundColor: colorScheme.onSurface, // İkon ve başlık rengi (koyu gri)
          elevation: 0.5, // Çok hafif bir gölge
          scrolledUnderElevation: 1.0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600, // Biraz daha kalın font
            color: Color(0xFF1F2937),
          ),
        ),

        // Text Alanı (TextField) Teması
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
          ),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),

        // Buton (ElevatedButton) Teması
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            elevation: 2.0,
          ),
        ),

        // Card (Kart) Teması (Favoriler ve Geçmiş sayfaları için)
        cardTheme: CardThemeData(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
        ),

        // Diğer renkler ve ayarlar buradan devam ettirilebilir...
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
    );
  }
}