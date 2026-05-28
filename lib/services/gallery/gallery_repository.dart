import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/gallery_constants.dart';
import '../../shared/types/photo.dart';
import '../../shared/types/result.dart';
import '../../utils/errors.dart';

class GalleryPhotoData {
  const GalleryPhotoData({
    required this.id,
    required this.uri,
    required this.title,
    required this.sizeBytes,
    required this.createdAt,
    required this.thumbnailBytes,
  });

  final String id;
  final String uri;
  final String title;
  final int sizeBytes;
  final DateTime createdAt;
  final Uint8List? thumbnailBytes;
}

class GalleryLoadData {
  const GalleryLoadData({
    required this.totalPhotos,
    required this.totalBytes,
    required this.photos,
    required this.aiPhotos,
  });

  final int totalPhotos;
  final int totalBytes;
  final List<GalleryPhotoData> photos;
  final List<PhotoItem> aiPhotos;
}

class GalleryProgressData {
  const GalleryProgressData({
    required this.photos,
    required this.loadedCount,
    required this.totalCount,
    required this.totalBytes,
  });

  final List<GalleryPhotoData> photos;
  final int loadedCount;
  final int totalCount;
  final int totalBytes;
}

class GalleryRepository {
  Stream<GalleryProgressData> streamGallery() async* {
    if (kIsWeb) {
      return;
    }

    final permission = await PhotoManager.requestPermissionExtend();
    final hasAccess = permission.isAuth || permission.isLimited;
    if (!hasAccess) {
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) {
      return;
    }

    final allAlbum = albums.first;
    final totalPhotos = await allAlbum.assetCountAsync;
    if (totalPhotos == 0) {
      return;
    }

    final photos = <GalleryPhotoData>[];
    var totalBytes = 0;
    var fetched = 0;
    var page = 0;

    while (fetched < totalPhotos && photos.length < kGalleryMaxAssets) {
      final pageAssets = await allAlbum.getAssetListPaged(
        page: page,
        size: kGalleryPageSize,
      );

      if (pageAssets.isEmpty) {
        break;
      }

      // Shuffle each page before processing using DateTime seed.
      final shuffled = List<AssetEntity>.from(pageAssets)
        ..shuffle(Random(DateTime.now().millisecondsSinceEpoch));

      for (final asset in shuffled) {
        final File? file = await asset.originFile ?? await asset.file;
        final sizeBytes = await file?.length() ?? 0;
        final uri = file?.path ?? '';
        totalBytes += sizeBytes;

        // Skip corrupted or missing files.
        if (file == null || (sizeBytes == 0 && uri.isEmpty)) {
          fetched += 1;
          continue;
        }

        Uint8List? thumbnailBytes;
        try {
          thumbnailBytes = await asset.thumbnailDataWithSize(
            const ThumbnailSize(kGalleryThumbnailSize, kGalleryThumbnailSize),
          );
        } catch (_) {
          thumbnailBytes = null;
        }

        if (photos.length < kGalleryMaxAssets) {
          photos.add(
            GalleryPhotoData(
              id: asset.id,
              uri: uri,
              title: asset.title ?? 'Photo',
              sizeBytes: sizeBytes,
              createdAt: asset.createDateTime,
              thumbnailBytes: thumbnailBytes,
            ),
          );

          yield GalleryProgressData(
            photos: List.unmodifiable(photos),
            loadedCount: photos.length,
            totalCount: totalPhotos,
            totalBytes: totalBytes,
          );
        }

        fetched += 1;
      }

      page += 1;
      if (pageAssets.length < kGalleryPageSize) {
        break;
      }
    }
  }

  Future<Result<GalleryLoadData, AppError>> loadGallery() async {
    if (kIsWeb) {
      return Result.failure(const AppError(AppErrorType.permissionDenied));
    }

    final permission = await PhotoManager.requestPermissionExtend();
    final hasAccess = permission.isAuth || permission.isLimited;
    if (!hasAccess) {
      return Result.failure(const AppError(AppErrorType.permissionDenied));
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) {
      return Result.failure(const AppError(AppErrorType.galleryEmpty));
    }

    final allAlbum = albums.first;
    final totalPhotos = await allAlbum.assetCountAsync;
    if (totalPhotos == 0) {
      return Result.failure(const AppError(AppErrorType.galleryEmpty));
    }

    final photos = <GalleryPhotoData>[];
    final aiPhotos = <PhotoItem>[];
    var totalBytes = 0;
    var fetched = 0;
    var page = 0;

    while (fetched < totalPhotos) {
      final pageAssets = await allAlbum.getAssetListPaged(
        page: page,
        size: kGalleryPageSize,
      );

      if (pageAssets.isEmpty) {
        break;
      }

      for (final asset in pageAssets) {
        final File? file = await asset.originFile ?? await asset.file;
        final sizeBytes = await file?.length() ?? 0;
        final uri = file?.path ?? '';
        totalBytes += sizeBytes;

        // Skip corrupted or missing files.
        if (file == null || (sizeBytes == 0 && uri.isEmpty)) {
          fetched += 1;
          continue;
        }

        Uint8List? thumbnailBytes;
        try {
          thumbnailBytes = await asset.thumbnailDataWithSize(
            const ThumbnailSize(kGalleryThumbnailSize, kGalleryThumbnailSize),
          );
        } catch (_) {
          thumbnailBytes = null;
        }

        if (uri.isNotEmpty) {
          aiPhotos.add(
            PhotoItem(
              id: asset.id,
              uri: uri,
              size: sizeBytes,
              createdAt: asset.createDateTime.millisecondsSinceEpoch,
            ),
          );
        }

        if (photos.length < kGalleryMaxAssets) {
          photos.add(
            GalleryPhotoData(
              id: asset.id,
              uri: uri,
              title: asset.title ?? 'Photo',
              sizeBytes: sizeBytes,
              createdAt: asset.createDateTime,
              thumbnailBytes: thumbnailBytes,
            ),
          );
        }

        fetched += 1;
      }

      page += 1;
      if (pageAssets.length < kGalleryPageSize) {
        break;
      }
    }

    return Result.success(
      GalleryLoadData(
        totalPhotos: totalPhotos,
        totalBytes: totalBytes,
        photos: photos,
        aiPhotos: aiPhotos,
      ),
    );
  }

  Future<Result<void, AppError>> deletePhoto(String assetId) async {
    try {
      await PhotoManager.editor.deleteWithIds([assetId]);
      return Result.success(null);
    } catch (e) {
      return Result.failure(const AppError(AppErrorType.deleteFailed));
    }
  }

  Future<Result<List<String>, AppError>> deletePhotos(
    List<String> assetIds,
  ) async {
    if (assetIds.isEmpty) return Result.success([]);
    try {
      await PhotoManager.editor.deleteWithIds(assetIds);
      return Result.success(assetIds);
    } catch (e) {
      return Result.failure(const AppError(AppErrorType.deleteFailed));
    }
  }
}
