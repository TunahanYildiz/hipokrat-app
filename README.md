# Hipokrat - Tıp Terimleri Sözlüğü

Flutter ve Riverpod ile geliştirilmiş modern tıp terimleri sözlüğü uygulaması.

## Özellikler

- 🔍 Google Gemini AI ile tıp terimi arama
- ⭐ Favori terimleri kaydetme
- 📚 Arama geçmişi
- ⚙️ Cevap detay seviyesi ayarları
- 📱 Android, iOS, Linux, Web desteği
- 🎯 TUS soruları entegrasyonu
- 📱 Google Mobile Ads entegrasyonu

## Kurulum

### 1. Projeyi klonlayın
```bash
git clone <repository-url>
cd hipokrat-app
```

### 2. Bağımlılıkları yükleyin
```bash
flutter pub get
```

### 3. API Anahtarı Ayarlayın

Proje kök dizininde `.env` dosyası oluşturun:

```bash
# .env dosyası
GEMINI_API_KEY=your_google_gemini_api_key_here
```

Google Gemini API anahtarı almak için:
1. [Google AI Studio](https://makersuite.google.com/app/apikey) adresine gidin
2. API anahtarı oluşturun
3. `.env` dosyasına ekleyin

### 4. Uygulamayı çalıştırın

```bash
# Linux için
flutter run -d linux

# Android için
flutter run -d android

# iOS için
flutter run -d ios

# Web için
flutter run -d chrome
```

## Teknolojiler

- **Flutter**: UI framework
- **Riverpod**: State management
- **Google Generative AI**: AI arama motoru
- **Shared Preferences**: Yerel veri saklama
- **Google Mobile Ads**: Reklam entegrasyonu

## Platform Desteği

- ✅ Android
- ✅ iOS  
- ✅ Linux
- ✅ Web
- ⚠️ Windows (reklamlar desteklenmez)
- ⚠️ macOS (reklamlar desteklenmez)

## Geliştirme

### State Management
Uygulama Riverpod ile state management kullanır:
- `SearchProvider`: Arama işlemleri
- `FavoritesProvider`: Favori yönetimi
- `SearchHistoryProvider`: Arama geçmişi
- `SettingsProvider`: Uygulama ayarları

### Kod Yapısı
```
lib/
├── features/
│   └── dictionary/
│       ├── data/
│       │   ├── models/
│       │   └── providers/
│       └── presentation/
│           └── pages/
└── main.dart
```

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.
