enum AppError {
  // Analytics
  sessionNotFound,
  statsUnavailable,
  sessionPersistFailed,

  // AI
  imageLoadFailed,
  blurAnalysisFailed,
  duplicateAnalysisFailed,
  screenshotAnalysisFailed,
  recommendationFailed,

  // Supabase
  networkUnavailable,
  queryFailed,
  insertFailed,

  // General
  unknown;

  String get message => switch (this) {
        AppError.sessionNotFound => 'Session not found.',
        AppError.statsUnavailable => 'Analytics stats are currently unavailable.',
        AppError.sessionPersistFailed => 'Failed to save session data.',
        AppError.imageLoadFailed => 'Could not load image for analysis.',
        AppError.blurAnalysisFailed => 'Blur detection failed for this image.',
        AppError.duplicateAnalysisFailed => 'Duplicate detection could not complete.',
        AppError.screenshotAnalysisFailed => 'Screenshot detection failed.',
        AppError.recommendationFailed => 'Failed to generate recommendations.',
        AppError.networkUnavailable => 'No network connection. Check your internet.',
        AppError.queryFailed => 'Database query failed. Please try again.',
        AppError.insertFailed => 'Failed to save data to the database.',
        AppError.unknown => 'An unexpected error occurred.',
      };
}
