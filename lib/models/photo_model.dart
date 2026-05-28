class PhotoModel {
  const PhotoModel({
    required this.id,
    required this.imageUrl,
    required this.filename,
    required this.fileSize,
    required this.fileSizeBytes,
    required this.date,
  });

  final String id;
  final String imageUrl;
  final String filename;
  final String fileSize;
  final int fileSizeBytes;
  final String date;

  // Replace this mock list with real gallery data once photo access is added.
  static const List<PhotoModel> mockPhotos = [
    PhotoModel(
      id: '1',
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
      filename: 'holiday_lake_view.jpg',
      fileSize: '4.8 MB',
      fileSizeBytes: 5046272,
      date: '2026-05-18',
    ),
    PhotoModel(
      id: '2',
      imageUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=1200&q=80',
      filename: 'portrait_studio_01.jpg',
      fileSize: '6.1 MB',
      fileSizeBytes: 6396313,
      date: '2026-05-17',
    ),
    PhotoModel(
      id: '3',
      imageUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=1200&q=80',
      filename: 'cafe_story_02.jpg',
      fileSize: '5.2 MB',
      fileSizeBytes: 5452595,
      date: '2026-05-17',
    ),
    PhotoModel(
      id: '4',
      imageUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=1200&q=80',
      filename: 'sunset_profile.png',
      fileSize: '3.9 MB',
      fileSizeBytes: 4089446,
      date: '2026-05-16',
    ),
    PhotoModel(
      id: '5',
      imageUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=1200&q=80',
      filename: 'night_walk_edit.jpg',
      fileSize: '7.4 MB',
      fileSizeBytes: 7759462,
      date: '2026-05-16',
    ),
    PhotoModel(
      id: '6',
      imageUrl:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=1200&q=80',
      filename: 'city_layers.jpeg',
      fileSize: '8.2 MB',
      fileSizeBytes: 8598323,
      date: '2026-05-15',
    ),
    PhotoModel(
      id: '7',
      imageUrl:
          'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?auto=format&fit=crop&w=1200&q=80',
      filename: 'vintage_flash.jpg',
      fileSize: '4.3 MB',
      fileSizeBytes: 4512154,
      date: '2026-05-15',
    ),
    PhotoModel(
      id: '8',
      imageUrl:
          'https://images.unsplash.com/photo-1524503033411-f9f932b6a8f1?auto=format&fit=crop&w=1200&q=80',
      filename: 'clean_skyline.png',
      fileSize: '5.7 MB',
      fileSizeBytes: 5976883,
      date: '2026-05-14',
    ),
    PhotoModel(
      id: '9',
      imageUrl:
          'https://images.unsplash.com/photo-1517841905240-2e5b2e5e5c1e?auto=format&fit=crop&w=1200&q=80',
      filename: 'soft_portrait_09.jpg',
      fileSize: '6.8 MB',
      fileSizeBytes: 7124828,
      date: '2026-05-13',
    ),
    PhotoModel(
      id: '10',
      imageUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=1200&q=80',
      filename: 'cleanup_queue_10.jpg',
      fileSize: '4.9 MB',
      fileSizeBytes: 5138022,
      date: '2026-05-12',
    ),
  ];
}
