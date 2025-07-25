import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Bu import önemli
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sozluk_app/features/dictionary/presentation/pages/search_history_page.dart';
import 'package:sozluk_app/features/dictionary/presentation/pages/favorites_page.dart';
import 'package:flutter/services.dart';

import '../../../../main.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>  with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _definition = '';
  bool _isLoading = false;



  // YENİ: API anahtarı için nullable String değişkeni
  // Değeri initState içinde .env dosyasından okunacak.
  String? _apiKey;

  // YENİ: initState metodu
  // Bu metod, widget ilk kez oluşturulduğunda bir kereliğine çalışır.

  double _lengthSliderValue = 1; // 0: Kısa, 1: Orta, 2: Detaylı
  final List<String> _lengthLabels = ['Kısa', 'Orta', 'Detaylı'];


  @override
  void initState() {
    super.initState(); // Her zaman ilk bu satır olmalı
    _apiKey = dotenv.env['GEMINI_API_KEY']; // .env dosyasından GEMINI_API_KEY'i oku

    // Geliştirme sırasında kontrol için konsola yazdırma (isteğe bağlı)
    if (_apiKey == null) {
      print('HATA: GEMINI_API_KEY .env dosyasında bulunamadı veya .env dosyası yüklenemedi!');
    } else {
      print('API Anahtarı başarıyla yüklendi.');
    }
    _loadBannerAd();
    _loadSettings();

   // WidgetsBinding.instance.addPostFrameCallback((_) {
      //FocusScope.of(context).unfocus();
    //});
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // 'definition_length' anahtarıyla kaydedilmiş değeri oku.
      // Eğer bir değer yoksa, varsayılan olarak 1.0 (Orta) kullan.
      _lengthSliderValue = prefs.getDouble('definition_length') ?? 1.0;
    });
  }

  // _HomePageState sınıfının içine ekle

  // _HomePageState sınıfının içinde

  void _showSettingsBottomSheet(BuildContext context) {
    // showModalBottomSheet'in içinde bir state değişikliği (Slider'ı hareket ettirme)
    // olacağı için, içeriği bir StatefulWidget olan StatefulBuilder ile sarmalıyoruz.
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        // StatefulBuilder, bottom sheet'in kendi içindeki durumu güncellemesini sağlar.
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Ayarlar',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Cevap detayı başlığı ve seçili değer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cevap Detay Seviyesi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _lengthLabels[_lengthSliderValue.round()], // 0, 1, 2 -> 'Kısa', 'Orta', 'Detaylı'
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  // Slider'ın kendisi
                  Slider(
                    value: _lengthSliderValue,
                    min: 0,
                    max: 2,
                    divisions: 2, // 3 durak noktası (0, 1, 2)
                    label: _lengthLabels[_lengthSliderValue.round()], // Kaydırırken çıkan etiket
                    onChanged: (double value) {
                      // Slider hareket ettirildiğinde çalışır
                      setSheetState(() {
                        _lengthSliderValue = value;
                      });
                    },
                    // Slider bırakıldığında (kaydırma bittiğinde) çalışır
                    onChangeEnd: (double value) async {
                      final SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setDouble('definition_length', value);
                      // Ana sayfadaki state'i de güncelle (isteğe bağlı, ama tutarlılık için iyi)
                      setState(() {
                        _lengthSliderValue = value;
                      });
                      print('Ayar kaydedildi: $value');
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveSearchTerm(String term) async {
    if (term.isEmpty) return; // Boş terimi kaydetme

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Mevcut arama geçmişini al (varsa)
    List<String> searchHistory = prefs.getStringList('search_history') ?? [];

    // Eğer terim zaten geçmişte varsa, önce onu kaldır (en üste taşımak için)
    searchHistory.remove(term);

    // Yeni terimi listenin başına ekle
    searchHistory.insert(0, term);

    // Geçmiş listesinin boyutunu sınırla (örneğin son 20 arama)
    const int historyLimit = 20;
    if (searchHistory.length > historyLimit) {
      searchHistory = searchHistory.sublist(0, historyLimit);
    }

    // Güncellenmiş geçmişi kaydet
    await prefs.setStringList('search_history', searchHistory);
    print('Arama geçmişi güncellendi: $searchHistory'); // Konsolda kontrol için
  }


  // YENİ: Favori durumu için
  bool _isCurrentTermFavorited = false; // O anki aranan terimin favori olup olmadığını tutar
  String _currentSearchTermForFavorite = ''; // Favori işlemi için o anki aranan terimi tutar


  Future<bool> _checkIfFavorited(String term) async {
    if (term.isEmpty) return false;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Favorileri bir Map<String, String> (terim: tanım) olarak saklayabiliriz
    // Veya şimdilik sadece terim listesi olarak da saklayabiliriz.
    // Daha gelişmiş bir yapı için Map daha iyi olur. Şimdilik String listesiyle başlayalım.
    List<String> favorites = prefs.getStringList('favorite_terms') ?? [];
    return favorites.contains(term);
  }


  Future<void> _toggleFavorite(String term, String definition) async {
    if (term.isEmpty) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorite_terms') ?? [];
    // Tanımları da saklamak için ayrı bir liste veya Map kullanabiliriz.
    // Şimdilik sadece terimleri saklayalım, daha sonra tanımları eklemeyi düşünebiliriz.
    // VEYA daha iyisi: Her favoriyi "terim|tanım" formatında tek bir string olarak saklayalım.
    // Örnek: "kalp|Karnı vücuda pompalayan..."

    String favoriteEntry = "$term|$definition"; // Terim ve tanımı birleştir
    bool isCurrentlyFavorited = false;

    // Favori listesinde terimi bulmaya çalış (sadece terim kısmına göre)
    int existingIndex = favorites.indexWhere((entry) => entry.startsWith("$term|"));

    if (existingIndex != -1) { // Eğer terim zaten favorilerdeyse
      favorites.removeAt(existingIndex); // Favorilerden çıkar
      isCurrentlyFavorited = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$term" favorilerden çıkarıldı.')),
      );
    } else { // Eğer terim favorilerde değilse
      favorites.insert(0, favoriteEntry); // Başa ekle (terim|tanım formatında)
      isCurrentlyFavorited = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$term" favorilere eklendi.')),
      );
    }

    await prefs.setStringList('favorite_terms', favorites);
    setState(() {
      _isCurrentTermFavorited = isCurrentlyFavorited;
    });
    print('Favori listesi güncellendi: $favorites');
  }


  BannerAd? _bannerAd; // Banner reklam nesnesi
  bool _isBannerAdLoaded = false; // Banner reklamın yüklenip yüklenmediğini takip etmek için
  final String _bannerAdUnitId = 'ca-app-pub-8397020510693173/3179376225'; // Android Test Banner ID

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(), // Standart bir reklam isteği
      size: AdSize.banner, // Standart banner boyutu
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$BannerAd loaded.');
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$BannerAd failedToLoad: $error');
          ad.dispose(); // Hata durumunda reklamı temizle
        },
        // Diğer listener event'leri (onAdOpened, onAdClosed vb.) isteğe bağlı eklenebilir.
      ),
    )..load(); // Reklamı oluşturduktan sonra hemen yüklemesini başlat
  }


  void _performSearch() async {
    FocusScope.of(context).unfocus();
    final String userQuery = _searchController.text.trim();

    if (userQuery.isEmpty) {
      setState(() {
        _definition = 'Lütfen bir tıp terimi giriniz.';
        _isCurrentTermFavorited = false; // Tanım yoksa favori olamaz
        _currentSearchTermForFavorite = ''; // Terimi sıfırla
      });
      return;
    }

    // Arama terimini arama geçmişine kaydet (bu satır doğru yerde)
    await _saveSearchTerm(userQuery);

    if (_apiKey == null || _apiKey!.isEmpty) {
      setState(() {
        _definition =
        'API anahtarı yapılandırılmamış. Lütfen uygulamayı yeniden başlatın veya .env dosyasını kontrol edin.';
        _isLoading = false;
        _isCurrentTermFavorited = false;
        _currentSearchTermForFavorite = userQuery; // Terimi yine de ata
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _definition = ''; // Önceki tanımı temizle
      _isCurrentTermFavorited = false; // Yeni arama için favori durumunu sıfırla
      _currentSearchTermForFavorite = userQuery; // O anki aranan terimi sakla
    });

    String lengthInstruction = '';

    switch (_lengthSliderValue.round()) {
      case 0: // Kısa
        lengthInstruction = 'Cevabın 2-3 cümleyi geçmeyecek kadar kısa ve özet olsun.';
        break;
      case 1: // Orta (Varsayılan)
        lengthInstruction = 'Cevabın 5-6 cümle uzunluğunda, dengeli bir açıklama olsun.';
        break;
      case 2: // Detaylı
        lengthInstruction = 'Cevabın ortalama 10 cümle uzunluğunda bir açıklama olsun. ';
        break;
      default: // Beklenmedik bir durum olursa diye varsayılan
        lengthInstruction = 'Cevabın 5-6 cümle uzunluğunda, dengeli bir açıklama olsun.';
    }


    final prompt = """Lütfen aşağıdaki tıp terimini veya terim grubunu 2. sınıf bir tıp öğrencisinin anlayabileceği seviyede, yalın ve anlaşılır bir Türkçe ile açıkla.
    Kesinlikle bir giriş cümlesi veya "Tabii, açıklıyorum:" gibi bir ifade kullanma.
  $lengthInstruction 
  Terim: "$userQuery"
  Açıklama:""";

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash', // VEYA KULLANDIĞINIZ MODEL
        apiKey: _apiKey!,
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );


      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      // ---- BURADAN İTİBAREN DEĞİŞİKLİKLER ----
      if (response.text != null && response.text!.isNotEmpty) {
        // API'den geçerli bir cevap geldi
        _definition = response.text!; // Tanımı ata
        // Şimdi bu tanımın favori olup olmadığını kontrol et
        _isCurrentTermFavorited = await _checkIfFavorited(userQuery);
      } else {
        // API'den cevap gelmedi veya boş geldi
        _definition =
        'Bu terim için bir tanım bulunamadı veya API bir sorunla karşılaştı.';
        _isCurrentTermFavorited = false; // Tanım yoksa favori olamaz
      }
      // ---- DEĞİŞİKLİKLER BURADA BİTİYOR ----

    } catch (e) {
      _definition = 'Arama sırasında bir hata oluştu: ${e.toString()}';
      _isCurrentTermFavorited = false; // Hata durumunda favori olamaz
      print('API Hatası: $e');
    } finally {
      // Her durumda (başarılı, başarısız, hata) setState'i burada çağırıyoruz.
      // Bu, _definition ve _isCurrentTermFavorited'ın en son değerleriyle UI'ın güncellenmesini sağlar.
      if (mounted) { // Widget hala ağaçtaysa setState çağır
        setState(() {
          _isLoading = false;
          // _currentSearchTermForFavorite zaten setState(_isLoading = true...) bloğunda atanmıştı.
          // _isCurrentTermFavorited ve _definition yukarıdaki try-catch içinde güncellendi.
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // main.dart'ta oluşturduğumuz routeObserver'a bu sayfayı (context) abone yap
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _bannerAd?.dispose(); // YENİ: Banner reklamı temizle
    super.dispose();
  }

  @override
  void didPopNext() {
    // Başka bir sayfadan HomePage'e geri dönüldüğünde bu metod çalışır.
    // Odağı temizleyerek klavyenin açılmasını engelleyelim.
    print("HomePage'e geri dönüldü, odak kaldırılıyor.");
    _searchFocusNode.unfocus();
    super.didPopNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tıp Terimleri Sözlüğü'),
        // YENİ: AppBar'ın sağına ikon eklemek için 'actions'
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined), // Dişli çark ikonu
            tooltip: 'Ayarlar', // İkonun üzerine basılı tutunca çıkan ipucu
            onPressed: () {
              // Tıklandığında Modal Bottom Sheet'i açacak olan fonksiyonu çağır
              _showSettingsBottomSheet(context);
            },
          ),
        ],
      ),
      // _HomePageState -> build() metodu içinde

// ... (AppBar aynı) ...

      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.background,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'Menü',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Arama Geçmişi'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SearchHistoryPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Kaydedilenler'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FavoritesPage()),
                );
                if (_currentSearchTermForFavorite.isNotEmpty) {
                  final bool isFavorited =
                  await _checkIfFavorited(_currentSearchTermForFavorite);
                  if (mounted) {
                    setState(() {
                      _isCurrentTermFavorited = isFavorited;
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),

      onDrawerChanged: (isOpened) {
        // Bu fonksiyon drawer açıldığında veya kapandığında çalışır
        if (isOpened) {
          // Eğer drawer AÇILIYORSA, arama çubuğundan odağı kaldır.
          _searchFocusNode.unfocus();
          print("Drawer açıldı, odak kaldırıldı.");
        }
      },

// ... (body ve diğer Scaffold elemanları aynı) ...
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Tıp terimi giriniz...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: (value) => _performSearch(),
            ),
            const SizedBox(height: 16.0),

            ElevatedButton(

              onPressed: _isLoading ? null : _performSearch,

              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: const TextStyle(fontSize: 18),
                // Yükleme sırasında düğmenin görünümünü de ayarlayabiliriz (isteğe bağlı)
                disabledBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),

              child: const Text('Ara'),
            ),
            const SizedBox(height: 24.0),
            // build() metodu içindeki Expanded widget'ı

            // build() metodu içindeki Expanded widget'ı

            // lib/features/dictionary/presentation/pages/home_page.dart
// _HomePageState -> build() metodu içinde

            Expanded(
              // Çerçeveyi kaldırdığımız için Container'ı ve decoration'ı siliyoruz.
              // Onun yerine direkt Column kullanacağız.
              // Padding'i de Column'un içine alabiliriz.
              child: SingleChildScrollView( // İçerik taşarsa kaydırabilmek için
                padding: const EdgeInsets.symmetric(vertical: 16.0), // Sadece dikeyde boşluk
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanım metni
                    // Text widget'ını bir Padding ile sarmalayarak kenarlardan boşluk veriyoruz
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _definition.isEmpty && !_isLoading
                          ? SizedBox(
                        height: 150, // Boş durumda biraz yer kaplasın
                        child: Center(
                          child: Text(
                            'Bir terim arayın veya arama sonucunu burada görün.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                          : _isLoading
                          ? const SizedBox(
                        height: 150, // Yüklenirken de aynı yeri kaplasın
                        child: Center(child: CircularProgressIndicator()),
                      )
                          : Text(
                        _definition,
                        style: const TextStyle(fontSize: 16.0, height: 1.5), // Satır aralığını artırdım
                        textAlign: TextAlign.justify,
                      ),
                    ),

                    // Tanım metni ile favori butonu arasına boşluk
                    // Sadece geçerli bir tanım varsa gösterilecek
                    if (_definition.isNotEmpty &&
                        !_definition.startsWith('Lütfen bir terim giriniz') &&
                        !_definition.startsWith('Bu terim için bir tanım bulunamadı') &&
                        !_definition.startsWith('API anahtarı yapılandırılmamış') &&
                        !_definition.startsWith('Arama sırasında bir hata oluştu'))
                      const SizedBox(height: 8.0), // Tanım ile buton arası boşluk

                    // Favori butonu
                    // Sadece geçerli bir tanım varsa gösterilecek
                    if (_definition.isNotEmpty &&
                        !_definition.startsWith('Lütfen bir terim giriniz') &&
                        !_definition.startsWith('Bu terim için bir tanım bulunamadı') &&
                        !_definition.startsWith('API anahtarı yapılandırılmamış') &&
                        !_definition.startsWith('Arama sırasında bir hata oluştu'))
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          // YENİ: İki butonu yan yana koymak için Row
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // Row'un sadece içindeki kadar yer kaplamasını sağlar
                            children: [
                              // 1. Kopyala Butonu
                              IconButton(
                                icon: Icon(
                                  Icons.copy_outlined,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                tooltip: 'Tanımı Kopyala',
                                onPressed: () {
                                  // Panoya kopyalama işlemi
                                  Clipboard.setData(ClipboardData(text: _definition)).then((_) {
                                    // Kullanıcıya geri bildirim ver
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Tanım panoya kopyalandı!"),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  });
                                },
                              ),
                              // 2. Favori Butonu (mevcut buton)
                              IconButton(
                                icon: Icon(
                                  _isCurrentTermFavorited ? Icons.bookmark : Icons.bookmark_border,
                                  color: _isCurrentTermFavorited
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                tooltip: _isCurrentTermFavorited ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                                onPressed: () {
                                  if (_currentSearchTermForFavorite.isNotEmpty && _definition.isNotEmpty) {
                                    _toggleFavorite(_currentSearchTermForFavorite, _definition);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _isBannerAdLoaded && _bannerAd != null
          ? SizedBox(
        height: _bannerAd!.size.height.toDouble(), // Reklamın yüksekliği kadar
        width: _bannerAd!.size.width.toDouble(),  // Reklamın genişliği kadar
        child: AdWidget(ad: _bannerAd!), // Reklamı gösteren widget
      )
          : const SizedBox.shrink(),

    );
  }
}