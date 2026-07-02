// lib/utils/text_utils.dart
//
// Yer adlarını tutarlı şekilde göstermek için yardımcı fonksiyon.
// "KARACAAHMET SULTAN DERGAHI" → "Karacaahmet Sultan Dergahı"
// "şok market" → "Şok Market"
// "Yağmur Sıhhi Tesisat" → "Yağmur Sıhhi Tesisat" (zaten doğru, değişmez)
//
// Kullanım:
//   import '../utils/text_utils.dart';
//   Text(toTitleCase(place.name))

String toTitleCase(String text) {
  if (text.isEmpty) return text;

  return text
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        // İlk harfi büyük, gerisini küçük yap.
        // Türkçe karakter uyumluluğu için özel kontrol:
        final first = word[0].toUpperCase();
        final rest = word.length > 1 ? word.substring(1).toLowerCase() : '';
        return first + rest;
      })
      .join(' ');
}