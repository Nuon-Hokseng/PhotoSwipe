import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/shared/theme/app_colors.dart';
import 'package:background_remover/shared/theme/app_spacing.dart';
import 'package:background_remover/shared/widgets/empty_state.dart';
import 'package:background_remover/utils/image_analysis/format_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DailyChart extends StatelessWidget {
  const DailyChart(
      {super.key, required this.data, this.title = 'This Week'});

  final List<DailyStat> data;
  final String title;

  List<DailyStat> get _displayData {
    final sorted = List<DailyStat>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
  }

  bool get _isEmpty => _displayData.every((d) => d.deleted == 0);

  @override
  Widget build(BuildContext context) {
    final display = _displayData;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpacingM),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      const SizedBox(height: kSpacingS),
      SizedBox(
        height: 180,
        child: _isEmpty
            ? const EmptyState(
                icon: Icons.bar_chart, title: 'No cleanups this week')
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSpacingS),
                child: BarChart(BarChartData(
                  barGroups: _buildBarGroups(display),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                          display.isNotEmpty && v.toInt() < display.length
                              ? getDayLabel(display[v.toInt()].date)
                              : '',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                )),
              ),
      ),
    ]);
  }

  List<BarChartGroupData> _buildBarGroups(List<DailyStat> display) =>
      List.generate(display.length, (i) {
        final v = display[i].deleted.toDouble();
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: v,
            color: kColorChartPrimary,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            rodStackItems: [],
          ),
        ]);
      });
}
