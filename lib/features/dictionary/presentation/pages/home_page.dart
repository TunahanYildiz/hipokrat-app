import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math';
import '../../../../main.dart';
import '../../data/providers/search_provider.dart';
import '../../data/providers/favorites_provider.dart';
import '../../data/providers/search_history_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../../data/models/search_result.dart';
import '../pages/search_history_page.dart';
import '../pages/favorites_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
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
            print('$BannerAd loaded.');
            setState(() {
              _isBannerAdLoaded = true;
            });
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('$BannerAd failedToLoad: $error');
            ad.dispose();
          },
        ),
      )..load();
    }
  }

  void _performSearch() async {
    FocusScope.of(context).unfocus();
    final String userQuery = _searchController.text.trim();

    if (userQuery.isEmpty) {
      ref.read(searchProvider.notifier).clearSearch();
      return;
    }

    // Add to search history
    await ref.read(searchHistoryProvider.notifier).addSearchTerm(userQuery);

    // Perform search
    await ref.read(searchProvider.notifier).searchTerm(userQuery);
  }

  void _performRandomSearch() async {
    FocusScope.of(context).unfocus();

    // Rastgele tıp terimleri listesi
    final randomTerms = [
      'kalp',
      'akciğer',
      'böbrek',
      'karaciğer',
      'beyin',
      'kas',
      'kemik',
      'damar',
      'sinir',
      'kan',
      'göz',
      'kulak',
      'burun',
      'ağız',
      'diş',
      'mide',
      'bağırsak',
      'pankreas',
      'dalak',
      'tiroid',
      'adrenal',
      'hipofiz',
      'timus',
      'lenf',
      'bağışıklık',
      'hormon',
      'enzim',
      'vitamin',
      'mineral',
      'protein',
      'karbonhidrat',
      'yağ',
      'glikoz',
      'kolesterol',
      'hemoglobin',
      'trombosit',
      'lökosit',
      'eritrosit',
      'plazma',
      'serum',
      'antikor',
      'antijen',
      'bakteri',
      'virüs',
      'mantar',
      'parazit',
      'enfeksiyon',
      'inflamasyon',
      'alerji',
      'otoimmün',
      'kanser',
      'tümör',
      'metastaz',
      'biyopsi',
      'radyoloji',
      'ultrason',
      'tomografi',
      'manyetik rezonans',
      'elektrokardiyogram',
      'elektroensefalogram',
      'endoskopi',
      'laparoskopi',
      'anestezi',
      'cerrahi',
      'transplantasyon',
      'diyaliz',
      'kemoterapi',
      'radyoterapi',
      'immunoterapi',
      'fizyoterapi',
      'psikoterapi',
      'farmakoloji',
      'toksikoloji',
      'epidemiyoloji',
      'patoloji',
      'histoloji',
      'sitoloji',
      'genetik',
      'moleküler biyoloji',
      'biyokimya',
      'fizyoloji',
      'anatomik',
      'embriyoloji',
      'gelişim',
      'yaşlanma',
      'rejenerasyon',
      'apoptoz',
      'nekroz',
      'hipertrofi',
      'atrofi',
      'hiperplazi',
      'metaplazi',
      'disfonksiyon',
      'malformasyon',
      'konjenital',
      'edinsel',
      'akut',
      'kronik',
      'subakut',
      'progresif',
      'regresif',
      'remisyon',
      'relaps',
      'komplikasyon',
      'yan etki',
      'kontrendikasyon',
      'endikasyon',
      'prognoz',
      'teşhis',
      'tedavi',
      'profilaksi',
      'rehabilitasyon',
      'palyatif',
      'küratif',
      'semptomatik',
      'etiyolojik',
      'patogenetik',
      'patofizyolojik',
      'klinik',
      'laboratuvar',
      'görüntüleme',
      'monitoring',
      'takip',
      'kontrol',
      'değerlendirme',
      'analiz',
      'sentez',
      'metabolizma',
      'homeostaz',
      'adaptasyon',
      'stres',
      'travma',
      'şok',
      'sepsis',
      'multiorgan yetmezliği',
      'kritik bakım',
      'yoğun bakım',
      'acil servis',
      'ambulans',
      'resüsitasyon',
      'defibrilasyon',
      'entübasyon',
      'trakeostomi',
      'gastrostomi',
      'nefrostomi',
      'kolostomi',
      'ileostomi',
      'ürostomi',
      'ventrikülostomi',
      'peritoneal diyaliz',
      'hemodiyaliz',
      'plazmaferez',
      'kan transfüzyonu',
      'organ nakli',
      'kemik iliği nakli',
      'kök hücre',
      'rejeneratif tıp',
      'gen terapisi',
      'immunoterapi',
      'hedefe yönelik tedavi',
      'kişiselleştirilmiş tıp',
      'precision medicine',
      'translational medicine',
      'evidence-based medicine',
      'klinik araştırma',
      'randomize kontrollü çalışma',
      'meta-analiz',
      'sistematik derleme',
      'kohort çalışma',
      'vaka kontrol çalışması',
      'çapraz kesit çalışması',
      'longitudinal çalışma',
      'prospektif çalışma',
      'retrospektif çalışma',
      'çift kör çalışma',
      'plasebo kontrollü çalışma',
      'etkinlik çalışması',
      'güvenlik çalışması',
      'faz I çalışma',
      'faz II çalışma',
      'faz III çalışma',
      'faz IV çalışma',
      'post-marketing surveillance',
      'adverse event',
      'serious adverse event',
      'unexpected adverse event',
      'drug interaction',
      'contraindication',
      'precaution',
      'warning',
      'black box warning',
      'boxed warning',
    ];

    // Rastgele terim seç
    final random = Random();
    final selectedTerm = randomTerms[random.nextInt(randomTerms.length)];

    // Arama yap
    await ref.read(searchProvider.notifier).searchTerm(selectedTerm);
    await ref.read(searchHistoryProvider.notifier).addSearchTerm(selectedTerm);
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final settings = ref.watch(settingsProvider);

            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setSheetState) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 25.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Ayarlar',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      // Zorluk çubuğu ayarı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Zorluk Çubuğu Göster',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: settings.showDifficultyBar,
                            onChanged: (bool value) async {
                              await ref
                                  .read(settingsProvider.notifier)
                                  .updateShowDifficultyBar(value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Karanlık mod ayarı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Karanlık Mod',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: settings.isDarkMode,
                            onChanged: (bool value) async {
                              await ref
                                  .read(settingsProvider.notifier)
                                  .updateDarkMode(value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cevap Detay Seviyesi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            settings.lengthLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.definitionLength,
                        min: 0,
                        max: 2,
                        divisions: 2,
                        label: settings.lengthLabel,
                        onChanged: (double value) {
                          setSheetState(() {
                            // Local state update for immediate UI feedback
                          });
                        },
                        onChangeEnd: (double value) async {
                          await ref
                              .read(settingsProvider.notifier)
                              .updateDefinitionLength(value);
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
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    print("HomePage'e geri dönüldü, odak kaldırılıyor.");
    _searchFocusNode.unfocus();
    super.didPopNext();
  }

  // İtiraz dialog fonksiyonu
  void _showReportDialog(BuildContext context, SearchResult searchResult) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Soruya İtiraz Et'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terim: ${searchResult.term}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('İtiraz sebebinizi belirtin:'),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Örnek: Soru yanlış, cevap hatalı, açıklama eksik...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  ref
                      .read(searchProvider.notifier)
                      .reportQuestion(
                        searchResult.term,
                        searchResult.relatedQuestion!,
                        reasonController.text.trim(),
                      );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('İtirazınız kaydedildi. Teşekkürler!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('İtiraz Et'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResult = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tıp Terimleri Sözlüğü'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ayarlar',
            onPressed: () => _showSettingsBottomSheet(context),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                    builder: (context) => const SearchHistoryPage(),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) => const FavoritesPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _searchFocusNode.unfocus();
          print("Drawer açıldı, odak kaldırıldı.");
        }
      },
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
              onPressed: searchResult.isLoading ? null : _performSearch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: const TextStyle(fontSize: 18),
                disabledBackgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.5),
              ),
              child: const Text('Ara'),
            ),
            const SizedBox(height: 12.0),

            // Rastgele bilgi butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: searchResult.isLoading ? null : _performRandomSearch,
                icon: const Icon(Icons.shuffle),
                label: const Text('Rastgele Bilgi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  textStyle: const TextStyle(fontSize: 16),
                  disabledBackgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child:
                          searchResult.definition.isEmpty &&
                              !searchResult.isLoading
                          ? SizedBox(
                              height: 150,
                              child: Center(
                                child: Text(
                                  'Bir terim arayın veya arama sonucunu burada görün.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : searchResult.isLoading
                          ? const SizedBox(
                              height: 150,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Text(
                              searchResult.definition,
                              style: const TextStyle(
                                fontSize: 16.0,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                    ),
                    if (searchResult.hasValidDefinition) ...[
                      const SizedBox(height: 8.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.copy_outlined,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                tooltip: 'Tanımı Kopyala',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: searchResult.definition,
                                    ),
                                  ).then((_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Tanım panoya kopyalandı!",
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  });
                                },
                              ),
                              Consumer(
                                builder: (context, ref, child) {
                                  return FutureBuilder<bool>(
                                    future: ref
                                        .read(favoritesProvider.notifier)
                                        .isFavorited(searchResult.term),
                                    builder: (context, snapshot) {
                                      final isFavorited =
                                          snapshot.data ?? false;

                                      return IconButton(
                                        icon: Icon(
                                          isFavorited
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          color: isFavorited
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                        ),
                                        tooltip: isFavorited
                                            ? 'Favorilerden Çıkar'
                                            : 'Favorilere Ekle',
                                        onPressed: () async {
                                          if (searchResult.term.isNotEmpty &&
                                              searchResult
                                                  .definition
                                                  .isNotEmpty) {
                                            if (isFavorited) {
                                              await ref
                                                  .read(
                                                    favoritesProvider.notifier,
                                                  )
                                                  .removeFavorite(
                                                    searchResult.term,
                                                  );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '"${searchResult.term}" favorilerden çıkarıldı.',
                                                  ),
                                                ),
                                              );
                                            } else {
                                              await ref
                                                  .read(
                                                    favoritesProvider.notifier,
                                                  )
                                                  .addFavorite(
                                                    searchResult.term,
                                                    searchResult.definition,
                                                  );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '"${searchResult.term}" favorilere eklendi.',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (searchResult.hasValidDefinition &&
                        searchResult.relatedQuestion != null &&
                        searchResult.relatedQuestion!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 24.0,
                          left: 16.0,
                          right: 16.0,
                        ),
                        child: Card(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'TUS veya Kaynak Soru',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (searchResult.difficultyLevel != null &&
                                        ref
                                            .watch(settingsProvider)
                                            .showDifficultyBar)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: searchResult.difficultyColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          border: Border.all(
                                            color: searchResult.difficultyColor,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Text(
                                          '${searchResult.difficultyLevel}/10 - ${searchResult.difficultyLabel}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: searchResult.difficultyColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  searchResult.relatedQuestion!,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                if (searchResult.relatedQuestionSource !=
                                        null &&
                                    searchResult
                                        .relatedQuestionSource!
                                        .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Kaynak: ${searchResult.relatedQuestionSource}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),

                                // Soru açıklaması butonu
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            searchResult.isLoadingExplanation ||
                                                searchResult
                                                    .hasExplanationRequested
                                            ? null
                                            : () {
                                                ref
                                                    .read(
                                                      searchProvider.notifier,
                                                    )
                                                    .getQuestionExplanation(
                                                      searchResult.term,
                                                      searchResult
                                                          .relatedQuestion!,
                                                    );
                                              },
                                        icon: searchResult.isLoadingExplanation
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.lightbulb_outline,
                                              ),
                                        label: Text(
                                          searchResult.isLoadingExplanation
                                              ? 'Açıklama yükleniyor...'
                                              : searchResult
                                                    .hasExplanationRequested
                                              ? 'Açıklama alındı'
                                              : 'Soru Açıklaması',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.amber.shade100,
                                          foregroundColor:
                                              Colors.amber.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showReportDialog(
                                          context,
                                          searchResult,
                                        ),
                                        icon: const Icon(Icons.report_problem),
                                        label: const Text('İtiraz Et'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade100,
                                          foregroundColor: Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Soru açıklaması gösterimi
                                if (searchResult.questionExplanation != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.lightbulb,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Soru Açıklaması',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          searchResult.questionExplanation!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
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
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : const SizedBox.shrink(),
    );
  }
}
