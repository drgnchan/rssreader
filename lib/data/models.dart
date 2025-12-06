class SessionToken {
  SessionToken({required this.baseUrl, required this.sid, required this.email});

  final String baseUrl;
  final String sid;
  final String email;

  String authHeader() => 'GoogleLogin auth=$sid';
}

class SubscriptionListDto {
  SubscriptionListDto({required this.subscriptions});

  final List<SubscriptionDto> subscriptions;

  factory SubscriptionListDto.fromJson(Map<String, dynamic> json) {
    final raw = json['subscriptions'] as List<dynamic>? ?? [];
    return SubscriptionListDto(
      subscriptions: raw
          .map((e) => SubscriptionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubscriptionDto {
  SubscriptionDto({
    required this.id,
    required this.title,
    this.url,
    this.htmlUrl,
    this.categories = const [],
    this.unreadCount,
  });

  final String id; // e.g., feed/https://example.com/rss
  final String title;
  final String? url;
  final String? htmlUrl;
  final List<CategoryDto> categories;
  final int? unreadCount;

  factory SubscriptionDto.fromJson(Map<String, dynamic> json) {
    final cats = json['categories'] as List<dynamic>? ?? [];
    return SubscriptionDto(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      url: json['url'] as String?,
      htmlUrl: json['htmlUrl'] as String?,
      categories: cats
          .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: json['unreadCount'] as int?,
    );
  }

  SubscriptionDto withUnread(int? unread) => SubscriptionDto(
    id: id,
    title: title,
    url: url,
    htmlUrl: htmlUrl,
    categories: categories,
    unreadCount: unread,
  );
}

class CategoryDto {
  CategoryDto({required this.id, required this.label});

  final String id; // e.g., user/-/label/Tech
  final String label;

  factory CategoryDto.fromJson(Map<String, dynamic> json) => CategoryDto(
    id: json['id'] as String,
    label: json['label'] as String? ?? '',
  );
}

class UnreadCountDto {
  UnreadCountDto({required this.unreadcounts});

  final List<UnreadCountItem> unreadcounts;

  factory UnreadCountDto.fromJson(Map<String, dynamic> json) {
    final raw = json['unreadcounts'] as List<dynamic>? ?? [];
    return UnreadCountDto(
      unreadcounts: raw
          .map((e) => UnreadCountItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UnreadCountItem {
  UnreadCountItem({required this.id, required this.count});

  final String id; // feed or category id
  final int count;

  factory UnreadCountItem.fromJson(Map<String, dynamic> json) =>
      UnreadCountItem(
        id: json['id'] as String,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

class StreamContentDto {
  StreamContentDto({required this.id, required this.items});

  final String id;
  final List<ItemDto> items;

  factory StreamContentDto.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return StreamContentDto(
      id: json['id'] as String? ?? '',
      items: raw
          .map((e) => ItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ItemDto {
  ItemDto({
    required this.id,
    required this.title,
    required this.published,
    this.updated,
    this.author,
    this.summary,
    this.content,
    this.categories = const [],
    this.alternate,
  });

  final String id; // entry id
  final String title;
  final int published;
  final int? updated;
  final String? author;
  final ContentDto? summary;
  final ContentDto? content;
  final List<String> categories;
  final LinkDto? alternate;

  bool get isRead => categories.contains(_tagRead);
  bool get isStarred => categories.contains(_tagStarred);

  ItemDto copyWith({bool? read, bool? starred}) {
    final set = {...categories};
    if (read != null) {
      if (read) {
        set.add(_tagRead);
      } else {
        set.remove(_tagRead);
      }
    }
    if (starred != null) {
      if (starred) {
        set.add(_tagStarred);
      } else {
        set.remove(_tagStarred);
      }
    }
    return ItemDto(
      id: id,
      title: title,
      published: published,
      updated: updated,
      author: author,
      summary: summary,
      content: content,
      categories: set.toList(),
      alternate: alternate,
    );
  }

  factory ItemDto.fromJson(Map<String, dynamic> json) {
    final altList = json['alternate'] as List<dynamic>? ?? [];
    return ItemDto(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      published: (json['published'] as num?)?.toInt() ?? 0,
      updated: (json['updated'] as num?)?.toInt(),
      author: json['author'] as String?,
      summary: json['summary'] != null
          ? ContentDto.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
      content: json['content'] != null
          ? ContentDto.fromJson(json['content'] as Map<String, dynamic>)
          : null,
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      alternate: altList.isNotEmpty
          ? LinkDto.fromJson(altList.first as Map<String, dynamic>)
          : null,
    );
  }
}

class LinkDto {
  LinkDto({required this.href, this.type});

  final String href;
  final String? type;

  factory LinkDto.fromJson(Map<String, dynamic> json) => LinkDto(
    href: json['href'] as String? ?? '',
    type: json['type'] as String?,
  );
}

class ContentDto {
  ContentDto({required this.content, this.direction});

  final String content;
  final String? direction;

  factory ContentDto.fromJson(Map<String, dynamic> json) => ContentDto(
    content: json['content'] as String? ?? '',
    direction: json['direction'] as String?,
  );
}

const _tagRead = 'user/-/state/com.google/read';
const _tagStarred = 'user/-/state/com.google/starred';
