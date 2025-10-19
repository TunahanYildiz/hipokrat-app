import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../data/providers/favorites_provider.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  Map<String, bool> _expansionState = {};

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
            print('$BannerAd on FavoritesPage loaded.');
            if (mounted) {
              setState(() {
                _isBannerAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('$BannerAd on FavoritesPage failedToLoad: $error');
            ad.dispose();
          },
        ),
      )..load();
    }
  }

  Future<void> _clearFavorites() async {
    await ref.read(favoritesProvider.notifier).clearAllFavorites();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tüm favoriler silindi.')));
    }
  }

  Future<void> _removeFavorite(String term) async {
    await ref.read(favoritesProvider.notifier).removeFavorite(term);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$term" favorilerden çıkarıldı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaydedilenler (Favoriler)'),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Tüm Favorileri Temizle',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext ctx) {
                    return AlertDialog(
                      title: const Text('Favorileri Temizle'),
                      content: const Text(
                        'Tüm kaydedilmiş favorileri silmek istediğinizden emin misiniz?',
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('İptal'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
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
      body: favorites.isEmpty
          ? const Center(
              child: Text(
                'Henüz kaydedilmiş favori teriminiz bulunmuyor.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favoriteItem = favorites[index];
                final term = favoriteItem.term;
                final definition = favoriteItem.definition;

                final bool isExpanded = _expansionState[term] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  child: InkWell(
                    onTap: () {
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
                              Expanded(
                                child: Text(
                                  term,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.grey[600],
                                ),
                                tooltip: 'Favorilerden Çıkar',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _removeFavorite(term),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            definition,
                            maxLines: isExpanded ? null : 2,
                            overflow: isExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
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
