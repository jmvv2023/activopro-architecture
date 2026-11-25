---
id: 0065
title: Envío a FACe desde la plataforma (fase 2 de la factura electrónica)
status: proposed
date: 2026-11-25
services: [core]
supersedes: null
superseded_by: null
---

## Contexto

ADR-0048 dejó para su fase 2 «enviar por el servicio web de FACe y seguir su estado», como módulo de pago. El 25/11/2026 José María
confirma que el entorno de pruebas de FACe no exige alta previa y pide avanzar. Este ADR fija los detalles que la fase 2 dejaba
abiertos.

Lo que dice el propio servicio (WSDL de `facturasspp2` y pruebas contra `se-face-webservice.redsara.es` el 25/11/2026):

- SOAP 1.1 RPC/literal, espacio de nombres `https://webservice.face.gob.es`.
- Operaciones de proveedor: `enviarFactura` (correo, Facturae en base64, anexos), `consultarFactura`, `consultarListadoFacturas`
  (varios números de registro), `anularFactura` (número y motivo), `consultarEstados`, y las del directorio (unidades y NIF por
  administración).
- La identidad es una firma WS-Security X.509 (Timestamp y Body firmados, C14N exclusiva), sin TLS de cliente.
  - Sin firma: fallo 401 «La petición no esta firmada».
  - Firmada con un certificado autofirmado: fallo 401 «Error al validar el certificado».
- El resultado de cada operación lleva un `codigo` (0 = correcto). La factura tiene dos estados: el de tramitación (1200 registrada,
  1300 registrada en el RCF, 2400 contabilizada, 2500 obligación reconocida, 2600 pagada, 3100 rechazada, 3200 anulada) y el de
  anulación (4100 no solicitada, 4200 solicitada, 4300 aceptada, 4400 rechazada).

## Opciones consideradas

### Dónde vive el cliente de FACe

1. Un paquete nuevo.
2. **En `@activopro/efactura`**, junto a la Facturae que envía; sin acceso a la base, como el resto del paquete. **Elegida.**

### Cuándo se consulta el estado

1. Solo a mano.
2. **Una hora después de registrarla y, mientras quede algo vivo de la empresa, una vez al día**; además, «Consultar ahora».
   Una sola consulta por empresa (`consultarListadoFacturas`, 500 números por petición). **Elegida.** FACe pide no consultar de más,
   y el pago o el rechazo no corren prisa de minutos.

### Volver a presentar una factura

1. Nunca: una rechazada se corrige con una rectificativa.
2. **Solo si la anterior está rechazada, anulada o con la anulación aceptada, o se quedó en error, y con motivo.** **Elegida.** Una
   administración rechaza a menudo por falta de un dato de la cabecera (pedido, expediente), y FACe admite la misma factura otra
   vez. Si lo que falla es el importe, se rectifica como siempre.

### Correo de avisos

1. Uno por cliente o por factura.
2. **El correo de la empresa** (Datos de la empresa): sin él no se envía. **Elegida.** Es a quien FACe avisa de los cambios de estado.

### Anexos

1. El PDF de la factura como anexo siempre.
2. **Sin anexos en esta fase.** **Elegida.** La Facturae es la factura. El PDF como anexo, si una administración lo pide.

## Decisión

- **Módulo `face`, «Envío a FACe»**, contratado en la consola. Sin él, la Facturae se sigue generando y descargando (fase 1).
  Permisos `face.consultar` y `face.enviar`, para los dos roles.
- **`envio_face`**: un registro por presentación, con su historial en `envio_face_evento`. La aplicación solo lee; todo pasa por
  funciones de la base.
  - Solo uno vivo por factura: pendiente, o registrado sin rechazo ni anulación. Un pagado sigue vivo, así que no se presenta otra vez.
  - `terminado` (pagada, rechazada, anulada o anulación aceptada): ya no se consulta.
- **Lo que impide enviar**:
  - el módulo, sin contratar;
  - la factura sin emitir, o simplificada;
  - un cliente que no es administración pública;
  - la factura sin DIR3;
  - la empresa sin certificado o sin correo;
  - otro envío vivo de la misma factura.
- **Worker**, solo con `FACE_ENV` (`pre` / `pro`), que pone quien despliega (nunca `pro` en una sesión autónoma):
  - `face.enviar`: genera la Facturae firmada si falta, la firma en el sobre y la envía.
    - Un fallo SOAP 5xx o la falta de respuesta: se reintenta.
    - Un código de FACe distinto de 0 o el 401 del certificado: error con el motivo, sin reintentos.
  - `face.consultar`: por empresa, lo registrado y sin terminar.
  - `face.anular`: pide la anulación con su motivo.
  - Cada envío guarda el entorno donde se registró. La consulta y la anulación solo van a ese entorno.
- **Pantalla**: una franja «FACe» en la factura emitida, bajo la de VeriFactu, con:
  - el estado y el número de registro;
  - el historial;
  - enviar o volver a enviar (con motivo);
  - consultar ahora;
  - pedir la anulación (con motivo).
  Solo sale con el módulo y si el cliente es una administración.

## Consecuencias

- El cliente deja de descargar la Facturae y subirla a FACe a mano, y ve en la factura si está registrada, contabilizada o pagada.
- La prueba con un certificado válido (Enumbers-Test, `FACE_ENV=pre`) tiene que salir del worker de José María: una sesión autónoma
  no saca el certificado de Vault.
- Pendiente:
  - e-FACT y los portales autonómicos (cada uno es otro servicio), si un cliente lo necesita;
  - la búsqueda en el directorio DIR3 desde la ficha (el cliente ya tiene `consultarUnidadesPorAdministracion`);
  - el PDF como anexo.

## Origen

H-082. Mensaje de José María del 25/11/2026 («lo probé y no encontré el motivo por el que deba estar bloqueado»). Implementado en
activopro-platform `20261231000048_envio_face.sql`. Pendiente de que José María lo pase a `accepted`.
