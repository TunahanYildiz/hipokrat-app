import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../data/providers/search_history_provider.dart';

class SearchHistoryPage extends ConsumerStatefulWidget {
  const SearchHistoryPage({super.key});

  @override
  ConsumerState<SearchHistoryPage> createState() => _SearchHistoryPageState();
}

class _SearchHistoryPageState extends ConsumerState<SearchHistoryPage> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  final String _bannerAdUnitId = 'ca-app-pub-8397020510693173/3179376225';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    // Only load ads on supported platforms
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
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
  }

  void _onHistoryItemTapped(String term) {
    Navigator.pop(context, term);
    print("Geçmişten seçilen terim: $term");
  }

  Future<void> _clearSearchHistory() async {
    await ref.read(searchHistoryProvider.notifier).clearSearchHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arama geçmişi temizlendi.')),
      );
    }
  }

  Future<void> _removeHistoryItem(String term) async {
    await ref.read(searchHistoryProvider.notifier).removeSearchTerm(term);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"$term" geçmişten silindi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchHistory = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arama Geçmişi'),
        actions: [
          if (searchHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Geçmişi Temizle',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext ctx) {
                    return AlertDialog(
                      title: const Text('Geçmişi Temizle'),
                      content: const Text(
                        'Tüm arama geçmişini silmek istediğinizden emin misiniz?',
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('İptal'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Sil'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _clearSearchHistory();
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
      body: searchHistory.isEmpty
          ? const Center(
              child: Text(
                'Henüz arama geçmişiniz bulunmuyor.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: searchHistory.length,
              itemBuilder: (context, index) {
                final term = searchHistory[index];
                return ListTile(
                  title: Text(term),
                  leading: const Icon(Icons.history),
                  onTap: () => _onHistoryItemTapped(term),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    tooltip: 'Geçmişten Sil',
                    onPressed: () {
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
