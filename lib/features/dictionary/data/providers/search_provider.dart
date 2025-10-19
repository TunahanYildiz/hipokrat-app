import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/search_result.dart';
import 'settings_provider.dart';

class SearchNotifier extends StateNotifier<SearchResult> {
  SearchNotifier(this.ref)
    : super(const SearchResult(term: '', definition: ''));

  final Ref ref;

  // Mock TUS questions data
  static const Map<String, Map<String, String>> _tusQuestions = {
    'kalp': {
      'question':
          'Aşağıdakilerden hangisi kalbin sağ atriyumunun görevlerinden biridir?\n\nA) Kanı akciğerlere pompalar\nB) Kanı vücuda pompalar\nC) Kanı kalbe getirir\nD) Kanı temizler\nE) Kanı filtreler\n\nCevap: C',
      'source': 'TUS 2022 İlkbahar',
    },
    'akciğer': {
      'question':
          'Akciğerlerin temel solunum fonksiyonu nedir?\n\nA) Kanı pompalar\nB) Oksijen alışverişi yapar\nC) Besinleri sindirir\nD) Hormon üretir\nE) Atıkları filtreler\n\nCevap: B',
      'source': 'TUS 2021 Sonbahar',
    },
    'böbrek': {
      'question':
          'Böbreğin temel görevi aşağıdakilerden hangisidir?\n\nA) Kanı pompalar\nB) Oksijen alışverişi yapar\nC) Atıkları filtreler ve idrar üretir\nD) Besinleri sindirir\nE) Hormon üretir\n\nCevap: C',
      'source': 'TUS 2020 İlkbahar',
    },
    'karaciğer': {
      'question':
          'Karaciğerin temel fonksiyonları arasında hangisi yer almaz?\n\nA) Safra üretimi\nB) Protein sentezi\nC) Toksin detoksifikasyonu\nD) Kan pompalama\nE) Glikojen depolama\n\nCevap: D',
      'source': 'TUS 2023 İlkbahar',
    },
    'beyin': {
      'question':
          'Beynin hangi bölgesi motor fonksiyonları kontrol eder?\n\nA) Frontal lob\nB) Parietal lob\nC) Temporal lob\nD) Oksipital lob\nE) Serebellum\n\nCevap: A',
      'source': 'TUS 2023 Sonbahar',
    },
  };

  // Zorluk seviyesi hesaplama fonksiyonu
  int _calculateDifficultyLevel(String term, String question) {
    int difficulty = 3; // Varsayılan orta seviye

    // Terim bazlı zorluk ayarları
    final termDifficulty = {
      'kalp': 4,
      'akciğer': 3,
      'böbrek': 3,
      'karaciğer': 5,
      'beyin': 6,
      'kas': 2,
      'kemik': 2,
      'damar': 5,
      'sinir': 7,
      'kan': 4,
      'göz': 4,
      'kulak': 3,
      'burun': 2,
      'ağız': 2,
      'diş': 2,
    };

    final key = term.toLowerCase();
    if (termDifficulty.containsKey(key)) {
      difficulty = termDifficulty[key]!;
    }

    // Soru içeriğine göre zorluk ayarlaması
    if (question.contains('hangi') || question.contains('nedir')) {
      difficulty += 1; // Temel sorular biraz daha kolay
    }

    if (question.contains('fonksiyon') || question.contains('görev')) {
      difficulty += 1; // Fonksiyonel sorular daha zor
    }

    if (question.contains('hastalık') || question.contains('patoloji')) {
      difficulty += 2; // Hastalık soruları çok zor
    }

    if (question.contains('anatomik') || question.contains('yapı')) {
      difficulty += 1; // Anatomik sorular zor
    }

    // 0-10 arasında sınırla
    return difficulty.clamp(0, 10);
  }

  Future<Map<String, dynamic>> _fetchRelatedTusQuestion(String term) async {
    final settings = ref.read(settingsProvider);

    if (settings.apiKey == null || settings.apiKey!.isEmpty) {
      // Fallback to static questions if no API key
      final key = term.toLowerCase();
      if (_tusQuestions.containsKey(key)) {
        final questionData = _tusQuestions[key]!;
        final difficulty = _calculateDifficultyLevel(
          term,
          questionData['question']!,
        );
        return {
          'question': questionData['question']!,
          'source': questionData['source']!,
          'difficulty': difficulty,
        };
      } else {
        final fallbackQuestion =
            'Bu terimle ilgili TUS sorusu bulunamadı. Örnek: "${term[0].toUpperCase()}${term.substring(1)} ile ilgili temel bir fonksiyon nedir?"';
        final difficulty = _calculateDifficultyLevel(term, fallbackQuestion);
        return {
          'question': fallbackQuestion,
          'source': 'Kaynak: Medikal Soru Bankası',
          'difficulty': difficulty,
        };
      }
    }

    try {
      final prompt =
          """Lütfen "$term" terimi ile ilgili TUS (Tıp Uzmanlık Sınavı) tarzında bir çoktan seçmeli soru oluştur.

Soru formatı şöyle olsun:
SORU: [Soru metni]
A) Seçenek 1
B) Seçenek 2  
C) Seçenek 3
D) Seçenek 4
E) Seçenek 5

CEVAP: [Doğru cevap harfi]

KAYNAK: [Hangi TUS dönemi veya kaynak]

Sadece soru, cevap ve kaynak bilgisini ver, başka açıklama ekleme.""";

      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: settings.apiKey!,
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.medium,
          ),
        ],
      );

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        // Parse the response to extract question and source
        String questionText = response.text!;
        String source = 'Gemini AI';

        // Try to extract source if mentioned
        final sourceRegex = RegExp(r'KAYNAK:\s*(.+)', caseSensitive: false);
        final sourceMatch = sourceRegex.firstMatch(questionText);
        if (sourceMatch != null) {
          source = sourceMatch.group(1)?.trim() ?? 'Gemini AI';
          // Remove source line from question
          questionText = questionText.replaceAll(sourceRegex, '').trim();
        }

        // Try to extract answer if mentioned
        final answerRegex = RegExp(r'CEVAP:\s*(.+)', caseSensitive: false);
        final answerMatch = answerRegex.firstMatch(questionText);
        if (answerMatch != null) {
          final answer = answerMatch.group(1)?.trim() ?? '';
          // Add answer to question text
          questionText = questionText.replaceAll(answerRegex, '').trim();
          questionText += '\n\nCevap: $answer';
        }

        // Clean up the question text
        questionText = questionText
            .replaceAll(RegExp(r'^SORU:\s*', caseSensitive: false), '')
            .trim();

        // Calculate difficulty level
        final difficulty = _calculateDifficultyLevel(term, questionText);

        return {
          'question': questionText,
          'source': source,
          'difficulty': difficulty,
        };
      } else {
        // Fallback to static questions
        final key = term.toLowerCase();
        if (_tusQuestions.containsKey(key)) {
          final questionData = _tusQuestions[key]!;
          final difficulty = _calculateDifficultyLevel(
            term,
            questionData['question']!,
          );
          return {
            'question': questionData['question']!,
            'source': questionData['source']!,
            'difficulty': difficulty,
          };
        } else {
          final fallbackQuestion =
              'Bu terimle ilgili TUS sorusu bulunamadı. Örnek: "${term[0].toUpperCase()}${term.substring(1)} ile ilgili temel bir fonksiyon nedir?"';
          final difficulty = _calculateDifficultyLevel(term, fallbackQuestion);
          return {
            'question': fallbackQuestion,
            'source': 'Kaynak: Medikal Soru Bankası',
            'difficulty': difficulty,
          };
        }
      }
    } catch (e) {
      print('TUS sorusu alma hatası: $e');
      // Fallback to static questions on error
      final key = term.toLowerCase();
      if (_tusQuestions.containsKey(key)) {
        final questionData = _tusQuestions[key]!;
        final difficulty = _calculateDifficultyLevel(
          term,
          questionData['question']!,
        );
        return {
          'question': questionData['question']!,
          'source': questionData['source']!,
          'difficulty': difficulty,
        };
      } else {
        final fallbackQuestion =
            'Bu terimle ilgili TUS sorusu bulunamadı. Örnek: "${term[0].toUpperCase()}${term.substring(1)} ile ilgili temel bir fonksiyon nedir?"';
        final difficulty = _calculateDifficultyLevel(term, fallbackQuestion);
        return {
          'question': fallbackQuestion,
          'source': 'Kaynak: Medikal Soru Bankası',
          'difficulty': difficulty,
        };
      }
    }
  }

  // Soru açıklaması alma fonksiyonu
  Future<void> getQuestionExplanation(String term, String question) async {
    // Eğer açıklama daha önce istenmişse, tekrar isteme
    if (state.hasExplanationRequested) {
      return;
    }

    final settings = ref.read(settingsProvider);

    if (settings.apiKey == null || settings.apiKey!.isEmpty) {
      state = state.copyWith(
        questionExplanation:
            'API anahtarı yapılandırılmamış. Açıklama alınamadı.',
        isLoadingExplanation: false,
        hasExplanationRequested: true,
      );
      return;
    }

    // Set loading state for explanation
    state = state.copyWith(isLoadingExplanation: true);

    try {
      final prompt =
          """Aşağıdaki TUS sorusunu açıkla:

SORU: $question

Format:
1. Soru analizi
2. Seçenek değerlendirmesi
3. Doğru cevap açıklaması
4. Yanlış seçenekler
5. Ek bilgiler""";

      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: settings.apiKey!,
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.medium,
          ),
        ],
      );

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        state = state.copyWith(
          questionExplanation: response.text!,
          isLoadingExplanation: false,
          hasExplanationRequested: true,
        );
      } else {
        state = state.copyWith(
          questionExplanation: 'Açıklama alınamadı. Lütfen tekrar deneyin.',
          isLoadingExplanation: false,
          hasExplanationRequested: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        questionExplanation: 'Açıklama alınırken hata oluştu: ${e.toString()}',
        isLoadingExplanation: false,
        hasExplanationRequested: true,
      );
    }
  }

  // İtiraz fonksiyonu
  void reportQuestion(String term, String question, String reason) {
    // Bu fonksiyon gelecekte bir API'ye gönderilebilir
    print('İtiraz raporu:');
    print('Terim: $term');
    print('Soru: $question');
    print('Sebep: $reason');

    // Kullanıcıya bilgi ver
    state = state.copyWith(
      questionExplanation: 'İtirazınız kaydedildi. Teşekkürler!',
    );
  }

  Future<void> searchTerm(String term) async {
    if (term.isEmpty) {
      state = const SearchResult(
        term: '',
        definition: 'Lütfen bir tıp terimi giriniz.',
      );
      return;
    }

    final settings = ref.read(settingsProvider);

    if (settings.apiKey == null || settings.apiKey!.isEmpty) {
      state = SearchResult(
        term: term,
        definition:
            'API anahtarı yapılandırılmamış. Lütfen uygulamayı yeniden başlatın veya .env dosyasını kontrol edin.',
      );
      return;
    }

    // Set loading state
    state = SearchResult(term: term, definition: '', isLoading: true);

    try {
      final prompt =
          """Lütfen aşağıdaki tıp terimini veya terim grubunu 2. sınıf bir tıp öğrencisinin anlayabileceği seviyede, yalın ve anlaşılır bir Türkçe ile açıkla.
    Kesinlikle bir giriş cümlesi veya "Tabii, açıklıyorum:" gibi bir ifade kullanma.
  ${settings.lengthInstruction} 
  Terim: "$term"
  Açıklama:""";

      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: settings.apiKey!,
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.medium,
          ),
        ],
      );

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        // Fetch related TUS question
        final tusData = await _fetchRelatedTusQuestion(term);

        state = SearchResult(
          term: term,
          definition: response.text!,
          relatedQuestion: tusData['question'],
          relatedQuestionSource: tusData['source'],
          difficultyLevel: tusData['difficulty'],
          isLoading: false,
        );
      } else {
        state = SearchResult(
          term: term,
          definition:
              'Bu terim için bir tanım bulunamadı veya API bir sorunla karşılaştı.',
          isLoading: false,
        );
      }
    } catch (e) {
      state = SearchResult(
        term: term,
        definition: 'Arama sırasında bir hata oluştu: ${e.toString()}',
        isLoading: false,
        error: e.toString(),
      );
      print('API Hatası: $e');
    }
  }

  void clearSearch() {
    state = const SearchResult(term: '', definition: '');
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchResult>((
  ref,
) {
  return SearchNotifier(ref);
});
