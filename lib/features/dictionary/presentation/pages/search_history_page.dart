import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';


class SearchHistoryPage extends StatefulWidget {
  const SearchHistoryPage({super.key});

  @override
  State<SearchHistoryPage> createState() => _SearchHistoryPageState();
}

class _SearchHistoryPageState extends State<SearchHistoryPage> {
  List<String> _searchHistory = []; // Arama geçmişini tutacak liste
  bool _isLoading = true; // Yükleme durumunu takip etmek için
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  final String _bannerAdUnitId = 'ca-app-pub-8397020510693173/3179376225';


  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadBannerAd(); // YENİ: Bu satırı initState'in sonuna ekle
  }

  Future<void> _loadSearchHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
      _isLoading = false;
    });
  }

  // Geçmişten bir terime tıklandığında ana sayfaya o terimle dönmek için
  // (Bu fonksiyonu şimdilik boş bırakabilir veya sadece pop yapabiliriz)
  void _onHistoryItemTapped(String term) {
    // TODO: Ana sayfada bu terimle arama yapacak şekilde geri dön.
    // Şimdilik sadece sayfayı kapatıyoruz.
    Navigator.pop(context, term); // 'term'i geri döndür
    print("Geçmişten seçilen terim: $term");
  }

  // Tüm geçmişi temizlemek için (isteğe bağlı)
  Future<void> _clearSearchHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history'); // 'search_history' anahtarını sil
    setState(() {
      _searchHistory = []; // Ekrandaki listeyi de boşalt
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Arama geçmişi temizlendi.')),
    );
  }

  Future<void> _removeHistoryItem(String termToRemove) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> searchHistory = prefs.getStringList('search_history') ?? [];

    // Silinecek öğeyi listeden kaldır
    searchHistory.remove(termToRemove);

    // Güncellenmiş listeyi kaydet
    await prefs.setStringList('search_history', searchHistory);

    // UI'ı güncellemek için ekrandaki listeyi de güncelle
    if (mounted) {
      setState(() {
        _searchHistory = searchHistory;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$termToRemove" geçmişten silindi.')),
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
          print('$BannerAd on SearchHistoryPage loaded.');
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$BannerAd on SearchHistoryPage failedToLoad: $error');
          ad.dispose();
        },
      ),
    )..load();
  }



  @override
  void dispose() {
    _bannerAd?.dispose(); // Sayfa kapandığında reklamı temizle
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arama Geçmişi'),
        actions: [
          // Geçmişi temizle butonu (isteğe bağlı)
          if (_searchHistory.isNotEmpty) // Sadece geçmiş varsa göster
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Geçmişi Temizle',
              onPressed: () {
                // Kullanıcıya onay sorusu sorabiliriz
                showDialog(
                  context: context,
                  builder: (BuildContext ctx) {
                    return AlertDialog(
                      title: const Text('Geçmişi Temizle'),
                      content: const Text('Tüm arama geçmişini silmek istediğinizden emin misiniz?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('İptal'),
                          onPressed: () {
                            Navigator.of(ctx).pop(); // Dialogu kapat
                          },
                        ),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Sil'),
                          onPressed: () {
                            Navigator.of(ctx).pop(); // Dialogu kapat
                            _clearSearchHistory();    // Geçmişi temizle
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
          ? const Center(child: CircularProgressIndicator()) // Yükleniyorsa
          : _searchHistory.isEmpty
          ? const Center(
        child: Text(
          'Henüz arama geçmişiniz bulunmuyor.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        itemCount: _searchHistory.length,
        itemBuilder: (context, index) {
          final term = _searchHistory[index];
          return ListTile(
            title: Text(term),
            leading: const Icon(Icons.history), // 'search' yerine 'history' ikonu daha uygun olabilir
            onTap: () => _onHistoryItemTapped(term),
            // YENİ: Her öğe için tek tek silme butonu
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey), // 'delete' veya 'close' ikonu
              tooltip: 'Geçmişten Sil',
              onPressed: () {
                // Silme metodunu çağır
                _removeHistoryItem(term);
              },
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