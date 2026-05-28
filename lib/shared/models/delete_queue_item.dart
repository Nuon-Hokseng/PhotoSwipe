import 'photo_item.dart';

class DeleteQueueItem {
  final PhotoItem photo;
  final int queuedAt; // when the user swiped left (milliseconds)

  const DeleteQueueItem({required this.photo, required this.queuedAt});

  factory DeleteQueueItem.fromJson(Map<String, dynamic> json) =>
      DeleteQueueItem(
        photo: PhotoItem.fromJson(json['photo'] as Map<String, dynamic>),
        queuedAt: json['queuedAt'] as int,
      );

  Map<String, dynamic> toJson() => {
        'photo': photo.toJson(),
        'queuedAt': queuedAt,
      };
}
