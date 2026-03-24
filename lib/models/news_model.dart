// =============================================================================
// MODEL: news_model.dart
// Represents a news article. Pure data class.
// =============================================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NewsCategory { all, health, academic, campus, sports }

extension NewsCategoryExt on NewsCategory {
  String get label => name[0].toUpperCase() + name.substring(1);
  String get tag   => name.toUpperCase();

  Color get color {
    switch (this) {
      case NewsCategory.health:   return const Color(0xFF8B0000);
      case NewsCategory.academic: return AppTheme.primary;
      case NewsCategory.campus:   return const Color(0xFF5D4037);
      case NewsCategory.sports:   return const Color(0xFF1565C0);
      default:                    return AppTheme.primary;
    }
  }
}

class NewsModel {
  final String id;
  final String title;
  final String body;
  final NewsCategory category;
  final DateTime publishedAt;
  final bool isFeatured;
  final String? imageUrl;
  final String authorName;

  const NewsModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.publishedAt,
    this.isFeatured = false,
    this.imageUrl,
    this.authorName = 'Scholife Editorial',
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) => NewsModel(
    id:          json['id'] as String,
    title:       json['title'] as String,
    body:        json['body'] as String,
    category:    NewsCategory.values.firstWhere(
          (c) => c.name == (json['category'] as String).toLowerCase(),
      orElse: () => NewsCategory.all,
    ),
    publishedAt: DateTime.parse(json['published_at'] as String),
    isFeatured:  json['is_featured'] as bool? ?? false,
    imageUrl:    json['image_url'] as String?,
    authorName:  json['author_name'] as String? ?? 'Scholife Editorial',
  );

  Map<String, dynamic> toJson() => {
    'id':           id,
    'title':        title,
    'body':         body,
    'category':     category.name,
    'published_at': publishedAt.toIso8601String(),
    'is_featured':  isFeatured,
    'image_url':    imageUrl,
    'author_name':  authorName,
  };

  String get timeAgo {
    final diff = DateTime.now().difference(publishedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Mock data list for development
  static List<NewsModel> get mockList => [
    NewsModel(id: 'n1', title: 'COVID-19 UPDATE', body: 'Important health protocols and vaccination requirements for the upcoming semester. All students must comply with updated health guidelines.', category: NewsCategory.health, publishedAt: DateTime.now().subtract(const Duration(hours: 2)), isFeatured: true),
    NewsModel(id: 'n2', title: 'Enrollment Schedule Released', body: 'Second semester enrollment is now open. Check the portal for your designated schedule.', category: NewsCategory.academic, publishedAt: DateTime.now().subtract(const Duration(hours: 5))),
    NewsModel(id: 'n3', title: 'Library Extended Hours', body: 'The library will extend operating hours until 10PM during finals week.', category: NewsCategory.campus, publishedAt: DateTime.now().subtract(const Duration(days: 1))),
    NewsModel(id: 'n4', title: 'Intramurals 2024 Registration', body: 'Registration for the annual intramural sports competition is now open.', category: NewsCategory.sports, publishedAt: DateTime.now().subtract(const Duration(days: 2))),
    NewsModel(id: 'n5', title: 'Mental Health Week', body: 'Join us for a week of wellness activities, counseling sessions, and community support.', category: NewsCategory.health, publishedAt: DateTime.now().subtract(const Duration(days: 3))),
  ];
}