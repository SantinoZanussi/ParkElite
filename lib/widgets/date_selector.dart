import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  final DateTime date;
  final int selectedDay;
  final Function(int) onDaySelected;

  const DateSelector({
    super.key,
    required this.date,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: daysInMonth,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = index + 1;
          final dateTime = DateTime(date.year, date.month, day);
          final label = getShortDayLabel(dateTime.weekday);

          final isSelected = day == selectedDay;

          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF1D2130) : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(day.toString().padLeft(2, '0'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  if (isSelected)
                    const Icon(Icons.circle, size: 6, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String getShortDayLabel(int weekday) {
    const labels = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];
    return labels[(weekday - 1) % 7];
  }
}
