import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas y Pagos'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In es, this message translates to:
  /// **'Tus tarjetas, gastos y deudas en un solo lugar'**
  String get appTagline;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @databaseOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la base de datos'**
  String get databaseOpenError;

  /// No description provided for @skip.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get getStarted;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get back;

  /// No description provided for @notNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get notNow;

  /// No description provided for @activate.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get activate;

  /// No description provided for @unexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error. Intenta de nuevo.'**
  String get unexpectedError;

  /// No description provided for @showPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get hidePassword;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @firstNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get lastNameLabel;

  /// No description provided for @passwordRulesHint.
  ///
  /// In es, this message translates to:
  /// **'Mínimo {min} caracteres, con letras y números'**
  String passwordRulesHint(int min);

  /// No description provided for @tooManyAttemptsWait.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera {wait}.'**
  String tooManyAttemptsWait(String wait);

  /// No description provided for @fingerprintUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Configura una huella en los ajustes del teléfono primero.'**
  String get fingerprintUnavailable;

  /// No description provided for @fingerprintNotConfirmed.
  ///
  /// In es, this message translates to:
  /// **'No se confirmó la huella.'**
  String get fingerprintNotConfirmed;

  /// No description provided for @onboardingCardsTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus tarjetas'**
  String get onboardingCardsTitle;

  /// No description provided for @onboardingCardsBody.
  ///
  /// In es, this message translates to:
  /// **'Registra tus tarjetas de crédito con una foto. Solo guardamos los últimos 4 dígitos.'**
  String get onboardingCardsBody;

  /// No description provided for @onboardingAiTitle.
  ///
  /// In es, this message translates to:
  /// **'Gastos con IA'**
  String get onboardingAiTitle;

  /// No description provided for @onboardingAiBody.
  ///
  /// In es, this message translates to:
  /// **'Toma una foto de la factura y la app llena el gasto por ti.'**
  String get onboardingAiBody;

  /// No description provided for @onboardingBestCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Mejor tarjeta hoy'**
  String get onboardingBestCardTitle;

  /// No description provided for @onboardingBestCardBody.
  ///
  /// In es, this message translates to:
  /// **'Te decimos qué tarjeta usar según su fecha de corte para pagar más tarde.'**
  String get onboardingBestCardBody;

  /// No description provided for @onboardingReportsTitle.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get onboardingReportsTitle;

  /// No description provided for @onboardingReportsBody.
  ///
  /// In es, this message translates to:
  /// **'Filtra por fecha, tarjeta, categoría o comercio y mira en qué se va tu dinero.'**
  String get onboardingReportsBody;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Entra para ver tus tarjetas y gastos'**
  String get loginSubtitle;

  /// No description provided for @wrongCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos'**
  String get wrongCredentials;

  /// No description provided for @tooManyAttemptsRetryIn.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Intenta de nuevo en {wait}.'**
  String tooManyAttemptsRetryIn(String wait);

  /// No description provided for @fingerprintVerifyFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar tu huella'**
  String get fingerprintVerifyFailed;

  /// No description provided for @loginWithFingerprintAs.
  ///
  /// In es, this message translates to:
  /// **'Entrar con huella como {name}'**
  String loginWithFingerprintAs(String name);

  /// No description provided for @noAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get noAccount;

  /// No description provided for @createAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get createAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tus datos se guardan solo en este teléfono'**
  String get registerSubtitle;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmPasswordLabel;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In es, this message translates to:
  /// **'Este correo ya está registrado'**
  String get emailAlreadyRegistered;

  /// No description provided for @unlockHello.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String unlockHello(String name);

  /// No description provided for @unlockPrompt.
  ///
  /// In es, this message translates to:
  /// **'Usa tu huella para entrar'**
  String get unlockPrompt;

  /// No description provided for @unlockFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar tu huella. Intenta de nuevo o usa tu contraseña.'**
  String get unlockFailed;

  /// No description provided for @unlockBlocked.
  ///
  /// In es, this message translates to:
  /// **'No pudimos verificar tu huella. Entra con tu contraseña.'**
  String get unlockBlocked;

  /// No description provided for @unlockWithFingerprint.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear con huella'**
  String get unlockWithFingerprint;

  /// No description provided for @usePassword.
  ///
  /// In es, this message translates to:
  /// **'Usar contraseña'**
  String get usePassword;

  /// No description provided for @loginWithPassword.
  ///
  /// In es, this message translates to:
  /// **'Entrar con contraseña'**
  String get loginWithPassword;

  /// No description provided for @biometricReasonUnlock.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu identidad para entrar'**
  String get biometricReasonUnlock;

  /// No description provided for @biometricReasonEnable.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu huella para activarla'**
  String get biometricReasonEnable;

  /// No description provided for @fieldEmailRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu correo'**
  String get fieldEmailRequired;

  /// No description provided for @fieldEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Correo no válido'**
  String get fieldEmailInvalid;

  /// No description provided for @fieldPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña'**
  String get fieldPasswordRequired;

  /// No description provided for @fieldPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'Mínimo {min} caracteres'**
  String fieldPasswordTooShort(int min);

  /// No description provided for @fieldTooLong.
  ///
  /// In es, this message translates to:
  /// **'Máximo {max} caracteres'**
  String fieldTooLong(int max);

  /// No description provided for @fieldPasswordLettersDigits.
  ///
  /// In es, this message translates to:
  /// **'Debe tener letras y números'**
  String get fieldPasswordLettersDigits;

  /// No description provided for @fieldConfirmRequired.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu contraseña'**
  String get fieldConfirmRequired;

  /// No description provided for @fieldPasswordMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get fieldPasswordMismatch;

  /// No description provided for @fieldFirstNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu nombre'**
  String get fieldFirstNameRequired;

  /// No description provided for @fieldLastNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu apellido'**
  String get fieldLastNameRequired;

  /// No description provided for @fieldSamePassword.
  ///
  /// In es, this message translates to:
  /// **'Debe ser distinta de la actual'**
  String get fieldSamePassword;

  /// No description provided for @fieldNotifyDaysRange.
  ///
  /// In es, this message translates to:
  /// **'Escribe de {min} a {max} días'**
  String fieldNotifyDaysRange(int min, int max);

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get profileTitle;

  /// No description provided for @sectionData.
  ///
  /// In es, this message translates to:
  /// **'Datos'**
  String get sectionData;

  /// No description provided for @nameAndSurname.
  ///
  /// In es, this message translates to:
  /// **'Nombre y apellido'**
  String get nameAndSurname;

  /// No description provided for @changeEmail.
  ///
  /// In es, this message translates to:
  /// **'Cambiar correo'**
  String get changeEmail;

  /// No description provided for @changePassword.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePassword;

  /// No description provided for @sectionSecurity.
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get sectionSecurity;

  /// No description provided for @fingerprintLogin.
  ///
  /// In es, this message translates to:
  /// **'Entrar con huella'**
  String get fingerprintLogin;

  /// No description provided for @fingerprintLoginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Al abrir la app se pide tu huella.'**
  String get fingerprintLoginSubtitle;

  /// No description provided for @fingerprintEnabled.
  ///
  /// In es, this message translates to:
  /// **'Listo: la app te pedirá tu huella.'**
  String get fingerprintEnabled;

  /// No description provided for @sectionAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get sectionAppearance;

  /// No description provided for @themeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get themeLabel;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @languageLabel.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageLabel;

  /// No description provided for @sectionPreferences.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get sectionPreferences;

  /// No description provided for @defaultCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda predeterminada'**
  String get defaultCurrency;

  /// No description provided for @notifyBefore.
  ///
  /// In es, this message translates to:
  /// **'Avisarme antes de'**
  String get notifyBefore;

  /// No description provided for @sectionCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get sectionCategories;

  /// No description provided for @myCategories.
  ///
  /// In es, this message translates to:
  /// **'Mis categorías'**
  String get myCategories;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Tus datos quedan guardados en este teléfono.'**
  String get logoutConfirmBody;

  /// No description provided for @fewerDays.
  ///
  /// In es, this message translates to:
  /// **'Menos días'**
  String get fewerDays;

  /// No description provided for @moreDays.
  ///
  /// In es, this message translates to:
  /// **'Más días'**
  String get moreDays;

  /// No description provided for @daysCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String daysCount(int count);

  /// No description provided for @currentPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña actual'**
  String get currentPasswordRequired;

  /// No description provided for @currentPasswordWrong.
  ///
  /// In es, this message translates to:
  /// **'La contraseña actual no es correcta'**
  String get currentPasswordWrong;

  /// No description provided for @emailHasAccount.
  ///
  /// In es, this message translates to:
  /// **'Ese correo ya tiene una cuenta'**
  String get emailHasAccount;

  /// No description provided for @emailUpdated.
  ///
  /// In es, this message translates to:
  /// **'Correo actualizado'**
  String get emailUpdated;

  /// No description provided for @currentEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo actual: {email}'**
  String currentEmail(String email);

  /// No description provided for @newEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo nuevo'**
  String get newEmailLabel;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña nueva'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña nueva'**
  String get confirmNewPasswordLabel;

  /// No description provided for @passwordUpdated.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get passwordUpdated;

  /// No description provided for @setupTitle.
  ///
  /// In es, this message translates to:
  /// **'Configura tu cuenta'**
  String get setupTitle;

  /// No description provided for @stepOf.
  ///
  /// In es, this message translates to:
  /// **'Paso {step} de {total}'**
  String stepOf(int step, int total);

  /// No description provided for @setupCurrencyTitle.
  ///
  /// In es, this message translates to:
  /// **'¿En qué moneda gastas más?'**
  String get setupCurrencyTitle;

  /// No description provided for @setupCurrencyBody.
  ///
  /// In es, this message translates to:
  /// **'Será la moneda que aparece primero en gastos y deudas nuevos.'**
  String get setupCurrencyBody;

  /// No description provided for @setupCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Agrega tu primera tarjeta'**
  String get setupCardTitle;

  /// No description provided for @setupCardBody.
  ///
  /// In es, this message translates to:
  /// **'Solo guardamos los últimos 4 dígitos.'**
  String get setupCardBody;

  /// No description provided for @setupFingerprintTitle.
  ///
  /// In es, this message translates to:
  /// **'Entra con tu huella'**
  String get setupFingerprintTitle;

  /// No description provided for @setupFingerprintBody.
  ///
  /// In es, this message translates to:
  /// **'Al abrir la app se pedirá tu huella en vez de la contraseña.'**
  String get setupFingerprintBody;

  /// No description provided for @setupRemindersTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get setupRemindersTitle;

  /// No description provided for @setupRemindersBody.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos antes del corte de tus tarjetas, de la fecha límite de pago y de las deudas por vencer.'**
  String get setupRemindersBody;

  /// No description provided for @addCard.
  ///
  /// In es, this message translates to:
  /// **'Agregar tarjeta'**
  String get addCard;

  /// No description provided for @illDoItLater.
  ///
  /// In es, this message translates to:
  /// **'Lo haré después'**
  String get illDoItLater;

  /// No description provided for @enableReminders.
  ///
  /// In es, this message translates to:
  /// **'Activar recordatorios'**
  String get enableReminders;

  /// No description provided for @cardAdded.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta agregada'**
  String get cardAdded;

  /// No description provided for @notificationsDenied.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso no podremos avisarte. Puedes darlo luego en los ajustes del teléfono.'**
  String get notificationsDenied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
