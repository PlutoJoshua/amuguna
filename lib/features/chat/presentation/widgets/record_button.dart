import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class RecordButton extends StatefulWidget {
  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onTap;

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didUpdateWidget(RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isProcessing) {
      return _buildProcessingButton();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = widget.isRecording
              ? 1.0 + (_pulseController.value * 0.15)
              : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording
                    ? AppColors.recordingRed
                    : AppColors.primary,
                boxShadow: widget.isRecording
                    ? [
                        BoxShadow(
                          color: AppColors.recordingRed.withValues(
                              alpha: 0.4 + _pulseController.value * 0.3),
                          blurRadius: 20 + _pulseController.value * 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
              ),
              child: Icon(
                widget.isRecording ? Icons.stop : Icons.mic,
                color: widget.isRecording ? Colors.white : Colors.black,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProcessingButton() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),
    );
  }
}
