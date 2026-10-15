# ActivoPro — arquitectura (repo central)

Punto de entrada para cualquier sesión (humana o de Claude) que trabaje en ActivoPro.
Este repo es **privado e interno**. No contiene código: contiene el mapa del sistema, las
decisiones transversales y el conocimiento de dominio.

## Qué es ActivoPro

ERP/contabilidad SaaS multi-tenant de Enumbers Digital Solutions SLU (Sabadell).

- **Núcleo actual:** GeneXus 16 U8 (Java) sobre Tomcat 9 + MySQL 8. ~160 clientes en producción.
- **Multi-tenant por schema:** cada cliente tiene su schema `mconta####`. Algunos schemas
  contienen más de una empresa (`EmpCod`). Tenant de pruebas: `mconta0048`.
- **Microservicios** alrededor del núcleo (ver `system-map.md`), cada uno en su propio repo.
- **Nuevo ActivoPro** (React + Supabase) en desarrollo en el monorepo `activopro-platform`,
  sin clientes todavía. Coexistencia temporal con GeneXus (ver ADR-0003).

## Dónde está cada cosa

| Necesito… | Mirar en |
|---|---|
| Qué micro hace qué, puertos, dominios, tablas que toca | `system-map.md` |
| Por qué algo es como es (transversal) | `decisions/` |
| Por qué algo es como es (de un micro) | `docs/decisions/` del repo del micro |
| Reglas fiscales: VeriFactu, SPFE, multi-tenant | `domain/` |
| Cómo se construye un micro, gotchas de GeneXus | `conventions/` |
| Migraciones de clientes (proceso y lecciones) | `clients/` |

Regla para decidir dónde va un documento: si la decisión cambiaría al reescribir solo un
micro, va en el repo de ese micro. Si afecta a dos o más micros, o al núcleo, va aquí.

## Reglas globales (no negociables)

1. **Nunca acceso a producción desde una sesión autónoma.** Sin credenciales de PROD, sin
   despliegues. Se trabaja contra tests y `mconta0048` / datos de prueba. El despliegue lo hace
   José María.
2. **Nunca secretos en Git.** `.env` fuera del repo, `.env.example` con placeholders.
   (Precedente: incidente de `.env` subido en ms-activopro-import, ver `conventions/microservices.md`.)
3. **No se modifican datos de clientes salvo para corregir errores.** Lo que es configuración
   del cliente (vencimientos, fichas…) lo corrige el propio cliente.
4. **No se toca la lógica de contabilización de GeneXus** (`ContaFacVen`, `CalcFacVen2`, sus
   `Commit on exit`) sin decisión explícita. Riesgo para la contabilidad de todos los tenants.
5. **Ante una ambigüedad de diseño, parar y preguntar.** Se deja planteada en el PR o issue
   con las opciones; no se decide en solitario. El diseño se discute antes de implementar.
6. **MySQL es la fuente de verdad** de los datos de negocio del núcleo (ADR-0002).

## Cómo trabajar en este repo

- ADRs con la plantilla `conventions/adr-template.md`, numeración correlativa, nunca se borran:
  se marcan `superseded` y se enlaza el nuevo.
- `status: proposed` = planteado, sin decidir. Solo José María pasa un ADR a `accepted`.
- Documentos cortos y concretos. Si algo crece, se parte.
