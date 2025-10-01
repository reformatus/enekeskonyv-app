class NewsActionButton {
  final String title;
  final String uri;

  const NewsActionButton({
    required this.title,
    required this.uri,
  });

  factory NewsActionButton.fromJson(Map<String, dynamic> json) {
    return NewsActionButton(
      title: json['title'] as String,
      uri: json['uri'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'uri': uri,
    };
  }
}

class News {
  final String id;
  final String title;
  final String markdownText;
  final bool archived;
  final DateTime timestamp;
  final DateTime? expirationTimestamp;
  final List<NewsActionButton> actionButtons;

  const News({
    required this.id,
    required this.title,
    required this.markdownText,
    required this.archived,
    required this.timestamp,
    this.expirationTimestamp,
    this.actionButtons = const [],
  });

  factory News.fromJson(Map<String, dynamic> json) {
    final actionButtonsList = json['actionButtons'] as List?;
    final actionButtons = actionButtonsList?.map((button) => 
        NewsActionButton.fromJson(button as Map<String, dynamic>)).toList() ?? [];

    return News(
      id: json['id'] as String,
      title: json['title'] as String,
      markdownText: json['markdownText'] as String,
      archived: json['archived'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expirationTimestamp: json['expirationTimestamp'] != null 
          ? DateTime.parse(json['expirationTimestamp'] as String)
          : null,
      actionButtons: actionButtons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'markdownText': markdownText,
      'archived': archived,
      'timestamp': timestamp.toIso8601String(),
      'expirationTimestamp': expirationTimestamp?.toIso8601String(),
      'actionButtons': actionButtons.map((button) => button.toJson()).toList(),
    };
  }

  bool get isExpired {
    if (expirationTimestamp == null) return false;
    return DateTime.now().isAfter(expirationTimestamp!);
  }
}