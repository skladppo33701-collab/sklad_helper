import 'package:flutter/material.dart';

/// Schedule Planner Demo Screen — rebuilt to match your reference spec.
///
/// Rules respected:
/// - NO withOpacity(): use .withValues(alpha: ...)
/// - AppBar panel color: #2B2D2C
/// - Scaffold bg: #161616
/// - Date strip: ~90 days horizontally, selected has rounded rect bg + red dot + white text
/// - Progress widget: same shape as reference, thicker bar
/// - Suggested header with star icon and separate like/dislike pills
/// - Task cards: bg #2B2D2C, left icon tile colored, text colors as spec
/// - FAB: white circle with thin white glow + 2-color glow (#253f36, #373b24)
class SchedulePlannerDemoScreen extends StatefulWidget {
  const SchedulePlannerDemoScreen({super.key});

  @override
  State<SchedulePlannerDemoScreen> createState() =>
      _SchedulePlannerDemoScreenState();
}

class _SchedulePlannerDemoScreenState extends State<SchedulePlannerDemoScreen> {
  // Colors from your spec
  static const Color _scaffoldBg = Color(0xFF161616);
  static const Color _appbarBg = Color(0xFF2B2D2C);
  static const Color _textPrimary = Color(0xFFF5F5F3);
  static const Color _textSecondary = Color(0xFF878883);
  static const Color _dowMuted = Color(0xFF949695);

  // Pills background in reference (like/dislike)
  static const Color _pillBg = Color(0xFF2F2F2F);
  static const Color _pillIcon = Color(0xFFACACAC);

  // Selected date indicator
  static const Color _selectedDot = Color(0xFFE0524D);

  // Demo state
  late final List<DateTime> _dates; // ~90 days
  int _selectedIndex = 2; // mimic “23” being selected (roughly)

  @override
  void initState() {
    super.initState();
    final now = DateTime(2025, 9, 23); // reference month context
    final start = now.subtract(const Duration(days: 30));
    _dates = List.generate(90, (i) => start.add(Duration(days: i)));

    // select the exact date if present
    final idx = _dates.indexWhere(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );
    if (idx != -1) _selectedIndex = idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: Column(
        children: [
          _TopPanel(
            appbarBg: _appbarBg,
            textPrimary: _textPrimary,
            textSecondary: _textSecondary,
            dowMuted: _dowMuted,
            selectedDot: _selectedDot,
            dates: _dates,
            selectedIndex: _selectedIndex,
            onSelectIndex: (i) => setState(() => _selectedIndex = i),
            // Right button: reference uses smartwatch, we replace with something useful.
            rightIcon: Icons.qr_code_scanner_rounded,
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
              children: [
                // 2) "Exo Score" section becomes your page-native metric widget,
                // but with identical layout/styling.
                _MetricCard(
                  bg: _appbarBg,
                  textPrimary: _textPrimary,
                  textSecondary: _textSecondary,
                  title: 'Outbound readiness', // you can rename later
                  value: 68,
                ),

                const SizedBox(height: 18),

                // 3) Schedule summary
                Center(
                  child: Text(
                    'Schedule',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _CountersRow(
                  iconColor: _textSecondary,
                  textPrimary: _textPrimary,
                  // Replace "meetings" with warehouse-relevant counter:
                  leftIcon: Icons.calendar_today_outlined,
                  leftText: '1 dispatch', // replace later with real data
                  rightIcon: Icons.local_shipping_outlined,
                  rightText: '3 transfers',
                ),

                const SizedBox(height: 18),

                // 4) Insight chips (outlined pills)
                _InsightPill(
                  borderColor: Colors.white.withValues(alpha: 0.08),
                  textPrimary: _textPrimary,
                  textSecondary: _textSecondary,
                  icon: Icons.bedtime_outlined,
                  iconColor: const Color(0xFFD18B3D), // brown/orange-ish
                  title: 'Morning grogginess',
                  suffix: '15m left',
                ),
                const SizedBox(height: 12),
                _InsightPill(
                  borderColor: Colors.white.withValues(alpha: 0.08),
                  textPrimary: _textPrimary,
                  textSecondary: _textSecondary,
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF59FF92),
                  title: 'Alertness rise',
                  suffix: 'in 45m',
                ),

                const SizedBox(height: 18),

                // 5) Suggested header with star + like/dislike pills
                _SuggestedHeader(
                  textSecondary: _textSecondary,
                  pillBg: _pillBg,
                  pillIcon: _pillIcon,
                ),

                const SizedBox(height: 12),

                // 6) Suggested task cards
                _TaskCard(
                  bg: _appbarBg,
                  textPrimary: _textPrimary,
                  textSecondary: _textSecondary,
                  iconBg: const Color(0xFF1E3A2A),
                  iconFg: const Color(0xFF59FF92),
                  icon: Icons.park_outlined,
                  title: 'Outdoor run',
                  time: '1:30 – 2 PM',
                ),
                const SizedBox(height: 14),
                _TaskCard(
                  bg: _appbarBg,
                  textPrimary: _textPrimary,
                  textSecondary: _textSecondary,
                  iconBg: const Color(0xFF19383B),
                  iconFg: const Color(0xFF4DF0FF),
                  icon: Icons.rocket_launch_outlined,
                  title: 'Apply to YC',
                  time: '2:30 – 3:30 PM',
                ),
                const SizedBox(height: 14),
                _TaskCard(
                  bg: _appbarBg,
                  textPrimary: _textPrimary,
                  textSecondary: _textSecondary,
                  iconBg: const Color(0xFF2A2F1A),
                  iconFg: const Color(0xFFBBD96A),
                  icon: Icons.local_pharmacy_outlined,
                  title: 'Order vitamin D',
                  time: '7 – 7:30 PM',
                ),
              ],
            ),
          ),
        ],
      ),

      // 7) FAB: white circle, thin white glow + 2-color glow
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: const _ReferenceFab(),
    );
  }
}

/// 1) High app bar with rounded bottom corners + scrollable 90-day strip.
class _TopPanel extends StatelessWidget {
  const _TopPanel({
    required this.appbarBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.dowMuted,
    required this.selectedDot,
    required this.dates,
    required this.selectedIndex,
    required this.onSelectIndex,
    required this.rightIcon,
  });

  final Color appbarBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color dowMuted;
  final Color selectedDot;

  final List<DateTime> dates;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;

  final IconData rightIcon;

  static const _radius = Radius.circular(26);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    final selected = dates[selectedIndex];
    final monthText = _monthName(selected.month); // "Sep"
    final yearText = '${selected.year}';

    return Container(
      padding: EdgeInsets.fromLTRB(16, topInset + 14, 16, 16),
      decoration: const BoxDecoration(
        color: _appbarBgConst,
        borderRadius: BorderRadius.only(
          bottomLeft: _radius,
          bottomRight: _radius,
        ),
      ),
      child: Column(
        children: [
          // Row: burger (left), month+year (center), right icon (right)
          Row(
            children: [
              _BurgerTwoLinesButton(
                bg: appbarBg,
                lineColor: textPrimary,
                onTap: () {},
              ),
              const Spacer(),

              // Month white, year as "chip": bg white, text appbar color (#2b2d2c)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthText,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: textPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      yearText,
                      style: TextStyle(
                        color: appbarBg,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),
              _IconTileButton(
                icon: rightIcon,
                bg: appbarBg,
                fg: textPrimary,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Horizontal date strip: ~90 days
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: dates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final d = dates[i];
                final isSelected = i == selectedIndex;
                return _DateChip(
                  date: d,
                  isSelected: isSelected,
                  appbarBg: appbarBg,
                  textPrimary: textPrimary,
                  dowMuted: dowMuted,
                  selectedDot: selectedDot,
                  onTap: () => onSelectIndex(i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const Color _appbarBgConst = Color(0xFF2B2D2C);

  static String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}

class _BurgerTwoLinesButton extends StatelessWidget {
  const _BurgerTwoLinesButton({
    required this.bg,
    required this.lineColor,
    required this.onTap,
  });

  final Color bg;
  final Color lineColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Background same as appbar, but add subtle border to separate.
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(18, 12),
            painter: _TwoLineBurgerPainter(color: lineColor),
          ),
        ),
      ),
    );
  }
}

class _TwoLineBurgerPainter extends CustomPainter {
  _TwoLineBurgerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    // two lines only
    canvas.drawLine(
      Offset(0, size.height * 0.30),
      Offset(size.width, size.height * 0.30),
      p,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.70),
      Offset(size.width, size.height * 0.70),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _TwoLineBurgerPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _IconTileButton extends StatelessWidget {
  const _IconTileButton({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Icon(icon, color: fg, size: 22),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.appbarBg,
    required this.textPrimary,
    required this.dowMuted,
    required this.selectedDot,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final Color appbarBg;
  final Color textPrimary;
  final Color dowMuted;
  final Color selectedDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dow = _dowLetter(date.weekday);
    final dd = '${date.day}';

    final fg = isSelected ? textPrimary : dowMuted;

    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dow,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),

          // Selected gets the rounded-rectangle background + red dot top-left
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? appbarBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: isSelected
                      ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                      : null,
                ),
                child: Text(
                  dd,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: selectedDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _dowLetter(int weekday) {
    // Mon=1..Sun=7
    const map = {1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'};
    return map[weekday] ?? 'M';
  }
}

/// 2) Metric card: same styling as Exo Score block.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.bg,
    required this.textPrimary,
    required this.textSecondary,
    required this.title,
    required this.value,
  });

  final Color bg;
  final Color textPrimary;
  final Color textSecondary;
  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: _ThickProgressBar(value: value / 100.0)),
          const SizedBox(width: 14),
          Icon(
            Icons.directions_run_rounded,
            size: 18,
            color: const Color(0xFFE0524D).withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThickProgressBar extends StatelessWidget {
  const _ThickProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10, // thicker than before (as your spec)
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.white.withValues(alpha: 0.12)),
            ),
            FractionallySizedBox(
              widthFactor: v,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF59FF92),
                      const Color(0xFF4DF0FF).withValues(alpha: 0.7),
                      const Color(0xFFFF5C5C).withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            // small right dots like reference
            Positioned(
              right: 22,
              top: 4,
              child: Container(
                width: 7,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 4,
              child: Container(
                width: 7,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3) Counters row like "1 event 3 meetings"
class _CountersRow extends StatelessWidget {
  const _CountersRow({
    required this.iconColor,
    required this.textPrimary,
    required this.leftIcon,
    required this.leftText,
    required this.rightIcon,
    required this.rightText,
  });

  final Color iconColor;
  final Color textPrimary;

  final IconData leftIcon;
  final String leftText;
  final IconData rightIcon;
  final String rightText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(leftIcon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text(
          leftText,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 18),
        Icon(rightIcon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text(
          rightText,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

/// 4) Outline “chips” with icon + title + time suffix.
class _InsightPill extends StatelessWidget {
  const _InsightPill({
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.suffix,
  });

  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  final IconData icon;
  final Color iconColor;
  final String title;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            suffix,
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// 5) Suggested header + separate like/dislike pills.
class _SuggestedHeader extends StatelessWidget {
  const _SuggestedHeader({
    required this.textSecondary,
    required this.pillBg,
    required this.pillIcon,
  });

  final Color textSecondary;
  final Color pillBg;
  final Color pillIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.auto_awesome_outlined, color: textSecondary, size: 18),
        const SizedBox(width: 10),
        Text(
          'Suggested',
          style: TextStyle(
            color: textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.15,
          ),
        ),
        const Spacer(),
        _IconPill(
          bg: pillBg,
          icon: Icons.thumb_up_alt_outlined,
          iconColor: pillIcon,
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _IconPill(
          bg: pillBg,
          icon: Icons.thumb_down_alt_outlined,
          iconColor: pillIcon,
          onTap: () {},
        ),
      ],
    );
  }
}

class _IconPill extends StatelessWidget {
  const _IconPill({
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final Color bg;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}

/// 6) Task card rows
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.bg,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconBg,
    required this.iconFg,
    required this.icon,
    required this.title,
    required this.time,
  });

  final Color bg;
  final Color textPrimary;
  final Color textSecondary;

  final Color iconBg;
  final Color iconFg;
  final IconData icon;

  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconFg, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            time,
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// 7) Reference FAB: white circle + thin white glow + two-color glow around.
class _ReferenceFab extends StatelessWidget {
  const _ReferenceFab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 10),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            // very thin white glow
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.20),
              blurRadius: 10,
              spreadRadius: 0.5,
            ),
            // 2-color glow as you specified
            const BoxShadow(
              color: Color(0xFF253F36),
              blurRadius: 26,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Color(0xFF373B24),
              blurRadius: 26,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.add, color: Color(0xFF161616), size: 26),
        ),
      ),
    );
  }
}
