# Onboarding (desarrollo)

> Documento en construcción: la guía completa (arquitectura, base de datos y
> flujo con Marionette) llega con el issue #11.

## Clave de la IA (escaneo de facturas)

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

Sin el archivo, la app funciona igual y el botón no aparece.

**Riesgo aceptado (#6):** la clave queda embebida en el APK y alguien con el
APK podría extraerla. Usa una clave con límite de gasto y no distribuyas el
APK fuera del equipo. La foto de la factura se envía a la API de Anthropic
(`claude-sonnet-5-5`) una sola vez y se borra del teléfono al terminar.
