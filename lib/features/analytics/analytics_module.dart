import 'package:background_remover/features/analytics/providers/analytics_provider.dart';
import 'package:background_remover/features/analytics/repositories/analytics_repository.dart';
import 'package:background_remover/features/analytics/services/analytics_service.dart';
import 'package:background_remover/features/analytics/services/history_service.dart';
import 'package:background_remover/features/analytics/services/session_service.dart';

/// Wires the full analytics dependency chain. Use this instead of manual instantiation.
class AnalyticsModule {
  AnalyticsModule._();

  static AnalyticsRepository get repository => AnalyticsRepository();

  static SessionService get sessionService => SessionService(repository);

  static HistoryService get historyService => HistoryService(repository);

  static AnalyticsService get analyticsService =>
      AnalyticsService(sessionService, historyService);

  static AnalyticsProvider get provider =>
      AnalyticsProvider(analyticsService, sessionService);
}
