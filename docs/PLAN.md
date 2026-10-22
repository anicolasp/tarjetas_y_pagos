# Plan: App "Tarjetas y Pagos" (Flutter / Android)

## Contexto
El repo es la plantilla base de Flutter 3.47 (`lib/main.dart` contador + `MarionetteBinding` en debug). Se construye desde cero una app personal de finanzas: registro de tarjetas de crédito, gastos por categoría, deudas, recomendación de "mejor tarjeta hoy" según fecha de corte, reportes con filtros y gráficos, login local (SQLite) con biometría y modo claro/oscuro. UI en español.

## Decisiones tomadas (respuestas del usuario)
| Tema | Decisión |
|---|---|
| OCR tarjeta | Google ML Kit en el dispositivo (la foto no sale del teléfono) |
| OCR factura | Claude API (visión) — `claude-sonnet-5-5`; key vía `--dart-define=ANTHROPIC_API_KEY` (si vacía, se oculta el botón) |
| Número tarjeta | Se leen los 16 dígitos solo para detectar marca; **se guardan solo los últimos 4** |
| Moneda | RD$ y US$ por tarjeta/gasto; totales siempre separados por moneda (sin conversión) |
| Deudas | Balance automático por tarjeta (gastos − pagos) **y** módulo aparte de deudas con abonos |
| Mejor tarjeta | Día de corte + días para pagar + límite de crédito |
| Onboarding | Slides de bienvenida + asistente post-registro + `ONBOARDING.md` para devs |
| Categorías | Base precargadas + personalizadas (ícono y color) |
| Reportes | Lista filtrada + gráficos + totales/resumen (sin exportar) |
| Sesión | Se recuerda; si biometría activa, se pide huella/rostro al abrir |
| Estilo | Material 3, seed teal/azul financiero, claro/oscuro/sistema |
| Alertas | Notificaciones locales antes de corte, fecha límite de pago y vencimiento de deudas |

## Dependencias (`pubspec.yaml`)
`flutter_riverpod`, `go_router`, `sqflite`, `path`, `cryptography` (PBKDF2 para contraseñas), `flutter_secure_storage` (sesión), `shared_preferences` (flags onboarding/tema), `local_auth`, `image_picker`, `google_mlkit_text_recognition`, `http`, `fl_chart`, `intl`, `flutter_local_notifications`, `timezone`, `flutter_timezone`. Dev: `sqflite_common_ffi` (tests). Se conserva `marionette_flutter`.

## Configuración Android
- `android/app/build.gradle.kts`: `minSdk = 23`, desugaring habilitado (requerido por notificaciones).
- `MainActivity.kt` → extender `FlutterFragmentActivity` (requerido por `local_auth`).
- `AndroidManifest.xml`: `CAMERA`, `INTERNET`, `USE_BIOMETRIC`, `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` + receivers de `flutter_local_notifications`; label "Tarjetas y Pagos".

## Arquitectura (`lib/`)
```
main.dart                 # MarionetteBinding en debug (se mantiene), ProviderScope, init tz/notifs
app.dart                  # MaterialApp.router, temas claro/oscuro
core/  theme.dart, router.dart (go_router + redirect por sesión/onboarding),
       formatters.dart (moneda RD$/US$, fechas es_DO), greeting.dart, validators.dart
       billing_cycle.dart     # cálculo de corte / fecha límite / mejor tarjeta (puro, testeable)
       card_detection.dart    # Luhn, marca por BIN, banco por texto OCR (puro, testeable)
data/  database.dart (sqflite, onCreate + migraciones versionadas, seed categorías)
       models/ (user, credit_card, category, expense, card_payment, debt, debt_payment)
       repositories/ (auth, cards, categories, expenses, debts) — todas filtran por user_id
services/ session_service, biometric_service, card_scan_service (ML Kit),
          receipt_ai_service (Claude), notification_service
features/ onboarding/, auth/, setup_wizard/, home/, cards/, expenses/, reports/, debts/, profile/, categories/
          (cada una: screens + providers Riverpod + widgets)
```
Todos los widgets interactivos llevan `ValueKey` (p.ej. `login.email`, `card.save`) para manejarlos con Marionette.

## Esquema SQLite
- `users(id, first_name, last_name, email UNIQUE, password_hash, salt, biometric_enabled, theme_mode, default_currency, notify_days_before, created_at)`
- `cards(id, user_id, alias, bank, brand[visa|mastercard|amex|otra], last4, cut_day 1–31, payment_days, credit_limit, currency, color, archived, created_at)`
- `categories(id, user_id NULL=base, name, icon, color)` — base: Supermercado, Combustible, Barbería, Salón, Belleza, Ferretería, Luz, Agua, Teléfono, Licor, Salud, Restaurante, Otros
- `expenses(id, user_id, card_id, category_id, merchant, amount, currency, date, notes, source[manual|ia], created_at)`
- `card_payments(id, card_id, amount, currency, date, note)`
- `debts(id, user_id, creditor, description, amount, currency, due_date, status[activa|saldada], created_at)`
- `debt_payments(id, debt_id, amount, date, note)`

Contraseñas: PBKDF2-HMAC-SHA256 con salt aleatorio por usuario. Sesión: `user_id` en `flutter_secure_storage`.

## Lógica clave
**Ciclo de facturación** (`billing_cycle.dart`): `nextCut(today, cutDay)` limita el día al último día del mes (p.ej. corte 31 → 30 de abril). Una compra hecha el día de corte entra en ese corte. `dueDate = cut + paymentDays`.
**Mejor tarjeta hoy**: para cada tarjeta, `díasFinanciamiento = (nextCut + paymentDays) − hoy`; disponible = `límite − balance`. Se ordena por días de financiamiento (desc.), se excluyen o marcan las que tienen menos del 10 % de crédito disponible, y se muestra un ranking con explicación ("Corta en 28 días · pagas el 15/dic · 52 días").
**Balance por tarjeta**: Σ gastos − Σ pagos (por moneda); "a pagar este corte" = gastos del último ciclo cerrado − pagos posteriores.
**OCR tarjeta**: ML Kit → regex de 13–19 dígitos + Luhn → `last4` + marca por BIN (4 = Visa; 51–55 o 2221–2720 = Mastercard; 34/37 = Amex). Banco: se busca en el texto una lista de bancos de RD (Banreservas, Popular, BHD, Scotiabank, APAP, Santa Cruz, Promerica, Banesco, Caribe, BDI, Vimenca, López de Haro, Ademi, Cibao, Qik). Lo extraído se precarga en el formulario y el usuario lo confirma. El día de corte siempre es manual porque no viene impreso en la tarjeta.
**OCR factura**: foto (`image_picker`, comprimida a ~1600px) → base64 → `POST https://api.anthropic.com/v1/messages` con `model: claude-sonnet-5-5` y una herramienta con esquema JSON `{merchant, total, currency, date, category}` (la categoría debe ser una de las del usuario). Se precarga el formulario de gasto y el usuario confirma. Si falla, se muestra un mensaje y se sigue con captura manual.

## Pantallas
1. **Onboarding slides** (solo la primera apertura; flag en prefs): 4 slides (tarjetas, gastos con IA, mejor tarjeta, reportes) → Login.
2. **Login**: correo, contraseña, "Crear cuenta", botón de biometría si está habilitada. **Registro**: nombre, apellido, correo, contraseña + confirmación.
3. **Asistente de configuración** (post-registro, se puede omitir): moneda predeterminada → primera tarjeta → biometría → notificaciones.
4. **Home**: header "Buenos días / Buenas tardes / Buenas noches, {nombre}" (5–11:59 / 12–18:59 / resto) + avatar con iniciales (nombre + apellido) → Perfil. Contenido: resumen del mes (gastado RD$/US$, deuda total), tarjeta "Mejor tarjeta hoy", accesos rápidos (Mis Tarjetas, Nuevo gasto, Reportes, Deudas) y carrusel de tarjetas → detalle.
5. **Mis Tarjetas**: lista (alias, banco, logo de marca, •••• 1234, próximo corte, disponible), agregar (manual o "Escanear tarjeta"), editar y archivar.
6. **Detalle de tarjeta**: balance, próximo corte, fecha límite, barra de uso del límite; movimientos agrupados por fecha; filtros (categoría, rango de fechas, comercio, rango de monto); FAB "Nuevo gasto" con la tarjeta preseleccionada; "Registrar pago".
7. **Nuevo/editar gasto**: comercio, categoría, monto, moneda, fecha, tarjeta y notas; botón "Escanear factura (IA)".
8. **Reportes**: filtros (tarjetas, categorías, fechas con atajos Este mes / Mes pasado / 3 meses / Rango, monto mín./máx., comercio). Pestaña Resumen: totales, promedio y cantidad por moneda, pastel por categoría, barras por mes y totales por tarjeta. Pestaña Movimientos: lista filtrada.
9. **Deudas**: lista de deudas activas y saldadas con su progreso; crear y editar; registrar abono. También muestra el balance de cada tarjeta.
10. **Perfil**: editar nombre, cambiar correo y contraseña (piden la contraseña actual), activar biometría (verifica con `local_auth` antes de guardar), tema claro/oscuro/sistema, moneda predeterminada, días de aviso para notificaciones, gestionar categorías, cerrar sesión.

**Notificaciones**: al guardar o editar tarjetas o deudas y al iniciar la app, se reprograman los avisos N días antes del corte, de la fecha límite y del vencimiento de cada deuda.

## Orden de implementación
1. Dependencias, configuración Android, tema, router, base de datos y modelos.
2. Auth (registro, login, sesión, biometría) + onboarding slides.
3. Home + tarjetas (CRUD + escaneo ML Kit) + `billing_cycle` y mejor tarjeta.
4. Gastos (CRUD + filtros + IA de facturas) + detalle de tarjeta + pagos.
5. Reportes (filtros + fl_chart).
6. Deudas + abonos.
7. Perfil, categorías personalizadas, notificaciones y asistente de configuración.
8. `ONBOARDING.md` (arquitectura, cómo correr con `--dart-define`, esquema de BD, flujo con Marionette) y actualización del README.

## Verificación
- `flutter analyze` sin errores.
- `flutter test`: unit tests de `billing_cycle` (fin de mes, compras el día de corte, cambio de año, ranking), `card_detection` (Luhn, BIN, banco), hashing de contraseñas, repositorios con `sqflite_common_ffi` (aislamiento por usuario, balances) y saludo por hora; widget test del login.
- `flutter run -d <emulador Android> --dart-define=ANTHROPIC_API_KEY=...` → conectar Marionette MCP y recorrer: slides → registro → asistente → crear 2 tarjetas → gasto manual → gasto desde detalle (tarjeta preseleccionada) → filtros → reportes → deuda + abono → perfil (tema oscuro, cambio de contraseña) → logout/login, con capturas de pantalla en cada paso.
- El escaneo con cámara, la biometría y las notificaciones se prueban en el emulador (huella simulada, imagen de cámara virtual) o en un dispositivo físico, ya que Marionette no puede inyectar fotos reales.
