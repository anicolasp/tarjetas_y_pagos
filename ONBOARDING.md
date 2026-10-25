# Onboarding (desarrollo)

Guía para que una persona (o un agente) entienda, corra y pruebe
**Tarjetas y Pagos** desde cero. Si algo de aquí no funciona en un clon
limpio, es un bug de esta guía: corrígela en el mismo PR.

## 1. Requisitos

| Herramienta | Versión usada |
|---|---|
| Flutter | 3.47 (stable), con Dart 3.13 |
| JDK | 17 (`JAVA_HOME` apuntando a él para compilar Android) |
| Android SDK | con `platform-tools` (adb) y un emulador, p. ej. Pixel 8 con API 34 o superior |
| GitHub CLI | `gh`, autenticado (`gh auth login`); se usa en el flujo de issues y PRs |

Comprueba todo con `flutter doctor`. En macOS con Homebrew, el JDK queda en
`/opt/homebrew/opt/openjdk@17`.

## 2. Primeros pasos

```bash
git clone https://github.com/anicolasp/tarjetas_y_pagos.git
cd tarjetas_y_pagos
flutter pub get
flutter analyze          # debe decir "No issues found!"
flutter test             # todos en verde (~900 tests, ~40 s)
```

Arranca un emulador (Android Studio → Device Manager, o
`flutter emulators --launch <id>`) y corre la app:

```bash
flutter devices                    # anota el id, p. ej. emulator-5554
flutter run -d emulator-5554
```

La primera vez verás las slides de bienvenida → login. Crea una cuenta
con datos ficticios (p. ej. `ana@example.com` / `abc12345`); después del
registro aparece el asistente de configuración.

### Clave de la IA (escaneo de facturas, opcional)

El botón **Escanear factura (IA)** solo aparece si la app se compila con
`ANTHROPIC_API_KEY`. La clave **nunca** se sube al repositorio.

1. Crea `dart_defines.local.json` en la raíz del proyecto (ya está en
   `.gitignore`):

   ```json
   { "ANTHROPIC_API_KEY": "sk-ant-..." }
   ```

2. Corre o compila con:

   ```bash
   flutter run --dart-define-from-file=dart_defines.local.json
   flutter build apk --dart-define-from-file=dart_defines.local.json
   ```

Sin el archivo, la app funciona igual y el botón no aparece. Nunca
imprimas ni pegues la clave en issues, PRs, logs o capturas.

## 3. Arquitectura

```
lib/
  main.dart        MarionetteBinding (solo debug), prefs, ProviderScope
  app.dart         MaterialApp.router, tema, recordatorios
  core/            lógica pura y testeable: ciclo de facturación, estado de
                   cuenta, dinero, formatos, validaciones, router, tema,
                   responsive, plan de recordatorios
  data/            SQLite (database.dart + migraciones), modelos,
                   repositorios (todo filtrado por user_id), FinanceSnapshot
  services/        plugins detrás de interfaces (sesión, biometría, OCR de
                   tarjeta, IA de facturas, tasa de cambio, notificaciones)
  features/<x>/    pantallas + providers Riverpod de cada funcionalidad:
                   splash, onboarding, auth, setup_wizard, home, cards,
                   expenses, scan, reports, debts, profile, categories,
                   notifications
```

Reglas que se respetan en todo el código:

- **Riverpod 3** para estado y dependencias. Todo servicio externo tiene un
  provider que los tests reemplazan por un fake: casi todos en
  `services/providers.dart`; la tasa de cambio en
  `features/cards/cards_providers.dart` y el reloj (`clockProvider`) en
  `core/clock.dart`.
- **Una sola fuente de verdad financiera:** `financeProvider`
  (`features/cards/cards_providers.dart`) carga tarjetas, gastos, pagos,
  deudas y abonos del usuario en un `FinanceSnapshot`. Home, tarjetas,
  reportes, deudas y recordatorios derivan de ahí. Después de cualquier
  cambio se llama `refreshFinance(ref)` (o `refreshCategories(ref)`).
- **Router** (`core/router.dart`, go_router): `authRedirect` decide a dónde
  ir según el estado: slides → login → desbloqueo con huella → asistente
  pendiente → Home. Las pantallas privadas cuelgan de `/home/...` para que
  "atrás" nunca cierre la app. El router vuelve a evaluar el redirect
  cuando cambia el *tipo* de estado de auth (no en cada edición del
  perfil), la bandera de las slides o la del asistente pendiente.
- **Dinero en centavos (`int`)** y monedas RD$ (`DOP`) / US$ (`USD`) que
  nunca se suman entre sí: todo total va por moneda.
- **De una tarjeta solo se guardan los últimos 4 dígitos.** El OCR (ML Kit,
  en el teléfono) lee el número completo solo para detectar la marca.
- **Responsive (regla #2):** toda pantalla usa `ResponsiveCenter` /
  `CenteredScrollView` (`core/responsive.dart`) y se prueba en
  `responsiveCases` (teléfono pequeño, horizontal, tablet, texto ×2).
- **Widgets interactivos con `ValueKey`** (`'login.email'`,
  `'cardForm.save'`…) para los tests y para Marionette.

## 4. Base de datos

SQLite con `sqflite` (`sqflite_common_ffi` en los tests). Archivo:
`lib/data/database.dart`.

| Tabla | Qué guarda | Reglas (CHECK / FK) |
|---|---|---|
| `users` | nombre, correo único (NOCASE), hash + salt de la contraseña, biometría, tema, moneda predeterminada, días de aviso | tema ∈ system/light/dark; moneda ∈ DOP/USD |
| `cards` | alias, banco, marca, `last4`, día de corte, días para pagar, límite, moneda, color, archivada; desde v2 `dual_currency` y `secondary_limit_cents` | `last4` = 4 dígitos; corte 1–31; días de pago 0–60 |
| `categories` | `user_id` NULL = base (13 precargadas), si no, propia del usuario | nombre único por dueño, sin distinguir mayúsculas |
| `expenses` | tarjeta, categoría, comercio, monto, moneda, fecha, notas, origen (`manual`/`ia`); desde v2, monto/moneda original y tasa si se convirtió | FK compuesta (tarjeta, usuario): un gasto no puede apuntar a la tarjeta de otro |
| `card_payments` | pagos a una tarjeta | monto > 0 |
| `debts` | acreedor, descripción, monto, moneda, vencimiento, estado (`activa`/`saldada`) | el estado se mantiene al día en la misma transacción del abono |
| `debt_payments` | abonos a una deuda | monto > 0 |

Las fechas se guardan como texto ISO-8601.

**Migraciones:** `_migrations` es una lista; el índice 0 lleva a la
versión 1 (`_v1`), el 1 a la versión 2 (`_v2`), etc. Para cambiar el
esquema:

1. Agrega una función `_v3` al final y súmala a `_migrations`. Nunca edites
   una migración que ya está en `main`.
2. Agrega un caso en `test/data/migration_test.dart` que abra una base en la
   versión anterior, migre y verifique los datos.

**Contraseñas:** PBKDF2-HMAC-SHA256 con salt aleatorio por usuario
(`services/password_hasher.dart`). Tras 5 intentos fallidos, el correo se
bloquea 30 s, luego 60 s, 120 s…, hasta un máximo de 15 min; los fallos de
más de 15 min se olvidan (`services/login_throttle.dart`). La sesión
(id del usuario) vive en `flutter_secure_storage`.

## 5. Lógica del dominio

Todo es puro y está en `lib/core/`, con tests en `test/core/`.

**Ciclo de facturación** (`billing_cycle.dart`), siempre en fechas sin hora
(`dateOnly`):

- `cutInMonth`: el día de corte se ajusta al largo del mes (corte 31 en
  abril → 30 de abril).
- `nextCut`: la fecha en que cierra el estado abierto hoy. **Una compra
  hecha el mismo día de corte entra en ese corte.**
- `dueDate = corte + días para pagar`.
- **Mejor tarjeta hoy** (`rankCards`): primero las tarjetas con al menos
  10 % de crédito disponible; dentro de cada grupo, más días de
  financiamiento (`financingDays`), luego más disponible y luego alias.

**Estado de cuenta** (`statement.dart`): por moneda, balance, lo que se
debe del último corte cerrado y lo vencido. `payBy()` da la fecha de pago
que importa hoy (un corte vencido, el corte cerrado pendiente o el próximo).

**Recordatorios** (`notification_plan.dart` + `features/notifications/`):
a las 9:00 hora local, N días antes (configurable en el perfil) del
próximo corte, de la fecha límite de pago (solo si la tarjeta debe algo) y
del vencimiento de cada deuda activa. IDs estables
`id de entidad × 4 + tipo`. Se replanifican en cada carga del
`FinanceSnapshot` y se cancelan al cerrar sesión. Las alarmas son
inexactas (pueden llegar hasta ~1 h tarde).

**Tasa US$→RD$** (`services/exchange_rate_service.dart`): se usa al
registrar un gasto en otra moneda que la tarjeta. Se guarda en caché 12 h y
después se vuelve a consultar en línea; la tasa usada queda guardada con el
gasto.

## 6. Tests

```bash
flutter test                                  # todo
flutter test test/features/profile_test.dart  # un archivo
flutter test --name "archiving"               # por nombre
```

- `test/core`: lógica pura. `test/data`: repositorios y migraciones contra
  una base en memoria (`test/helpers/test_db.dart`). `test/features`:
  la app completa con `testApp(await testOverrides(...))`.
- `testOverrides` (`test/helpers/fakes.dart`) reemplaza lo externo:
  almacenamiento seguro, biometría, cámara/OCR, IA, tasa de cambio y
  notificaciones siempre; la base de datos y el reloj solo si los pasas
  (`database: Future.value(await openTestDatabase())`, `now: …`). **Pasa
  siempre `database:`** en los tests de pantallas: sin él se intenta abrir
  la base real y el test se cuelga. Ningún test toca la red ni un plugin
  real. Si agregas un servicio, agrega su fake ahí.
- `seedUser`, `seedCard`, `seedExpense` (`test/helpers/seed.dart`) crean
  datos ficticios. La contraseña de prueba es `abc12345`.
- Cada pantalla nueva lleva su matriz responsive:
  `for (final c in responsiveCases) … setScreen(tester, c.size, c.textScale)`,
  en claro y oscuro, y verifica `tester.takeException()` nulo.
- Usa siempre datos ficticios (`@example.com`, nombres inventados).

## 7. Pruebas E2E con Marionette MCP

[Marionette](https://pub.dev/packages/marionette_flutter) deja que un
agente (Claude Code) maneje la app en el emulador: tocar, escribir, hacer
scroll, capturas y hot reload. En debug, `main.dart` ya inicializa
`MarionetteBinding` y `MarionetteDeviceConfig` (para cambiar tema y tamaño
de texto desde el agente).

Instalación (una vez):

```bash
dart pub global activate marionette_mcp
claude mcp add marionette -- marionette_mcp
```

Uso:

1. `flutter run -d emulator-5554` y copia la URI del VM service que imprime
   (`ws://127.0.0.1:PUERTO/.../ws`).
2. En Claude Code: `connect` con esa URI, luego `get_interactive_elements`,
   `tap` / `enter_text` por `key`, `scroll_to`, `take_screenshots`.
3. Visual: `set_device_config` con `platform_brightness: dark` y
   `text_scale: 2`; para horizontal:
   `adb shell settings put system accelerometer_rotation 0` y
   `adb shell settings put system user_rotation 1`. Para volver a
   vertical: `user_rotation 0` y `accelerometer_rotation 1`.

Trucos aprendidos:

- Si `hot_restart` se cuelga, detén `flutter run` y vuelve a lanzarlo.
- Las pestañas (Tab) se tocan mejor por su **texto** que por su key.
- `scroll_to` se detiene sobre los gráficos; los gráficos usan
  `onTapUp` en vez del touch de fl_chart para no robar el scroll vertical
  (verifícalo con `adb shell input swipe`).
- Encadenar muchas acciones falla si una pantalla tarda en abrir: después
  de una navegación, toma una captura antes de seguir.
- **Selector de fotos** (escaneo de tarjeta/factura): sube una imagen con
  `adb push img.jpg /sdcard/Pictures/`, avisa al sistema con
  `adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/img.jpg`,
  y toca la miniatura con `adb shell uiautomator dump` + `adb shell input tap X Y`.
- **Diálogos del sistema** (permisos): `adb shell uiautomator dump` y busca
  el botón "Allow" para tocarlo con `adb shell input tap`. Para volver a
  ver el diálogo de notificaciones:
  `adb shell pm revoke <paquete> android.permission.POST_NOTIFICATIONS` y
  `adb shell pm clear-permission-flags <paquete> android.permission.POST_NOTIFICATIONS user-set user-fixed`.
- **Recordatorios pendientes:**
  `adb shell dumpsys alarm | grep -A2 "tarjetas_y_pagos/com.dexterous"`
  muestra cada alarma con su `origWhen`.
- La biometría real no se puede probar si el emulador no tiene una huella
  registrada; en ese caso se verifica la ruta "no disponible" y el resto
  con widget tests.

Las capturas de los issues #1–#8 están en `docs/screenshots/issue-N/`
(#9 y #10 no guardaron capturas; su verificación está descrita en los
PRs #23 y #24) y las del README en
`docs/screenshots/readme/`.

## 8. Flujo de trabajo

El trabajo se organiza en un **epic** (#12) con un issue por fase, usando
dos skills de Claude Code que viven en `.claude/skills/`:

- **`task-write`**: convierte un plan en epic + issues con clasificación,
  especificación UX, flujo E2E y criterios de aceptación.
- **`pick-issue #N`**: reserva el issue, crea la rama `feat/<slug>`,
  presenta un plan y **espera aprobación**, implementa, corre
  `flutter analyze` + `flutter test`, hace los gates que pide la
  clasificación (visual y E2E con Marionette, validación de la
  especificación), corre `code-review`, abre el PR con `Closes #N` y el
  bloque de gates, y vuelve a `main`.

Reglas del proyecto:

- **Nunca se hace merge sin autorización explícita del dueño para ese PR.**
- Una rama y un PR por issue.
- Nunca `git add -A` ni `git add .`: se agregan archivos explícitos.
- Nunca se suben claves, `.env` ni `dart_defines.local.json`. El repo es
  **público**.
- Solo datos ficticios en código, tests, capturas e issues.
- Commits en formato conventional (`feat(cards): … (#3)`), terminados en
  `Skill-Used: …` y la línea `Co-Authored-By` correspondiente.

## 9. Riesgos conocidos

- **La clave de Anthropic queda embebida en el APK (#6).** Alguien con el
  APK podría extraerla. Usa una clave con límite de gasto y no distribuyas
  el APK fuera del equipo. La foto de la factura se envía a la API
  (`claude-sonnet-5-5`) una sola vez y se borra del teléfono al terminar.
  Falta verificar el escaneo con la API real (#19).
- **Permiso de notificaciones:** hoy solo se pide en el asistente de
  configuración. Un usuario existente, o uno que eligió "Ahora no", debe
  darlo en los ajustes del teléfono.
- **Recordatorios:** son alarmas inexactas y solo se programa la próxima
  ocurrencia de cada uno; alcanza si la app se abre al menos una vez por
  ciclo.
- **Tasa de cambio:** depende de un servicio en línea; sin conexión se usa
  la última tasa conocida (con aviso) o se escribe a mano.
- **Contraseña:** no hay recuperación; si se olvida y no hay huella
  activada, la cuenta local no se puede recuperar.
