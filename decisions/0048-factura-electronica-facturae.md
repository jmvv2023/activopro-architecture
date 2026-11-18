---
id: 0048
title: Facturae 3.2.2 firmada desde un modelo común EN 16931, firmada una vez en el worker y guardada; DIR3 en la relación cliente
status: proposed
date: 2026-11-18
services: [core, einvoice]
supersedes: null
superseded_by: null
---

## Contexto

- Las facturas a las **administraciones públicas** (B2G, Ley 25/2013) van en **Facturae 3.2.2**, con **firma XAdES-EPES**
  (política de firma de Facturae) hecha con el certificado de quien emite. La misma factura sirve para FACe (Administración
  General del Estado) y para los portales autonómicos y locales (e-FACT en Cataluña, FACCan en Canarias…).
- Cada factura lleva los centros **DIR3** del destinatario: oficina contable (rol 01), órgano gestor (02) y unidad
  tramitadora (03); a veces, también el órgano proponente (04). Las administraciones suelen exigir además las referencias
  del **expediente**, el **contrato** o el **pedido**.
- En la revisión del 17/11 se pidió «Generar → Facturae» en la factura emitida (hueco H-078).
- La plataforma ya tiene casi todo lo que la factura necesita:
  - las líneas comerciales con descuentos de línea y de pie (paralelo y cascada, ADR-0036);
  - el desglose por tipo (`app.desglose_factura`);
  - las retenciones con su clave;
  - las rectificativas;
  - los vencimientos y la forma de pago con su medio normalizado;
  - el certificado de la empresa en Vault (ADR-0046), que solo puede leer el worker;
  - la firma XMLDSig de VeriFactu (`xml-crypto`).
- Lo que falta: los **códigos DIR3** y las **referencias** no existen ni en el cliente ni en la factura.
- Dos trabajos que vienen después manejan los mismos datos:
  - la **factura B2B obligatoria** (SPFE, en UBL conforme a EN 16931; ADR-0006, `domain/spfe.md`);
  - la **lectura de las facturas que llegan a la bandeja** en Facturae o UBL (ADR-0047, fase 2).

## Opciones consideradas

### Modelo

1. **Facturae directo** desde los datos de la factura. Es lo más rápido ahora, pero la SPFE y la lectura de la bandeja
   repetirían la correspondencia de impuestos, descuentos, retenciones y rectificativas.
2. **Modelo común EN 16931** (términos BT/BG) en un paquete, con un adaptador por formato: Facturae ahora; UBL para la
   SPFE y la lectura de Facturae y UBL después. Las tres cosas comparten una sola correspondencia. **Elegida.**

### Firma

1. **En la API, en cada descarga y sin guardar.** Es síncrono, pero la API tendría que poder leer la clave privada, y cada
   descarga daría un fichero distinto (cambia la hora de la firma).
2. **En el worker, una vez, y se guarda.** El usuario pide la Facturae, la pantalla espera unos segundos y descarga. El
   fichero firmado queda en el archivo, y volver a descargarlo da el mismo fichero: es el documento que recibe la
   administración. La clave no sale del worker, como en VeriFactu. **Elegida.**

### DIR3 y referencias

1. **Solo en la factura**: se teclean en cada una y se propone la última del cliente.
2. **En la relación cliente y en la factura.** El cliente se marca como «Administración pública» y lleva uno o varios
   juegos de DIR3 (un ayuntamiento tiene varias unidades tramitadoras), uno de ellos por defecto. La factura elige el juego
   y lleva sus propias referencias. **Elegida.**

### Envío

1. **Solo descargar el fichero firmado**: el usuario lo sube al portal. **Elegida para la fase 1.**
2. **Enviar por el servicio web de FACe y seguir su estado** (registrada, contabilizada, pagada…): fase 2.

## Decisión

### Paquete `@activopro/efactura` (sin acceso a la base)

- `modelo.ts`: la factura en términos EN 16931, independiente del formato. Contiene:
  - emisor y destinatario (identificación por `tipo_identificacion`, dirección);
  - líneas (cantidad, unidad, precio, descuentos de línea, impuesto, tipo y categoría);
  - descuentos y cargos de pie, como **importes**: EN 16931 no tiene cascada y Facturae tampoco la calcula, así que los
    importes salen de `app.desglose_factura`;
  - desglose por impuesto y tipo, con recargo de equivalencia;
  - retenciones con su clave;
  - vencimientos y medio de pago, con el IBAN de la empresa en transferencia o el mandato en domiciliación;
  - factura rectificada, motivo y método;
  - referencias y centros administrativos.

  La categoría de impuesto y la exención salen de la misma regla que VeriFactu (S1/S2/E1–E6/N1/N2), para que la misma
  factura no se declare de dos maneras.
- `facturae.ts`: del modelo a Facturae 3.2.2. Correspondencias:
  - impuesto: IVA 01, IGIC 03, IRPF 04;
  - medio de pago de Facturae (01–19) desde el medio normalizado de `forma_pago`;
  - persona física o jurídica y residencia por el NIF y el país;
  - centros DIR3 en `AdministrativeCentres`;
  - referencias en cada línea: `FileReference`, `ReceiverContractReference` y `ReceiverTransactionReference`;
  - la retención repartida por línea en `TaxesWithheld`, en proporción a la base;
  - la rectificativa en `Corrective`: número y fecha de la original, motivo, método 01 íntegra o 02 por diferencias, y
    periodo.
- `firma.ts`: firma XAdES-EPES envuelta con la política de Facturae (identificador y huella publicados), sobre
  `xml-crypto` como la de VeriFactu.
- Los tests validan contra el **XSD oficial de Facturae 3.2.2** (con `xmllint-wasm`, como `@activopro/sepa`) y comprueban la
  firma. La primera factura real la pasa José María por el validador oficial de facturae.gob.es antes de dar la fase por
  buena.
- Después, `ubl.ts` (SPFE) y `leer.ts` (Facturae y UBL al modelo, para la bandeja) sobre el mismo modelo.

### Base

- **Centros DIR3 de la relación cliente:**
  - `tercero_rol.administracion_publica`;
  - `rol_dir3` con el nombre del juego, oficina contable, órgano gestor, unidad tramitadora, órgano proponente opcional y
    marca de por defecto (uno como mucho).
  - Los códigos se validan por forma (letra y ocho caracteres) y no contra el directorio. La búsqueda en el directorio DIR3
    público queda para más adelante.
- **En la factura emitida:** `factura.dir3_id` (propuesto el de por defecto) y `factura.referencias` (expediente, contrato,
  pedido y referencia del receptor). Se editan mientras es borrador.
  - En la rectificativa a una administración, también el **motivo Facturae** (catálogo 01–16 y 80–85) y el método, que
    sale del tipo de rectificación (por diferencias = 02).
  - Avisos que no bloquean: cliente administración sin DIR3, y sin referencias.
- **`app.datos_efactura(factura)`:** el modelo común en JSON, en el mismo punto que `app.datos_documento_factura` y con la
  misma fuente.
- **`factura_electronica`:** factura, formato `facturae_322`, estado (pendiente, generada, error), fichero en el archivo con
  su huella, firmado en, huella y titular del certificado, error.
  - Se genera **una vez**: la emitida no cambia, así que el fichero tampoco. Se puede rehacer solo tras un error, o con
    motivo si cambia el certificado.
  - La aplicación solo lee: `app.pedir_facturae` (encola `efactura.generar`, clave por factura), `app.estado_facturae` y,
    para el worker, `app.terminar_facturae`.
- Solo para **emitidas de la plataforma** y no simplificadas (F1, R1–R4).

### Worker y API

- **Worker `efactura.generar`:**
  - lee el modelo y el certificado (`app.certificado_envio`);
  - genera, firma, valida contra el XSD, guarda en el archivo (`<tenant>/<empresa>/efactura/<factura>.xsig`) y termina;
  - sin certificado o caducado, error permanente con su código, sin reintentos.
- **API:**
  - `POST /facturacion/facturas/:id/facturae` pide la generación, o devuelve la que ya hay;
  - `GET …/facturae` da el estado;
  - `GET …/facturae/fichero` descarga el `.xsig`.

### Front

- **«Generar ▾ → Facturae (firmada)»** en la emitida.
  - Abre un diálogo que espera mientras el worker firma (unos segundos) y descarga el fichero.
  - Antes de generar avisa si falta el certificado o los DIR3 en un cliente administración.
  - Después, el diálogo dice dónde subirlo (FACe o el portal autonómico) y deja volver a descargar.
- **Relación cliente:** marca «Administración pública» y la tabla de centros DIR3.
- **Factura:** cuando el cliente es una administración, un bloque «Administración» con el juego de DIR3 y las referencias.
- **Correo:** la Facturae se puede adjuntar al envío de una factura a un cliente administración (después del PDF; casilla
  en el diálogo de envío).

## Consecuencias

- La SPFE y la lectura de la bandeja parten de un modelo ya probado con un formato real y validado contra su XSD.
- El fichero firmado es el que se presenta y queda guardado. Es otra copia en el archivo, del tamaño de un XML, y no
  depende de «conservar los originales» (eso es para lo recibido).
- La firma depende del certificado de la empresa. Sin certificado no hay Facturae: la pantalla lo explica y lleva a Datos
  de la empresa.
- Fases:
  1. modelo, Facturae 3.2.2 firmada, DIR3 y referencias, descarga y adjunto al correo;
  2. envío a FACe (servicio web con el certificado) y estados; después, e-FACT si hace falta;
  3. UBL/SPFE (ADR-0006) y la lectura de Facturae y UBL en la bandeja (ADR-0047, fase 2).
- Pendiente: búsqueda en el directorio DIR3; las cesiones de crédito (factoring), que Facturae admite y la plataforma no
  tiene; y Facturae para albaranes o presupuestos, que no se usa.

## Origen

Revisión del 17/11 (H-078) y decisiones del 18/11/2026 en la sesión de la plataforma:
- descargar firmada en la fase 1;
- firma en el worker, una vez, y se guarda;
- DIR3 en la relación cliente y referencias por factura;
- modelo común EN 16931.
