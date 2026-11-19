String _two(int n) => n.toString().padLeft(2, '0');

/// `19/11/2026`
String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// `09:05`
String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
