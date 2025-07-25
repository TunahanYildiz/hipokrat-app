import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

BannerAd? _bannerAd;
bool _isBannerAdLoaded = false;
final String _bannerAdUnitId = 'ca-app-pub-8397020510693173/3179376225';

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, String>> _favorites = [];
  bool _isLoading = true;

  Map<String, bool> _expansionState = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadBannerAd(); // Bu satırı ekle
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // Bu metodu komple ekle
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteEntries = prefs.getStringList('favorite_terms') ?? [];
    List<Map<String, String>> loadedFavorites = [];

    for (String entry in favoriteEntries) {
      // "terim|tanım" formatını ayır
      var parts = entry.split('|');
      if (parts.length == 2) { // Doğru formatta ise
        loadedFavorites.add({'term': parts[0], 'definition': parts[1]});
      }
    }

    if (mounted) {
      setState(() {
        _favorites = loadedFavorites;
        _isLoading = false;
      });
    }
  }

  // Bir favori öğesine tıklandığında (şimdilik bir şey yapmıyoruz, isteğe bağlı eklenebilir)
  void _onFavoriteItemTapped(String term, String definition) {
    // Belki tanımı detaylı gösteren bir pop-up açılabilir veya
    // ana sayfada o terim tekrar aranabilir.
    // Şimdilik sadece konsola yazdıralım.
    print("Favorilerden seçildi: $term");
    // Navigator.pop(context, term); // Ana sayfaya terimle dönmek istersek
  }

  // Tüm favorileri temizlemek için
  Future<void> _clearFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('favorite_terms');
    if (mounted) {
      setState(() {
        _favorites = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm favoriler silindi.')),
      );
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$BannerAd on FavoritesPage loaded.');
          if (mounted) {
            setState(() { _isBannerAdLoaded = true; });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$BannerAd on FavoritesPage failedToLoad: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  // Tek bir favoriyi silmek için
  Future<void> _removeFavorite(String termToRemove) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteEntries = prefs.getStringList('favorite_terms') ?? [];

    // Silinecek öğeyi "terim|tanım" formatında bul ve kaldır
    favoriteEntries.removeWhere((entry) => entry.startsWith("$termToRemove|"));

    await prefs.setStringList('favorite_terms', favoriteEntries);
    // UI'ı güncellemek için favorileri yeniden yükle
    _loadFavorites();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$termToRemove" favorilerden çıkarıldı.')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaydedilenler (Favoriler)'),
        actions: [
          if (_favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Tüm Favorileri Temizle',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext ctx) {
                    return AlertDialog(
                      title: const Text('Favorileri Temizle'),
                      content: const Text('Tüm kaydedilmiş favorileri silmek istediğinizden emin misiniz?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('İptal'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Hepsini Sil'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _clearFavorites();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? const Center(
        child: Text(
          'Henüz kaydedilmiş favori teriminiz bulunmuyor.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      )
          : // build() metodu içindeki ListView.builder

      ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final favoriteItem = _favorites[index];
          final term = favoriteItem['term']!;
          final definition = favoriteItem['definition']!;

          // O anki terimin genişleme durumunu al. Eğer map'te yoksa, varsayılan olarak kapalı (false).
          final bool isExpanded = _expansionState[term] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: InkWell( // ListTile yerine tüm karta tıklama efekti vermek için
              onTap: () {
                // Tıklandığında o terimin genişleme durumunu tersine çevir
                setState(() {
                  _expansionState[term] = !isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Terim
                        Expanded(
                          child: Text(
                            term,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        // Silme butonu
                        IconButton(
                          icon:  Icon(Icons.delete, color: Colors.grey[600]),
                          tooltip: 'Favorilerden Çıkar',
                          visualDensity: VisualDensity.compact, // Butonu biraz küçült
                          onPressed: () => _removeFavorite(term),
                        ),
                        // Genişletme/Daraltma ikonu
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.grey[700],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    // Tanım metni (genişleme durumuna göre değişecek)
                    Text(
                      definition,
                      // Eğer genişletilmişse tüm satırları göster, değilse 2 satır göster.
                      maxLines: isExpanded ? null : 2,
                      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
        bottomNavigationBar: _isBannerAdLoaded && _bannerAd != null
    ? SizedBox(
    height: _bannerAd!.size.height.toDouble(),
    width: _bannerAd!.size.width.toDouble(),
    child: AdWidget(ad: _bannerAd!),
    )
        : const SizedBox.shrink(),
    );
  }
}