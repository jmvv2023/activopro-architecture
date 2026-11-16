# Registro horario y horas extra: ¿un módulo de ActivoPro? (por valorar)

Fecha: 16/11/2026. Estado: **planteado, sin decidir**. Lo propone José María al ver que la plataforma ya tiene al empleado como
tercero (relación `empleado`, datos laborales protegidos, ADR-0034) y las plantillas de asiento para contabilizar los salarios
(ADR-0033).

## La idea

Un módulo **Registro horario** que cada empleado de un cliente usa para fichar, con la jornada pactada y las horas extra valoradas
según su tarifa. Se vendería aparte, a **x € por empleado con acceso al registro** y mes.

## Por qué ahora: la normativa

- **En vigor desde 2019** (art. 34.9 ET, RDL 8/2019): toda empresa registra cada día la hora de inicio y de fin de la jornada de cada
  trabajador por cuenta ajena. Tiene que conservarlo **4 años** y ponerlo a disposición de los trabajadores, sus representantes y la
  Inspección. Hoy vale cualquier sistema fiable, incluido el papel.
- **Tiempo parcial** (art. 12.4.c ET): además, hay que registrar las horas complementarias y entregar al trabajador un resumen mensual.
- **Horas extra** (art. 35.5 ET): hay que registrarlas día a día, totalizarlas en el periodo de pago y entregar copia del resumen.
- **Sanción por no llevar el registro:** infracción grave, de 751 a 7.500 € (LISOS 7.5 y 40.1.b).
- **Real decreto de registro digital**, en tramitación. Lo que se sabe en octubre de 2026:
  - **Sin aprobar.** Tuvo un dictamen desfavorable del Consejo de Estado en marzo de 2026. Trabajo dio por hecha la revisión a
    principios de octubre, pero sigue sin fecha.
  - **Lo que pide el último borrador conocido:**
    - registro digital e individual;
    - inalterable, con el historial de quién cambió qué, cuándo y por qué;
    - acceso del propio trabajador;
    - acceso remoto de la Inspección por un sistema interoperable;
    - un protocolo interno de la empresa.
  - **Entrada en vigor** a los 20 días de su publicación en el BOE. Se ha hablado de un plazo de adaptación para las pymes, sin
    concretar.
  - Las fuentes son sobre todo de proveedores de control horario. **Comprobar en el BOE antes de decidir.**

**Lectura:** si el real decreto sale, todo cliente con empleados tendrá que cambiar el papel o la hoja de cálculo por un sistema
digital, y los que ya lo hacen con algo suelto tendrán que revisar que cumpla. Es una demanda obligada, como VeriFactu. Pero el
detalle técnico (cómo accede la Inspección) depende de un texto que aún no existe.

## Qué sería el módulo

| Pieza | Contenido | Ya hay en la plataforma |
|---|---|---|
| Empleado con acceso | El empleado ficha con su propio login, con un rol que solo ve su registro (no ocupa plaza de usuario de ActivoPro) | Relación `empleado` y `empleado_laboral`; usuarios y accesos por empresa (ADR-0015, ADR-0043) |
| Fichaje | Entrada, salida y pausas; web y móvil (aplicación web instalable); hora del servidor, no del dispositivo | — |
| Jornada teórica | Calendario laboral, horario y jornada por empleado o por grupo; festivos; tiempo parcial | — |
| Correcciones | Nunca se borra: cada corrección guarda el antes, el después, quién la hizo y por qué; el empleado la ve | El patrón de auditoría (`audit_log`, eventos con motivo) |
| Horas extra | Exceso sobre la jornada, por día y periodo; **tarifa** por empleado o convenio (precio por hora, recargo, o compensación con descanso) | — |
| Informes | Resumen mensual al trabajador (firma o acuse); extracción por periodo para la Inspección y los representantes; conservación 4 años | — |
| Enlace contable | Las horas extra valoradas del mes, como dato para la nómina o para la plantilla de asiento de salarios | Plantillas de asiento (ADR-0033) |

**Límite que hay que decidir:** ActivoPro no calcula nóminas. Las horas extra valoradas son un **dato para quien hace la nómina**
(la gestoría o el programa de nóminas) y un importe que la plantilla de asiento puede tomar. No son una nómina. Si se quisiera ir más
allá, sería otro producto.

**Fuera de una primera versión:** geolocalización (pide análisis de protección de datos y proporcionalidad), biometría (no),
turnos complejos y cuadrantes, terminales físicos.

## Impacto en la plataforma

- **Usuarios de un tipo nuevo.** Hoy un usuario es una plaza de pago con acceso al ERP. El empleado que ficha sería un usuario
  limitado a su registro, que se cuenta y se cobra aparte. Toca el modelo de acceso y de contratación (ADR-0043: plazas,
  `tenant_modulo`), con un ADR propio.
- **Datos personales.** El registro horario es dato personal del trabajador. Mismo criterio que `empleado_laboral`: acceso por permiso
  y trazado, nunca a la Data API. Habrá que revisar la evaluación de impacto con la geolocalización fuera.
- **Volumen.** Unas 4 marcas al día por empleado, unas 1.000 al año. Es despreciable para la base.
- **Soporte: el coste real.** Los usuarios ya no son contables, sino empleados de nuestros clientes: contraseñas olvidadas, el
  móvil, «no me deja fichar». Necesita alta en bloque, restablecer el acceso desde la empresa y una pantalla de fichar que no
  necesite explicación.
- **Dependencia del real decreto.** Lo que es seguro (registro diario, inalterable, con correcciones trazadas, acceso del trabajador,
  4 años) se puede hacer ya. El acceso de la Inspección se haría cuando haya texto.

## Coste estimado

- **Construcción:** un módulo de tamaño medio, comparable a Recurrencias o a Cartera. Esto es una estimación, no una medición:
  - fase 1 (fichaje, jornada, correcciones, resumen mensual, informe para la Inspección, rol de empleado): 3 a 5 semanas al ritmo
    actual;
  - fase 2 (horas extra con tarifas, enlace con la plantilla de asiento, tiempo parcial, avisos): 2 a 3 semanas;
  - aparte, el acceso de la Inspección cuando se publique.
- **Funcionamiento:** las bases y la autenticación tienen un coste marginal por empleado de céntimos al mes. El coste que cuenta es
  el soporte del punto anterior.

## Precio: referencias de mercado

Las cifras salen de un foro y de comparativas de proveedores. **No están verificadas**: hay que comprobarlas en sus webs antes de
fijar nada.

| Programa | Precio orientativo |
|---|---|
| Regitap, En Hora, Bixpe | 1 a 2 € por empleado y mes |
| Factorial, Sesame | ~5,50 € por empleado y mes (Sesame con mínimo mensual) |
| Woffu | ~7,50 € |
| Bizneo | desde 6 € por empleado, más una cuota fija |
| FichMe, Mi Fichaje Legal | por tramos de empresa: 9 € hasta 5–6 empleados, 19–29 € hasta 25–30 |

**Hipótesis para discutir:** **1,5 a 2,5 € por empleado y mes**, con un mínimo por empresa (por ejemplo, el precio de 5 empleados).

- No compite con las suites de RR. HH. Compite con lo barato, y gana por estar dentro del programa que el cliente ya usa: los
  empleados ya están dados de alta y las horas extra llegan a la contabilidad.
- **Cuenta orientativa:** 160 clientes, de los que la mitad tuviera 8 empleados de media, a 2 €, darían unos 1.280 € al mes.
- Falta el dato real: cuántos clientes tienen empleados y cuántos.

## Preguntas abiertas (para José María)

1. ¿Cuántos clientes de ActivoPro tienen trabajadores, y cuántos? ¿Cómo registran la jornada hoy?
2. ¿Esperar al texto del real decreto, o salir con la fase 1, que cumple la norma vigente, y añadir el acceso de la Inspección
   después?
3. El empleado que ficha, ¿es un usuario de la plataforma con un rol limitado, o un acceso aparte (enlace o PIN por empleado)?
   Decide el modelo de plazas.
4. Horas extra: ¿tarifa por empleado, por categoría o convenio, o las dos? ¿Compensación por descanso?
5. ¿Lo venden también los asesores a sus clientes? Un cliente de gestoría podría usar solo este módulo.
6. ¿Producto aparte, o parte de un paquete de laboral con la nómina hecha fuera?

## Fuentes consultadas

- [Que.es, 17/07/2026: nuevo registro horario tras el Consejo de Estado](https://www.que.es/2026/07/17/nuevo-registro-horario-julio-2026/)
- [DSI, estado en octubre de 2026](https://www.dsi-net.com/registro-horario-digital-obligatorio/)
- [Horalia, 05/10/2026](https://horaliahr.com/es/blog/registro-horario-digital-obligatorio-2026-27)
- [Rankia, comparativa de precios de control horario 2026 (foro)](https://www.rankia.com/foros/empresas/temas/7373620-mejores-software-control-horario-espana-2026-comparativa-real-precios?page=1)
