import 'package:flutter/material.dart';

class SearchHighlights extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle textStyle;

  const SearchHighlights({
    super.key,
    required this.text,
    required this.query,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return const SizedBox.shrink();

    return RichText(
      text: _buildSpan(),
      softWrap: false,
      overflow: TextOverflow.visible,
      textScaleFactor: 1.0,
    );
  }

  TextSpan _buildSpan() {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int startIndex = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, startIndex);
      if (index == -1) {
        spans.add(
          TextSpan(
            text: text.substring(startIndex),
            style: textStyle.copyWith(color: Colors.transparent),
          ),
        );
        break;
      }

      if (index > startIndex) {
        spans.add(
          TextSpan(
            text: text.substring(startIndex, index),
            style: textStyle.copyWith(color: Colors.transparent),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: textStyle.copyWith(
            color: Colors.transparent,
            backgroundColor: const Color(0x809C27B0), // Purple with 0.5 opacity
          ),
        ),
      );

      startIndex = index + query.length;
    }

    return TextSpan(children: spans);
  }
}
