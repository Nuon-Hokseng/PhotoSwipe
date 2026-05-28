import 'package:background_remover/shared/types/photo.dart';

class BlurResult {
  const BlurResult({
    required this.photoId,
    required this.blurScore,
    required this.isBlurry,
  });

  factory BlurResult.fromJson(Map<String, Object?> json) => BlurResult(
        photoId: json['photo_id'] as String,
        blurScore: (json['blur_score'] as num).toDouble(),
        isBlurry: json['is_blurry'] as bool,
      );

  final String photoId;
  final double blurScore;
  final bool isBlurry;

  Map<String, Object?> toJson() => {
        'photo_id': photoId,
        'blur_score': blurScore,
        'is_blurry': isBlurry,
      };
}

class ScreenshotSignals {
  const ScreenshotSignals({
    required this.matchesDeviceRatio,
    required this.matchesScreenResolution,
    required this.hasHighDPI,
  });

  final bool matchesDeviceRatio;
  final bool matchesScreenResolution;
  final bool hasHighDPI;
}

class ScreenshotResult {
  const ScreenshotResult({
    required this.photoId,
    required this.confidence,
    required this.isScreenshot,
  });

  final String photoId;
  final double confidence;
  final bool isScreenshot;
}

class DuplicateGroup {
  const DuplicateGroup({
    required this.groupId,
    required this.photos,
    required this.similarity,
    required this.recommendKeep,
  });

  factory DuplicateGroup.fromJson(Map<String, Object?> json) => DuplicateGroup(
        groupId: json['group_id'] as String,
        photos: (json['photos'] as List<Object?>)
            .map((e) => PhotoItem.fromJson(e as Map<String, Object?>))
            .toList(),
        similarity: (json['similarity'] as num).toDouble(),
        recommendKeep: json['recommend_keep'] as String,
      );

  final String groupId;
  final List<PhotoItem> photos;
  final double similarity;
  final String recommendKeep;

  Map<String, Object?> toJson() => {
        'group_id': groupId,
        'photos': photos.map((p) => p.toJson()).toList(),
        'similarity': similarity,
        'recommend_keep': recommendKeep,
      };
}

enum RecommendationType { blur, duplicate, screenshot, cluster }

enum RecommendationAction { delete, review }

class Recommendation {
  const Recommendation({
    required this.id,
    required this.type,
    required this.photoIds,
    required this.reason,
    required this.confidence,
    required this.action,
  });

  factory Recommendation.fromJson(Map<String, Object?> json) => Recommendation(
        id: json['id'] as String,
        type: RecommendationType.values.byName(json['type'] as String),
        photoIds:
            (json['photo_ids'] as List<Object?>).cast<String>(),
        reason: json['reason'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        action: RecommendationAction.values.byName(json['action'] as String),
      );

  final String id;
  final RecommendationType type;
  final List<String> photoIds;
  final String reason;
  final double confidence;
  final RecommendationAction action;

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'photo_ids': photoIds,
        'reason': reason,
        'confidence': confidence,
        'action': action.name,
      };
}
