// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Soundboard';

  @override
  String get ready => 'Ready';

  @override
  String get addPad => 'Add pad';

  @override
  String get editTooltip => 'Edit';

  @override
  String get loadError => 'Error loading sounds';

  @override
  String get retry => 'Try again';

  @override
  String get emptyState => 'No sounds loaded.\nTap Add pad to import.';

  @override
  String get newSound => 'New sound';

  @override
  String get editSound => 'Edit sound';

  @override
  String get chooseFile => 'Choose file';

  @override
  String get fileSelected => 'File selected';

  @override
  String get name => 'Name';

  @override
  String get padLed => 'Pad LED';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirm => 'Delete sound?';

  @override
  String get cancel => 'Cancel';

  @override
  String get importError => 'couldn\'t import';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get level => 'Level';

  @override
  String get play => 'Play';

  @override
  String get stop => 'Stop';

  @override
  String get loop => 'Loop';

  @override
  String get record => 'Record';

  @override
  String get micDenied => 'Microphone permission denied';
}
