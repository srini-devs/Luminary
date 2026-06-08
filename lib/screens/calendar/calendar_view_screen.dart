import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../models/grief_calendar_event.dart';
import '../../providers/grief_calendar_provider.dart';
import '../../providers/loss_profile_provider.dart';
import '../../screens/harddate/hard_date_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';
import '../../widgets/luminary_button.dart';
import '../../widgets/luminary_text_field.dart';
import '../../widgets/section_header.dart';

const _calvuuid = Uuid();

class CalendarViewScreen extends ConsumerStatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  ConsumerState<CalendarViewScreen> createState() =>
      _CalendarViewScreenState();
}

class _CalendarViewScreenState
    extends ConsumerState<CalendarViewScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _pastExpanded = false;

  Map<DateTime, List<GriefCalendarEvent>> _buildEventMap(
      List<GriefCalendarEvent> events) {
    final map = <DateTime, List<GriefCalendarEvent>>{};
    for (final e in events) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      (map[day] ??= []).add(e);
    }
    return map;
  }

  void _showAddCustomDate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddCustomDateSheet(
        onAdd: (event) {
          ref
              .read(customCalendarEventsProvider.notifier)
              .addCustomEvent(event);
        },
      ),
    );
  }

  void _showPreview(BuildContext context, GriefCalendarEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: HardDateScreen(previewEvent: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(allCalendarEventsProvider);
    final profile = ref.watch(lossProfileProvider);
    final name = profile?.deceasedName ?? 'them';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final futureEvents = events
        .where((e) => !e.date.isBefore(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final pastEvents = events
        .where((e) => e.date.isBefore(today))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final eventMap = _buildEventMap(events);
    final dateFmt = DateFormat('d MMM yyyy');
    final typeFmt = DateFormat('d MMM');

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _CircleBtn(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.pop();
                        },
                        child: const Text('‹',
                            style: TextStyle(
                                fontSize: 22,
                                color: AppColors.textSecondary)),
                      ),
                      Expanded(
                        child: Text('Your Grief Calendar',
                            style: AppTextStyles.screenTitle,
                            textAlign: TextAlign.center),
                      ),
                      Semantics(
                        label: 'Calendar information',
                        button: true,
                        child: _CircleBtn(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text(
                                    'About your grief calendar'),
                                content: Text(
                                  'This calendar marks significant dates in your grief journey — anniversaries, birthdays, and holidays. Tap any date to see details or get support.',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Got it'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Icon(Icons.info_outline,
                              size: 18,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        20, 12, 20, 100),
                    children: [
                      // ── Mini calendar ────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgWhite,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.cardRadius),
                          border: Border.all(
                              color: AppColors.cardBorder,
                              width: 2),
                        ),
                        child: TableCalendar<GriefCalendarEvent>(
                          firstDay: DateTime(
                              now.year - 5, 1, 1),
                          lastDay: DateTime(
                              now.year + 5, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          eventLoader: (day) {
                            final key = DateTime(
                                day.year, day.month, day.day);
                            return eventMap[key] ?? [];
                          },
                          calendarFormat:
                              CalendarFormat.month,
                          startingDayOfWeek:
                              StartingDayOfWeek.monday,
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            leftChevronIcon: const Icon(
                                Icons.chevron_left,
                                color: AppColors.textSecondary,
                                size: 20),
                            rightChevronIcon: const Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                                size: 20),
                            titleTextStyle:
                                AppTextStyles.bodyMedium
                                    .copyWith(
                                        fontWeight:
                                            FontWeight.w700),
                            headerPadding:
                                const EdgeInsets.symmetric(
                                    vertical: 10),
                          ),
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            todayDecoration: const BoxDecoration(
                              color: AppColors.warmAmber,
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: AppColors.textPrimary,
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle:
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700),
                            selectedTextStyle:
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700),
                            defaultTextStyle:
                                AppTextStyles.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 13),
                            weekendTextStyle:
                                AppTextStyles.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 13),
                            markerSize: 6,
                            markerDecoration:
                                const BoxDecoration(
                              color: AppColors.softPurple,
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 3,
                            markersAlignment:
                                Alignment.bottomCenter,
                            cellMargin: const EdgeInsets.all(2),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle:
                                AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11),
                            weekendStyle:
                                AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11),
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder:
                                (context, day, dayEvents) {
                              if (dayEvents.isEmpty) return null;
                              return Positioned(
                                bottom: 2,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: dayEvents
                                      .take(3)
                                      .map((_) => Container(
                                            width: 5,
                                            height: 5,
                                            margin: const EdgeInsets
                                                .symmetric(
                                                horizontal: 1),
                                            decoration:
                                                const BoxDecoration(
                                              color: AppColors
                                                  .softPurple,
                                              shape:
                                                  BoxShape.circle,
                                            ),
                                          ))
                                      .toList(),
                                ),
                              );
                            },
                          ),
                          onDaySelected:
                              (selectedDay, focusedDay) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Coming Up ────────────────────────────────────
                      SectionHeader('COMING UP',
                          padding: const EdgeInsets.fromLTRB(
                              2, 0, 2, 10)),
                      if (futureEvents.isEmpty)
                        _EmptySection(
                            text:
                                'No upcoming dates for $name.')
                      else
                        ...futureEvents.map((event) {
                          final daysUntil = event.date
                              .difference(today)
                              .inDays;
                          return Semantics(
                            label:
                                '${event.label}, ${dateFmt.format(event.date)}, in $daysUntil days',
                            button: true,
                            child: _EventCard(
                              event: event,
                              trailing: Text(
                                'in $daysUntil ${daysUntil == 1 ? 'day' : 'days'}',
                                style: AppTextStyles.caption
                                    .copyWith(
                                  color: AppColors.warmAmber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              dateFmt: typeFmt,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _showPreview(context, event);
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 16),

                      // ── Past Dates (collapsible) ─────────────────────
                      GestureDetector(
                        onTap: () => setState(
                            () => _pastExpanded = !_pastExpanded),
                        child: Row(
                          children: [
                            Text('PAST DATES',
                                style: AppTextStyles
                                    .sectionLabel),
                            const SizedBox(width: 6),
                            Icon(
                              _pastExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_pastExpanded)
                        if (pastEvents.isEmpty)
                          _EmptySection(
                              text: 'No past dates yet.')
                        else
                          ...pastEvents.map((event) => Opacity(
                                opacity: 0.7,
                                child: _EventCard(
                                  event: event,
                                  trailing: null,
                                  dateFmt: typeFmt,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _showPastReflect(context, event);
                                  },
                                ),
                              )),
                    ],
                  ),
                ),
              ],
            ),
            // FAB
            Positioned(
              bottom: 90,
              right: 24,
              child: Semantics(
                label: 'Add custom date',
                button: true,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showAddCustomDate(context);
                  },
                  child: Container(
                    width: AppDimensions.fabSize,
                    height: AppDimensions.fabSize,
                    decoration: BoxDecoration(
                      color: AppColors.warmAmber,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.amberDark,
                          width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.amberDark,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPastReflect(
      BuildContext context, GriefCalendarEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).padding.bottom + 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.label,
                style: AppTextStyles.screenTitle
                    .copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              DateFormat('d MMMM yyyy').format(event.date),
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.purpleTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.softPurple, width: 1.5),
              ),
              child: Text(
                'How were you feeling on this day? A brief reflection can help you track your journey.',
                style: AppTextStyles.bodyMedium
                    .copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            LuminaryButton(
              label: 'Write a reflection',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/home/journal/prompted');
              },
              style: LuminaryButtonStyle.purple,
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final GriefCalendarEvent event;
  final Widget? trailing;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.trailing,
    required this.dateFmt,
    required this.onTap,
  });

  String _typeLabel(CalendarEventType t) => switch (t) {
        CalendarEventType.milestone => 'Milestone',
        CalendarEventType.deathAnniversary => 'Anniversary',
        CalendarEventType.birthdayOfDeceased => 'Birthday',
        CalendarEventType.holiday => 'Holiday',
        CalendarEventType.custom => 'Custom',
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius:
              BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(
              color: AppColors.cardBorder, width: 2),
        ),
        child: Row(
          children: [
            Semantics(
              label: 'Hard date marker',
              excludeSemantics: true,
              child: CandleIcon(size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.label,
                      style: AppTextStyles.bodyMedium
                          .copyWith(
                              fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(dateFmt.format(event.date),
                          style: AppTextStyles.caption),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.bgGray,
                          borderRadius:
                              BorderRadius.circular(100),
                        ),
                        child: Text(
                          _typeLabel(event.eventType),
                          style: AppTextStyles.caption
                              .copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right,
                size: 18,
                color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String text;
  const _EmptySection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text,
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textTertiary)),
    );
  }
}

// ── Add Custom Date Bottom Sheet ─────────────────────────────────────────────

class _AddCustomDateSheet extends StatefulWidget {
  final void Function(GriefCalendarEvent) onAdd;
  const _AddCustomDateSheet({required this.onAdd});

  @override
  State<_AddCustomDateSheet> createState() =>
      _AddCustomDateSheetState();
}

class _AddCustomDateSheetState
    extends State<_AddCustomDateSheet> {
  final _labelCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.warmAmber,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty || _selectedDate == null || _isSaving) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final event = GriefCalendarEvent(
      id: _calvuuid.v4(),
      lossProfileId: 'custom',
      date: _selectedDate!,
      eventType: CalendarEventType.custom,
      label: label,
      isRecurring: false,
      isPast: _selectedDate!.isBefore(today),
    );
    widget.onAdd(event);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _labelCtrl.text.trim().isNotEmpty &&
        _selectedDate != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).padding.bottom + 80 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add custom date',
              style: AppTextStyles.screenTitle
                  .copyWith(fontSize: 18)),
          const SizedBox(height: 20),
          LuminaryTextField(
            label: 'DATE LABEL',
            hint: 'e.g. Their work anniversary…',
            controller: _labelCtrl,
            onChanged: (_) => setState(() {}),
          ),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.bgWhite,
                borderRadius: BorderRadius.circular(
                    AppDimensions.buttonRadius),
                border: Border.all(
                    color: _selectedDate != null
                        ? AppColors.warmAmber
                        : AppColors.divider,
                    width: 2),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null
                        ? DateFormat('d MMMM yyyy')
                            .format(_selectedDate!)
                        : 'Choose a date',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          LuminaryButton(
            label: 'Add to calendar',
            onTap: canSave ? _save : null,
            isLoading: _isSaving,
          ),
        ],
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
          border: Border.all(
              color: AppColors.divider, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
