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

  /// No description provided for @secQFirstPet.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo se llamaba tu primera mascota?'**
  String get secQFirstPet;

  /// No description provided for @secQBirthCity.
  ///
  /// In es, this message translates to:
  /// **'¿En qué ciudad naciste?'**
  String get secQBirthCity;

  /// No description provided for @secQPrimarySchool.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo se llamaba tu escuela primaria?'**
  String get secQPrimarySchool;

  /// No description provided for @secQChildhoodFriend.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo se llamaba tu mejor amigo de la infancia?'**
  String get secQChildhoodFriend;

  /// No description provided for @secQFirstJob.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde fue tu primer trabajo?'**
  String get secQFirstJob;

  /// No description provided for @secQCustom.
  ///
  /// In es, this message translates to:
  /// **'Escribir mi propia pregunta'**
  String get secQCustom;

  /// No description provided for @securityQuestionLabel.
  ///
  /// In es, this message translates to:
  /// **'Pregunta de seguridad'**
  String get securityQuestionLabel;

  /// No description provided for @customQuestionLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu pregunta'**
  String get customQuestionLabel;

  /// No description provided for @securityAnswerLabel.
  ///
  /// In es, this message translates to:
  /// **'Respuesta'**
  String get securityAnswerLabel;

  /// No description provided for @securityAnswerHint.
  ///
  /// In es, this message translates to:
  /// **'No importan las mayúsculas ni las tildes.'**
  String get securityAnswerHint;

  /// No description provided for @registerSecurityHint.
  ///
  /// In es, this message translates to:
  /// **'La usarás si olvidas tu contraseña.'**
  String get registerSecurityHint;

  /// No description provided for @fieldQuestionChoose.
  ///
  /// In es, this message translates to:
  /// **'Elige una pregunta'**
  String get fieldQuestionChoose;

  /// No description provided for @fieldQuestionRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu pregunta'**
  String get fieldQuestionRequired;

  /// No description provided for @fieldAnswerRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu respuesta'**
  String get fieldAnswerRequired;

  /// No description provided for @fieldAnswerTooShort.
  ///
  /// In es, this message translates to:
  /// **'Mínimo {min} caracteres'**
  String fieldAnswerTooShort(int min);

  /// No description provided for @forgotPasswordLink.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPasswordLink;

  /// No description provided for @forgotTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get forgotTitle;

  /// No description provided for @forgotEmailSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe el correo de tu cuenta.'**
  String get forgotEmailSubtitle;

  /// No description provided for @forgotAnswerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Responde tu pregunta de seguridad.'**
  String get forgotAnswerSubtitle;

  /// No description provided for @forgotNewPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea una contraseña nueva.'**
  String get forgotNewPasswordSubtitle;

  /// No description provided for @continueLabel.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueLabel;

  /// No description provided for @accountNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos una cuenta con ese correo'**
  String get accountNotFound;

  /// No description provided for @noSecurityQuestion.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta no tiene pregunta de seguridad'**
  String get noSecurityQuestion;

  /// No description provided for @wrongAnswer.
  ///
  /// In es, this message translates to:
  /// **'La respuesta no es correcta'**
  String get wrongAnswer;

  /// No description provided for @securityQuestionMissing.
  ///
  /// In es, this message translates to:
  /// **'Configura una pregunta para poder recuperar tu contraseña.'**
  String get securityQuestionMissing;

  /// No description provided for @securityQuestionSaved.
  ///
  /// In es, this message translates to:
  /// **'Pregunta de seguridad guardada'**
  String get securityQuestionSaved;

  /// No description provided for @greetingMorning.
  ///
  /// In es, this message translates to:
  /// **'Buenos días, {name}'**
  String greetingMorning(String name);

  /// No description provided for @greetingAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes, {name}'**
  String greetingAfternoon(String name);

  /// No description provided for @greetingNight.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches, {name}'**
  String greetingNight(String name);

  /// No description provided for @cutsIn.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =0{Corta hoy} =1{Corta mañana} other{Corta en {days} días}}'**
  String cutsIn(int days);

  /// No description provided for @recommendationLine.
  ///
  /// In es, this message translates to:
  /// **'{cut} · pagas el {due} · {days}'**
  String recommendationLine(String cut, String due, String days);

  /// No description provided for @receiptErrorOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión a internet. Completa el gasto a mano.'**
  String get receiptErrorOffline;

  /// No description provided for @receiptErrorTimeout.
  ///
  /// In es, this message translates to:
  /// **'La IA tardó demasiado. Intenta de nuevo o completa a mano.'**
  String get receiptErrorTimeout;

  /// No description provided for @receiptErrorInvalidKey.
  ///
  /// In es, this message translates to:
  /// **'La clave de la IA no es válida. Completa el gasto a mano.'**
  String get receiptErrorInvalidKey;

  /// No description provided for @receiptErrorRateLimited.
  ///
  /// In es, this message translates to:
  /// **'La IA está recibiendo muchas solicitudes. Intenta en un rato.'**
  String get receiptErrorRateLimited;

  /// No description provided for @receiptErrorUnavailable.
  ///
  /// In es, this message translates to:
  /// **'La IA no está disponible ahora. Completa el gasto a mano.'**
  String get receiptErrorUnavailable;

  /// No description provided for @receiptErrorImageTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La foto es demasiado grande. Prueba con otra.'**
  String get receiptErrorImageTooLarge;

  /// No description provided for @receiptErrorInvalidResponse.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer la factura. Completa el gasto a mano.'**
  String get receiptErrorInvalidResponse;

  /// No description provided for @fieldCardAliasRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre para la tarjeta'**
  String get fieldCardAliasRequired;

  /// No description provided for @fieldCardBankRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el banco'**
  String get fieldCardBankRequired;

  /// No description provided for @fieldCardLast4Invalid.
  ///
  /// In es, this message translates to:
  /// **'Escribe los últimos 4 dígitos'**
  String get fieldCardLast4Invalid;

  /// No description provided for @fieldCardCutDayRange.
  ///
  /// In es, this message translates to:
  /// **'El día de corte va del 1 al 31'**
  String get fieldCardCutDayRange;

  /// No description provided for @fieldCardPaymentDaysRange.
  ///
  /// In es, this message translates to:
  /// **'Los días para pagar van de 0 a 60'**
  String get fieldCardPaymentDaysRange;

  /// No description provided for @fieldCardLimitInvalid.
  ///
  /// In es, this message translates to:
  /// **'Límite no válido'**
  String get fieldCardLimitInvalid;

  /// No description provided for @fieldCardDualMustBeDop.
  ///
  /// In es, this message translates to:
  /// **'Una tarjeta de doble balance es RD\\\$ y US\\\$'**
  String get fieldCardDualMustBeDop;

  /// No description provided for @fieldCardCurrencyInUse.
  ///
  /// In es, this message translates to:
  /// **'Esta tarjeta tiene movimientos en esa moneda; no puedes quitarla'**
  String get fieldCardCurrencyInUse;

  /// No description provided for @fieldAmountInvalid.
  ///
  /// In es, this message translates to:
  /// **'Monto no válido'**
  String get fieldAmountInvalid;

  /// No description provided for @fieldNoBalanceInCurrency.
  ///
  /// In es, this message translates to:
  /// **'La tarjeta no tiene balance en esa moneda'**
  String get fieldNoBalanceInCurrency;

  /// No description provided for @fieldMerchantRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe el comercio'**
  String get fieldMerchantRequired;

  /// No description provided for @fieldConversionInvalid.
  ///
  /// In es, this message translates to:
  /// **'Conversión no válida'**
  String get fieldConversionInvalid;

  /// No description provided for @fieldCategoryRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige una categoría'**
  String get fieldCategoryRequired;

  /// No description provided for @fieldCardRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige una tarjeta'**
  String get fieldCardRequired;

  /// No description provided for @fieldDateInFuture.
  ///
  /// In es, this message translates to:
  /// **'La fecha no puede ser futura'**
  String get fieldDateInFuture;

  /// No description provided for @fieldCategoryNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre'**
  String get fieldCategoryNameRequired;

  /// No description provided for @fieldCategoryIconInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ícono no válido'**
  String get fieldCategoryIconInvalid;

  /// No description provided for @fieldCategoryColorInvalid.
  ///
  /// In es, this message translates to:
  /// **'Color no válido'**
  String get fieldCategoryColorInvalid;

  /// No description provided for @fieldCategoryNameTaken.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes una categoría así'**
  String get fieldCategoryNameTaken;

  /// No description provided for @fieldCategoryReassignOther.
  ///
  /// In es, this message translates to:
  /// **'Elige otra categoría'**
  String get fieldCategoryReassignOther;

  /// No description provided for @catSupermarket.
  ///
  /// In es, this message translates to:
  /// **'Supermercado'**
  String get catSupermarket;

  /// No description provided for @catFuel.
  ///
  /// In es, this message translates to:
  /// **'Combustible'**
  String get catFuel;

  /// No description provided for @catBarbershop.
  ///
  /// In es, this message translates to:
  /// **'Barbería'**
  String get catBarbershop;

  /// No description provided for @catSalon.
  ///
  /// In es, this message translates to:
  /// **'Salón'**
  String get catSalon;

  /// No description provided for @catBeauty.
  ///
  /// In es, this message translates to:
  /// **'Belleza'**
  String get catBeauty;

  /// No description provided for @catHardware.
  ///
  /// In es, this message translates to:
  /// **'Ferretería'**
  String get catHardware;

  /// No description provided for @catElectricity.
  ///
  /// In es, this message translates to:
  /// **'Luz'**
  String get catElectricity;

  /// No description provided for @catWater.
  ///
  /// In es, this message translates to:
  /// **'Agua'**
  String get catWater;

  /// No description provided for @catPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get catPhone;

  /// No description provided for @catLiquor.
  ///
  /// In es, this message translates to:
  /// **'Licor'**
  String get catLiquor;

  /// No description provided for @catHealth.
  ///
  /// In es, this message translates to:
  /// **'Salud'**
  String get catHealth;

  /// No description provided for @catRestaurant.
  ///
  /// In es, this message translates to:
  /// **'Restaurante'**
  String get catRestaurant;

  /// No description provided for @catOther.
  ///
  /// In es, this message translates to:
  /// **'Otros'**
  String get catOther;

  /// No description provided for @myCards.
  ///
  /// In es, this message translates to:
  /// **'Mis tarjetas'**
  String get myCards;

  /// No description provided for @seeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todas'**
  String get seeAll;

  /// No description provided for @cardsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus tarjetas'**
  String get cardsLoadError;

  /// No description provided for @monthSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de {month}'**
  String monthSummary(String month);

  /// No description provided for @spentThisMonth.
  ///
  /// In es, this message translates to:
  /// **'Gastado este mes'**
  String get spentThisMonth;

  /// No description provided for @totalDebt.
  ///
  /// In es, this message translates to:
  /// **'Deuda total'**
  String get totalDebt;

  /// No description provided for @debtSplit.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas {cards} · Otras deudas {other}'**
  String debtSplit(String cards, String other);

  /// No description provided for @bestCardToday.
  ///
  /// In es, this message translates to:
  /// **'Mejor tarjeta hoy'**
  String get bestCardToday;

  /// No description provided for @bestCardEmpty.
  ///
  /// In es, this message translates to:
  /// **'Agrega una tarjeta para saber cuál te conviene usar hoy.'**
  String get bestCardEmpty;

  /// No description provided for @lowCredit.
  ///
  /// In es, this message translates to:
  /// **'Poco crédito disponible'**
  String get lowCredit;

  /// No description provided for @newExpense.
  ///
  /// In es, this message translates to:
  /// **'Nuevo gasto'**
  String get newExpense;

  /// No description provided for @reports.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get reports;

  /// No description provided for @debts.
  ///
  /// In es, this message translates to:
  /// **'Deudas'**
  String get debts;

  /// No description provided for @noCardsYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes tarjetas.'**
  String get noCardsYet;

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get add;

  /// No description provided for @noCardsYetTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes tarjetas'**
  String get noCardsYetTitle;

  /// No description provided for @addFirstCardHint.
  ///
  /// In es, this message translates to:
  /// **'Agrega tu primera tarjeta para saber cuál te conviene usar cada día.'**
  String get addFirstCardHint;

  /// No description provided for @cutOn.
  ///
  /// In es, this message translates to:
  /// **'Corte {date}'**
  String cutOn(String date);

  /// No description provided for @availableNone.
  ///
  /// In es, this message translates to:
  /// **'Disponible —'**
  String get availableNone;

  /// No description provided for @availableAmount.
  ///
  /// In es, this message translates to:
  /// **'Disponible {amount}'**
  String availableAmount(String amount);

  /// No description provided for @dualBalance.
  ///
  /// In es, this message translates to:
  /// **'RD\\\$ y US\\\$'**
  String get dualBalance;

  /// No description provided for @cardNotFound.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta no encontrada'**
  String get cardNotFound;

  /// No description provided for @registerPayment.
  ///
  /// In es, this message translates to:
  /// **'Registrar pago'**
  String get registerPayment;

  /// No description provided for @fieldAmountPositive.
  ///
  /// In es, this message translates to:
  /// **'Escribe un monto mayor que 0'**
  String get fieldAmountPositive;

  /// No description provided for @amountPaid.
  ///
  /// In es, this message translates to:
  /// **'Monto pagado'**
  String get amountPaid;

  /// No description provided for @payStatementDue.
  ///
  /// In es, this message translates to:
  /// **'Pagar lo de este corte: {amount}'**
  String payStatementDue(String amount);

  /// No description provided for @paymentDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha del pago'**
  String get paymentDate;

  /// No description provided for @noteOptional.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get noteOptional;

  /// No description provided for @card.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get card;

  /// No description provided for @filterExpenses.
  ///
  /// In es, this message translates to:
  /// **'Filtrar gastos'**
  String get filterExpenses;

  /// No description provided for @editCard.
  ///
  /// In es, this message translates to:
  /// **'Editar tarjeta'**
  String get editCard;

  /// No description provided for @movements.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get movements;

  /// No description provided for @clearFilters.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get clearFilters;

  /// No description provided for @filterError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron filtrar los gastos'**
  String get filterError;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// No description provided for @nextCut.
  ///
  /// In es, this message translates to:
  /// **'Próximo corte'**
  String get nextCut;

  /// No description provided for @nextCutDue.
  ///
  /// In es, this message translates to:
  /// **'Fecha límite de ese corte'**
  String get nextCutDue;

  /// No description provided for @payInIfUsedToday.
  ///
  /// In es, this message translates to:
  /// **'Si la usas hoy, pagas en'**
  String get payInIfUsedToday;

  /// No description provided for @daysCountPlain.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{0 días} =1{1 día} other{{count} días}}'**
  String daysCountPlain(int count);

  /// No description provided for @creditInFavor.
  ///
  /// In es, this message translates to:
  /// **'Saldo a favor ({currency})'**
  String creditInFavor(String currency);

  /// No description provided for @balanceIn.
  ///
  /// In es, this message translates to:
  /// **'Balance ({currency})'**
  String balanceIn(String currency);

  /// No description provided for @availableOf.
  ///
  /// In es, this message translates to:
  /// **'Disponible {available} de {limit}'**
  String availableOf(String available, String limit);

  /// No description provided for @dueThisStatement.
  ///
  /// In es, this message translates to:
  /// **'A pagar este corte'**
  String get dueThisStatement;

  /// No description provided for @payBefore.
  ///
  /// In es, this message translates to:
  /// **'Paga antes del {date}'**
  String payBefore(String date);

  /// No description provided for @overdueSince.
  ///
  /// In es, this message translates to:
  /// **'Vencido: {amount} desde el {date}'**
  String overdueSince(String amount, String date);

  /// No description provided for @noCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get noCategory;

  /// No description provided for @convertedAt.
  ///
  /// In es, this message translates to:
  /// **'{amount} a {rate}'**
  String convertedAt(String amount, String rate);

  /// No description provided for @deletePaymentTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este pago?'**
  String get deletePaymentTitle;

  /// No description provided for @deletePaymentBody.
  ///
  /// In es, this message translates to:
  /// **'El balance volverá a subir {amount}.'**
  String deletePaymentBody(String amount);

  /// No description provided for @payment.
  ///
  /// In es, this message translates to:
  /// **'Pago'**
  String get payment;

  /// No description provided for @noExpensesMatch.
  ///
  /// In es, this message translates to:
  /// **'Ningún gasto coincide con los filtros'**
  String get noExpensesMatch;

  /// No description provided for @noMovementsYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay movimientos en esta tarjeta'**
  String get noMovementsYet;

  /// No description provided for @tapNewExpenseHint.
  ///
  /// In es, this message translates to:
  /// **'Toca \"Nuevo gasto\" para registrar el primero.'**
  String get tapNewExpenseHint;

  /// No description provided for @cardScanNothing.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer la tarjeta, completa los datos manualmente'**
  String get cardScanNothing;

  /// No description provided for @scanPurposeCard.
  ///
  /// In es, this message translates to:
  /// **'Lo usamos solo para leer la tarjeta en tu teléfono. La foto no se guarda ni se envía, y solo conservamos los últimos 4 dígitos.'**
  String get scanPurposeCard;

  /// No description provided for @scanPurposeReceipt.
  ///
  /// In es, this message translates to:
  /// **'Lo usamos solo para leer la factura con la IA. La foto se envía una sola vez para leerla y no se guarda.'**
  String get scanPurposeReceipt;

  /// No description provided for @archiveCardTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Archivar esta tarjeta?'**
  String get archiveCardTitle;

  /// No description provided for @archiveCardBody.
  ///
  /// In es, this message translates to:
  /// **'Dejará de aparecer en tus listas y en la recomendación. Sus datos se conservan.'**
  String get archiveCardBody;

  /// No description provided for @archive.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get archive;

  /// No description provided for @newCard.
  ///
  /// In es, this message translates to:
  /// **'Nueva tarjeta'**
  String get newCard;

  /// No description provided for @scanCard.
  ///
  /// In es, this message translates to:
  /// **'Escanear tarjeta'**
  String get scanCard;

  /// No description provided for @scanCardHint.
  ///
  /// In es, this message translates to:
  /// **'Leemos la foto en tu teléfono y solo guardamos los últimos 4 dígitos.'**
  String get scanCardHint;

  /// No description provided for @cardAliasLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre (ej. Gastos del mes)'**
  String get cardAliasLabel;

  /// No description provided for @detectedByPhoto.
  ///
  /// In es, this message translates to:
  /// **'Detectado por foto'**
  String get detectedByPhoto;

  /// No description provided for @brand.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get brand;

  /// No description provided for @brandOther.
  ///
  /// In es, this message translates to:
  /// **'Otra'**
  String get brandOther;

  /// No description provided for @last4Label.
  ///
  /// In es, this message translates to:
  /// **'Últimos 4 dígitos'**
  String get last4Label;

  /// No description provided for @last4Helper.
  ///
  /// In es, this message translates to:
  /// **'Nunca guardamos el número completo'**
  String get last4Helper;

  /// No description provided for @fieldCutDay.
  ///
  /// In es, this message translates to:
  /// **'Escribe un día del 1 al 31'**
  String get fieldCutDay;

  /// No description provided for @cutDayLabel.
  ///
  /// In es, this message translates to:
  /// **'Día de corte'**
  String get cutDayLabel;

  /// No description provided for @cutDayHelper.
  ///
  /// In es, this message translates to:
  /// **'Si el mes es más corto, se usa el último día'**
  String get cutDayHelper;

  /// No description provided for @fieldPaymentDays.
  ///
  /// In es, this message translates to:
  /// **'Escribe de 0 a 60 días'**
  String get fieldPaymentDays;

  /// No description provided for @paymentDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'Días para pagar después del corte'**
  String get paymentDaysLabel;

  /// No description provided for @currency.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get currency;

  /// No description provided for @dualBalanceOption.
  ///
  /// In es, this message translates to:
  /// **'RD\\\$ y US\\\$ (doble balance)'**
  String get dualBalanceOption;

  /// No description provided for @dualBalanceHint.
  ///
  /// In es, this message translates to:
  /// **'Cada gasto queda en su moneda, con un límite por moneda.'**
  String get dualBalanceHint;

  /// No description provided for @singleCurrencyHint.
  ///
  /// In es, this message translates to:
  /// **'Los gastos en otra moneda se convierten a esta.'**
  String get singleCurrencyHint;

  /// No description provided for @fieldLimitInvalid.
  ///
  /// In es, this message translates to:
  /// **'Monto no válido (ej. 50000 o 50,000.00)'**
  String get fieldLimitInvalid;

  /// No description provided for @limitDopOptional.
  ///
  /// In es, this message translates to:
  /// **'Límite en RD\\\$ (opcional)'**
  String get limitDopOptional;

  /// No description provided for @creditLimitOptional.
  ///
  /// In es, this message translates to:
  /// **'Límite de crédito (opcional)'**
  String get creditLimitOptional;

  /// No description provided for @limitUsdOptional.
  ///
  /// In es, this message translates to:
  /// **'Límite en US\\\$ (opcional)'**
  String get limitUsdOptional;

  /// No description provided for @color.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// No description provided for @archiveCard.
  ///
  /// In es, this message translates to:
  /// **'Archivar tarjeta'**
  String get archiveCard;

  /// No description provided for @readingCard.
  ///
  /// In es, this message translates to:
  /// **'Leyendo la tarjeta…'**
  String get readingCard;

  /// No description provided for @bank.
  ///
  /// In es, this message translates to:
  /// **'Banco'**
  String get bank;

  /// No description provided for @takePhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get takePhoto;

  /// No description provided for @pickFromGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get pickFromGallery;

  /// No description provided for @permissionAltGallery.
  ///
  /// In es, this message translates to:
  /// **'Puedes activarla en los ajustes o elegir una foto de la galería.'**
  String get permissionAltGallery;

  /// No description provided for @permissionAltCamera.
  ///
  /// In es, this message translates to:
  /// **'Puedes activarlo en los ajustes o tomar una foto con la cámara.'**
  String get permissionAltCamera;

  /// No description provided for @allowCamera.
  ///
  /// In es, this message translates to:
  /// **'Permite el uso de la cámara'**
  String get allowCamera;

  /// No description provided for @allowPhotos.
  ///
  /// In es, this message translates to:
  /// **'Permite el acceso a tus fotos'**
  String get allowPhotos;

  /// No description provided for @openSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get openSettings;

  /// No description provided for @openSettingsHint.
  ///
  /// In es, this message translates to:
  /// **'Abre los ajustes del teléfono para permitirlo'**
  String get openSettingsHint;

  /// No description provided for @expenseLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el gasto'**
  String get expenseLoadError;

  /// No description provided for @expenseNotFound.
  ///
  /// In es, this message translates to:
  /// **'Gasto no encontrado'**
  String get expenseNotFound;

  /// No description provided for @newExpenseTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo gasto'**
  String get newExpenseTitle;

  /// No description provided for @editExpense.
  ///
  /// In es, this message translates to:
  /// **'Editar gasto'**
  String get editExpense;

  /// No description provided for @addCardFirst.
  ///
  /// In es, this message translates to:
  /// **'Primero agrega una tarjeta para registrar gastos.'**
  String get addCardFirst;

  /// No description provided for @deleteExpenseTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este gasto?'**
  String get deleteExpenseTitle;

  /// No description provided for @deleteExpenseBody.
  ///
  /// In es, this message translates to:
  /// **'Se quitará de la tarjeta y de los reportes.'**
  String get deleteExpenseBody;

  /// No description provided for @scanReceipt.
  ///
  /// In es, this message translates to:
  /// **'Escanear factura (IA)'**
  String get scanReceipt;

  /// No description provided for @scanReceiptHint.
  ///
  /// In es, this message translates to:
  /// **'La IA lee la foto y propone los datos; tú los revisas antes de guardar. La foto no se guarda.'**
  String get scanReceiptHint;

  /// No description provided for @merchant.
  ///
  /// In es, this message translates to:
  /// **'Comercio'**
  String get merchant;

  /// No description provided for @category.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get category;

  /// No description provided for @archivedCardExpense.
  ///
  /// In es, this message translates to:
  /// **'La tarjeta de este gasto está archivada: puedes eliminarlo, pero no editarlo.'**
  String get archivedCardExpense;

  /// No description provided for @expenseCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda del gasto'**
  String get expenseCurrency;

  /// No description provided for @amount.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get amount;

  /// No description provided for @recordedOnCardAs.
  ///
  /// In es, this message translates to:
  /// **'Se registra en la tarjeta como {amount}'**
  String recordedOnCardAs(String amount);

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// No description provided for @notesOptional.
  ///
  /// In es, this message translates to:
  /// **'Notas (opcional)'**
  String get notesOptional;

  /// No description provided for @saveExpense.
  ///
  /// In es, this message translates to:
  /// **'Guardar gasto'**
  String get saveExpense;

  /// No description provided for @deleteExpense.
  ///
  /// In es, this message translates to:
  /// **'Eliminar gasto'**
  String get deleteExpense;

  /// No description provided for @readingReceipt.
  ///
  /// In es, this message translates to:
  /// **'Leyendo factura…'**
  String get readingReceipt;

  /// No description provided for @aiChip.
  ///
  /// In es, this message translates to:
  /// **'IA'**
  String get aiChip;

  /// No description provided for @rateLoading.
  ///
  /// In es, this message translates to:
  /// **'Buscando la tasa de hoy…'**
  String get rateLoading;

  /// No description provided for @rateOnline.
  ///
  /// In es, this message translates to:
  /// **'Tasa en línea de hoy. Puedes ajustarla a la de tu banco.'**
  String get rateOnline;

  /// No description provided for @rateStale.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: última tasa conocida. Revísala.'**
  String get rateStale;

  /// No description provided for @rateUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener la tasa. Escríbela.'**
  String get rateUnavailable;

  /// No description provided for @rateIdle.
  ///
  /// In es, this message translates to:
  /// **'Tasa usada en la conversión.'**
  String get rateIdle;

  /// No description provided for @fieldRateRequired.
  ///
  /// In es, this message translates to:
  /// **'Escribe la tasa (ej. 61.40)'**
  String get fieldRateRequired;

  /// No description provided for @rateLabel.
  ///
  /// In es, this message translates to:
  /// **'Tasa (RD\$ por US\$ 1)'**
  String get rateLabel;

  /// No description provided for @refreshRate.
  ///
  /// In es, this message translates to:
  /// **'Buscar la tasa de hoy'**
  String get refreshRate;

  /// No description provided for @allDates.
  ///
  /// In es, this message translates to:
  /// **'Todas las fechas'**
  String get allDates;

  /// No description provided for @merchantContains.
  ///
  /// In es, this message translates to:
  /// **'Comercio contiene'**
  String get merchantContains;

  /// No description provided for @minAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto mínimo'**
  String get minAmount;

  /// No description provided for @maxAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto máximo'**
  String get maxAmount;

  /// No description provided for @apply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get apply;

  /// No description provided for @newCategory.
  ///
  /// In es, this message translates to:
  /// **'Nueva categoría'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In es, this message translates to:
  /// **'Editar categoría'**
  String get editCategory;

  /// No description provided for @noOwnCategories.
  ///
  /// In es, this message translates to:
  /// **'Aún no has creado categorías.'**
  String get noOwnCategories;

  /// No description provided for @includedCategories.
  ///
  /// In es, this message translates to:
  /// **'Incluidas'**
  String get includedCategories;

  /// No description provided for @includedCategoriesHint.
  ///
  /// In es, this message translates to:
  /// **'Vienen con la app y no se pueden cambiar.'**
  String get includedCategoriesHint;

  /// No description provided for @categoriesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las categorías'**
  String get categoriesLoadError;

  /// No description provided for @categoryNotFound.
  ///
  /// In es, this message translates to:
  /// **'Categoría no encontrada'**
  String get categoryNotFound;

  /// No description provided for @deleteNamedTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{name}\"?'**
  String deleteNamedTitle(String name);

  /// No description provided for @categoryNoExpenses.
  ///
  /// In es, this message translates to:
  /// **'No tiene gastos.'**
  String get categoryNoExpenses;

  /// No description provided for @categoryNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre (ej. Mascotas)'**
  String get categoryNameLabel;

  /// No description provided for @icon.
  ///
  /// In es, this message translates to:
  /// **'Ícono'**
  String get icon;

  /// No description provided for @colorNumber.
  ///
  /// In es, this message translates to:
  /// **'Color {n}'**
  String colorNumber(int n);

  /// No description provided for @createCategory.
  ///
  /// In es, this message translates to:
  /// **'Crear categoría'**
  String get createCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In es, this message translates to:
  /// **'Eliminar categoría'**
  String get deleteCategory;

  /// No description provided for @categoryHasExpenses.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{\"{name}\" tiene 1 gasto} other{\"{name}\" tiene {count} gastos}}'**
  String categoryHasExpenses(String name, int count);

  /// No description provided for @reassignHint.
  ///
  /// In es, this message translates to:
  /// **'Para eliminarla, elige a qué categoría pasan.'**
  String get reassignHint;

  /// No description provided for @moveTo.
  ///
  /// In es, this message translates to:
  /// **'Pasar a'**
  String get moveTo;

  /// No description provided for @moveAndDelete.
  ///
  /// In es, this message translates to:
  /// **'Mover y eliminar'**
  String get moveAndDelete;
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
