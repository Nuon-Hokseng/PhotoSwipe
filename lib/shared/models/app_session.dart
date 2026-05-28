import 'delete_queue_item.dart';
import 'session_stats.dart';

class AppSession {
  final int queueIndex;                       // how far through the queue we are
  final List<String> seenIds;                 // IDs already shown to user
  final List<DeleteQueueItem> pendingDeletes;
  final SessionStats stats;
  final int lastUpdated;

  const AppSession({
    required this.queueIndex,
    required this.seenIds,
    required this.pendingDeletes,
    required this.stats,
    required this.lastUpdated,
  });

  factory AppSession.fromJson(Map<String, dynamic> json) => AppSession(
        queueIndex: json['queueIndex'] as int,
        seenIds: List<String>.from(json['seenIds'] as List),
        pendingDeletes: (json['pendingDeletes'] as List)
            .map((e) => DeleteQueueItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        stats: SessionStats.fromJson(json['stats'] as Map<String, dynamic>),
        lastUpdated: json['lastUpdated'] as int,
      );

  Map<String, dynamic> toJson() => {
        'queueIndex': queueIndex,
        'seenIds': seenIds,
        'pendingDeletes': pendingDeletes.map((e) => e.toJson()).toList(),
        'stats': stats.toJson(),
        'lastUpdated': lastUpdated,
      };
}

// Error types
sealed class AppError {}
class PermissionDenied extends AppError {}
class ImageLoadFailed extends AppError { final String photoId; ImageLoadFailed(this.photoId); }
class StorageFull extends AppError {}
class DeleteFailed extends AppError { final List<String> photoIds; DeleteFailed(this.photoIds); }
class GalleryEmpty extends AppError {}

// Permission states
enum PermissionStatus { granted, denied, notAsked, limited }
