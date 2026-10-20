import 'package:world_holidays/world_holidays.dart';

class HolidayService {
  static final HolidayService instance = HolidayService._();
  HolidayService._();

  final WorldHolidays _worldHolidays = WorldHolidays();
  final Map<int, List<Holiday>> _cacheByYear = {};

  Future<List<Holiday>> loadHolidaysForYear(int year, {String country = 'US'}) async {
    if (_cacheByYear.containsKey(year)) {
      return _cacheByYear[year]!;
    }

    try {
      final list = await _worldHolidays.getHolidays(country, year: year);
      _cacheByYear[year] = list;
      return list;
    } catch (_) {
      // In case of any network or platform error, provide empty list or fallback
      _cacheByYear[year] = [];
      return [];
    }
  }

  Holiday? findCachedHoliday(DateTime date) {
    final list = _cacheByYear[date.year];
    if (list == null || list.isEmpty) return null;

    for (final h in list) {
      if (h.date.year == date.year &&
          h.date.month == date.month &&
          h.date.day == date.day) {
        return h;
      }
    }
    return null;
  }
}
