const double kBlurThreshold = 0.35;
const double kDuplicateSimilarityThreshold = 0.92;
const double kScreenshotConfidenceThreshold = 0.75;
const int kMaxRecommendations = 20;
const double kMinRecommendationConfidence = 0.65;
const int kAiBatchSize = 20;

// Recommendation confidence weights by type
const double kBlurConfidenceWeight = 0.85;
const double kDuplicateConfidenceWeight = 1.00;
const double kScreenshotConfidenceWeight = 0.90;
const double kClusterConfidenceWeight = 0.75;

// Stats-based confidence boost
const double kHighDeletionRateThreshold = 0.70;
const double kBlurWeightBoost = 0.10;

// Performance limits
const int kMaxPairwiseComparisonBatch = 500;
const int kMaxAiCacheSize = 5000;
const int kMaxPhotosForRecommendation = 5000;
