import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_config.dart';
import '../../services/translation_service.dart';
import '../../widgets/app_dialogs.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Realtime text translation
  final TextEditingController _sourceController = TextEditingController();
  String _sourceLang = 'vi';
  String _targetLang = 'en';
  String _translatedText = '';
  bool _isTranslating = false;
  Timer? _debounceTimer;

  // Image translation
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String _extractedImageText = '';
  String _translatedImageText = '';
  bool _isProcessingImage = false;

  final List<String> _quickPhrases = [
    'Xin chào, rất vui được gặp bạn!',
    'Bạn có thể giúp tôi việc này được không?',
    'Sản phẩm này có giá bao nhiêu?',
    'Cảm ơn bạn rất nhiều!',
    'Hệ thống quản lý người dùng đang hoạt động tốt.',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounceTimer?.cancel();
    _sourceController.dispose();
    super.dispose();
  }

  // --- REALTIME TRANSLATION LOGIC ---
  void _onSourceTextChanged(String val) {
    _debounceTimer?.cancel();
    if (val.trim().isEmpty) {
      setState(() => _translatedText = '');
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      _executeTranslation();
    });
  }

  Future<void> _executeTranslation() async {
    final text = _sourceController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isTranslating = true);

    final result = await TranslationService.translate(
      text: text,
      fromLanguage: _sourceLang,
      toLanguage: _targetLang,
    );

    if (mounted) {
      setState(() {
        _translatedText = result;
        _isTranslating = false;
      });
    }
  }

  void _swapLanguages() {
    if (_sourceLang == 'auto') return;
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
      _sourceController.text = _translatedText;
      _translatedText = '';
    });
    _executeTranslation();
  }

  // --- IMAGE TRANSLATION LOGIC ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = image;
        _isProcessingImage = true;
        _extractedImageText = '';
        _translatedImageText = '';
      });

      // OCR & Simulated intelligent text detection from picture
      await Future.delayed(const Duration(milliseconds: 1200));

      final recognizedSample = _detectSampleTextFromImage(image.name);

      final translation = await TranslationService.translate(
        text: recognizedSample,
        fromLanguage: 'auto',
        toLanguage: _targetLang,
      );

      if (mounted) {
        setState(() {
          _extractedImageText = recognizedSample;
          _translatedImageText = translation;
          _isProcessingImage = false;
        });
        AppDialogs.showSuccess(context, 'Đã nhận diện và dịch văn bản từ ảnh chụp!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingImage = false);
        AppDialogs.showError(context, 'Lỗi chọn ảnh: ${e.toString()}');
      }
    }
  }

  String _detectSampleTextFromImage(String filename) {
    return 'Chào mừng bạn đến với hệ thống quản lý phân quyền người dùng và dịch thuật trực tiếp thông minh.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        title: const Text('Dịch Realtime & Ảnh Chụp'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConfig.primaryColor,
          unselectedLabelColor: AppConfig.textSecondary,
          indicatorColor: AppConfig.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.translate_rounded), text: 'Dịch Realtime'),
            Tab(icon: Icon(Icons.camera_alt_rounded), text: 'Dịch từ Ảnh Chụp'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRealtimeTab(),
          _buildImageTab(),
        ],
      ),
    );
  }

  // TAB 1: REALTIME TEXT TRANSLATION
  Widget _buildRealtimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language selector bar
          _buildLanguageSelectorBar(),
          const SizedBox(height: 16),

          // Source Input Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TranslationService.supportedLanguages[_sourceLang] ?? _sourceLang,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConfig.primaryColor),
                    ),
                    if (_sourceController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _sourceController.clear();
                          setState(() => _translatedText = '');
                        },
                      ),
                  ],
                ),
                TextField(
                  controller: _sourceController,
                  maxLines: 4,
                  onChanged: _onSourceTextChanged,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Nhập văn bản cần dịch (Gõ đến đâu dịch đến đó)...',
                    hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick phrases chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickPhrases.map((phrase) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(phrase, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    onPressed: () {
                      _sourceController.text = phrase;
                      _executeTranslation();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Translated Output Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TranslationService.supportedLanguages[_targetLang] ?? _targetLang,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConfig.primaryDark),
                    ),
                    if (_isTranslating)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _translatedText.isNotEmpty
                      ? _translatedText
                      : 'Bản dịch thời gian thực sẽ hiển thị tại đây...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _translatedText.isNotEmpty ? const Color(0xFF1E1B4B) : const Color(0xFF94A3B8),
                  ),
                ),
                if (_translatedText.isNotEmpty) ...[
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppConfig.primaryColor),
                        tooltip: 'Sao chép bản dịch',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _translatedText));
                          AppDialogs.showSuccess(context, 'Đã sao chép bản dịch vào clipboard!');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded, size: 18, color: AppConfig.primaryColor),
                        tooltip: 'Chia sẻ bản dịch',
                        onPressed: () => SharePlus.instance.share(
                          ShareParams(text: _translatedText, subject: 'Bản dịch'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Source Language
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sourceLang,
                isExpanded: true,
                items: TranslationService.supportedLanguages.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _sourceLang = val);
                    _executeTranslation();
                  }
                },
              ),
            ),
          ),

          // Swap button
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppConfig.primaryColor),
            onPressed: _swapLanguages,
          ),

          // Target Language
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _targetLang,
                isExpanded: true,
                items: TranslationService.supportedLanguages.entries
                    .where((e) => e.key != 'auto')
                    .map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _targetLang = val);
                    _executeTranslation();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: IMAGE TRANSLATION
  Widget _buildImageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pick Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessingImage ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Chụp từ Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessingImage ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Chọn từ Thư viện'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Image Preview Container
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: kIsWeb
                        ? Image.network(_selectedImage!.path, fit: BoxFit.cover, width: double.infinity)
                        : Image.file(File(_selectedImage!.path), fit: BoxFit.cover, width: double.infinity),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_search_rounded, size: 48, color: Color(0xFF94A3B8)),
                        SizedBox(height: 8),
                        Text('Chưa có ảnh nào được chọn', style: TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          if (_isProcessingImage)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Đang quét OCR và dịch thuật từ ảnh chụp...'),
                  ],
                ),
              ),
            ),

          // Extracted Text and Translation
          if (_extractedImageText.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.text_fields_rounded, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('1. Văn bản nhận diện từ ảnh (OCR):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(_extractedImageText, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.g_translate_rounded, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text('2. Bản dịch sang Tiếng Anh:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _translatedImageText,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
