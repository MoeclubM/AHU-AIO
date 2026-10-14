import 'package:flutter/material.dart';

class ScheduleWeekSelector extends StatefulWidget {
  final int weekCount;
  final int selectedWeek;
  final int? currentWeek;
  final ValueChanged<int> onSelected;

  const ScheduleWeekSelector({
    super.key,
    required this.weekCount,
    required this.selectedWeek,
    required this.currentWeek,
    required this.onSelected,
  });

  @override
  State<ScheduleWeekSelector> createState() => _ScheduleWeekSelectorState();
}

class _ScheduleWeekSelectorState extends State<ScheduleWeekSelector> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _focusWeekKey = GlobalKey();

  int get _focusWeek => widget.currentWeek ?? widget.selectedWeek;

  @override
  void initState() {
    super.initState();
    _centerFocusWeek();
  }

  @override
  void didUpdateWidget(covariant ScheduleWeekSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentWeek != widget.currentWeek ||
        oldWidget.weekCount != widget.weekCount) {
      _centerFocusWeek();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerFocusWeek() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _focusWeekKey.currentContext;
      if (!mounted || target == null || !_scrollController.hasClients) return;
      final renderObject = target.findRenderObject();
      if (renderObject == null) return;
      _scrollController.position.ensureVisible(
        renderObject,
        alignment: 0.5,
        duration: Duration.zero,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 36,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(widget.weekCount, (index) {
            final week = index + 1;
            final isSelected = week == widget.selectedWeek;
            final isCurrent = week == widget.currentWeek;

            return Padding(
              key: week == _focusWeek ? _focusWeekKey : null,
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: ChoiceChip(
                label: Text('第$week周'),
                selected: isSelected,
                onSelected: (_) => widget.onSelected(week),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.onPrimary : null,
                ),
                selectedColor: theme.colorScheme.primary,
                backgroundColor: isCurrent
                    ? theme.colorScheme.primary.withOpacity(0.12)
                    : null,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
        ),
      ),
    );
  }
}
