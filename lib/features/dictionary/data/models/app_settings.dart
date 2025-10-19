class AppSettings {
  final double definitionLength; // 0: Kısa, 1: Orta, 2: Detaylı
  final String? apiKey;
  final bool showDifficultyBar; // Zorluk çubuğu gösterilsin mi
  final bool isDarkMode; // Karanlık mod aktif mi

  const AppSettings({
    this.definitionLength = 1.0,
    this.apiKey,
    this.showDifficultyBar = true,
    this.isDarkMode = false,
  });

  AppSettings copyWith({
    double? definitionLength,
    String? apiKey,
    bool? showDifficultyBar,
    bool? isDarkMode,
  }) {
    return AppSettings(
      definitionLength: definitionLength ?? this.definitionLength,
      apiKey: apiKey ?? this.apiKey,
      showDifficultyBar: showDifficultyBar ?? this.showDifficultyBar,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  String get lengthLabel {
    switch (definitionLength.round()) {
      case 0:
        return 'Kısa';
      case 1:
        return 'Orta';
      case 2:
        return 'Detaylı';
      default:
        return 'Orta';
    }
  }

  String get lengthInstruction {
    switch (definitionLength.round()) {
      case 0:
        return 'Cevabın 2-3 cümleyi geçmeyecek kadar kısa ve özet olsun.';
      case 1:
        return 'Cevabın 5-6 cümle uzunluğunda, dengeli bir açıklama olsun.';
      case 2:
        return 'Cevabın ortalama 10 cümle uzunluğunda bir açıklama olsun.';
      default:
        return 'Cevabın 5-6 cümle uzunluğunda, dengeli bir açıklama olsun.';
    }
  }
}
