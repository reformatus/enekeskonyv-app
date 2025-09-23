import 'package:flutter_test/flutter_test.dart';
import 'package:enekeskonyv/models/news.dart';
import 'package:enekeskonyv/services/news_service.dart';

void main() {
  group('News System Tests', () {
    test('News model serialization works correctly', () {
      final news = News(
        id: 'test-1',
        title: 'Test Title',
        markdownText: 'Test **markdown** content',
        archived: false,
        actionButtons: [
          const NewsActionButton(
            title: 'Test Button',
            uri: 'https://example.com',
          ),
        ],
      );

      // Test serialization
      final json = news.toJson();
      expect(json['id'], 'test-1');
      expect(json['title'], 'Test Title');
      expect(json['markdownText'], 'Test **markdown** content');
      expect(json['archived'], false);
      expect(json['actionButtons'], hasLength(1));

      // Test deserialization
      final newsFromJson = News.fromJson(json);
      expect(newsFromJson.id, news.id);
      expect(newsFromJson.title, news.title);
      expect(newsFromJson.markdownText, news.markdownText);
      expect(newsFromJson.archived, news.archived);
      expect(newsFromJson.actionButtons, hasLength(1));
      expect(newsFromJson.actionButtons.first.title, 'Test Button');
      expect(newsFromJson.actionButtons.first.uri, 'https://example.com');
    });

    test('getUnreadNews filters correctly', () {
      final allNews = [
        const News(
          id: 'news-1',
          title: 'Unread Active News',
          markdownText: 'Content',
          archived: false,
        ),
        const News(
          id: 'news-2',
          title: 'Read Active News',
          markdownText: 'Content',
          archived: false,
        ),
        const News(
          id: 'news-3',
          title: 'Unread Archived News',
          markdownText: 'Content',
          archived: true,
        ),
      ];

      final readNewsIds = ['news-2'];

      final unreadNews = NewsService.getUnreadNews(allNews, readNewsIds);

      expect(unreadNews, hasLength(1));
      expect(unreadNews.first.id, 'news-1');
      expect(unreadNews.first.title, 'Unread Active News');
    });

    test('News model handles missing action buttons', () {
      final json = {
        'id': 'test-1',
        'title': 'Test Title',
        'markdownText': 'Test content',
        'archived': false,
        // No actionButtons field
      };

      final news = News.fromJson(json);
      expect(news.actionButtons, isEmpty);
    });
  });
}