class FavoriteItem {
  final String term;
  final String definition;

  const FavoriteItem({
    required this.term,
    required this.definition,
  });

  Map<String, String> toMap() {
    return {
      'term': term,
      'definition': definition,
    };
  }

  factory FavoriteItem.fromMap(Map<String, String> map) {
    return FavoriteItem(
      term: map['term'] ?? '',
      definition: map['definition'] ?? '',
    );
  }

  String toStorageString() {
    return '$term|$definition';
  }

  factory FavoriteItem.fromStorageString(String storageString) {
    final parts = storageString.split('|');
    if (parts.length == 2) {
      return FavoriteItem(
        term: parts[0],
        definition: parts[1],
      );
    }
    return const FavoriteItem(term: '', definition: '');
  }
}

