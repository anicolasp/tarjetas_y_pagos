// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Tarjetas y Pagos';

  @override
  String get appTagline => 'Tus tarjetas, gastos y deudas en un solo lugar';

  @override
  String get retry => 'Reintentar';

  @override
  String get databaseOpenError => 'No se pudo abrir la base de datos';

  @override
  String get skip => 'Omitir';

  @override
  String get next => 'Siguiente';

  @override
  String get getStarted => 'Empezar';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get back => 'Atrás';

  @override
  String get notNow => 'Ahora no';

  @override
  String get activate => 'Activar';

  @override
  String get unexpectedError => 'Ocurrió un error. Intenta de nuevo.';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get emailLabel => 'Correo';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get firstNameLabel => 'Nombre';

  @override
  String get lastNameLabel => 'Apellido';

  @override
  String passwordRulesHint(int min) {
    return 'Mínimo $min caracteres, con letras y números';
  }

  @override
  String tooManyAttemptsWait(String wait) {
    return 'Demasiados intentos. Espera $wait.';
  }

  @override
  String get fingerprintUnavailable =>
      'Configura una huella en los ajustes del teléfono primero.';

  @override
  String get fingerprintNotConfirmed => 'No se confirmó la huella.';

  @override
  String get onboardingCardsTitle => 'Tus tarjetas';

  @override
  String get onboardingCardsBody =>
      'Registra tus tarjetas de crédito con una foto. Solo guardamos los últimos 4 dígitos.';

  @override
  String get onboardingAiTitle => 'Gastos con IA';

  @override
  String get onboardingAiBody =>
      'Toma una foto de la factura y la app llena el gasto por ti.';

  @override
  String get onboardingBestCardTitle => 'Mejor tarjeta hoy';

  @override
  String get onboardingBestCardBody =>
      'Te decimos qué tarjeta usar según su fecha de corte para pagar más tarde.';

  @override
  String get onboardingReportsTitle => 'Reportes';

  @override
  String get onboardingReportsBody =>
      'Filtra por fecha, tarjeta, categoría o comercio y mira en qué se va tu dinero.';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginSubtitle => 'Entra para ver tus tarjetas y gastos';

  @override
  String get wrongCredentials => 'Correo o contraseña incorrectos';

  @override
  String tooManyAttemptsRetryIn(String wait) {
    return 'Demasiados intentos. Intenta de nuevo en $wait.';
  }

  @override
  String get fingerprintVerifyFailed => 'No se pudo verificar tu huella';

  @override
  String loginWithFingerprintAs(String name) {
    return 'Entrar con huella como $name';
  }

  @override
  String get noAccount => '¿No tienes cuenta?';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get registerSubtitle => 'Tus datos se guardan solo en este teléfono';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get emailAlreadyRegistered => 'Este correo ya está registrado';

  @override
  String unlockHello(String name) {
    return 'Hola, $name';
  }

  @override
  String get unlockPrompt => 'Usa tu huella para entrar';

  @override
  String get unlockFailed =>
      'No se pudo verificar tu huella. Intenta de nuevo o usa tu contraseña.';

  @override
  String get unlockBlocked =>
      'No pudimos verificar tu huella. Entra con tu contraseña.';

  @override
  String get unlockWithFingerprint => 'Desbloquear con huella';

  @override
  String get usePassword => 'Usar contraseña';

  @override
  String get loginWithPassword => 'Entrar con contraseña';

  @override
  String get biometricReasonUnlock => 'Confirma tu identidad para entrar';

  @override
  String get biometricReasonEnable => 'Confirma tu huella para activarla';

  @override
  String get fieldEmailRequired => 'Escribe tu correo';

  @override
  String get fieldEmailInvalid => 'Correo no válido';

  @override
  String get fieldPasswordRequired => 'Escribe tu contraseña';

  @override
  String fieldPasswordTooShort(int min) {
    return 'Mínimo $min caracteres';
  }

  @override
  String fieldTooLong(int max) {
    return 'Máximo $max caracteres';
  }

  @override
  String get fieldPasswordLettersDigits => 'Debe tener letras y números';

  @override
  String get fieldConfirmRequired => 'Confirma tu contraseña';

  @override
  String get fieldPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get fieldFirstNameRequired => 'Escribe tu nombre';

  @override
  String get fieldLastNameRequired => 'Escribe tu apellido';

  @override
  String get fieldSamePassword => 'Debe ser distinta de la actual';

  @override
  String fieldNotifyDaysRange(int min, int max) {
    return 'Escribe de $min a $max días';
  }

  @override
  String get profileTitle => 'Mi perfil';

  @override
  String get sectionData => 'Datos';

  @override
  String get nameAndSurname => 'Nombre y apellido';

  @override
  String get changeEmail => 'Cambiar correo';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get sectionSecurity => 'Seguridad';

  @override
  String get fingerprintLogin => 'Entrar con huella';

  @override
  String get fingerprintLoginSubtitle => 'Al abrir la app se pide tu huella.';

  @override
  String get fingerprintEnabled => 'Listo: la app te pedirá tu huella.';

  @override
  String get sectionAppearance => 'Apariencia';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get sectionPreferences => 'Preferencias';

  @override
  String get defaultCurrency => 'Moneda predeterminada';

  @override
  String get notifyBefore => 'Avisarme antes de';

  @override
  String get sectionCategories => 'Categorías';

  @override
  String get myCategories => 'Mis categorías';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get logoutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get logoutConfirmBody =>
      'Tus datos quedan guardados en este teléfono.';

  @override
  String get fewerDays => 'Menos días';

  @override
  String get moreDays => 'Más días';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get currentPasswordRequired => 'Escribe tu contraseña actual';

  @override
  String get currentPasswordWrong => 'La contraseña actual no es correcta';

  @override
  String get emailHasAccount => 'Ese correo ya tiene una cuenta';

  @override
  String get emailUpdated => 'Correo actualizado';

  @override
  String currentEmail(String email) {
    return 'Correo actual: $email';
  }

  @override
  String get newEmailLabel => 'Correo nuevo';

  @override
  String get currentPasswordLabel => 'Contraseña actual';

  @override
  String get newPasswordLabel => 'Contraseña nueva';

  @override
  String get confirmNewPasswordLabel => 'Confirmar contraseña nueva';

  @override
  String get passwordUpdated => 'Contraseña actualizada';

  @override
  String get setupTitle => 'Configura tu cuenta';

  @override
  String stepOf(int step, int total) {
    return 'Paso $step de $total';
  }

  @override
  String get setupCurrencyTitle => '¿En qué moneda gastas más?';

  @override
  String get setupCurrencyBody =>
      'Será la moneda que aparece primero en gastos y deudas nuevos.';

  @override
  String get setupCardTitle => 'Agrega tu primera tarjeta';

  @override
  String get setupCardBody => 'Solo guardamos los últimos 4 dígitos.';

  @override
  String get setupFingerprintTitle => 'Entra con tu huella';

  @override
  String get setupFingerprintBody =>
      'Al abrir la app se pedirá tu huella en vez de la contraseña.';

  @override
  String get setupRemindersTitle => 'Recordatorios';

  @override
  String get setupRemindersBody =>
      'Te avisamos antes del corte de tus tarjetas, de la fecha límite de pago y de las deudas por vencer.';

  @override
  String get addCard => 'Agregar tarjeta';

  @override
  String get illDoItLater => 'Lo haré después';

  @override
  String get enableReminders => 'Activar recordatorios';

  @override
  String get cardAdded => 'Tarjeta agregada';

  @override
  String get notificationsDenied =>
      'Sin permiso no podremos avisarte. Puedes darlo luego en los ajustes del teléfono.';

  @override
  String get secQFirstPet => '¿Cómo se llamaba tu primera mascota?';

  @override
  String get secQBirthCity => '¿En qué ciudad naciste?';

  @override
  String get secQPrimarySchool => '¿Cómo se llamaba tu escuela primaria?';

  @override
  String get secQChildhoodFriend =>
      '¿Cómo se llamaba tu mejor amigo de la infancia?';

  @override
  String get secQFirstJob => '¿Dónde fue tu primer trabajo?';

  @override
  String get secQCustom => 'Escribir mi propia pregunta';

  @override
  String get securityQuestionLabel => 'Pregunta de seguridad';

  @override
  String get customQuestionLabel => 'Tu pregunta';

  @override
  String get securityAnswerLabel => 'Respuesta';

  @override
  String get securityAnswerHint => 'No importan las mayúsculas ni las tildes.';

  @override
  String get registerSecurityHint => 'La usarás si olvidas tu contraseña.';

  @override
  String get fieldQuestionChoose => 'Elige una pregunta';

  @override
  String get fieldQuestionRequired => 'Escribe tu pregunta';

  @override
  String get fieldAnswerRequired => 'Escribe tu respuesta';

  @override
  String fieldAnswerTooShort(int min) {
    return 'Mínimo $min caracteres';
  }

  @override
  String get forgotPasswordLink => '¿Olvidaste tu contraseña?';

  @override
  String get forgotTitle => 'Recuperar contraseña';

  @override
  String get forgotEmailSubtitle => 'Escribe el correo de tu cuenta.';

  @override
  String get forgotAnswerSubtitle => 'Responde tu pregunta de seguridad.';

  @override
  String get forgotNewPasswordSubtitle => 'Crea una contraseña nueva.';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get accountNotFound => 'No encontramos una cuenta con ese correo';

  @override
  String get noSecurityQuestion => 'Esta cuenta no tiene pregunta de seguridad';

  @override
  String get wrongAnswer => 'La respuesta no es correcta';

  @override
  String get securityQuestionMissing =>
      'Configura una pregunta para poder recuperar tu contraseña.';

  @override
  String get securityQuestionSaved => 'Pregunta de seguridad guardada';
}
