import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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

  // Image / Camera translation
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _ocrTextController = TextEditingController();
  String _imageSourceLang = 'auto';
  String _imageTargetLang = 'en';
  String _translatedImageText = '';
  bool _isProcessingImage = false;
  bool _isTranslatingImage = false;

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
    _ocrTextController.dispose();
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

  // --- CAMERA & IMAGE TRANSLATION LOGIC ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = image;
        _isProcessingImage = true;
        _ocrTextController.clear();
        _translatedImageText = '';
      });

      String recognizedText = '';

      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        // Fallback for non-mobile platforms (e.g. Windows desktop/web)
        await Future.delayed(const Duration(milliseconds: 600));
        recognizedText =
            'Tính năng OCR từ Camera sử dụng Google ML Kit được tối ưu hóa cho thiết bị di động (Android / iOS). Trên máy tính, bạn có thể chỉnh sửa văn bản này trực tiếp để trải nghiệm dịch thuật.';
      } else {
        // Real OCR via Google ML Kit Text Recognition on Android/iOS
        final inputImage = InputImage.fromFilePath(image.path);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        try {
          final RecognizedText result = await textRecognizer.processImage(inputImage);
          recognizedText = result.text.trim();
        } finally {
          await textRecognizer.close();
        }
      }

      if (!mounted) return;

      if (recognizedText.isEmpty) {
        setState(() {
          _isProcessingImage = false;
        });
        AppDialogs.showWarning(
          context,
          'Không tìm thấy văn bản nào trong ảnh. Vui lòng chụp ảnh rõ nét hơn hoặc chọn ảnh có chữ in rõ ràng.',
        );
        return;
      }

      _ocrTextController.text = recognizedText;

      setState(() {
        _isProcessingImage = false;
        _isTranslatingImage = true;
      });

      final translation = await TranslationService.translate(
        text: recognizedText,
        fromLanguage: _imageSourceLang,
        toLanguage: _imageTargetLang,
      );

      if (mounted) {
        setState(() {
          _translatedImageText = translation;
          _isTranslatingImage = false;
        });
        AppDialogs.showSuccess(context, 'Đã nhận diện văn bản OCR và dịch thành công!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
          _isTranslatingImage = false;
        });
        AppDialogs.showError(context, 'Lỗi xử lý ảnh: ${e.toString()}');
      }
    }
  }

  Future<void> _retranslateImageText() async {
    final text = _ocrTextController.text.trim();
    if (text.isEmpty) {
      AppDialogs.showWarning(context, 'Chưa có nội dung văn bản để dịch.');
      return;
    }

    setState(() => _isTranslatingImage = true);

    final translation = await TranslationService.translate(
      text: text,
      fromLanguage: _imageSourceLang,
      toLanguage: _imageTargetLang,
    );

    if (mounted) {
      setState(() {
        _translatedImageText = translation;
        _isTranslatingImage = false;
      });
    }
  }

  void _swapImageLanguages() {
    if (_imageSourceLang == 'auto') {
      setState(() {
        final temp = _imageTargetLang;
        _imageTargetLang = 'vi';
        _imageSourceLang = temp;
      });
    } else {
      setState(() {
        final temp = _imageSourceLang;
        _imageSourceLang = _imageTargetLang;
        _imageTargetLang = temp;
      });
    }
    if (_ocrTextController.text.trim().isNotEmpty) {
      _retranslateImageText();
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _ocrTextController.clear();
      _translatedImageText = '';
    });
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
            Tab(icon: Icon(Icons.camera_alt_rounded), text: 'Dịch từ Camera / Ảnh'),
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
            tooltip: 'Đổi chiều dịch',
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

  // TAB 2: IMAGE / CAMERA TRANSLATION
  Widget _buildImageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language selector bar for camera/image translation
          _buildImageLanguageSelectorBar(),
          const SizedBox(height: 14),

          // Action Buttons: Camera & Gallery
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessingImage || _isTranslatingImage
                      ? null
                      : () => _pickImage(ImageSource.camera),
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
                  onPressed: _isProcessingImage || _isTranslatingImage
                      ? null
                      : () => _pickImage(ImageSource.gallery),
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
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: _selectedImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: kIsWeb
                            ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                            : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                            tooltip: 'Xóa ảnh',
                            onPressed: _clearSelectedImage,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.document_scanner_rounded, size: 48, color: Color(0xFF94A3B8)),
                        SizedBox(height: 8),
                        Text('Chụp hoặc chọn ảnh để nhận diện chữ (OCR) & dịch',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Loading Indicator for OCR / Translation
          if (_isProcessingImage || _isTranslatingImage)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      _isProcessingImage
                          ? 'Đang nhận diện văn bản từ ảnh (OCR)...'
                          : 'Đang dịch thuật văn bản...',
                      style: const TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          // Extracted OCR Text Card
          if (_ocrTextController.text.isNotEmpty) ...[
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
                      const Row(
                        children: [
                          Icon(Icons.text_fields_rounded, color: AppConfig.primaryColor, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '1. Văn bản nhận diện (OCR - Có thể sửa):',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConfig.textPrimary),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                            tooltip: 'Sao chép văn bản OCR',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _ocrTextController.text));
                              AppDialogs.showSuccess(context, 'Đã sao chép văn bản OCR!');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                            tooltip: 'Xóa văn bản',
                            onPressed: () {
                              _ocrTextController.clear();
                              setState(() => _translatedImageText = '');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ocrTextController,
                    maxLines: null,
                    minLines: 2,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                    decoration: const InputDecoration(
                      hintText: 'Văn bản nhận diện sẽ hiển thị ở đây...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isTranslatingImage ? null : _retranslateImageText,
                      icon: const Icon(Icons.translate_rounded, size: 16),
                      label: const Text('Dịch lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Translation Result Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.05),
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
                      Row(
                        children: [
                          const Icon(Icons.g_translate_rounded, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '2. Bản dịch sang ${TranslationService.supportedLanguages[_imageTargetLang] ?? _imageTargetLang}:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                      if (_isTranslatingImage)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    _translatedImageText.isNotEmpty
                        ? _translatedImageText
                        : (_isTranslatingImage ? 'Đang dịch...' : 'Chưa có bản dịch'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF064E3B),
                      height: 1.4,
                    ),
                  ),
                  if (_translatedImageText.isNotEmpty) ...[
                    const Divider(height: 20, color: Color(0xFFA7F3D0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF047857)),
                          tooltip: 'Sao chép bản dịch',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _translatedImageText));
                            AppDialogs.showSuccess(context, 'Đã sao chép bản dịch vào clipboard!');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded, size: 18, color: Color(0xFF047857)),
                          tooltip: 'Chia sẻ bản dịch',
                          onPressed: () => SharePlus.instance.share(
                            ShareParams(text: _translatedImageText, subject: 'Bản dịch ảnh'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Tips Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD97706), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mẹo chụp ảnh để nhận diện OCR tốt nhất:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Đặt camera song song và vuông góc với văn bản.\n• Đảm bảo đủ ánh sáng, tránh chói lóa hoặc bóng tối.\n• Bạn có thể sửa trực tiếp nội dung nhận diện trước khi bấm "Dịch lại".',
                        style: TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageLanguageSelectorBar() {
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
                value: _imageSourceLang,
                isExpanded: true,
                items: TranslationService.supportedLanguages.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _imageSourceLang = val);
                    if (_ocrTextController.text.trim().isNotEmpty) {
                      _retranslateImageText();
                    }
                  }
                },
              ),
            ),
          ),

          // Swap button
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppConfig.primaryColor),
            tooltip: 'Đổi chiều dịch',
            onPressed: _swapImageLanguages,
          ),

          // Target Language
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _imageTargetLang,
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
                    setState(() => _imageTargetLang = val);
                    if (_ocrTextController.text.trim().isNotEmpty) {
                      _retranslateImageText();
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
