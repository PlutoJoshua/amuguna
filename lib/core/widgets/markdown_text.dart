import 'package:flutter/material.dart';

/// 카나나-o 응답에 자주 등장하는 가벼운 마크다운만 렌더하는 위젯.
///
/// 지원:
///   `# heading`, `## heading`, `### heading`
///   `**bold**`     (인라인)
///   빈 줄          (간격)
///   `---`          (구분선)
///   리스트 마커 `1. ` `- `는 텍스트 그대로 통과 (시각적 들여쓰기는 안 함)
///
/// 외부 패키지(flutter_markdown 등) 도입 없이 60줄 안짝으로 우리 케이스만 처리.
class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MarkdownText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          _buildBlock(context, lines[i], base, isFirst: i == 0),
      ],
    );
  }

  Widget _buildBlock(
    BuildContext context,
    String line,
    TextStyle base, {
    required bool isFirst,
  }) {
    final trimmed = line.trim();

    // 헤딩 (h1/h2/h3)
    if (trimmed.startsWith('### ')) {
      return Padding(
        padding: EdgeInsets.only(top: isFirst ? 0 : 10, bottom: 4),
        child: Text(
          trimmed.substring(4),
          style: base.copyWith(
            fontSize: (base.fontSize ?? 14) + 1,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    if (trimmed.startsWith('## ')) {
      return Padding(
        padding: EdgeInsets.only(top: isFirst ? 0 : 14, bottom: 6),
        child: Text(
          trimmed.substring(3),
          style: base.copyWith(
            fontSize: (base.fontSize ?? 14) + 3,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
      );
    }
    if (trimmed.startsWith('# ')) {
      return Padding(
        padding: EdgeInsets.only(top: isFirst ? 0 : 16, bottom: 8),
        child: Text(
          trimmed.substring(2),
          style: base.copyWith(
            fontSize: (base.fontSize ?? 14) + 5,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
      );
    }

    // 구분선
    if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          height: 1,
          color: base.color?.withValues(alpha: 0.15),
        ),
      );
    }

    // 빈 줄 → 간격
    if (trimmed.isEmpty) {
      return const SizedBox(height: 6);
    }

    // 인라인 (**bold** 파싱) — 들여쓰기 없이 줄 그대로
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text.rich(
        TextSpan(
          style: base,
          children: _parseInline(line, base),
        ),
      ),
    );
  }

  List<InlineSpan> _parseInline(String line, TextStyle base) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*([^*\n]+)\*\*');
    int last = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > last) {
        spans.add(TextSpan(text: line.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: base.copyWith(fontWeight: FontWeight.bold),
      ));
      last = match.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last)));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: line));
    }
    return spans;
  }
}
