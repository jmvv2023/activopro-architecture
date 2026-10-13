# Revisión pendiente (borrar este fichero cuando esté todo resuelto)

Borradores generados el 13/10/2026 a partir de conversaciones y notas. Solo se han marcado como
`accepted` las decisiones que tomó José María; lo propuesto por Claude va como `proposed`.

## Decisiones a confirmar

1. ~~ADR-0004 — ms-verifactu, versión A o B.~~ Resuelto el 13/10/2026: el micro es el SIF y
   escribe en MySQL; Supabase se elimina.
2. **ADR-0005 — Frente A.** ¿Se deja de archivar el PDF con VeriFactu activo? Pendiente de
   hablar con Nestor.
3. **Supabase en VeriFactu — el código de GitHub no coincide con lo decidido.** En `main`
   (último commit 02/10/2026) el micro sigue usando Supabase para: Rule Store
   (`vf_rule_versions`, `vf_hash_fields`), **hash anterior de la cadena** (`vf_registros`, con
   el comentario "migración a MySQL verifactu_registro pendiente"), trazabilidad y lotes
   asíncronos (`vf_lotes`). No hay código que escriba en `verifactu_registro`; MySQL solo se usa
   en `/health`. `vf_error_catalog` no aparece en el código. ¿Hay código local sin subir?
4. **ADR-0007 — versionado del SIF.** Validar la propuesta (SemVer, versión por registro,
   CHANGELOG, tags).
5. **Columnas de `facturas` por escritor:** listar qué columnas escribe ms-verifactu y cuáles
   GeneXus, para `system-map.md`.
6. ~~Producción hoy.~~ Resuelto: un solo cliente con VeriFactu, por el flujo nativo; será el
   primero en pasar al micro.
7. ~~`SERSIMPL` sin configurar.~~ Resuelto: parámetro en `pdefecto`; si falta con VeriFactu,
   aviso y no se factura.

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
