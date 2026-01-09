class DateFormatter {
  static String formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String formatDateFromString(String dateString) {
    final date = DateTime.parse(dateString);
    return formatDate(date);
  }
}

class ExamTypeHelper {
  static String getExamType(String namaUjian) {
    String examType = 'Ujian';
    if (namaUjian.toUpperCase().contains('UTS')) {
      examType = 'UTS';
    } else if (namaUjian.toUpperCase().contains('UAS')) {
      examType = 'UAS';
    } else if (namaUjian.toUpperCase().contains('ULANGAN')) {
      examType = 'Ulangan';
    }
    return examType;
  }
}
