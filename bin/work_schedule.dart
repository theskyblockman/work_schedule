import 'dart:io';

import 'package:work_schedule/work_schedule.dart' as work_schedule;

enum HolidayZone {
  alsaceMoselle('Alsace-Moselle', 'alsace-moselle'),
  guadeloupe('Guadeloupe', 'guadeloupe'),
  guyane('Guyane', 'guyane'),
  laReunion('Réunion', 'la-reunion'),
  martinique('Martinique', 'martinique'),
  mayotte('Mayotte', 'mayotte'),
  metropole('Métropole', 'metropole'),
  nouvelleCaledonie('Nouvelle Calédonie', 'nouvelle-caledonie'),
  polynesieFrancaise('Polynésie française', 'polynesie-francaise'),
  saintBarthelemy('Saint-Barthélemy', 'saint-barthelemy'),
  saintMartin('Saint-Martin', 'saint-martin'),
  saintPierreEtMiquelon('Saint-Pierre-et-Miquelon', 'saint-pierre-et-miquelon'),
  wallisEtFutuna('Wallis et Futuna', 'wallis-et-futuna');

  final String name;
  final String apiCode;

  const HolidayZone(this.name, this.apiCode);
}

String formatDate(DateTime dateToFormat) {
  return '${dateToFormat.day.toString().padLeft(2, '0')}/${dateToFormat.month.toString().padLeft(2, '0')}/${dateToFormat.year.toString()} ${dateToFormat.hour.toString().padLeft(2, '0')}:${dateToFormat.minute.toString().padLeft(2, '0')}';
}

void main(List<String> arguments) async {
  stdout.write('Bonjour, veuillez rentrer le timestamp en UTC de la date et de l\'heure de début: ');
  String? startRawTimestamp = stdin.readLineSync();

  if(startRawTimestamp == null || startRawTimestamp.isEmpty) {
    print('La valeur rentrée n\'est pas valide !');
    exit(1);
  }

  int? startInterpretedTimestamp = int.tryParse(startRawTimestamp);

  if(startInterpretedTimestamp == null) {
    print('La valeur rentrée n\'est pas valide !');
    exit(2);
  }

  DateTime startTimestamp = DateTime.fromMillisecondsSinceEpoch(startInterpretedTimestamp * 1000, isUtc: true);

  stdout.write('Veuillez rentrer le timestamp en UTC de la date et de l\'heure de fin: ');
  String? endRawTimestamp = stdin.readLineSync();

  if(endRawTimestamp == null || endRawTimestamp.isEmpty) {
    print('La valeur rentrée n\'est pas valide !');
    exit(3);
  }

  int? endInterpretedTimestamp = int.tryParse(endRawTimestamp);

  if(endInterpretedTimestamp == null) {
    print('La valeur rentrée n\'est pas valide !');
    exit(4);
  }
  DateTime endTimestamp = DateTime.fromMillisecondsSinceEpoch(endInterpretedTimestamp * 1000, isUtc: true);

  if(endTimestamp.isBefore(startTimestamp)) {
    print('Votre temps de début de travail est avant celui de fin!');
    exit(5);
  }

  print('Les heures de travail commencent donc à :');
  print(startTimestamp.toString());
  print('Et finissent à :');
  print(endTimestamp.toString());

  stdout.write('\nEst-ce valide ? [Y/n]: ');
  String? result = stdin.readLineSync();

  stdout.write('Voulez-vous sélectionner une zone de jour fériés? [y/N]: ');

  String? selectHolidayZone = stdin.readLineSync();

  String? selectedZone;

  if(selectHolidayZone?.toLowerCase() == 'y') {
    for(HolidayZone zone in HolidayZone.values) {
      print('[${HolidayZone.values.indexOf(zone) + 1}] ${zone.name}');
    }
    stdout.write('Veuillez choisir une zone [1-${HolidayZone.values.length}]: ');
    String zone = stdin.readLineSync() ?? '7';

    int? zoneID = int.tryParse(zone);

    if(zoneID == null || zoneID < 1 || zoneID > HolidayZone.values.length) {
      print('L\'entrée n\'est pas valide.');
      exit(6);
    }

    print('Nous avons sélectionné: ${HolidayZone.values[zoneID - 1].name}');
    selectedZone = HolidayZone.values[zoneID - 1].apiCode;
  }

  if(result?.toLowerCase() == 'n') {
    print('Annulé!');
    exit(0);
  } else {
    print('Les valeurs sont:');
    int totalHours = 0;
    for((DateTime startHour, DateTime endhour) workTime in await work_schedule.listWorkHours(startTimestamp, endTimestamp, selectedZone)) {
      print('${formatDate(workTime.$1)} à ${formatDate(workTime.$2)}');
      totalHours += workTime.$2.difference(workTime.$1).inHours;
    }

    print('En tout, cela fait $totalHours de travail !');
  }
}
