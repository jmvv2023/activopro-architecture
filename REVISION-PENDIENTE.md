# Revisión pendiente (borrar este fichero cuando esté todo resuelto)

Borradores generados el 13/10/2026 a partir de conversaciones y notas. Solo se han marcado como
`accepted` las decisiones que tomó José María; lo propuesto por Claude va como `proposed`.

## Decisiones a confirmar

1. **ADR-0004 — ms-verifactu, versión A o B.** Hay dos diseños en las notas (asíncrono con el
   MS escribiendo en MySQL y sin Supabase, frente a síncrono con el MS sin tocar `facturas` y
   Rule Store en Supabase). Indicar cuál está vigente.
2. **ADR-0005 — Frente A.** ¿Se deja de archivar el PDF con VeriFactu activo? Pendiente de
   hablar con Nestor.
3. **Supabase en VeriFactu:** si se elimina, ¿dónde va el Rule Store / catálogo de errores?

## Datos a verificar

- Owner y nombre exacto de los repos de ms-einvoice, ms-docgenerator, ms-auth y ms-certificados.
- ¿ms-certificados y ms-verifactu-web siguen vivos o se retiran?
- ¿ms-auth necesita su propio `CLAUDE.md`? (Hay poca información sobre él.)

## Seguridad — acción recomendada

En conversaciones y notas antiguas aparecen en claro una **service_role key de Supabase** (abril
2026) y la **contraseña del usuario MySQL de ms-verifactu**. Ninguna se ha copiado a estos
borradores. Conviene rotarlas, porque ya han pasado por historiales de chat.

## Fuera de alcance de esta primera pasada

- Presupuestos (GeneXus): análisis en curso; cuando se cierre el diseño, ADR en este repo
  (afecta a núcleo, verifactu y docgenerator).
- Nuevo ActivoPro: ya tiene su propio `CLAUDE.md` en `activopro-platform`.
- Chats dentro de los proyectos "micros" y "nuevo ActivoPro" no se han recorrido uno a uno;
  se han usado sus notas resumidas.
