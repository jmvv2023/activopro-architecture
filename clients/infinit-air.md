# INFINIT AIR SL — diarios CONTASOL → ActivoPro

Schema: `mconta0070`. Ejercicios 2021–2024 (2025 ya cargado y validado por la clienta: no se toca).

## Decisiones

- Antes de cada importación se cuadran las cuentas del diario (columna E) con el Plan de Cuentas
  de ActivoPro; las que faltan se crean a mano antes de importar.
- Si la cuenta ya existe con el mismo código, se respeta el título de ActivoPro, no el de CONTASOL.
- Embargos de nómina 2021: se crea la cuenta tal cual (4759 + subcuenta 000000).
- Se importan también los asientos de regularización y cierre (no se generan con el asistente).
- `alinear_cuentas.py` debe partir del fichero original "Diari de moviments oficial", sin retoques manuales.

## Estado

2021–2024 importados y contrastados en local sobre copia de PROD. Pendiente: importar en PROD
cuando lo autorice la asesoría.
