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
    final today = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);

    // Filtrar días anteriores al día actual
    final validDays = List.generate(daysInMonth, (index) => index + 1)
        .where((day) => DateTime(date.year, date.month, day).isAfter(today.subtract(const Duration(days: 1))))
        .toList();

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: validDays.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = validDays[index];
          final dateTime = DateTime(date.year, date.month, day);
          final label = getShortDayLabel(dateTime.weekday);

          final isSelected = day == selectedDay;

          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4A90E2) : Color(0xff808387),
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
