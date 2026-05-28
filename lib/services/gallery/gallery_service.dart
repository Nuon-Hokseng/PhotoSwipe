import 'package:photo_manager/photo_manager.dart';
import '../../shared/models/photo_item.dart';

class GalleryService {
  /// Returns all photos sorted newest-first, or null on permission denial / empty library.
  Future<List<PhotoItem>?> getPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return null;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true, // "All Photos" album only — avoids duplicates across albums
    );
    if (albums.isEmpty) return null;

    final allAlbum = albums.first;
    final allPhotos = <PhotoItem>[];
    int page = 0;
    const pageSize = 200;

    while (true) {
      final assets = await allAlbum.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      if (assets.isEmpty) break;

      for (final asset in assets) {
        final file = await asset.file;
        final sizeInBytes = await file?.length() ?? 0;
        allPhotos.add(PhotoItem(
          id: asset.id,
          uri: file?.path ?? '',
          size: sizeInBytes,
          createdAt: asset.createDateTime.millisecondsSinceEpoch,
          width: asset.width,
          height: asset.height,
          mimeType: asset.mimeType ?? 'image/jpeg',
        ));
      }

      if (assets.length < pageSize) break;
      page++;
    }

    if (allPhotos.isEmpty) return null;
    return allPhotos;
  }

  /// Fetch a single photo by its asset ID (used by QueueService on demand).
  Future<PhotoItem?> getPhotoById(String id) async {
    final asset = await AssetEntity.fromId(id);
    if (asset == null) return null;
    final file = await asset.file;
    final sizeInBytes = await file?.length() ?? 0;
    return PhotoItem(
      id: asset.id,
      uri: file?.path ?? '',
      size: sizeInBytes,
      createdAt: asset.createDateTime.millisecondsSinceEpoch,
      width: asset.width,
      height: asset.height,
      mimeType: asset.mimeType ?? 'image/jpeg',
    );
  }
}
