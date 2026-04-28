import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

/// 메뉴 스캔 진행 단계
enum _ScanStage { picking, analyzing, reviewing }

class MenuScanScreen extends ConsumerStatefulWidget {
  const MenuScanScreen({super.key});

  @override
  ConsumerState<MenuScanScreen> createState() => _MenuScanScreenState();
}

class _MenuScanScreenState extends ConsumerState<MenuScanScreen> {
  final _picker = ImagePicker();
  final List<XFile> _pickedFiles = [];
  final List<Uint8List> _pickedBytes = [];
  _ScanStage _stage = _ScanStage.picking;
  String? _analysisResult;
  String? _error;

  /// macOS 데스크탑/웹에서는 카메라 직접 촬영이 불안정하거나 불가능하므로 항목을 숨김.
  bool get _supportsCamera {
    if (kIsWeb) return false;
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) return false;
    return true;
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '메뉴판 사진 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '여러 장도 가능해요',
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              if (_supportsCamera)
                ListTile(
                  leading:
                      Icon(Icons.camera_alt, color: context.colors.primary),
                  title: Text(
                    '카메라로 촬영',
                    style: TextStyle(color: context.colors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ListTile(
                leading:
                    Icon(Icons.photo_library, color: context.colors.primary),
                title: Text(
                  '갤러리에서 선택',
                  style: TextStyle(color: context.colors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultiImage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFile == null) return;

      final bytes = await xFile.readAsBytes();
      setState(() {
        _pickedFiles.add(xFile);
        _pickedBytes.add(bytes);
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = '이미지를 불러올 수 없습니다';
      });
    }
  }

  Future<void> _pickMultiImage() async {
    try {
      final xFiles = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFiles.isEmpty) return;

      final bytesList = <Uint8List>[];
      for (final xFile in xFiles) {
        bytesList.add(await xFile.readAsBytes());
      }
      setState(() {
        _pickedFiles.addAll(xFiles);
        _pickedBytes.addAll(bytesList);
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = '이미지를 불러올 수 없습니다';
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedFiles.removeAt(index);
      _pickedBytes.removeAt(index);
    });
  }

  Future<void> _runAnalysis() async {
    if (_pickedFiles.isEmpty) return;

    setState(() {
      _stage = _ScanStage.analyzing;
      _error = null;
    });

    final repository = ref.read(chatRepositoryProvider);

    try {
      final base64Images = <String>[];
      for (final bytes in _pickedBytes) {
        base64Images.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      }

      final result = await repository.analyzeMenu(base64Images);

      if (!mounted) return;
      setState(() {
        _analysisResult = result;
        _stage = _ScanStage.reviewing;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _ScanStage.picking;
        _error = '메뉴판 분석 실패: $e';
      });
    }
  }

  void _confirmAndStartChat() {
    final result = _analysisResult;
    if (result == null) return;

    final chatNotifier = ref.read(chatNotifierProvider.notifier);
    chatNotifier.startModeB(
      menuThumbnail: _pickedBytes.first,
      photoCount: _pickedFiles.length,
    );
    chatNotifier.completeModeB(result);
    context.go('/chat');
  }

  void _retryFromScratch() {
    setState(() {
      _stage = _ScanStage.picking;
      _analysisResult = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.colors.textSecondary),
          onPressed: () => context.go('/'),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📷 ', style: TextStyle(fontSize: 22)),
            Text(AppStrings.modeBTitle),
          ],
        ),
      ),
      body: SafeArea(
        child: switch (_stage) {
          _ScanStage.picking => _buildPickingStage(),
          _ScanStage.analyzing => _buildAnalyzingStage(),
          _ScanStage.reviewing => _buildReviewingStage(),
        },
      ),
    );
  }

  // ─── 1단계: 사진 선택 ────────────────────────────────────────────
  Widget _buildPickingStage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: _pickedFiles.isNotEmpty
                ? _buildImageGrid()
                : _buildEmptyState(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: TextStyle(
                    color: context.colors.recordingRed, fontSize: 13),
              ),
            ),
          _buildPickingButtons(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: context.colors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '메뉴판 사진을 추가해주세요',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '여러 장이면 더 정확하게 분석해요',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _pickedFiles.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(_pickedBytes[index], fit: BoxFit.cover),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${index + 1}',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickingButtons() {
    return Column(
      children: [
        if (_pickedFiles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_pickedFiles.length}장 선택됨',
              style: TextStyle(
                  color: context.colors.textSecondary, fontSize: 13),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(_pickedFiles.isNotEmpty ? '사진 추가' : '사진 선택'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.textPrimary,
                  side: BorderSide(
                      color: context.colors.textSecondary.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_pickedFiles.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _runAnalysis,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('분석하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ─── 2단계: 분석 중 로딩 ────────────────────────────────────────
  Widget _buildAnalyzingStage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(context.colors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '메뉴판을 분석하고 있어요',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_pickedFiles.length}장의 사진에서 메뉴를 추출 중…',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          // 진행 중 미리보기 (작게)
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: _pickedBytes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _pickedBytes[i],
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // ─── 3단계: 분석 결과 확인 ──────────────────────────────────────
  Widget _buildReviewingStage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 작은 썸네일 + 사진 수
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _pickedBytes.first,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '분석 완료 · ${_pickedFiles.length}장',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '인식 결과 확인 후 추천을 시작해요',
                      style: TextStyle(
                        color: context.colors.textSecondary.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 결과 본문 (모델 응답 그대로 표시)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: context.isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Text(
                  _analysisResult ?? '',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 액션 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retryFromScratch,
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 찍기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.textPrimary,
                    side: BorderSide(
                      color: context.colors.textSecondary.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmAndStartChat,
                  icon: const Icon(Icons.mic),
                  label: const Text('이대로 추천 받기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
