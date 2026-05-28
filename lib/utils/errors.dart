enum PermissionStatus { granted, denied, notAsked, limited }

enum AppErrorType {
  permissionDenied,
  imageLoadFailed,
  storageFull,
  deleteFailed,
  galleryEmpty,
}

class AppError {
  final AppErrorType type;
  final String? message;
  const AppError(this.type, {this.message});
}
