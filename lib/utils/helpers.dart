class DateFormatter {
  /// Format a DateTime to "D Mon YYYY" in the device's local timezone.
  static String formatDate(DateTime date) {
    final local = date.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  /// Format a DateTime to "HH:mm" in the device's local timezone.
  static String formatTime(DateTime date) {
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  /// Format a DateTime to "D Mon YYYY, HH:mm" in the device's local timezone.
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)}, ${formatTime(date)}';
  }

  static String formatDateFromString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return formatDate(date);
    } catch (_) {
      return dateString; // Return original string if parsing fails
    }
  }
}

class ExamTypeHelper {
  static String getExamType(String examName) {
    String examType = 'Ujian';
    if (examName.toUpperCase().contains('UTS')) {
      examType = 'UTS';
    } else if (examName.toUpperCase().contains('UAS')) {
      examType = 'UAS';
    } else if (examName.toUpperCase().contains('ULANGAN')) {
      examType = 'Ulangan';
    }
    return examType;
  }
}
