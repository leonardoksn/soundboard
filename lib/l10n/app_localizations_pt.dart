// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Retro Board';

  @override
  String get ready => 'Pronto';

  @override
  String get addPad => 'Adicionar';

  @override
  String get editTooltip => 'Editar';

  @override
  String get loadError => 'Erro ao carregar os sons';

  @override
  String get retry => 'Tentar de novo';

  @override
  String get emptyState =>
      'Nenhum som carregado.\nToque em Adicionar para importar.';

  @override
  String get newSound => 'Novo som';

  @override
  String get editSound => 'Editar som';

  @override
  String get chooseFile => 'Escolher arquivo';

  @override
  String get fileSelected => 'Arquivo selecionado';

  @override
  String get name => 'Nome';

  @override
  String get padLed => 'LED do pad';

  @override
  String get save => 'Salvar';

  @override
  String get delete => 'Excluir';

  @override
  String get deleteConfirm => 'Excluir som?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get importError => 'não foi possível importar';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get level => 'Nível';

  @override
  String get play => 'Tocar';

  @override
  String get stop => 'Parar';

  @override
  String get loop => 'Repetir';

  @override
  String get record => 'Gravar';

  @override
  String get micDenied => 'Permissão de microfone negada';
}
