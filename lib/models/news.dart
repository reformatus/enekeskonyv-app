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
  final List<NewsActionButton> actionButtons;

  const News({
    required this.id,
    required this.title,
    required this.markdownText,
    required this.archived,
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
      actionButtons: actionButtons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'markdownText': markdownText,
      'archived': archived,
      'actionButtons': actionButtons.map((button) => button.toJson()).toList(),
    };
  }
}