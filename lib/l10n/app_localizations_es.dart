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

  @override
  String greetingMorning(String name) {
    return 'Buenos días, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Buenas tardes, $name';
  }

  @override
  String greetingNight(String name) {
    return 'Buenas noches, $name';
  }

  @override
  String cutsIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Corta en $days días',
      one: 'Corta mañana',
      zero: 'Corta hoy',
    );
    return '$_temp0';
  }

  @override
  String recommendationLine(String cut, String due, String days) {
    return '$cut · pagas el $due · $days';
  }

  @override
  String get receiptErrorOffline =>
      'Sin conexión a internet. Completa el gasto a mano.';

  @override
  String get receiptErrorTimeout =>
      'La IA tardó demasiado. Intenta de nuevo o completa a mano.';

  @override
  String get receiptErrorInvalidKey =>
      'La clave de la IA no es válida. Completa el gasto a mano.';

  @override
  String get receiptErrorRateLimited =>
      'La IA está recibiendo muchas solicitudes. Intenta en un rato.';

  @override
  String get receiptErrorUnavailable =>
      'La IA no está disponible ahora. Completa el gasto a mano.';

  @override
  String get receiptErrorImageTooLarge =>
      'La foto es demasiado grande. Prueba con otra.';

  @override
  String get receiptErrorInvalidResponse =>
      'No pudimos leer la factura. Completa el gasto a mano.';

  @override
  String get fieldCardAliasRequired => 'Escribe un nombre para la tarjeta';

  @override
  String get fieldCardBankRequired => 'Escribe el banco';

  @override
  String get fieldCardLast4Invalid => 'Escribe los últimos 4 dígitos';

  @override
  String get fieldCardCutDayRange => 'El día de corte va del 1 al 31';

  @override
  String get fieldCardPaymentDaysRange => 'Los días para pagar van de 0 a 60';

  @override
  String get fieldCardLimitInvalid => 'Límite no válido';

  @override
  String get fieldCardDualMustBeDop =>
      'Una tarjeta de doble balance es RD\$ y US\$';

  @override
  String get fieldCardCurrencyInUse =>
      'Esta tarjeta tiene movimientos en esa moneda; no puedes quitarla';

  @override
  String get fieldAmountInvalid => 'Monto no válido';

  @override
  String get fieldNoBalanceInCurrency =>
      'La tarjeta no tiene balance en esa moneda';

  @override
  String get fieldMerchantRequired => 'Escribe el comercio';

  @override
  String get fieldConversionInvalid => 'Conversión no válida';

  @override
  String get fieldCategoryRequired => 'Elige una categoría';

  @override
  String get fieldCardRequired => 'Elige una tarjeta';

  @override
  String get fieldDateInFuture => 'La fecha no puede ser futura';

  @override
  String get fieldCategoryNameRequired => 'Escribe un nombre';

  @override
  String get fieldCategoryIconInvalid => 'Ícono no válido';

  @override
  String get fieldCategoryColorInvalid => 'Color no válido';

  @override
  String get fieldCategoryNameTaken => 'Ya tienes una categoría así';

  @override
  String get fieldCategoryReassignOther => 'Elige otra categoría';

  @override
  String get catSupermarket => 'Supermercado';

  @override
  String get catFuel => 'Combustible';

  @override
  String get catBarbershop => 'Barbería';

  @override
  String get catSalon => 'Salón';

  @override
  String get catBeauty => 'Belleza';

  @override
  String get catHardware => 'Ferretería';

  @override
  String get catElectricity => 'Luz';

  @override
  String get catWater => 'Agua';

  @override
  String get catPhone => 'Teléfono';

  @override
  String get catLiquor => 'Licor';

  @override
  String get catHealth => 'Salud';

  @override
  String get catRestaurant => 'Restaurante';

  @override
  String get catOther => 'Otros';

  @override
  String get myCards => 'Mis tarjetas';

  @override
  String get seeAll => 'Ver todas';

  @override
  String get cardsLoadError => 'No se pudieron cargar tus tarjetas';

  @override
  String monthSummary(String month) {
    return 'Resumen de $month';
  }

  @override
  String get spentThisMonth => 'Gastado este mes';

  @override
  String get totalDebt => 'Deuda total';

  @override
  String debtSplit(String cards, String other) {
    return 'Tarjetas $cards · Otras deudas $other';
  }

  @override
  String get bestCardToday => 'Mejor tarjeta hoy';

  @override
  String get bestCardEmpty =>
      'Agrega una tarjeta para saber cuál te conviene usar hoy.';

  @override
  String get lowCredit => 'Poco crédito disponible';

  @override
  String get newExpense => 'Nuevo gasto';

  @override
  String get reports => 'Reportes';

  @override
  String get debts => 'Deudas';

  @override
  String get noCardsYet => 'Aún no tienes tarjetas.';

  @override
  String get add => 'Agregar';

  @override
  String get noCardsYetTitle => 'Aún no tienes tarjetas';

  @override
  String get addFirstCardHint =>
      'Agrega tu primera tarjeta para saber cuál te conviene usar cada día.';

  @override
  String cutOn(String date) {
    return 'Corte $date';
  }

  @override
  String get availableNone => 'Disponible —';

  @override
  String availableAmount(String amount) {
    return 'Disponible $amount';
  }

  @override
  String get dualBalance => 'RD\$ y US\$';

  @override
  String get cardNotFound => 'Tarjeta no encontrada';

  @override
  String get registerPayment => 'Registrar pago';

  @override
  String get fieldAmountPositive => 'Escribe un monto mayor que 0';

  @override
  String get amountPaid => 'Monto pagado';

  @override
  String payStatementDue(String amount) {
    return 'Pagar lo de este corte: $amount';
  }

  @override
  String get paymentDate => 'Fecha del pago';

  @override
  String get noteOptional => 'Nota (opcional)';

  @override
  String get card => 'Tarjeta';

  @override
  String get filterExpenses => 'Filtrar gastos';

  @override
  String get editCard => 'Editar tarjeta';

  @override
  String get movements => 'Movimientos';

  @override
  String get clearFilters => 'Quitar filtros';

  @override
  String get filterError => 'No se pudieron filtrar los gastos';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get nextCut => 'Próximo corte';

  @override
  String get nextCutDue => 'Fecha límite de ese corte';

  @override
  String get payInIfUsedToday => 'Si la usas hoy, pagas en';

  @override
  String daysCountPlain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
      zero: '0 días',
    );
    return '$_temp0';
  }

  @override
  String creditInFavor(String currency) {
    return 'Saldo a favor ($currency)';
  }

  @override
  String balanceIn(String currency) {
    return 'Balance ($currency)';
  }

  @override
  String availableOf(String available, String limit) {
    return 'Disponible $available de $limit';
  }

  @override
  String get dueThisStatement => 'A pagar este corte';

  @override
  String payBefore(String date) {
    return 'Paga antes del $date';
  }

  @override
  String overdueSince(String amount, String date) {
    return 'Vencido: $amount desde el $date';
  }

  @override
  String get noCategory => 'Sin categoría';

  @override
  String convertedAt(String amount, String rate) {
    return '$amount a $rate';
  }

  @override
  String get deletePaymentTitle => '¿Eliminar este pago?';

  @override
  String deletePaymentBody(String amount) {
    return 'El balance volverá a subir $amount.';
  }

  @override
  String get payment => 'Pago';

  @override
  String get noExpensesMatch => 'Ningún gasto coincide con los filtros';

  @override
  String get noMovementsYet => 'Aún no hay movimientos en esta tarjeta';

  @override
  String get tapNewExpenseHint =>
      'Toca \"Nuevo gasto\" para registrar el primero.';

  @override
  String get cardScanNothing =>
      'No pudimos leer la tarjeta, completa los datos manualmente';

  @override
  String get scanPurposeCard =>
      'Lo usamos solo para leer la tarjeta en tu teléfono. La foto no se guarda ni se envía, y solo conservamos los últimos 4 dígitos.';

  @override
  String get scanPurposeReceipt =>
      'Lo usamos solo para leer la factura con la IA. La foto se envía una sola vez para leerla y no se guarda.';

  @override
  String get archiveCardTitle => '¿Archivar esta tarjeta?';

  @override
  String get archiveCardBody =>
      'Dejará de aparecer en tus listas y en la recomendación. Sus datos se conservan.';

  @override
  String get archive => 'Archivar';

  @override
  String get newCard => 'Nueva tarjeta';

  @override
  String get scanCard => 'Escanear tarjeta';

  @override
  String get scanCardHint =>
      'Leemos la foto en tu teléfono y solo guardamos los últimos 4 dígitos.';

  @override
  String get cardAliasLabel => 'Nombre (ej. Gastos del mes)';

  @override
  String get detectedByPhoto => 'Detectado por foto';

  @override
  String get brand => 'Marca';

  @override
  String get brandOther => 'Otra';

  @override
  String get last4Label => 'Últimos 4 dígitos';

  @override
  String get last4Helper => 'Nunca guardamos el número completo';

  @override
  String get fieldCutDay => 'Escribe un día del 1 al 31';

  @override
  String get cutDayLabel => 'Día de corte';

  @override
  String get cutDayHelper => 'Si el mes es más corto, se usa el último día';

  @override
  String get fieldPaymentDays => 'Escribe de 0 a 60 días';

  @override
  String get paymentDaysLabel => 'Días para pagar después del corte';

  @override
  String get currency => 'Moneda';

  @override
  String get dualBalanceOption => 'RD\$ y US\$ (doble balance)';

  @override
  String get dualBalanceHint =>
      'Cada gasto queda en su moneda, con un límite por moneda.';

  @override
  String get singleCurrencyHint =>
      'Los gastos en otra moneda se convierten a esta.';

  @override
  String get fieldLimitInvalid => 'Monto no válido (ej. 50000 o 50,000.00)';

  @override
  String get limitDopOptional => 'Límite en RD\$ (opcional)';

  @override
  String get creditLimitOptional => 'Límite de crédito (opcional)';

  @override
  String get limitUsdOptional => 'Límite en US\$ (opcional)';

  @override
  String get color => 'Color';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get archiveCard => 'Archivar tarjeta';

  @override
  String get readingCard => 'Leyendo la tarjeta…';

  @override
  String get bank => 'Banco';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get pickFromGallery => 'Elegir de la galería';

  @override
  String get permissionAltGallery =>
      'Puedes activarla en los ajustes o elegir una foto de la galería.';

  @override
  String get permissionAltCamera =>
      'Puedes activarlo en los ajustes o tomar una foto con la cámara.';

  @override
  String get allowCamera => 'Permite el uso de la cámara';

  @override
  String get allowPhotos => 'Permite el acceso a tus fotos';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get openSettingsHint =>
      'Abre los ajustes del teléfono para permitirlo';

  @override
  String get expenseLoadError => 'No se pudo cargar el gasto';

  @override
  String get expenseNotFound => 'Gasto no encontrado';

  @override
  String get newExpenseTitle => 'Nuevo gasto';

  @override
  String get editExpense => 'Editar gasto';

  @override
  String get addCardFirst =>
      'Primero agrega una tarjeta para registrar gastos.';

  @override
  String get deleteExpenseTitle => '¿Eliminar este gasto?';

  @override
  String get deleteExpenseBody => 'Se quitará de la tarjeta y de los reportes.';

  @override
  String get scanReceipt => 'Escanear factura (IA)';

  @override
  String get scanReceiptHint =>
      'La IA lee la foto y propone los datos; tú los revisas antes de guardar. La foto no se guarda.';

  @override
  String get merchant => 'Comercio';

  @override
  String get category => 'Categoría';

  @override
  String get archivedCardExpense =>
      'La tarjeta de este gasto está archivada: puedes eliminarlo, pero no editarlo.';

  @override
  String get expenseCurrency => 'Moneda del gasto';

  @override
  String get amount => 'Monto';

  @override
  String recordedOnCardAs(String amount) {
    return 'Se registra en la tarjeta como $amount';
  }

  @override
  String get date => 'Fecha';

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String get saveExpense => 'Guardar gasto';

  @override
  String get deleteExpense => 'Eliminar gasto';

  @override
  String get readingReceipt => 'Leyendo factura…';

  @override
  String get aiChip => 'IA';

  @override
  String get rateLoading => 'Buscando la tasa de hoy…';

  @override
  String get rateOnline =>
      'Tasa en línea de hoy. Puedes ajustarla a la de tu banco.';

  @override
  String get rateStale => 'Sin conexión: última tasa conocida. Revísala.';

  @override
  String get rateUnavailable => 'No se pudo obtener la tasa. Escríbela.';

  @override
  String get rateIdle => 'Tasa usada en la conversión.';

  @override
  String get fieldRateRequired => 'Escribe la tasa (ej. 61.40)';

  @override
  String get rateLabel => 'Tasa (RD\$ por US\$ 1)';

  @override
  String get refreshRate => 'Buscar la tasa de hoy';

  @override
  String get allDates => 'Todas las fechas';

  @override
  String get merchantContains => 'Comercio contiene';

  @override
  String get minAmount => 'Monto mínimo';

  @override
  String get maxAmount => 'Monto máximo';

  @override
  String get apply => 'Aplicar';

  @override
  String get newCategory => 'Nueva categoría';

  @override
  String get editCategory => 'Editar categoría';

  @override
  String get noOwnCategories => 'Aún no has creado categorías.';

  @override
  String get includedCategories => 'Incluidas';

  @override
  String get includedCategoriesHint =>
      'Vienen con la app y no se pueden cambiar.';

  @override
  String get categoriesLoadError => 'No se pudieron cargar las categorías';

  @override
  String get categoryNotFound => 'Categoría no encontrada';

  @override
  String deleteNamedTitle(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get categoryNoExpenses => 'No tiene gastos.';

  @override
  String get categoryNameLabel => 'Nombre (ej. Mascotas)';

  @override
  String get icon => 'Ícono';

  @override
  String colorNumber(int n) {
    return 'Color $n';
  }

  @override
  String get createCategory => 'Crear categoría';

  @override
  String get deleteCategory => 'Eliminar categoría';

  @override
  String categoryHasExpenses(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '\"$name\" tiene $count gastos',
      one: '\"$name\" tiene 1 gasto',
    );
    return '$_temp0';
  }

  @override
  String get reassignHint => 'Para eliminarla, elige a qué categoría pasan.';

  @override
  String get moveTo => 'Pasar a';

  @override
  String get moveAndDelete => 'Mover y eliminar';
}
