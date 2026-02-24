import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import 'dart:math';

class FinanceChart extends StatelessWidget {
  final List<TransactionItem> transactions;
  final TransactionType type;

  const FinanceChart({
    super.key,
    required this.transactions,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    // Filter by type
    final filtered = transactions.where((t) => t.type == type).toList();
    
    // Sort chronologically
    filtered.sort((a, b) => a.date.compareTo(b.date));

    // Aggregate by day, simplified for demonstration
    final Map<int, double> dailyAggregates = {};
    for (var tx in filtered) {
      final dayCode = tx.date.difference(DateTime.now()).inDays; // Days relative to now
      dailyAggregates[dayCode] = (dailyAggregates[dayCode] ?? 0) + tx.amount;
    }

    if (dailyAggregates.isEmpty) {
      return Center(
        child: Text(
          'No data yet',
          style: TextStyle(color: AppTheme.systemGray.withOpacity(0.5)),
        ),
      );
    }

    // Prepare FlSpot list keeping chronological order
    final sortedDays = dailyAggregates.keys.toList()..sort();
    List<FlSpot> spots = [];
    double cumulative = 0;
    
    for (int day in sortedDays) {
      // Assuming line charts show cumulative values over time for "Growth"
      cumulative += dailyAggregates[day]!;
      spots.add(FlSpot(day.toDouble(), cumulative));
    }

    // Provide a nice default range if there's only 1 point
    if (spots.length == 1) {
      spots.insert(0, FlSpot(spots.first.x - 1, spots.first.y * 0.9));
    }

    final minY = spots.map((s) => s.y).reduce(min) * 0.9;
    final maxY = spots.map((s) => s.y).reduce(max) * 1.1;
    final minX = spots.first.x;
    final maxX = spots.last.x;

    Color lineColor = type == TransactionType.expense ? CupertinoColors.systemRed : AppTheme.growthGreen;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false), // NO GRID LINES
        titlesData: const FlTitlesData(show: false), // Clean visual space
        borderData: FlBorderData(show: false),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.1), // Subtle gradient fill
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}
