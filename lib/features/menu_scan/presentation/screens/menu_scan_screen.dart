import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class MenuScanScreen extends ConsumerStatefulWidget {
  const MenuScanScreen({super.key});

  @override
  ConsumerState<MenuScanScreen> createState() => _MenuScanScreenState();
}

class _MenuScanScreenState extends ConsumerState<MenuScanScreen> {
  final _picker = ImagePicker();
  final List<XFile> _pickedFiles = [];
  final List<Uint8List> _pickedBytes = [];
  bool _isAnalyzing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showImageSourceDialog();
    });
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '메뉴판 사진 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '여러 장도 가능해요',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('카메라로 촬영',
                    style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('갤러리에서 선택',
                    style: TextStyle(color: AppColors.textPrimary)),
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

  Future<void> _analyzeAndNavigate() async {
    if (_pickedFiles.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    final chatNotifier = ref.read(chatNotifierProvider.notifier);
    final repository = ref.read(chatRepositoryProvider);

    try {
      // 모든 이미지를 Base64로 변환
      final base64Images = <String>[];
      for (final bytes in _pickedBytes) {
        base64Images.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      }

      final result = await repository.analyzeMenu(base64Images);

      chatNotifier.startModeB();
      chatNotifier.completeModeB(result);
      if (!mounted) return;
      context.go('/chat');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _error = '메뉴판 분석에 실패했어요. 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: AppColors.textSecondary),
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
        child: Padding(
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
                    style: const TextStyle(
                        color: AppColors.recordingRed, fontSize: 13),
                  ),
                ),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            '메뉴판 사진을 찍어주세요',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '여러 장이면 더 정확하게 분석해요',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
              // 삭제 버튼
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _isAnalyzing ? null : () => _removeImage(index),
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
              // 번호
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
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      children: [
        // 사진 수 표시
        if (_pickedFiles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_pickedFiles.length}장 선택됨',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isAnalyzing ? null : _showImageSourceDialog,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(_pickedFiles.isNotEmpty ? '사진 추가' : '사진 선택'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.3)),
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
                  onPressed: _isAnalyzing ? null : _analyzeAndNavigate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('분석하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
}
