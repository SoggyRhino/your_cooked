import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/grading.dart';

const _daysPerMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
const _daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class ConsistencyChart extends StatefulWidget {
  final Stream<List<Grading>> stream;

  const ConsistencyChart({super.key, required this.stream});

  @override
  State<ConsistencyChart> createState() => _ConsistencyChartState();
}

class _ConsistencyChartState extends State<ConsistencyChart> {
  DateTime _displayDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          final map = <int, List<Grading>>{};
          data
              .where(
                (grading) =>
                    grading.createdAt.month == _displayDate.month &&
                    grading.createdAt.year == _displayDate.year,
              )
              .forEach((grading) {
                if (map.containsKey(grading.createdAt.day)) {
                  map[grading.createdAt.day]!.add(grading);
                } else {
                  map[grading.createdAt.day] = [grading];
                }
              });

          return _buildChart(map);
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  Widget _buildChart(Map<int, List<Grading>> map) {
    final daysGrid = _getDaysGrid().toList();
    final now = DateTime.now();
    return Card(
      elevation: 4,
      color: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                icon: Center(child: const Icon(Icons.arrow_back_ios)),
                onPressed: () {
                  setState(() {
                    _displayDate = _displayDate.subtract(
                      Duration(days: _displayDate.day),
                    );
                  });
                },
              ),
              Center(
                child: Text(
                  DateFormat('MMMM yyyy').format(_displayDate),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              if (now.month == _displayDate.month &&
                  now.year == _displayDate.year)
                const SizedBox(width: 24)
              else
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: Center(child: const Icon(Icons.arrow_forward_ios)),
                  onPressed: () {
                    setState(() {
                      _displayDate = _displayDate.add(
                        Duration(days: _displayDate.day),
                      );
                    });
                  },
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: GridView.builder(
              itemCount: daysGrid.length + 7,
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                // add days of the week
                if (index < 7) {
                  return Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Center(child: Text(_daysOfWeek[index].toString())),
                  );
                }

                // handle padding days (prior month)
                if (daysGrid[index - 7] == -1) {
                  return Container();
                }

                final count = (map[index - 7]?.length ?? 0).clamp(0, 5);
                final baseColor = Theme.of(context).colorScheme.primary;
                final double factor = 1.0 - (count * 0.1).clamp(0.0, 0.5);
                final color = Color.fromRGBO(
                  ((baseColor.r * factor) * 255).round(),
                  ((baseColor.g * factor) * 255).round(),
                  ((baseColor.b * factor) * 255).round(),
                  1,
                );
                return Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: count > 0
                          ? color
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(child: Text(daysGrid[index - 7].toString())),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Iterable<int> _getDaysGrid() sync* {
    int padLeft = _displayDate
        .subtract(Duration(days: _displayDate.day))
        .weekday;
    for (int i = 0; i < padLeft; i++) {
      yield -1;
    }
    for (int i = 0; i < _daysPerMonth[_displayDate.month - 1]; i++) {
      yield i + 1;
    }
  }
}
