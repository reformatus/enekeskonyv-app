import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'news.dart';
import 'news_dialog.dart';
import 'news_service.dart';

class PastNewsPage extends StatefulWidget {
  const PastNewsPage({super.key});

  @override
  State<PastNewsPage> createState() => _PastNewsPageState();
}

class _PastNewsPageState extends State<PastNewsPage> {
  List<News>? _newsList;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allNews = await NewsService.fetchNews();
      final validNews = NewsService.getAllValidNews(allNews);
      final sortedNews = NewsService.sortNewsByDate(validNews);

      setState(() {
        _newsList = sortedNews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Hiba történt a hírek betöltése közben';
        _isLoading = false;
      });
    }
  }

  void _showNewsDialog(News news) {
    showDialog(
      context: context,
      builder: (context) => NewsDialog(
        news: news,
        onClose: () {}, // Don't mark as read from past news browser
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy. MM. dd.').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hírek'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNews,
                          child: const Text('Újrapróbálás'),
                        ),
                      ],
                    ),
                  ),
                )
              : _newsList == null || _newsList!.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Nincsenek elérhető hírek',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNews,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _newsList!.length,
                        itemBuilder: (context, index) {
                          final news = _newsList![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 8.0,
                            ),
                            child: ListTile(
                              title: Text(
                                news.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(news.timestamp),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    news.markdownText.length > 100
                                        ? '${news.markdownText.substring(0, 100)}...'
                                        : news.markdownText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (news.archived)
                                    Icon(
                                      Icons.archive,
                                      color: Theme.of(context).colorScheme.secondary,
                                      size: 16,
                                    ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () => _showNewsDialog(news),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}