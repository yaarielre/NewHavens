# Rift Hunters — CLAUDE.md

RPG de acción en Roblox (cazadores, mazmorras/Grietas, progresión de rango E→S).
GDD completo: `Docs/GDD — RPG de Cazadores y Mazmorras (Roblox + Agentes AI).pdf`.

## Regla de oro

**Nunca confiar en el cliente.** El cliente solo anima y pide (input, cámara, UI).
Todo daño, movimiento validado, cooldown, inventario y economía se calcula y valida
en el servidor. Cualquier RemoteEvent que reciba el servidor debe validar tipos,
rangos, distancia y rate limit antes de actuar.

## Arquitectura

- **Luau estricto** (`--!strict` en todo ModuleScript nuevo salvo que se justifique).
- Sincronización con **Rojo** (`default.project.json`) — nunca edites Studio y esperes
  que persista; todo cambio real vive en `src/` y se sincroniza.
- Paquetes con **Wally** (`wally.toml`).
- Estructura de carpetas:
  - `src/server/Services/` — un ModuleScript por servicio (Combat, Dungeon, Inventory,
    Quest, Economy, Data, EnemyAI...). Cada servicio expone una tabla con `:Init()` /
    `:Start()` y se arranca desde `src/server/init.server.lua`.
  - `src/client/Controllers/` — un controller por sistema de cliente (input, combate,
    UI, cámara). Arrancan desde `src/client/init.client.lua`.
  - `src/shared/Config/` — ModuleScripts de **datos puros** (armas, monstruos, loot,
    rangos, salas de mazmorra). El agente cambia números aquí, no en la lógica.
  - `src/shared/Remotes.lua` — definición central de RemoteEvents/RemoteFunctions.
  - `src/shared/Modules/` — utilidades compartidas (máquina de estados, matemáticas
    de daño, etc.).

## Convenciones de Luau

- PascalCase para servicios, módulos y clases; camelCase para variables y funciones
  locales; SCREAMING_SNAKE_CASE para constantes de configuración.
- Cada servicio de servidor es responsable de su propio estado; no leer directamente
  el estado interno de otro servicio, exponer una API de métodos.
- Los datos de configuración (`src/shared/Config/*`) no contienen lógica, solo tablas.
- Nombrar RemoteEvents por verbo de intención desde el cliente (`RequestAttack`,
  `RequestDodge`), nunca por lo que hacen en el servidor.

## Combate (fórmulas de referencia, ver GDD)

`daño = base del arma × escalado del stat × multiplicador de habilidad − defensa`

El servidor es quien decide si un golpe conecta: valida distancia al alcance del
arma, cooldown de la habilidad/combo, y que el atacante esté vivo y no aturdido.
Un golpe fuera de alcance no cuenta y suma sospecha al jugador (ver Anticheat).

## Anticheat

- Sistema de sospecha acumulativa por jugador: varias infracciones → kick;
  reincidencia → ban + aviso a Discord (webhook, vía `HttpService`, solo servidor).
- Cosas a validar siempre en servidor: distancia de golpes, velocidad de movimiento,
  cooldowns de habilidades, teleports, creación de ítems/monedas.
- Ítems y monedas se crean **solo** en el servidor. Nunca confiar en un remote que
  pida "dame X oro" sin que el servidor calcule X de forma independiente.

## Datos de jugador

- `ProfileStore` sobre `DataStoreService` para nivel, oro, cristales, inventario y
  equipo. Sesión bloqueada (no se puede tener el mismo perfil abierto en dos
  servidores) y anti-duplicado en cada transacción.
- Nunca guardar datos derivables (ej. stats totales) si se pueden recalcular desde
  la fuente (nivel + equipo); reduce el riesgo de desincronía.

## Flujo de trabajo con el agente

- Tareas chicas y concretas: una mecánica por sesión/PR.
- Todo en ramas de Git; nada llega a `main` sin playtest (vía Roblox Studio MCP) y
  revisión del usuario.
- Modelos 3D y animaciones clave se revisan a mano, no se generan a ciegas.
- Antes de dar por terminada una tarea de gameplay: correr el playtest por MCP, leer
  la consola de Studio, y confirmar que no hay errores ni warnings nuevos.

## Estado del proyecto

Fase 0 (prototipo) en curso — ver checklist en el GDD, sección "Roadmap y MVP".
