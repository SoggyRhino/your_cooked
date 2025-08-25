import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/grading.dart';

enum _ChartRange { day, week, month, sixMonths, year, allTime }

extension _ChartRangeExtension on _ChartRange {
  String get name => switch (this) {
    _ChartRange.day => 'Day',
    _ChartRange.week => 'Week',
    _ChartRange.month => 'Month',
    _ChartRange.sixMonths => '6 Months',
    _ChartRange.year => 'Year',
    _ChartRange.allTime => 'All Time',
  };

  Duration get duration => switch (this) {
    _ChartRange.day => const Duration(days: 1),
    _ChartRange.week => const Duration(days: 7),
    _ChartRange.month => const Duration(days: 30),
    _ChartRange.sixMonths => const Duration(days: 180),
    _ChartRange.year => const Duration(days: 365),
    _ChartRange.allTime => Duration.zero,
  };

  int get intervals => switch (this) {
    _ChartRange.day => 6,
    _ChartRange.week => 6,
    _ChartRange.month => 7,
    _ChartRange.sixMonths => 7,
    _ChartRange.year => 5,
    _ChartRange.allTime => 5,
  };

  String formatDate(DateTime date) => switch (this) {
    _ChartRange.day => DateFormat('h a').format(date),
    _ChartRange.week => DateFormat('MMM d').format(date),
    _ChartRange.month => DateFormat('MMM d').format(date),
    _ChartRange.sixMonths => DateFormat('MMM').format(date),
    _ChartRange.year => DateFormat('MMM').format(date),
    _ChartRange.allTime => DateFormat('MMM yy').format(date),
  };
}

class GradingsChart extends StatefulWidget {
  final Stream<List<Grading>> gradings;
  final double? minY;
  final double? maxY;

  const GradingsChart({
    super.key,
    required this.gradings,
    this.minY,
    this.maxY,
  });

  @override
  State<GradingsChart> createState() => _GradingsChartState();
}

class _GradingsChartState extends State<GradingsChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<bool> _rangeButtonSelected = List.generate(
    _ChartRange.values.length,
    (i) => i == 0,
  );
  _ChartRange _chartRange = _ChartRange.values[0];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Results',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ), // Slightly larger and bolder
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Card(
            elevation: 4,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChart(),
                  const SizedBox(height: 16),
                  _buildRangeSelector(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Center(
      child: SizedBox(
        height: 40,
        child: ToggleButtons(
          isSelected: _rangeButtonSelected,
          onPressed: (index) => setState(() => _changeRange(index)),
          children: [
            for (final range in _ChartRange.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(range.name),
              ),
          ],
        ),
      ),
    );
  }

  void _changeRange(int index) {
    setState(() {
      _rangeButtonSelected = List.generate(
        _ChartRange.values.length,
        (i) => i == index,
      );
      _chartRange = _ChartRange.values[index];
    });
    _animationController.reset();
    _animationController.forward();
  }

  Widget _buildChart() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: StreamBuilder<List<Grading>>(
        stream: widget.gradings,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          final gradings = snapshot.data ?? [];

          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return LineChart(
                _buildLineChartData(gradings),
                curve: Curves.linear,
                duration: const Duration(milliseconds: 300),
              );
            },
          );
        },
      ),
    );
  }

  LineChartData _buildLineChartData(List<Grading> gradings) {
    final now = DateTime.now();
    final DateTime start;
    final DateTime end = now;

    if (_chartRange == _ChartRange.allTime) {
      if (gradings.isEmpty || gradings.length == 1) {
        start = DateTime.now().subtract(const Duration(days: 365));
      } else {
        start = gradings.map((g) => g.createdAt).min;
      }
    } else {
      start = end.subtract(_chartRange.duration);
    }

    final spots = gradings
        .where(
          (grading) =>
              grading.createdAt.isAfter(start) &&
              grading.createdAt.isBefore(end.add(const Duration(hours: 1))),
        )
        .map(
          (grading) => FlSpot(
            grading.createdAt.millisecondsSinceEpoch.toDouble(),
            grading.averageScore,
          ),
        )
        .toList();

    spots.insert(0, FlSpot(start.millisecondsSinceEpoch.toDouble(), 0));
    // probably unnecessary but had issues with parabola when curve true
    spots.sort((a, b) => a.x.compareTo(b.x));

    final theme = Theme.of(context);
    return LineChartData(
      minY: 0,
      maxY: 10,
      minX: start.millisecondsSinceEpoch.toDouble(),
      maxX: end.millisecondsSinceEpoch.toDouble(),
      clipData: const FlClipData.all(),
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
            reservedSize: 40,
            interval: 10,
            getTitlesWidget: (value, meta) {
              return const SizedBox.shrink();
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
            reservedSize: 40,
            interval: 10,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            maxIncluded: false,
            minIncluded: false,
            reservedSize: 40,
            interval:
                end.difference(start).inMilliseconds / _chartRange.intervals,
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  _chartRange.formatDate(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots
              .map(
                (spot) => FlSpot(
                  spot.x,
                  spot.y * _animation.value, // Animate the values
                ),
              )
              .toList(),
          color: theme.colorScheme.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.2),
                theme.colorScheme.primary.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load chart data',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
