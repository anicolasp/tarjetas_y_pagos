---
name: pick-issue
description: Toma un issue de GitHub y lo lleva por reserva, clasificación, rama, plan aprobado, implementación, verificación, revisión y PR, sin hacer merge nunca. Úsalo cuando el usuario diga "pick issue #N", "pick-issue #N", "toma el issue #N" o "trabaja en el issue #N".
argument-hint: "#<número de issue>"
---

# pick-issue

Flujo ligero para tomar un issue de GitHub y llevarlo hasta un pull request. Issue solicitado: **$ARGUMENTS**

## 1. Anunciar y reservar el issue
Antes de tocar código:
- Lee los comentarios del issue (`gh issue view <N> --comments`) y revisa si otro agente lo reclamó en las últimas 24 horas.
- Busca PRs relacionados: `gh pr list --state all --search "<N> in:body"`.
- Si es seguro continuar, comenta en el issue la reserva, con la ruta del working tree y la rama que vas a usar.
- Si hay una reserva de menos de 24 horas, **detente y pregunta al operador**.

## 2. Leer el contexto del proyecto y del issue
Lee estos documentos si existen: `AGENTS.md`, `CLAUDE.md`, `ONBOARDING.md`, `.claude/skills/CONTRACT.md`, el plan en `~/.claude/plans/` y el epic padre (`Parte de #<epic>`).
Lee el issue completo (`gh issue view <N>`) y anota: título, prioridad, agente asignado, archivos clave, dependencias y criterios de aceptación.
Si alguna dependencia (`#issue`) no está mergeada, detente y pregunta.

## 3. Revisar la especificación y derivar los gates
Antes de crear la rama o cambiar código, revisa en este orden:
1. `## Issue Classification`
2. `## UX/UI Spec`, cuando la superficie UX es `minor` o `major`
3. `## E2E Flow Required`, cuando el flujo tiene varios pasos

Si falta `## Issue Classification`, **detente** y pide aprobación para refinar el issue. Si falta una sección de UX/UI o de E2E que la clasificación exige, pide primero el refinamiento.

Gates según la clasificación:
- UX `minor` o `major` → **verificación visual**: capturas con Marionette MCP en claro y oscuro.
- Flujo de varios pasos `yes` → **verificación E2E**: recorrer el flujo completo con Marionette MCP sobre el emulador de Android.
- Riesgo `high`, `Money logic: yes` (o `money/fiscal: yes`) o `Auth/security: yes` (o `permissions/auth: yes`) → **validación de la especificación** (paso 6).

Elige el enfoque de implementación: feature de Flutter, SQL/migraciones, bug fix, refactor o trabajo entre varias capas.

## 4. Crear y verificar la rama
```bash
git checkout main
git pull
git checkout -b feat/<slug-descriptivo-del-issue>
git branch --show-current
```
No implementes nada hasta confirmar que estás en la rama correcta. Si hay PRs en paralelo, usa un worktree aparte.

## 5. Investigar y planear
Revisa los archivos clave del issue y el código cercano: comportamiento actual, dependencias, imports/exports, estructura de módulos y reglas de negocio.

Presenta un plan corto con:
- Archivos que vas a cambiar y qué cambia en cada uno
- Orden de implementación y dependencias
- Si hace falta generar código (`build_runner`) o migraciones de la base de datos
- Riesgos y casos borde
- **Decisión Capability-First:**
  - **Outcome:** el flujo completo para el usuario o el operador
  - **Evidence:** las búsquedas que hiciste y la implementación existente más cercana que revisaste
  - **Decision:** reutilizar, extender o crear, y por qué
  - **Boundary:** las reglas de dominio que deben quedar explícitas
  - **Metadata:** qué debería ser configurable y por qué
- Los gates derivados y el enfoque elegido

**Espera la aprobación del usuario antes de implementar**, a menos que ya la haya dado para este issue.

## 6. Validar la especificación cuando haga falta
Si el riesgo es alto, o el issue toca dinero/finanzas o permisos/autenticación, valida que la especificación sea suficiente antes de implementar:
- Si es suficiente, documéntalo y continúa.
- Si es vaga, detente y pide aprobación para refinar el issue.
- Si el refinamiento se rechaza, documenta la decisión y continúa, dejando la limitación explícita.

## 7. Implementar dentro del alcance
- Respeta las reglas de negocio del issue y no toques archivos fuera de su alcance.
- Lee cada archivo justo antes de editarlo.
- Si hay diseño de base de datos, crea la migración antes del código que depende de ella.
- Regenera el código generado cuando cambien modelos o providers generados.
- Usa `ValueKey` en los widgets interactivos nuevos para que Marionette pueda encontrarlos.
- Nunca subas secretos (API keys, `.env`) ni cambios ajenos al issue.

## 8. Verificar
Revisa cada criterio de aceptación y ejecuta:
```bash
flutter analyze
flutter test
git diff --stat   # sin cambios ajenos al issue
```
Ejecuta además los gates visuales y E2E con Marionette MCP: `flutter run` en el emulador, `connect`, recorrer el flujo y `take_screenshots`.
Corrige los errores en los archivos que cambiaste y documenta aparte los problemas que ya existían.

## 9. Commit y revisión
- Confirma con `git branch --show-current` que estás en la rama del issue.
- Agrega solo archivos explícitos. **Nunca uses `git add -A` ni `git add .`.**
- Usa conventional commits que referencien el issue, por ejemplo `feat(cards): CRUD de tarjetas (#12)`.
- Termina cada commit con `Skill-Used: pick-issue` (más cualquier otro skill que hayas usado) y la línea `Co-Authored-By` del sistema.
- Antes de abrir el PR, ejecuta el skill `code-review` sobre el diff y corrige sus hallazgos. Los cambios de UI/UX que surjan de la revisión requieren aprobación del operador. No abras el PR mientras queden hallazgos obligatorios sin resolver.

## 10. Crear el pull request
Haz `git push -u origin <rama>` y crea el PR con `gh pr create`. El cuerpo incluye:
- Resumen de los cambios para el usuario
- `Closes #<N>` y los criterios de aceptación con su estado
- Plan de pruebas e instrucciones de validación, con capturas si hubo verificación visual
- `## Mockup deviation`, cuando aplique
- `## Capability-First Decision`, con los cinco campos
- `## Gates Declarados`, entre los anchors exactos:
  ```
  <!-- gates-block-start -->
  - [ ] Visual (Marionette)
  - [ ] E2E (Marionette)
  - [ ] Spec validation
  <!-- gates-block-end -->
  ```
  Declara solo los gates que salen de la clasificación y márcalos `[x]` únicamente cuando estén verificados. Si un gate no se puede ejecutar (por ejemplo, la cámara real o la biometría en el emulador), márcalo `[~]` con la razón y como recomendado, no bloqueante.
- Lista solo los skills que realmente usaste.

## 11. Limpiar y reportar
- Vuelve a `main` y haz `git pull`.
- Borra solo las ramas locales que ya estén mergeadas (`git branch -d`, nunca `-D`).
- Reporta la URL del PR, el estado de los criterios de aceptación y los gates pendientes.
- **No hagas merge del PR.** El merge requiere autorización explícita del usuario para ese PR en particular, sin excepciones.
- Después de un merge autorizado, si hubo aprendizajes reutilizables, propón guardarlos en memoria o en `ONBOARDING.md`.

## Condiciones para detenerse
Detente y reporta en lugar de continuar si:
- Falta la clasificación del issue.
- Falta una sección de especificación obligatoria y no se refinó con aprobación.
- Otro agente reclamó el issue hace menos de 24 horas.
- Hay una dependencia sin mergear o trabajo en conflicto que necesita decisión del operador.
- El agente asignado no eres tú y hace falta confirmación.
- El plan no está aprobado.
- La revisión tiene hallazgos obligatorios sin resolver.
- Algún gate obligatorio está incompleto.

## Reglas adicionales
- Crea la rama solo después de tener el contexto y la clasificación completos.
- Verifica la rama antes de cada commit.
- Nunca uses `git add -A`; agrega archivos explícitos.
- No modifiques archivos fuera del alcance acordado.
- Usa un worktree aparte para PRs en paralelo.
- **Nunca hagas merge por tu cuenta.**
