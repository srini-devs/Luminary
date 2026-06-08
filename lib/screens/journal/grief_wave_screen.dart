import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/dev_index_provider.dart';
import '../../providers/grief_calendar_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';

class GriefWaveScreen extends ConsumerStatefulWidget {
  const GriefWaveScreen({super.key});

  @override
  ConsumerState<GriefWaveScreen> createState() =>
      _GriefWaveScreenState();
}

class _GriefWaveScreenState extends ConsumerState<GriefWaveScreen> {
  int _rangeIndex = 1; // 0=7d, 1=30d, 2=3mo, 3=all

  static const _ranges = ['7 days', '30 days', '3 months', 'All time'];
  static const _rangeDays = [7, 30, 91, 365];

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(checkinProvider);
    final hardDates = ref.watch(griefCalendarProvider);
    // Dev: set range from devState
    final devState = ref.watch(devStateProvider);
    if (devState == '3months' && _rangeIndex != 2) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) { if (mounted) setState(() => _rangeIndex = 2); });
    } else if (devState == 'alltime' && _rangeIndex != 3) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) { if (mounted) setState(() => _rangeIndex = 3); });
    }
    final days = _rangeDays[_rangeIndex];
    final cutoff =
        DateTime.now().subtract(Duration(days: days));

    final filtered = entries
        .where((e) => e.date.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Build chart spots
    final now = DateTime.now();
    final spots = filtered.map((e) {
      final x = e.date.difference(cutoff).inHours.toDouble();
      return FlSpot(x, e.waveIntensity.toDouble());
    }).toList();

    // Hard date vertical lines within range
    final hardDateX = hardDates
        .where((hd) =>
            hd.date.isAfter(cutoff) &&
            hd.date.isBefore(now))
        .map((hd) => hd.date.difference(cutoff).inHours.toDouble())
        .toList();

    final maxX = now.difference(cutoff).inHours.toDouble();

    final dateFmt = DateFormat('MMM d');
    final highestEntry = filtered.isNotEmpty
        ? filtered.reduce((a, b) =>
            a.waveIntensity > b.waveIntensity ? a : b)
        : null;
    final emotionCounts = <String, int>{};
    for (final e in filtered) {
      for (final em in e.emotions) {
        emotionCounts[em.name] =
            (emotionCounts[em.name] ?? 0) + 1;
      }
    }
    String? topEmotion;
    if (emotionCounts.isNotEmpty) {
      topEmotion = emotionCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _CircleBtn(
                    onTap: () => context.pop(),
                    child: const Text('‹',
                        style: TextStyle(
                            fontSize: 22,
                            color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: Text('Your Grief Wave',
                        style: AppTextStyles.screenTitle,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(20, 12, 20, 88),
                children: [
                  // Time range selector
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.divider, width: 1.5),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: List.generate(
                          _ranges.length, (i) {
                        final isActive = i == _rangeIndex;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _rangeIndex = i);
                            },
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 9),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.textPrimary
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                _ranges[i],
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Chart card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.cardRadius),
                      border: Border.all(
                          color: AppColors.cardBorder, width: 2),
                    ),
                    child: spots.length < 2
                        ? _EmptyChart(name: 'you')
                        : SizedBox(
                            height: 140,
                            child: LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: maxX,
                                minY: 0,
                                maxY: 10,
                                clipData: const FlClipData.all(),
                                gridData:
                                    const FlGridData(show: false),
                                borderData:
                                    FlBorderData(show: false),
                                extraLinesData: ExtraLinesData(
                                  verticalLines: hardDateX
                                      .map(
                                        (x) => VerticalLine(
                                          x: x,
                                          color: AppColors
                                              .softPurple
                                              .withAlpha(180),
                                          strokeWidth: 1.5,
                                          dashArray: [4, 3],
                                        ),
                                      )
                                      .toList(),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 20,
                                      interval: 5,
                                      getTitlesWidget: (v, _) =>
                                          Text(
                                        v.toInt().toString(),
                                        style: AppTextStyles.caption
                                            .copyWith(
                                                fontSize: 9,
                                                color: AppColors
                                                    .textTertiary),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 22,
                                      interval: maxX / 4,
                                      getTitlesWidget: (v, meta) {
                                        final date =
                                            cutoff.add(Duration(
                                                hours: v.toInt()));
                                        return Text(
                                          dateFmt.format(date),
                                          style: AppTextStyles
                                              .caption
                                              .copyWith(
                                            fontSize: 9,
                                            color: AppColors
                                                .textTertiary,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles: false)),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    curveSmoothness: 0.4,
                                    color: AppColors.warmAmber,
                                    barWidth: 2.5,
                                    dotData: const FlDotData(
                                        show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppColors.warmAmber
                                              .withAlpha(100),
                                          AppColors.warmAmber
                                              .withAlpha(0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  // Wave insight card
                  if (highestEntry != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.amberTint,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.cardRadius),
                        border: const Border(
                          left: BorderSide(
                              color: AppColors.warmAmber, width: 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WAVE INSIGHT',
                            style: AppTextStyles.sectionLabel
                                .copyWith(
                                    color: AppColors.amberDark),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your wave peaked on ${dateFmt.format(highestEntry.date)}. Your data shows your grief is being tracked and witnessed — that matters.',
                            style: AppTextStyles.bodyLight,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Stats card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.cardRadius),
                        border: Border.all(
                            color: AppColors.cardBorder, width: 2),
                      ),
                      child: Column(
                        children: [
                          _StatRow(
                            label: 'Highest intensity day',
                            value:
                                '${dateFmt.format(highestEntry.date)} · ${highestEntry.waveIntensity}/10',
                            valueColor: AppColors.dustyRose,
                          ),
                          if (topEmotion != null)
                            _StatRow(
                              label: 'Most common emotion',
                              value: topEmotion,
                              valueColor: AppColors.softPurple,
                            ),
                          _StatRow(
                            label: 'Check-ins in range',
                            value: '${filtered.length}',
                            valueColor: AppColors.sageGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Empty state
                  if (spots.length < 2 && filtered.isEmpty) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          const CandleIcon(size: 40),
                          const SizedBox(height: 16),
                          Text(
                            'Your grief wave will take shape here\n— keep checking in.',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatRow(
      {required this.label,
      required this.value,
      required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String name;
  const _EmptyChart({required this.name});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Not enough data yet — check in daily to see your wave.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _CircleBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
