import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/shared/theme/app_colors.dart';
import 'package:background_remover/shared/theme/app_spacing.dart';
import 'package:background_remover/shared/widgets/empty_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyChart extends StatelessWidget {
  const WeeklyChart(
      {super.key, required this.data, this.title = 'Weekly Progress'});

  final List<WeeklyStat> data;
  final String title;

  List<WeeklyStat> get _displayData {
    final sorted = List<WeeklyStat>.from(data)
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
    return sorted.length > 8 ? sorted.sublist(sorted.length - 8) : sorted;
  }

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
        height: 200,
        child: display.isEmpty
            ? const EmptyState(
                icon: Icons.show_chart,
                title: 'No data yet — start cleaning!')
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSpacingS),
                child: LineChart(LineChartData(
                  lineBarsData: [_buildLine(display)],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= display.length) return const Text('');
                          final d = display[i].weekStart.split('-');
                          return Text('${d[2]} ${_abbr(d[1])}',
                              style: const TextStyle(fontSize: 9));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}MB',
                            style: const TextStyle(fontSize: 9)),
                      ),
                    ),
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

  LineChartBarData _buildLine(List<WeeklyStat> display) => LineChartBarData(
        spots: List.generate(display.length,
            (i) => FlSpot(i.toDouble(), display[i].storageSaved / 1048576)),
        color: kColorChartPrimary,
        barWidth: 2.5,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: kColorChartSecondary.withValues(alpha: 0.3),
        ),
      );

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  String _abbr(String m) => _months[int.tryParse(m) ?? 0];
}
