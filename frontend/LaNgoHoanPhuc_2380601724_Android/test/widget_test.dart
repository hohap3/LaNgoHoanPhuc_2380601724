import 'package:flutter_test/flutter_test.dart';
import 'package:langohoanphuc_2380601724_android/services/translation_service.dart';

void main() {
  test('TranslationService has supported languages', () {
    expect(TranslationService.supportedLanguages.isNotEmpty, isTrue);
    expect(TranslationService.supportedLanguages.containsKey('vi'), isTrue);
    expect(TranslationService.supportedLanguages.containsKey('en'), isTrue);
  });
}
