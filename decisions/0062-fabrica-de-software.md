---
id: 0062
title: Fábrica de software con agentes — la persona decide la especificación, el riesgo lo deciden reglas fijas por fichero y los revisores se ajustan al riesgo, con uno de dominio fiscal
status: proposed
date: 2026-11-22
services: [platform]
supersedes: null
superseded_by: null
---

Para cuando la plataforma esté construida. No cambia nada de cómo se trabaja hoy.

## Contexto

- **Cómo se trabaja hoy:**
  - Una sesión de Claude con el mandato de José María construye, comprueba en local (CI completa: `db:reset`, contrato,
    `npm test`, `build:web`, `e2e`), fusiona sus PR e informa.
  - José María decide el diseño (ADRs `proposed` → `accepted`) y despliega.
  - La CI de GitHub está parada hasta el 1/12/2026 por facturación.
- **La propuesta de José María (22/11/2026), en la línea de las «software factories»:**
  1. Todo entra por el mismo sitio: errores de producción, issues de GitHub o tareas que manda él.
  2. Un agente escribe la especificación consultando el conocimiento escrito («brain»), para no duplicar código ni
     contradecir decisiones anteriores.
  3. Otro agente construye en una rama, con el test primero y el código después, hasta que pasa.
  4. Cuatro revisores en paralelo, sin el contexto del constructor y con modelos distintos: seguridad, experiencia de
     uso, diseño y código.
  5. Un aprobador junta los informes y, si uno falla, devuelve el trabajo a construcción.
  6. Un último paso decide si hace falta una persona: un color pasa solo; la base de datos o el núcleo del negocio, a
     mano.
- **Lo que ya existe y es la base de cualquier fábrica.** Lo difícil no es generar código, sino saber si está bien:
  - **conocimiento escrito:** ADRs, `CLAUDE.md`, `docs/manual`, `huecos.md`, `domain/`;
  - **reglas que se comprueban solas:**
    - el catálogo de RLS (`aislamiento.test.ts`);
    - el reloj (`reloj.test.ts`);
    - el contrato estricto de la API;
    - las claves de i18n de todo `app.error`;
    - los errores con código;
  - **referencias externas**, que valen más que cualquier revisor:
    - los XSD de la AEAT (SII, Facturae) y de ISO 20022 (SEPA);
    - el vector SIM7 de la huella de VeriFactu;
    - los diseños de registro oficiales;
    - el modo sombra frente al programa anterior.
- **Lo que tiene de especial ActivoPro:**
  - Los errores caros no son de estilo ni de seguridad: son de dominio. Una casilla del 303 mal calculada, un asiento
    que no cuadra o un registro de VeriFactu mal encadenado llegan a más de 300 usuarios y a Hacienda.
  - Las incidencias de clientes son para evitar errores, no para convertir deseos en funcionalidad.
  - Ante una ambigüedad de diseño se para y se pregunta (regla global 5).
- **El `CLAUDE.md` de la plataforma ya es un único fichero enorme.** Un agente que redacta especificaciones necesita
  encontrar lo que le toca sin leerlo entero.

## Opciones consideradas

1. **Seguir como ahora:** una sesión que hace todo, más José María.
   - Funciona y es barato.
   - Quien construye se revisa a sí mismo, y no escala a varias tareas a la vez.
2. **La fábrica tal como está planteada.**
   - Separa papeles y revisa con modelos distintos.
   - Pero:
     - la persona entra solo al final, cuando revisar cuesta más;
     - el riesgo lo clasifica un agente;
     - cuatro revisores para cada cambio, sean cuales sean;
     - ningún revisor de dominio fiscal;
     - el bucle de aprobador y constructor no tiene límite;
     - lo que entra (errores, issues) se trata como instrucciones.
3. **Elegida (propuesta). La fábrica con las puertas en su sitio:**
   - la persona aprueba la especificación;
   - el riesgo sale de reglas fijas sobre los ficheros que toca el cambio;
   - los revisores dependen del riesgo y siempre hay uno de dominio en lo fiscal y contable;
   - el bucle tiene límites;
   - lo que entra se trata como datos;
   - y hay dos pasos más: mantener el conocimiento escrito y comprobar después de desplegar.

## Decisión (propuesta)

### 1. Entrada única, tratada como datos

- **Fuentes:** issues de GitHub y tareas de José María desde el principio. Los errores de producción, en una fase
  posterior.
- **Todo lo que entra es texto que no controlamos.** Un issue, un mensaje de error o un dato de un cliente pueden llevar
  instrucciones («ignora lo anterior y…»): ningún agente las sigue, solo las describe.
- **Errores de producción:**
  - entran agregados: código de error (`errores.<codigo>`), ruta, versión, número de veces y primera y última vez;
  - **nunca con datos de clientes** (ni importes, ni NIF, ni nombres), que tampoco pueden ir a un issue;
  - los repetidos se agrupan en uno.
- **Los agentes no tienen credenciales de producción ni secretos** (regla global 1). El token de GitHub tiene el
  alcance mínimo y los revisores solo leen.

### 2. Especificación, con la persona en esta puerta

- Un agente redacta la especificación después de consultar el conocimiento escrito:
  - qué ADRs y reglas aplican;
  - qué funciones y pantallas existen ya, para no duplicarlas;
  - los criterios de aceptación en forma de tests;
  - la clase de riesgo prevista (punto 4).
- Puede terminar de tres formas:
  1. **Lista.**
  2. **Requiere decisión:** una ambigüedad de diseño, con las opciones planteadas (regla 5, como la etiqueta
     `requiere-decision`).
  3. **No procede:** un deseo que no tiene sentido para todos, o algo que contradice un ADR. Lo dice, con el motivo.
- **José María aprueba la especificación** de todo lo que no sea de clase C. Revisar la intención cuesta mucho menos que
  revisar el código, y es donde se decide si algo tiene que existir.

### 3. Construcción con el test primero

- El constructor trabaja en una rama.
  - Primero escribe los tests de los criterios de aceptación y comprueba que fallan; después, el código hasta que pasan.
  - Después, la CI local completa (la de hoy).
- Siempre que exista, se usa una referencia externa: XSD, diseño de registro, vector oficial, modo sombra. Un test escrito
  por quien construye puede repetir su propio malentendido; un XSD de la AEAT no.
- **Cada PR mantiene el conocimiento escrito:** su entrada en `CLAUDE.md` (o el documento del módulo), el manual y
  `huecos.md`. Lo comprueba un revisor.

### 4. Clases de riesgo por reglas fijas, no por criterio de un agente

- La clase sale de los ficheros que toca el PR, con una tabla en el repositorio (como `CODEOWNERS`), y manda la más
  alta. Ningún agente la puede bajar.

| Clase | Qué toca (ejemplos) | Persona |
|---|---|---|
| **A** | `supabase/migrations/`, RLS y permisos (`permisos.ts`, `contexto.ts`, `auth.ts`), `packages/fiscal`, `verifactu`, `sii`, `aeat`, `efactura`, `sepa`, funciones de contabilización y liquidación, `etl/`, la CI, `CLAUDE.md` y los ADRs | Aprueba la especificación y el PR |
| **B** | Rutas de la API y pantallas fuera de lo anterior, `packages/informes`, `documentos`, `correo`, el glosario de i18n | Aprueba la especificación; el PR lo fusiona el aprobador y José María recibe el resumen |
| **C** | Estilos, textos que no son del glosario, el manual y sus capturas, tests añadidos sin cambiar código | Nadie: lo fusiona el aprobador |

- **El conocimiento escrito es de clase A.** Es lo que orienta a los agentes siguientes: un ADR o una regla de
  `CLAUDE.md` mal cambiada estropea todo lo que venga después.
- **Fusionar no es desplegar.** El despliegue sigue siendo de José María en todas las clases (regla global 1).

### 5. Revisores según la clase, sin el contexto del constructor pero con el de la tarea

- Ven la especificación, el diff, el conocimiento escrito y los resultados de los tests. No ven la conversación del
  constructor.
- **Por clase:**
  - **C:** código.
  - **B:** código y seguridad, más experiencia de uso y diseño si toca pantallas.
  - **A:** los anteriores que apliquen, más **dominio fiscal y contable**: normativa, casillas, cuadre, cadena, las
    reglas de `CLAUDE.md` y los ADRs.
- Usar modelos distintos al del constructor ayuda, pero sus puntos ciegos se parecen. Lo que de verdad protege son las
  referencias externas del punto 3.
- **Cada hallazgo lleva gravedad y cómo se reproduce**, y se comprueba antes de devolver el trabajo. Así el constructor no
  «arregla» falsos positivos.

### 6. Aprobador con límites

- Junta los informes. Si hay un hallazgo comprobado de gravedad alta o media, devuelve a construcción con la lista.
- **Tres vueltas como máximo.** Después se para y le llega a José María con el estado y lo que no se ha resuelto.
- Un hallazgo que en realidad es de diseño vuelve a la especificación (punto 2), no a construcción.

### 7. Después de desplegar

- Lo que entró como error de producción se cierra cuando el error deja de aparecer en la versión desplegada, no al
  fusionar.
- **Medidas de la fábrica:**
  - vueltas por PR;
  - errores que llegan a producción por clase;
  - hallazgos de los revisores que resultan ciertos;
  - tiempo de José María por PR.
- Con esas cifras se mueven ficheros de una clase a otra. Solo José María cambia la tabla.

### Requisito previo: el conocimiento escrito, partido y con índice

- `CLAUDE.md` de la plataforma pasa a ser un índice corto: reglas globales y un enlace por módulo.
- Las reglas de cada módulo van a su documento (`docs/modulos/<modulo>.md` o en `domain/` de la arquitectura), con los
  ADRs que las justifican.
- Un agente lee el índice y los documentos de los módulos que toca.

### Fases

1. **Puertas fijas:** la tabla de clases, los checks obligatorios en la CI (cuando vuelva) y partir `CLAUDE.md`.
2. **Especificación** como paso propio, con sus tres salidas y la aprobación de José María.
3. **Dos revisores independientes:** dominio fiscal y contable, y código y seguridad. Después, experiencia de uso y
   diseño, si las cifras dicen que hacen falta.
4. **Aprobador** con límites, y fusión automática de la clase C.
5. **Errores de producción** como entrada, agregados y sin datos de clientes, con el cierre tras desplegar.

## Consecuencias

- **José María pasa de revisar código a decidir especificaciones**, que es donde más valor aporta y donde le gusta
  trabajar.
- **Nada delicado pasa solo:** la base, la fiscalidad, los permisos y el propio conocimiento escrito siempre llegan a él.
- **Más tareas a la vez** sin perder coherencia, mientras el conocimiento escrito esté al día. Si se descuida, la fábrica
  produce rápido cosas que no encajan.
- **Coste:**
  - varias ejecuciones de modelos por tarea (se limita con revisores por clase y con el máximo de vueltas);
  - mantener la tabla de clases;
  - partir y mantener el conocimiento escrito.
- **Riesgos que se asumen:** que los revisores coincidan en sus puntos ciegos (se cubre con referencias externas y el
  revisor de dominio) y que entre una instrucción maliciosa (se cubre con el punto 1).

## Por decidir (José María)

1. **La persona en la especificación** (además de en el PR de clase A), en lugar de solo al final.
2. **La tabla de clases A/B/C** de arriba como punto de partida.
3. **Modelos de otros proveedores en las revisiones:** solo ven código y especificación, nunca datos de clientes. ¿Se
   aceptan, o todo con un mismo proveedor?
4. **Partir `CLAUDE.md`** en índice y documentos por módulo como primer paso.
5. **Cuándo empezar:** al terminar la plataforma, o la fase 1 antes, aprovechando la vuelta de la CI el 1/12.

## Origen

Conversación del 22/11/2026 con José María («una vez construido deberemos avanzar a ello… lo que hace un tiempo ya se está
imponiendo, las SW factory»), con los seis pasos que propuso.
