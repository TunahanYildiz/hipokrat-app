import 'package:flutter/material.dart';

class SearchResult {
  final String term;
  final String definition;
  final String? relatedQuestion;
  final String? relatedQuestionSource;
  final int? difficultyLevel; // 0-10 arası zorluk seviyesi
  final String? questionExplanation; // Soru açıklaması
  final bool isLoading;
  final bool isLoadingExplanation; // Açıklama yükleniyor mu
  final bool hasExplanationRequested; // Açıklama bir kez istenmiş mi
  final String? error;

  const SearchResult({
    required this.term,
    required this.definition,
    this.relatedQuestion,
    this.relatedQuestionSource,
    this.difficultyLevel,
    this.questionExplanation,
    this.isLoading = false,
    this.isLoadingExplanation = false,
    this.hasExplanationRequested = false,
    this.error,
  });

  SearchResult copyWith({
    String? term,
    String? definition,
    String? relatedQuestion,
    String? relatedQuestionSource,
    int? difficultyLevel,
    String? questionExplanation,
    bool? isLoading,
    bool? isLoadingExplanation,
    bool? hasExplanationRequested,
    String? error,
  }) {
    return SearchResult(
      term: term ?? this.term,
      definition: definition ?? this.definition,
      relatedQuestion: relatedQuestion ?? this.relatedQuestion,
      relatedQuestionSource:
          relatedQuestionSource ?? this.relatedQuestionSource,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      questionExplanation: questionExplanation ?? this.questionExplanation,
      isLoading: isLoading ?? this.isLoading,
      isLoadingExplanation: isLoadingExplanation ?? this.isLoadingExplanation,
      hasExplanationRequested:
          hasExplanationRequested ?? this.hasExplanationRequested,
      error: error ?? this.error,
    );
  }

  bool get hasValidDefinition =>
      definition.isNotEmpty &&
      !definition.startsWith('Lütfen bir terim giriniz') &&
      !definition.startsWith('Bu terim için bir tanım bulunamadı') &&
      !definition.startsWith('API anahtarı yapılandırılmamış') &&
      !definition.startsWith('Arama sırasında bir hata oluştu');

  String get difficultyLabel {
    if (difficultyLevel == null) return '';

    switch (difficultyLevel!) {
      case 0:
      case 1:
        return 'Çok Kolay';
      case 2:
      case 3:
        return 'Kolay';
      case 4:
      case 5:
        return 'Orta';
      case 6:
      case 7:
        return 'Zor';
      case 8:
      case 9:
        return 'Çok Zor';
      case 10:
        return 'Uzman Seviyesi';
      default:
        return 'Bilinmiyor';
    }
  }

  Color get difficultyColor {
    if (difficultyLevel == null) return Colors.grey;

    if (difficultyLevel! <= 2) return Colors.green;
    if (difficultyLevel! <= 4) return Colors.lightGreen;
    if (difficultyLevel! <= 6) return Colors.orange;
    if (difficultyLevel! <= 8) return Colors.red;
    return Colors.deepPurple;
  }
}
