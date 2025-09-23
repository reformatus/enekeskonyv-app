import 'dart:convert';
import 'package:http/http.dart' as http;
import 'news.dart';

class NewsService {
  static const String defaultNewsApiUrl = 'https://reformatus.github.io/enekeskonyv-app/news.json';
  
  static Future<List<News>> fetchNews({String? customUrl}) async {
    try {
      final url = customUrl ?? defaultNewsApiUrl;
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => News.fromJson(json)).toList();
      } else {
        // If the API fails, return empty list (graceful degradation)
        return [];
      }
    } catch (e) {
      // If there's any error (network, parsing, etc.), return empty list
      // This ensures the app continues to work even if news service is down
      return [];
    }
  }
  
  static List<News> getUnreadNews(List<News> allNews, List<String> readNewsIds) {
    return allNews.where((news) => 
        !news.archived && !news.isExpired && !readNewsIds.contains(news.id)
    ).toList();
  }

  static List<News> getAllValidNews(List<News> allNews) {
    return allNews.where((news) => !news.isExpired).toList();
  }

  static List<News> sortNewsByDate(List<News> newsList) {
    final sorted = List<News>.from(newsList);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }
}