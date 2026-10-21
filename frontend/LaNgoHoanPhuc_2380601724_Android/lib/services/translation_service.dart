import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const Map<String, String> supportedLanguages = {
    'auto': 'Tự động phát hiện',
    'vi': 'Tiếng Việt',
    'en': 'English (Tiếng Anh)',
    'ja': '日本語 (Tiếng Nhật)',
    'ko': '한국어 (Tiếng Hàn)',
    'zh-CN': '中文 (Tiếng Trung)',
    'fr': 'Français (Tiếng Pháp)',
    'de': 'Deutsch (Tiếng Đức)',
    'es': 'Español (Tiếng Tây Ban Nha)',
    'ru': 'Русский (Tiếng Nga)',
    'th': 'ไทย (Tiếng Thái)',
  };

  /// Dịch văn bản theo thời gian thực (Realtime translation)
  static Future<String> translate({
    required String text,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    final query = text.trim();
    if (query.isEmpty) return '';

    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$fromLanguage&tl=$toLanguage&dt=t&q=${Uri.encodeComponent(query)}',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          final buffer = StringBuffer();
          for (var item in data[0]) {
            if (item is List && item.isNotEmpty && item[0] != null) {
              buffer.write(item[0].toString());
            }
          }
          return buffer.toString();
        }
      }
      return 'Không thể nhận diện bản dịch.';
    } catch (e) {
      return 'Lỗi kết nối dịch thuật: ${e.toString()}';
    }
  }
}
