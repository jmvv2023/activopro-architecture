# Factura electrónica B2B (SPFE)

Marco: Ley 18/2022 "Crea y Crece", RD 238/2026. SPFE = Solución Pública de Facturación
Electrónica de la AEAT. Distinta de VeriFactu: VeriFactu regula la integridad del software de
facturación; la SPFE regula el formato y el intercambio de la factura entre empresas y los
estados de pago.

## Calendario (verificar contra el texto definitivo en BOE)

- Oct 2027: empresas con volumen > 8 M€ (factura y estados de pago).
- Oct 2028: resto de empresas; estados de pago de pymes personas jurídicas.
- Oct 2029: estados de pago de personas físicas.

## Puntos técnicos clave

- Formato UBL 2.5 conforme a EN 16931 + Anexo I español. Validación XSD + Schematron antes de enviar.
- Sin binarios embebidos: el PDF del docgenerator solo como URL externa.
- EN 16931 no admite descuentos en cascada: hay que convertir los de `CalcFacVen2` a importes
  por línea. Primer caso de prueba (riesgo de rechazos por céntimos).
- Correspondencia con VeriFactu casi directa: S1 → `S`/`Z`, S2 → `AE`, E1–E6 → `E` + VATEX,
  N1/N2 → `O`. Reutilizar la lógica de ms-verifactu.
- Ámbito: solo facturas a empresarios con sede en España, no simplificadas
  (`FacAmbito`, `FacPaisCee`, `FacIntraTipo`, `FacTriang`, `Fac349`).
- Como colaborador social, ActivoPro puede remitir y cambiar estados; para **recibir** facturas
  de un tenant hace falta apoderamiento o su certificado. Aplazado.

Diseño del servicio: ADR-0006 y repo `ms-activopro-einvoice`.
