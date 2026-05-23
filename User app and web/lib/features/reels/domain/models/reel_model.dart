import 'package:sixam_mart/util/app_constants.dart';

class ReelModel {
  int? reelId;
  String? description;
  String? thumbnailFullUrl;
  String? videoFullUrl;
  int? storeId;
  String? storeName;
  String? storeLogoFullUrl;
  int? verifiedSeller;
  ReelStatsModel? stats;

  ReelModel({
    this.reelId,
    this.description,
    this.thumbnailFullUrl,
    this.videoFullUrl,
    this.storeId,
    this.storeName,
    this.storeLogoFullUrl,
    this.verifiedSeller,
    this.stats,
  });

  ReelModel.fromJson(Map<String, dynamic> json) {
    reelId = _readInt(json['reel_id']);
    description = _readString(json['description']);
    thumbnailFullUrl = _resolveUrl(_readString(json['thumbnail_full_url']));
    videoFullUrl = _resolveUrl(
      _readString(json['video_full_url'])
          ?? _readString(json['video_url'])
          ?? _readString(json['video_attachment_full_url'])
          ?? _readString(json['stream_url'])
          ?? _readString(json['reel_full_url']),
    );
    storeId = _readInt(json['store_id']);
    storeName = _readString(json['store_name']);
    storeLogoFullUrl = _resolveUrl(_readString(json['store_logo_full_url']));
    verifiedSeller = _readInt(json['verified_seller']);
    stats = json['stats'] is Map<String, dynamic>
        ? ReelStatsModel.fromJson(json['stats'])
        : json['stats'] is Map
            ? ReelStatsModel.fromJson(Map<String, dynamic>.from(json['stats']))
            : null;
    // `is_liked` may be returned at the reel root (list/details response) rather
    // than inside `stats`. Fold it in so downstream code has a single source of truth.
    final bool? topLevelIsLiked = _readBool(json['is_liked'] ?? json['liked']);
    if(topLevelIsLiked != null) {
      stats ??= ReelStatsModel();
      stats!.isLiked ??= topLevelIsLiked;
    }
  }

  String get resolvedTitle {
    final String cleanedDescription = resolvedDescription;
    if(cleanedDescription.isNotEmpty) {
      return cleanedDescription;
    }
    if(storeName?.trim().isNotEmpty == true) {
      return storeName!.trim();
    }
    return 'Trending Bite';
  }

  String get resolvedSubtitle => storeName?.trim().isNotEmpty == true ? storeName!.trim() : 'Store';

  String get resolvedDescription => description?.trim().isNotEmpty == true ? description!.trim() : '';

  String get resolvedLikeCountText => _compactCount(stats?.totalLikes ?? 0);

  String get resolvedViewCountText => _compactCount(stats?.totalViews ?? 0);

  String get resolvedLogoUrl => _resolveUrl(storeLogoFullUrl);

  String get resolvedThumbnailUrl => _resolveUrl(thumbnailFullUrl);

  String get resolvedVideoUrl => _resolveUrl(videoFullUrl);

  ReelModel mergeWith(ReelModel? other) {
    if(other == null) {
      return this;
    }
    return ReelModel(
      reelId: other.reelId ?? reelId,
      description: other.description ?? description,
      thumbnailFullUrl: other.thumbnailFullUrl ?? thumbnailFullUrl,
      videoFullUrl: other.videoFullUrl ?? videoFullUrl,
      storeId: other.storeId ?? storeId,
      storeName: other.storeName ?? storeName,
      storeLogoFullUrl: other.storeLogoFullUrl ?? storeLogoFullUrl,
      verifiedSeller: other.verifiedSeller ?? verifiedSeller,
      stats: other.stats ?? stats,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'reel_id': reelId,
      'description': description,
      'thumbnail_full_url': thumbnailFullUrl,
      'video_full_url': videoFullUrl,
      'store_id': storeId,
      'store_name': storeName,
      'store_logo_full_url': storeLogoFullUrl,
      'verified_seller': verifiedSeller,
      'stats': stats?.toJson(),
    };
  }

  static String compactCount(int value) => _compactCount(value);

  static String _compactCount(int value) {
    if(value >= 1000000) {
      final double compactValue = value / 1000000;
      return '${_trimTrailingZero(compactValue)}M';
    }
    if(value >= 1000) {
      final double compactValue = value / 1000;
      return '${_trimTrailingZero(compactValue)}K';
    }
    return value.toString();
  }

  static String _trimTrailingZero(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  static String _resolveUrl(String? value) {
    final String sanitized = value?.trim() ?? '';
    if(sanitized.isEmpty) {
      return '';
    }
    if(sanitized.startsWith('http://') || sanitized.startsWith('https://')) {
      return sanitized;
    }
    if(sanitized.startsWith('/')) {
      return '${AppConstants.baseUrl}$sanitized';
    }
    return '${AppConstants.baseUrl}/$sanitized';
  }

  static String? _readString(dynamic value) {
    if(value == null) {
      return null;
    }
    final String parsedValue = value.toString().trim();
    if(parsedValue.isEmpty || parsedValue.toLowerCase() == 'null') {
      return null;
    }
    return parsedValue;
  }

  static bool? readBoolPublic(dynamic value) => _readBool(value);
  static int? readIntPublic(dynamic value) => _readInt(value);

  static bool? _readBool(dynamic value) {
    if(value == null) {
      return null;
    }
    if(value is bool) {
      return value;
    }
    if(value is num) {
      return value != 0;
    }
    if(value is String) {
      final String lower = value.trim().toLowerCase();
      if(lower == 'true' || lower == '1' || lower == 'yes') {
        return true;
      }
      if(lower == 'false' || lower == '0' || lower == 'no') {
        return false;
      }
    }
    return null;
  }

  static int? _readInt(dynamic value) {
    if(value is int) {
      return value;
    }
    if(value is String && value.trim().isNotEmpty) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}

class ReelStatsModel {
  int? totalViews;
  int? totalLikes;
  int? totalStoreVisits;
  bool? isLiked;

  ReelStatsModel({
    this.totalViews,
    this.totalLikes,
    this.totalStoreVisits,
    this.isLiked,
  });

  ReelStatsModel.fromJson(Map<String, dynamic> json) {
    totalViews = ReelModel._readInt(json['total_views']);
    totalLikes = ReelModel._readInt(json['total_likes']);
    totalStoreVisits = ReelModel._readInt(json['total_store_visits']);
    isLiked = ReelModel._readBool(json['is_liked'] ?? json['liked']);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'total_views': totalViews,
      'total_likes': totalLikes,
      'total_store_visits': totalStoreVisits,
      'is_liked': isLiked,
    };
  }
}

class ReelListModel {
  int? totalSize;
  String? limit;
  int? offset;
  List<ReelModel>? reels;

  ReelListModel({this.totalSize, this.limit, this.offset, this.reels});

  ReelListModel.fromJson(Map<String, dynamic> json) {
    totalSize = ReelModel._readInt(json['total_size']);
    limit = json['limit']?.toString();
    offset = ReelModel._readInt(json['offset']);

    final dynamic rawList = json['reels'] ?? json['data'] ?? json['content'] ?? json['items'];
    if(rawList is List) {
      reels = rawList.map<ReelModel>((dynamic data) {
        if(data is Map<String, dynamic>) {
          return ReelModel.fromJson(data);
        }
        return ReelModel.fromJson(Map<String, dynamic>.from(data as Map));
      }).where((ReelModel reel) => reel.resolvedThumbnailUrl.isNotEmpty).toList();
    } else {
      reels = <ReelModel>[];
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'total_size': totalSize,
      'limit': limit,
      'offset': offset,
      'reels': reels?.map((ReelModel reel) => reel.toJson()).toList(),
    };
  }
}
