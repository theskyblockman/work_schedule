import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart';

extension DateOnlyCompare on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month
        && day == other.day;
  }
}


Future<List<(DateTime, DateTime)>> listWorkHours(DateTime startDate, DateTime endDate, String? holidayZone) async {
  List<DateTime> workDays = [];

  Duration workPeriod = endDate.difference(startDate);

  Map<int, List<DateTime>> cachedHolidays = {};

  // Removing all weekends (saturday and sunday in France) and fetching/checking for holidays (if applicable).
  for(int i = 0; i < workPeriod.inDays; i++) {
    DateTime currentDate = startDate.add(Duration(days: i));
    if(holidayZone != null) {
      if(!cachedHolidays.containsKey(currentDate.year)) {
        Uri uriToFetch = Uri.https('calendrier.api.gouv.fr', '/jours-feries/$holidayZone/${currentDate.year.toString()}.json');
        Map<String, dynamic> resp = jsonDecode((await get(uriToFetch)).body);
        cachedHolidays[currentDate.year] = [];

        for(String rawDay in resp.keys) {
          cachedHolidays[currentDate.year]!.add(DateTime.parse(rawDay));
        }
      }
    }


    if(![DateTime.saturday, DateTime.sunday].contains(currentDate.weekday) && !cachedHolidays[currentDate.year]!.any((element) => element.isSameDay(currentDate))) {
      workDays.add(startDate.add(Duration(days: i)));
    }
  }

  List<(DateTime, DateTime)> workPeriods = [];

  for(DateTime workDay in workDays) {
    // Morning
    DateTime morningStart = workDay.copyWith(hour: 8);
    DateTime morningEnd = workDay.copyWith(hour: 12);

    // Afternoon
    DateTime afternoonStart = workDay.copyWith(hour: 13);
    DateTime afternoonEnd = workDay.copyWith(hour: 19);

    if(morningStart.isSameDay(startDate)) {
      morningStart = morningStart.copyWith(hour: max(8, startDate.hour));
    }
    if(afternoonStart.isSameDay(startDate)) {
      afternoonStart = afternoonStart.copyWith(hour: max(13, startDate.hour));
    }

    if(morningEnd.isSameDay(endDate)) {
      morningEnd = morningEnd.copyWith(hour: min(12, endDate.hour));
    }
    if(afternoonEnd.isSameDay(endDate)) {
      afternoonEnd = afternoonEnd.copyWith(hour: min(19, endDate.hour));
    }

    if(morningStart.isBefore(morningEnd)) {
      workPeriods.add((morningStart, morningEnd));
    }
    if(afternoonStart.isBefore(afternoonEnd)) {
      workPeriods.add((afternoonStart, afternoonEnd));
    }
  }

  return workPeriods;
}