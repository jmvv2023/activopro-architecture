# Revisión pendiente (borrar este fichero cuando esté todo resuelto)

Borradores generados el 13/10/2026 a partir de conversaciones y notas. Solo se han marcado como
`accepted` las decisiones que tomó José María; lo propuesto por Claude va como `proposed`.

## Decisiones a confirmar

1. ~~ADR-0004 — ms-verifactu, versión A o B.~~ Resuelto el 13/10/2026: el micro es el SIF y
   escribe en MySQL; Supabase se elimina.
2. **ADR-0005 — Frente A.** ¿Se deja de archivar el PDF con VeriFactu activo? Pendiente de
   hablar con Nestor.
3. ~~Supabase en VeriFactu.~~ Resuelto: se mantiene (Rule Store, lotes, monitor); MySQL es la
   fuente de verdad de la cadena. Supabase es solo una copia para el monitor (ADR-0004); pendiente técnico en el issue #8 del micro.
4. ~~ADR-0007.~~ Aceptado: SemVer, implementado en la 1.0.0.
5. ~~Columnas por escritor.~~ Resuelto: el micro escribe en `verifactu_registro`; `facturas` es
   de GeneXus.
6. ~~Producción hoy.~~ Resuelto: un solo cliente con VeriFactu, por el flujo nativo; será el
   primero en pasar al micro.
7. ~~`SERSIMPL` sin configurar.~~ Resuelto: parámetro en `pdefecto`; si falta con VeriFactu,
   aviso y no se factura.

8. ~~Rectificativas.~~ Resuelto el 14/10/2026: por diferencias (ADR-0010). Queda pendiente el
   flujo nativo de GeneXus (ver `domain/verifactu.md`).
9. **Código AEAT de registro duplicado:** confirmar en el documento de validaciones.

## Datos a verificar

- Owner y nombre exacto de los repos de ms-einvoice, ms-docgenerator, ms-auth y ms-certificados.
- ¿ms-certificados y ms-verifactu-web siguen vivos o se retiran?
- ¿ms-auth necesita su propio `CLAUDE.md`? (Hay poca información sobre él.)

## Seguridad — acción recomendada

En conversaciones y notas antiguas aparecen en claro una **service_role key de Supabase** (abril
2026) y la **contraseña del usuario MySQL de ms-verifactu**. Ninguna se ha copiado a estos
borradores. Conviene rotarlas, porque ya han pasado por historiales de chat.

## Fuera de alcance de esta primera pasada

- Nuevo ActivoPro: ya tiene su propio `CLAUDE.md` en `activopro-platform`.
- Chats dentro de los proyectos "micros" y "nuevo ActivoPro" no se han recorrido uno a uno;
  se han usado sus notas resumidas.
