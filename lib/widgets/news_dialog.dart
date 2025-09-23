import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news.dart';

class NewsDialog extends StatelessWidget {
  final News news;
  final VoidCallback onClose;

  const NewsDialog({
    super.key,
    required this.news,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        news.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: MarkdownWidget(
            data: news.markdownText,
            shrinkWrap: true,
            selectable: true,
            config: MarkdownConfig(
              configs: [
                const PConfig(
                  textStyle: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        ...news.actionButtons.map((button) => TextButton(
          onPressed: () => _launchUrl(button.uri),
          child: Text(button.title),
        )),
        TextButton(
          onPressed: () {
            onClose();
            Navigator.of(context).pop();
          },
          child: const Text('Bezárás'),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Silently fail if URL is malformed or can't be launched
    }
  }
}

class NewsOverlay {
  static Future<void> showNewsSequence(
    BuildContext context,
    List<News> newsList,
    Function(String) markAsRead,
  ) async {
    for (int i = 0; i < newsList.length; i++) {
      final news = newsList[i];
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return NewsDialog(
            news: news,
            onClose: () => markAsRead(news.id),
          );
        },
      );
    }
  }
}