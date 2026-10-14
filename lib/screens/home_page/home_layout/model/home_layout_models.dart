import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart' show ProductData;
import '../../model/brands_model.dart';
import '../../model/category_model.dart';

class HomeLayoutResponse {
  final bool success;
  final String message;
  final String scopeType;
  final int? scopeId;
  final List<HomeSection> sections;

  HomeLayoutResponse({
    required this.success,
    required this.message,
    required this.scopeType,
    required this.scopeId,
    required this.sections,
  });

  factory HomeLayoutResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rawSections = (data['sections'] as List?) ?? const [];
    return HomeLayoutResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      scopeType: data['scope_type']?.toString() ?? 'global',
      scopeId: data['scope_id'] is int ? data['scope_id'] as int : null,
      sections: rawSections
          .whereType<Map>()
          .map((e) => HomeSection.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class HomeSection {
  final int id;
  final String type; // hero | categories | banners | brands | products
  final String? title;
  final String? style;
  final dynamic config; // Map or List depending on type
  final String? backgroundImage;
  final String? heroMedia;
  final String? cardBackgroundImage;
  final Map<String, dynamic> content;

  HomeSection({
    required this.id,
    required this.type,
    required this.title,
    required this.style,
    required this.config,
    required this.backgroundImage,
    required this.heroMedia,
    required this.cardBackgroundImage,
    required this.content,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    return HomeSection(
      id: json['id'] is int ? json['id'] as int : 0,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString(),
      style: json['style']?.toString(),
      config: json['config'],
      backgroundImage: json['background_image']?.toString(),
      heroMedia: json['hero_media']?.toString(),
      cardBackgroundImage: json['card_background_image']?.toString(),
      content: (json['content'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  String? configStr(String key) {
    if (config is Map && (config as Map)[key] != null) {
      return (config as Map)[key].toString();
    }
    return null;
  }

  List<dynamic> _list(String key) => (content[key] is List) ? content[key] as List : const [];

  List<HeroItem> get heroItems => _list('items')
      .whereType<Map>()
      .map((e) => HeroItem.fromJson(e.cast<String, dynamic>()))
      .toList();

  List<BannerItem> get bannerItems => _list('items')
      .whereType<Map>()
      .map((e) => BannerItem.fromJson(e.cast<String, dynamic>()))
      .toList();

  List<CategoryData> get categories => _list('categories')
      .whereType<Map>()
      .map((e) => CategoryData.fromJson(e.cast<String, dynamic>()))
      .toList();

  List<BrandData> get brands => _list('brands')
      .whereType<Map>()
      .map((e) => BrandData.fromJson(e.cast<String, dynamic>()))
      .toList();

  List<ProductData> get products => _list('products')
      .whereType<Map>()
      .map((e) => ProductData.fromJson(e.cast<String, dynamic>()))
      .toList();
}

class HeroItem {
  final int id;
  final String title;
  final String? image;
  final String? defaultImage;
  final String type;
  final int? targetId;
  final String slug;

  HeroItem({
    required this.id,
    required this.title,
    required this.image,
    required this.defaultImage,
    required this.type,
    required this.targetId,
    required this.slug,
  });

  factory HeroItem.fromJson(Map<String, dynamic> json) => HeroItem(
        id: json['id'] is int ? json['id'] as int : 0,
        title: json['title']?.toString() ?? '',
        image: (json['image']?.toString().isNotEmpty ?? false) ? json['image'].toString() : null,
        defaultImage: (json['default_image']?.toString().isNotEmpty ?? false) ? json['default_image'].toString() : null,
        type: json['type']?.toString() ?? '',
        targetId: json['target_id'] is int ? json['target_id'] as int : null,
        slug: json['slug']?.toString() ?? '',
      );
}

class BannerItem {
  final int id;
  final String image;
  final String? linkType;
  final String? linkUrl;
  final int? targetId;
  final String? slug;

  BannerItem({
    required this.id,
    required this.image,
    required this.linkType,
    required this.linkUrl,
    required this.targetId,
    required this.slug,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) => BannerItem(
        id: json['id'] is int ? json['id'] as int : 0,
        image: json['image']?.toString() ?? '',
        linkType: json['link_type']?.toString(),
        linkUrl: json['link_url']?.toString(),
        targetId: json['target_id'] is int ? json['target_id'] as int : null,
        slug: json['slug']?.toString(),
      );
}
