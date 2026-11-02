-- Estructura del schema de tenant de ActivoPro (GeneXus 16 U8, MySQL 8).
-- Origen: mconta0037 (copia local), 2026-11-03. Solo estructura, sin datos.
-- Todas las tablas de tenant comparten esta estructura (generada por GeneXus).

CREATE TABLE `acceso` (
  `AccEmpCod` smallint NOT NULL,
  `AccUsuCod` char(10) NOT NULL,
  `AccWRK` char(15) NOT NULL,
  `AccFechHor` date NOT NULL,
  `AccOBS` char(30) NOT NULL,
  PRIMARY KEY (`AccEmpCod`,`AccUsuCod`,`AccWRK`,`AccFechHor`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `acreedores` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `AcrCod` mediumint NOT NULL,
  `AcrNom` char(40) NOT NULL,
  `AcrCom` char(40) DEFAULT NULL,
  `AcrNemo` char(8) DEFAULT NULL,
  `Acrdir` char(50) DEFAULT NULL,
  `AcrCIF` char(15) DEFAULT NULL,
  `TerClaId` char(2) DEFAULT NULL,
  `AcrTel` char(65) DEFAULT NULL,
  `AcrFax` char(30) DEFAULT NULL,
  `AcrCon1` char(40) DEFAULT NULL,
  `AcrCon2` char(40) DEFAULT NULL,
  `AcrCon1Car` char(15) DEFAULT NULL,
  `AcrCon2Car` char(15) DEFAULT NULL,
  `AcrMail` char(50) DEFAULT NULL,
  `AcrWeb` char(50) DEFAULT NULL,
  `AcrObs` text,
  `AcrEst` char(1) DEFAULT NULL,
  `AcrIRPF` decimal(5,2) DEFAULT NULL,
  `TipIrpfCod` char(3) DEFAULT NULL,
  `AcrComi` decimal(5,2) DEFAULT NULL,
  `AcrUltFac` date DEFAULT NULL,
  `AcrUltUsu` char(10) DEFAULT NULL,
  `AcrUltFec` datetime DEFAULT NULL,
  `CenCod` char(10) DEFAULT NULL,
  `PaiCod` char(3) DEFAULT NULL,
  `PrvCod` char(2) DEFAULT NULL,
  `LocCodPos` char(10) DEFAULT NULL,
  `ClaAcrCod` char(2) DEFAULT NULL,
  `LocCnt` int DEFAULT NULL,
  `AcrCtaTit` char(4) NOT NULL,
  `ForPagCod` char(3) DEFAULT NULL,
  `AcrPlazos` smallint DEFAULT NULL,
  `AcrGtosPago` decimal(3,2) DEFAULT NULL,
  `AcrDiaHastaVto` smallint DEFAULT NULL,
  `AcrDiaEntreVto` smallint DEFAULT NULL,
  `AcrDiaCob1` smallint DEFAULT NULL,
  `AcrDiaCob2` smallint DEFAULT NULL,
  `AcreRiesgoAse` int DEFAULT NULL,
  `AcreRiesgoEmp` int DEFAULT NULL,
  `AcrBanEnt` char(6) DEFAULT NULL,
  `AcrBanOf` char(4) DEFAULT NULL,
  `AcrBanDc` char(2) DEFAULT NULL,
  `AcrBanCta` char(10) DEFAULT NULL,
  `AcrCtaCodGasto` char(6) DEFAULT NULL,
  `AcrCtaTitGasto` char(4) DEFAULT NULL,
  `AcrIvaTpoCod` char(5) DEFAULT NULL,
  `IdiCod` char(3) DEFAULT NULL,
  `AcrBancCod` int DEFAULT NULL,
  `AcrBanSwift` char(11) DEFAULT NULL,
  `AcrBanBban` char(30) DEFAULT NULL,
  `AcrBanIban` char(4) DEFAULT NULL,
  `AcrIgicTpoCod` char(5) DEFAULT NULL,
  `AcrBancCtaCod` char(6) DEFAULT NULL,
  `AcrBancCtaTit` char(4) DEFAULT NULL,
  `AcrFecBaja` date DEFAULT NULL,
  `AcrFecAlta` date DEFAULT NULL,
  `AcrConIdUlt` smallint DEFAULT NULL,
  `AcrCodRaz` char(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`EmpCod`,`AcrCod`),
  KEY `IACREEDORES1` (`EmpCod`,`ClaAcrCod`),
  KEY `IACREEDORES2` (`PaiCod`,`PrvCod`,`LocCodPos`,`LocCnt`),
  KEY `IACREEDORES3` (`CenCod`),
  KEY `IACREEDORES4` (`EmpCod`,`TipIrpfCod`),
  KEY `IACREEDORES5` (`EmpCod`,`ForPagCod`),
  KEY `IACREEDORES6` (`IdiCod`),
  KEY `IACREEDORES7` (`EmpCod`,`TerClaId`),
  CONSTRAINT `IACREEDORES1` FOREIGN KEY (`EmpCod`, `ClaAcrCod`) REFERENCES `claacr` (`EmpCod`, `ClaAcrCod`),
  CONSTRAINT `IACREEDORES4` FOREIGN KEY (`EmpCod`, `TipIrpfCod`) REFERENCES `tipirpf` (`EmpCod`, `TipIrpfCod`),
  CONSTRAINT `IACREEDORES7` FOREIGN KEY (`EmpCod`, `TerClaId`) REFERENCES `tercercladoc` (`EmpCod`, `TerClaId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `acreedoreslevel1` (
  `EmpCod` smallint NOT NULL,
  `AcrCod` mediumint NOT NULL,
  `AcrCtaTer` char(4) NOT NULL,
  `AcrCtaCod` char(6) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`AcrCod`,`AcrCtaTer`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `activofijo2actmod` (
  `EmpCod` smallint NOT NULL,
  `ActId` mediumint NOT NULL,
  `ActModLin` smallint NOT NULL,
  `ActModFec` date DEFAULT NULL,
  `ActModPor` decimal(7,4) DEFAULT NULL,
  `ActModPorR` decimal(9,6) DEFAULT NULL,
  `ActModPdte` decimal(9,2) DEFAULT NULL,
  `ActModFecFin` date DEFAULT NULL,
  `ActModPorFis` decimal(7,4) DEFAULT NULL,
  `ActModPorFisR` decimal(9,6) DEFAULT NULL,
  `ActModPdteFis` decimal(9,2) DEFAULT NULL,
  `ActModFecFinFis` date DEFAULT NULL,
  `ActModUsu` char(10) DEFAULT NULL,
  `ActModMod` datetime DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`ActId`,`ActModLin`),
  CONSTRAINT `IACTIVOFIJO2ACTMOD1` FOREIGN KEY (`EmpCod`, `ActId`) REFERENCES `activofijo` (`EmpCod`, `ActId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `activofijo` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `ActId` mediumint NOT NULL,
  `ActNom` char(80) DEFAULT NULL,
  `GruIdCtaTit` char(4) DEFAULT NULL,
  `GruIdCtaCod` char(6) DEFAULT NULL,
  `ActFab` char(80) DEFAULT NULL,
  `ActCom` char(80) DEFAULT NULL,
  `ActAcc` char(80) DEFAULT NULL,
  `ActObs` char(80) DEFAULT NULL,
  `ActFis` char(80) DEFAULT NULL,
  `ActLoc` char(80) DEFAULT NULL,
  `CentCod` smallint DEFAULT NULL,
  `DvsCod` smallint DEFAULT NULL,
  `ActFec` date DEFAULT NULL,
  `ActAny` decimal(6,2) DEFAULT NULL,
  `ActPor` decimal(8,4) DEFAULT NULL,
  `ActCri` char(3) DEFAULT NULL,
  `ActValRes` decimal(9,2) DEFAULT NULL,
  `ActUltCos` smallint DEFAULT NULL,
  `ActUltAmo` smallint DEFAULT NULL,
  `ActUltCon` smallint DEFAULT NULL,
  `ActUltBaj` smallint DEFAULT NULL,
  `ActUltDoc` smallint DEFAULT NULL,
  `ActInmCtaCod` char(6) DEFAULT NULL,
  `ActAmoCtaCod` char(6) DEFAULT NULL,
  `ActDotCtaCod` char(6) DEFAULT NULL,
  `ActMovim` char(23) DEFAULT NULL,
  `ActCompleta` char(1) DEFAULT NULL,
  `ActPorModif` decimal(8,4) DEFAULT NULL,
  `ActFecModif` date DEFAULT NULL,
  `GruAmoCtaTit` char(4) NOT NULL DEFAULT '',
  `GruAmoCtaCod` char(6) NOT NULL DEFAULT '',
  `GruDotCtaTit` char(4) NOT NULL DEFAULT '',
  `GruDotCtaCod` char(6) NOT NULL DEFAULT '',
  `ActAnyFis` decimal(6,2) DEFAULT NULL,
  `ActPorFis` decimal(8,4) DEFAULT NULL,
  `Actmodif` datetime DEFAULT NULL,
  `ActUsu` char(10) DEFAULT NULL,
  `ActUltMod` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`ActId`),
  KEY `IACTIVOFIJO1` (`EmpCod`,`CentCod`,`DvsCod`),
  KEY `IACTIVOFIJO3` (`EmpCod`,`GruIdCtaTit`,`GruIdCtaCod`),
  KEY `UACTIVOFIJO` (`EmpCod`,`ActCompleta`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `activofijoactamo` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `ActId` mediumint NOT NULL,
  `ActAmoLin` smallint NOT NULL,
  `ActAmoAny` char(4) NOT NULL,
  `ActAmoImp` decimal(9,2) NOT NULL,
  `ActAmoUMes` smallint unsigned NOT NULL DEFAULT '0',
  `ActAmoPMes` smallint unsigned NOT NULL DEFAULT '0',
  `ActAmoImpFis` decimal(10,2) DEFAULT NULL,
  `ActAmoUmesFis` smallint DEFAULT NULL,
  `ActAmoPmesFis` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`ActId`,`ActAmoLin`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `activofijoactbaj` (
  `EmpCod` smallint NOT NULL,
  `ActId` mediumint NOT NULL,
  `ActBajLin` smallint NOT NULL,
  `ActBajFec` date NOT NULL,
  `ActBajCon` char(30) NOT NULL,
  `ActBajUni` smallint NOT NULL,
  `ActBajImp` decimal(9,2) NOT NULL,
  `ActBajMod` datetime DEFAULT NULL,
  `ActBajUsu` char(10) DEFAULT NULL,
  `ActBajCtaCod` char(6) DEFAULT NULL,
  `ActBajCtaTit` char(4) DEFAULT NULL,
  `ActBajMot` char(1) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`ActId`,`ActBajLin`),
  CONSTRAINT `IACTIVOFIJOACTBAJ1` FOREIGN KEY (`EmpCod`, `ActId`) REFERENCES `activofijo` (`EmpCod`, `ActId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `activofijoactcon` (
  `EmpCod` smallint NOT NULL,
  `ActId` mediumint NOT NULL,
  `ActConLin` smallint NOT NULL,
  `ActConAny` char(4) NOT NULL,
  `ActConMes` char(2) NOT NULL,
  `ActConImp` decimal(9,2) NOT NULL,
  `ActConCon` char(1) NOT NULL,
  `ActMovId` char(23) DEFAULT NULL,
  `ActConImpFis` decimal(9,2) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`ActId`,`ActConLin`),
  CONSTRAINT `IACTIVOFIJOACTCON1` FOREIGN KEY (`EmpCod`, `ActId`) REFERENCES `activofijo` (`EmpCod`, `ActId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `activofijoactcos` (
  `EmpCod` smallint NOT NULL,
  `ActId` mediumint NOT NULL,
  `ActCosLin` smallint NOT NULL,
  `ActCosFec` date DEFAULT NULL,
  `ActCosCon` char(30) DEFAULT NULL,
  `ActCosPro` char(40) DEFAULT NULL,
  `ActCosUni` smallint DEFAULT NULL,
  `ActCosImp` decimal(11,2) DEFAULT NULL,
  `ActCtaTerCod` char(6) DEFAULT NULL,
  `ActCtaTerTit` char(4) DEFAULT NULL,
  `ActCosMod` datetime DEFAULT NULL,
  `ActCosUsu` char(10) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`ActId`,`ActCosLin`),
  CONSTRAINT `IACTIVOFIJOACTCOS1` FOREIGN KEY (`EmpCod`, `ActId`) REFERENCES `activofijo` (`EmpCod`, `ActId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `activofijoactdoc` (
  `EmpCod` smallint NOT NULL,
  `ActId` mediumint NOT NULL,
  `ActDocLin` smallint NOT NULL,
  `ActDocImg` longblob NOT NULL,
  `ActDocNom` char(200) NOT NULL,
  `ActDocTyp` char(4) NOT NULL,
  PRIMARY KEY (`EmpCod`,`ActId`,`ActDocLin`),
  CONSTRAINT `IACTIVOFIJOACTDOC1` FOREIGN KEY (`EmpCod`, `ActId`) REFERENCES `activofijo` (`EmpCod`, `ActId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `activofijoclase` (
  `EmpCod` smallint NOT NULL,
  `ActId` mediumint NOT NULL,
  `ClaInmCod` char(2) NOT NULL,
  PRIMARY KEY (`EmpCod`,`ActId`,`ClaInmCod`),
  KEY `IACTIVOFIJOCLASE1` (`EmpCod`,`ClaInmCod`),
  CONSTRAINT `IACTIVOFIJOCLASE1` FOREIGN KEY (`EmpCod`, `ClaInmCod`) REFERENCES `clainmo` (`EmpCod`, `ClaInmCod`),
  CONSTRAINT `IACTIVOFIJOCLASE2` FOREIGN KEY (`EmpCod`, `ActId`) REFERENCES `activofijo` (`EmpCod`, `ActId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `adjmovctas` (
  `adjempcod` smallint NOT NULL,
  `adjejercod` char(8) NOT NULL,
  `adjmovid` int NOT NULL,
  `adjmovimgdoc` longblob NOT NULL,
  `adjmovimgtype` char(4) NOT NULL,
  `adjmovimgname` char(200) NOT NULL,
  PRIMARY KEY (`adjempcod`,`adjejercod`,`adjmovid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `articulos` (
  `EmpCod` smallint NOT NULL,
  `ArtCod` char(13) NOT NULL,
  `ArtDes` char(50) DEFAULT NULL,
  `ArtPre` decimal(10,3) DEFAULT NULL,
  `ArtDesLar` varchar(2048) DEFAULT NULL,
  `ArtBarra` char(13) DEFAULT NULL,
  `ArtCtaTit` char(4) DEFAULT NULL,
  `ArtCtaCod` char(6) DEFAULT NULL,
  `ArtIvaTpoCod` char(5) DEFAULT NULL,
  `ArtDesSN` char(1) DEFAULT NULL,
  `ArtFamCod` char(8) DEFAULT NULL,
  `ArtDocImg` longblob,
  `ArtDocNom` char(200) DEFAULT NULL,
  `ArtDocTyp` char(4) DEFAULT NULL,
  `ArtCtaTitI` char(4) DEFAULT NULL,
  `ArtCtaCodI` char(6) DEFAULT NULL,
  `ArtCtaTitE` char(4) DEFAULT NULL,
  `ArtCtaCodE` char(6) DEFAULT NULL,
  `ArtUni` char(3) DEFAULT NULL,
  `ArtClase` char(1) DEFAULT NULL,
  `ArtStock` char(1) DEFAULT NULL,
  `ArtIrpfCod` char(3) DEFAULT NULL,
  `ArtComLin` smallint DEFAULT NULL,
  `ArtNoseqe` char(1) DEFAULT NULL,
  `ArtUsu` char(10) DEFAULT NULL,
  `ArtMod` datetime DEFAULT NULL,
  `ArtIgicTpoCod` char(5) DEFAULT NULL,
  `ArtBaj` char(1) DEFAULT NULL,
  `ArtPreCod` decimal(9,3) DEFAULT NULL,
  `ArtUniCaj` decimal(9,3) DEFAULT NULL,
  `ArtPreCom` decimal(9,3) DEFAULT NULL,
  `ArtIntCod` smallint DEFAULT NULL,
  `ArtDetLot` char(1) DEFAULT NULL,
  `ArtCodDes` char(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`EmpCod`,`ArtCod`),
  KEY `UARTICULOS` (`EmpCod`,`ArtBarra`),
  KEY `IARTICULOS1` (`EmpCod`,`ArtCtaTit`,`ArtCtaCod`),
  KEY `IARTICULOS2` (`EmpCod`,`ArtCtaTitI`,`ArtCtaCodI`),
  KEY `IARTICULOS3` (`EmpCod`,`ArtCtaTitE`,`ArtCtaCodE`),
  KEY `IARTICULOS4` (`EmpCod`,`ArtUni`),
  KEY `IARTICULOS5` (`EmpCod`,`ArtFamCod`),
  CONSTRAINT `IARTICULOS1` FOREIGN KEY (`EmpCod`, `ArtCtaTit`, `ArtCtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `IARTICULOS2` FOREIGN KEY (`EmpCod`, `ArtCtaTitI`, `ArtCtaCodI`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `IARTICULOS3` FOREIGN KEY (`EmpCod`, `ArtCtaTitE`, `ArtCtaCodE`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `IARTICULOS4` FOREIGN KEY (`EmpCod`, `ArtUni`) REFERENCES `uniconsumo` (`EmpCod`, `UniCod`),
  CONSTRAINT `IARTICULOS5` FOREIGN KEY (`EmpCod`, `ArtFamCod`) REFERENCES `familias` (`EmpCod`, `FamCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `artiprecio` (
  `EmpCod` smallint NOT NULL,
  `ArtCod` char(13) NOT NULL,
  `ArtFecVig` date NOT NULL,
  `ArtPreLin` decimal(9,3) DEFAULT NULL,
  `ArtFecUsu` char(10) DEFAULT NULL,
  `ArtFecMod` datetime DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`ArtCod`,`ArtFecVig`),
  KEY `IARTIPRECIO1` (`EmpCod`,`ArtCod`),
  CONSTRAINT `IARTIPRECIO1` FOREIGN KEY (`EmpCod`, `ArtCod`) REFERENCES `articulos` (`EmpCod`, `ArtCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `artistock` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `ArtCod` char(13) NOT NULL,
  `ArtCentCod` smallint NOT NULL,
  `ArtStockCan` decimal(9,3) NOT NULL,
  `ArtStockMin` decimal(9,3) NOT NULL,
  `ArtStockMax` decimal(9,3) NOT NULL,
  `ArtStockRes` decimal(9,3) NOT NULL,
  `ArtStockResPed` decimal(9,3) NOT NULL,
  `ArtIntCod` int DEFAULT NULL,
  `ArtStockPreMed` decimal(9,3) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`ArtCod`,`ArtCentCod`),
  CONSTRAINT `IARTICULOSTOCK1` FOREIGN KEY (`EmpCod`, `ArtCod`) REFERENCES `articulos` (`EmpCod`, `ArtCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `artitarifas` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `ArtCod` char(13) NOT NULL,
  `ArtTarCod` smallint NOT NULL,
  PRIMARY KEY (`EmpCod`,`ArtCod`,`ArtTarCod`),
  CONSTRAINT `IARTITARIFAS1` FOREIGN KEY (`EmpCod`, `ArtCod`) REFERENCES `articulos` (`EmpCod`, `ArtCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `artitarifasimporte` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `ArtCod` char(13) NOT NULL,
  `ArtTarCod` smallint NOT NULL,
  `ArtTarDivCod` char(3) NOT NULL,
  `ArtTarDivFecVig` date NOT NULL,
  `ArtTarDivImp` decimal(9,3) NOT NULL DEFAULT '0.000',
  `ArtTarDivUsu` char(10) NOT NULL,
  `ArtTarDivUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`ArtCod`,`ArtTarCod`,`ArtTarDivCod`,`ArtTarDivFecVig`),
  CONSTRAINT `IARTITARIFASIMPORTE1` FOREIGN KEY (`EmpCod`, `ArtCod`, `ArtTarCod`) REFERENCES `artitarifas` (`EmpCod`, `ArtCod`, `ArtTarCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `asidefcontroles` (
  `AsiEmpCod` smallint NOT NULL DEFAULT '0',
  `AsiDefCod` mediumint NOT NULL,
  `AsiDefConId` smallint NOT NULL,
  `AsiDefCon1` char(40) NOT NULL DEFAULT '',
  `AsiDefCon2` char(40) NOT NULL DEFAULT '',
  PRIMARY KEY (`AsiEmpCod`,`AsiDefCod`,`AsiDefConId`),
  CONSTRAINT `IASIDEFINICIONCONTROLES1` FOREIGN KEY (`AsiEmpCod`, `AsiDefCod`) REFERENCES `asidefinicion` (`AsiEmpCod`, `AsiDefCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `asidefcontrolestexto` (
  `AsiEmpCod` smallint NOT NULL,
  `AsiDefCod` mediumint NOT NULL,
  `AsiDefConId` smallint NOT NULL,
  `AsiDefConIdiCod` char(3) NOT NULL,
  `AsiDefConIdiText` char(80) NOT NULL,
  PRIMARY KEY (`AsiEmpCod`,`AsiDefCod`,`AsiDefConId`,`AsiDefConIdiCod`),
  CONSTRAINT `IASIDEFINICIONCONTROLESCONTRO1` FOREIGN KEY (`AsiEmpCod`, `AsiDefCod`, `AsiDefConId`) REFERENCES `asidefcontroles` (`AsiEmpCod`, `AsiDefCod`, `AsiDefConId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `asidefinicion` (
  `AsiEmpCod` smallint NOT NULL DEFAULT '0',
  `AsiDefCod` mediumint NOT NULL,
  `AsiDefUltCont` int NOT NULL DEFAULT '0',
  `AsiDefUltAsi` int NOT NULL DEFAULT '0',
  `AsiDefEst` char(1) NOT NULL DEFAULT 'A',
  PRIMARY KEY (`AsiEmpCod`,`AsiDefCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `asidefinicionidioma` (
  `AsiEmpCod` smallint NOT NULL,
  `AsiDefCod` mediumint NOT NULL,
  `AsiDefIdiCod` char(3) NOT NULL,
  `AsiDefIdiNom` char(80) NOT NULL,
  PRIMARY KEY (`AsiEmpCod`,`AsiDefCod`,`AsiDefIdiCod`),
  CONSTRAINT `IASIDEFINICIONIDIOMA1` FOREIGN KEY (`AsiEmpCod`, `AsiDefCod`) REFERENCES `asidefinicion` (`AsiEmpCod`, `AsiDefCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `asideflineas` (
  `AsiEmpCod` smallint NOT NULL DEFAULT '0',
  `AsiDefCod` mediumint NOT NULL,
  `AsiDefLin` int NOT NULL,
  `AsiDefGrupo` mediumint NOT NULL,
  `AsiDefOrden` mediumint NOT NULL,
  `AsiDefCtaTit` char(4) NOT NULL,
  `AsiDefCtaCod` char(6) NOT NULL,
  `AsiDefLinTpo` char(1) NOT NULL,
  `AsiDefConCod` smallint NOT NULL,
  `AsiDefCantLin` mediumint NOT NULL,
  `AsiDefObs` char(80) NOT NULL DEFAULT '',
  `AsiDefLinConf` char(40) DEFAULT NULL,
  PRIMARY KEY (`AsiEmpCod`,`AsiDefCod`,`AsiDefLin`),
  CONSTRAINT `IASIDEFINICIONASIENTO1` FOREIGN KEY (`AsiEmpCod`, `AsiDefCod`) REFERENCES `asidefinicion` (`AsiEmpCod`, `AsiDefCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `asideflintexto` (
  `AsiEmpCod` smallint NOT NULL,
  `AsiDefCod` mediumint NOT NULL,
  `AsiDefLin` int NOT NULL,
  `AsiDefLinIdiCod` char(3) NOT NULL,
  `AsiDefLinIdiText` char(80) NOT NULL,
  PRIMARY KEY (`AsiEmpCod`,`AsiDefCod`,`AsiDefLin`,`AsiDefLinIdiCod`),
  CONSTRAINT `IASIDEFINICIONASIENTOASIENTO_1` FOREIGN KEY (`AsiEmpCod`, `AsiDefCod`, `AsiDefLin`) REFERENCES `asideflineas` (`AsiEmpCod`, `AsiDefCod`, `AsiDefLin`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `auditores` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `AdtId` smallint NOT NULL,
  `AdtROAC` int DEFAULT NULL,
  `AdtFec` date DEFAULT NULL,
  `AdtFecIni` date DEFAULT NULL,
  `AdtFecFin` date DEFAULT NULL,
  `AdtEjercod` char(8) DEFAULT NULL,
  `AdtMes` smallint DEFAULT NULL,
  `AdtFecCarta` date DEFAULT NULL,
  `AdtUsuCod` char(10) DEFAULT NULL,
  `AdtUltMod` datetime DEFAULT NULL,
  `AcrCod` mediumint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`AdtId`),
  KEY `IAUDITORES1` (`EmpCod`,`AcrCod`),
  CONSTRAINT `IAUDITORES1` FOREIGN KEY (`EmpCod`, `AcrCod`) REFERENCES `acreedores` (`EmpCod`, `AcrCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `bancos_contactos` (
  `EmpCod` smallint NOT NULL,
  `BancCod` int NOT NULL,
  `BanConId` smallint NOT NULL,
  `BancConTip` char(30) DEFAULT NULL,
  `BancConNom` char(30) DEFAULT NULL,
  `BancConTel` char(20) DEFAULT NULL,
  `BancConMov` char(20) DEFAULT NULL,
  `BancConMail` char(50) DEFAULT NULL,
  `CarCod` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`BancCod`,`BanConId`),
  KEY `IBANCOS_CONTACTOS` (`EmpCod`,`CarCod`),
  CONSTRAINT `IBANCOS_CONTACTOS` FOREIGN KEY (`EmpCod`, `CarCod`) REFERENCES `tcargos` (`EmpCod`, `CarCod`),
  CONSTRAINT `IBANCOSCONTACTOS` FOREIGN KEY (`EmpCod`, `BancCod`) REFERENCES `bancos` (`EmpCod`, `BancCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `bancos` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `BancCod` int NOT NULL,
  `BancNom` char(40) NOT NULL,
  `BancUltCtaid` smallint NOT NULL,
  `BancSwift` char(11) NOT NULL,
  `BancCif` char(15) NOT NULL,
  `LocCodPos` char(10) DEFAULT NULL,
  `LocCnt` int DEFAULT NULL,
  `PrvCod` char(2) DEFAULT NULL,
  `PaiCod` char(3) DEFAULT NULL,
  `BancDir` char(50) NOT NULL,
  `BancUsuCod` char(10) NOT NULL,
  `BancUltMov` datetime NOT NULL,
  `BancUltApunt` int DEFAULT NULL,
  `BancWeb` char(50) DEFAULT NULL,
  `BancMail` char(50) DEFAULT NULL,
  `BancFax` char(30) DEFAULT NULL,
  `BancTel` char(65) DEFAULT NULL,
  `BancNomCom` char(40) NOT NULL,
  `BancCabEnt` char(6) DEFAULT NULL,
  `BancCabOf` char(4) DEFAULT NULL,
  `BancCabOfEnt` char(10) DEFAULT NULL,
  `BanConIdUlt` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`BancCod`),
  KEY `IBANCOS` (`PaiCod`,`PrvCod`,`LocCodPos`,`LocCnt`),
  CONSTRAINT `ITBANCOS1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `bancosbcta` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `BancCod` int NOT NULL,
  `BancEnt` char(6) NOT NULL,
  `BancOf` char(4) NOT NULL,
  `BancDC` char(2) NOT NULL,
  `BancCta` char(10) NOT NULL,
  `BancCodIban` char(34) NOT NULL,
  `BancCheNroRH` int DEFAULT NULL,
  `BancCheNroRD` int DEFAULT NULL,
  `BancPagNroRH` int DEFAULT NULL,
  `BancPagNroRD` int DEFAULT NULL,
  `BancPagSerie` char(4) DEFAULT NULL,
  `BancPagNroH` int DEFAULT NULL,
  `BancPagNroD` int DEFAULT NULL,
  `BancUltPag` int DEFAULT NULL,
  `BancCheSerie` char(4) DEFAULT NULL,
  `BancCheNroH` int DEFAULT NULL,
  `BancCheNroD` int DEFAULT NULL,
  `BancUltChe` int DEFAULT NULL,
  `BancCtaTit` char(4) DEFAULT NULL,
  `BancCtaCod` char(6) DEFAULT NULL,
  `BancSufijo34` smallint DEFAULT NULL,
  `BancSufijo58` smallint DEFAULT NULL,
  `BancSufijo19` smallint DEFAULT NULL,
  `BancBBan` char(30) DEFAULT NULL,
  `BancIban` char(4) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`BancCod`,`BancEnt`,`BancOf`,`BancDC`,`BancCta`),
  CONSTRAINT `ITBANCOSBANCOCTA1` FOREIGN KEY (`EmpCod`, `BancCod`) REFERENCES `bancos` (`EmpCod`, `BancCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `bancoscontactos` (
  `EmpCod` smallint NOT NULL,
  `BancCod` int NOT NULL,
  `BancConTip` char(30) NOT NULL,
  `BancConNom` char(30) DEFAULT NULL,
  `BancConTel` char(20) DEFAULT NULL,
  `BancConMov` char(20) DEFAULT NULL,
  `BancConMail` char(50) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`BancCod`,`BancConTip`),
  CONSTRAINT `IBANCOSCONTACTOS1` FOREIGN KEY (`EmpCod`, `BancCod`) REFERENCES `bancos` (`EmpCod`, `BancCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `cartamod` (
  `EmpCod` smallint NOT NULL,
  `CartaId` smallint NOT NULL,
  `CartaMod` char(1) NOT NULL,
  `IdiCod` char(3) NOT NULL,
  `CartaModMod` longblob NOT NULL,
  `CartaCom` char(40) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CartaId`),
  KEY `ICARTAMOD1` (`IdiCod`),
  CONSTRAINT `ICARTAMOD1` FOREIGN KEY (`IdiCod`) REFERENCES `idiomas` (`IdiCod`),
  CONSTRAINT `ICARTAMOD2` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `carteradecobros` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `CcbId` int NOT NULL,
  `CliCod` mediumint NOT NULL,
  `CliDirCod` mediumint DEFAULT NULL,
  `CcbFacFec` date NOT NULL,
  `CcbFacSer` char(3) NOT NULL,
  `CcbFacNum` decimal(8,0) NOT NULL DEFAULT '0',
  `CcbFacImp` decimal(11,2) NOT NULL DEFAULT '0.00',
  `CcbDivCod` char(3) DEFAULT NULL,
  `CcbDivCam` decimal(11,4) DEFAULT NULL,
  `CcbDivImp` decimal(11,2) DEFAULT NULL,
  `DocCod` char(3) NOT NULL,
  `CcbCiaSeg` decimal(6,0) DEFAULT NULL,
  `CcbFacEjer` char(8) DEFAULT NULL,
  `CcbFacAsi` int DEFAULT NULL,
  `CcbUltLin` smallint NOT NULL,
  `CcbUsu` char(10) NOT NULL,
  `CcbMod` datetime NOT NULL,
  `CcbCobCod` char(3) NOT NULL,
  `CcbPdf` mediumblob,
  `CcbCon82` char(40) DEFAULT NULL,
  `CcbCon81` char(40) DEFAULT NULL,
  `CcbCon72` char(40) DEFAULT NULL,
  `CcbCon71` char(40) DEFAULT NULL,
  `CcbCon62` char(40) DEFAULT NULL,
  `CcbCon61` char(40) DEFAULT NULL,
  `CcbCon52` char(40) DEFAULT NULL,
  `CcbCon51` char(40) DEFAULT NULL,
  `CcbCon42` char(40) DEFAULT NULL,
  `CcbCon41` char(40) DEFAULT NULL,
  `CcbCon32` char(40) DEFAULT NULL,
  `CcbCon31` char(40) DEFAULT NULL,
  `CcbCon22` char(40) DEFAULT NULL,
  `CcbCon21` char(40) DEFAULT NULL,
  `CcbCon12` char(40) DEFAULT NULL,
  `CcbCon11` char(40) DEFAULT NULL,
  `CcbCon17` char(17) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CcbId`),
  KEY `ICARTERADECOBROS2` (`EmpCod`,`DocCod`),
  KEY `ICARTERADECOBROS1` (`EmpCod`,`CliCod`,`CliDirCod`),
  KEY `UCARTERADECOBROS1` (`EmpCod`,`CcbId`,`CcbFacEjer`,`CcbFacAsi`),
  KEY `UCARTERADECOBROS2` (`EmpCod`,`CcbFacEjer`,`CcbFacAsi`),
  KEY `UCARTERADECOBROS` (`EmpCod`,`CliCod`,`CliDirCod`,`CcbCon11`),
  KEY `UCARTERADECOBROS3` (`EmpCod`,`CcbFacFec`),
  CONSTRAINT `ICARTERADECOBROS1` FOREIGN KEY (`EmpCod`, `CliCod`, `CliDirCod`) REFERENCES `clidir` (`EmpCod`, `CliCod`, `CliDirCod`),
  CONSTRAINT `ICARTERADECOBROS2` FOREIGN KEY (`EmpCod`, `DocCod`) REFERENCES `docscartera` (`EmpCod`, `DocCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `carteradecobrosccbvto` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `CcbId` int NOT NULL,
  `CcbVtoLin` smallint NOT NULL,
  `CcbVto` date NOT NULL,
  `CcbVtoImp` decimal(11,2) NOT NULL,
  `CcbVtoLis` date DEFAULT NULL,
  `CcbVtoUlt` smallint NOT NULL,
  `CcbVtoRemFec` date DEFAULT NULL,
  `CcbVtoRemNum` decimal(8,0) DEFAULT NULL,
  `CcbVtoCom` char(40) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CcbId`,`CcbVtoLin`),
  CONSTRAINT `ICARTERADECOBROSCCBVTO1` FOREIGN KEY (`EmpCod`, `CcbId`) REFERENCES `carteradecobros` (`EmpCod`, `CcbId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `carteradecobrosccbvtocob` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `CcbId` int NOT NULL,
  `CcbVtoLin` smallint NOT NULL,
  `CcbVtoCobLin` smallint NOT NULL,
  `CcbVtoCobImp` decimal(11,2) NOT NULL,
  `CcbVtoCobFec` date NOT NULL,
  `CcbVtoCobNum` int NOT NULL,
  `CcbVtoCobUsu` char(10) NOT NULL,
  `CcbVtoCobMod` datetime NOT NULL,
  `CcbVtoCobRis` decimal(11,2) NOT NULL,
  `CcbVtoRisCod` char(3) NOT NULL DEFAULT '',
  `CcbVtoCobCtaCod` char(6) DEFAULT NULL,
  `CcbVtoCobCtaTit` char(4) DEFAULT NULL,
  `CcbVtoMovid` int DEFAULT NULL,
  `CcbVtoEjercod` char(8) DEFAULT NULL,
  `CcbVtoCobDev` char(1) DEFAULT NULL,
  `CcbVtoNumEfe` char(10) DEFAULT NULL,
  `CcbVtoBanEfe` char(20) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CcbId`,`CcbVtoLin`,`CcbVtoCobLin`),
  KEY `UCARTERADECOBROSCCBVTOCOBMOVID` (`EmpCod`,`CcbVtoEjercod`,`CcbVtoMovid`),
  CONSTRAINT `ICARTERADECOBROSCCBVTOCCBVTOC1` FOREIGN KEY (`EmpCod`, `CcbId`, `CcbVtoLin`) REFERENCES `carteradecobrosccbvto` (`EmpCod`, `CcbId`, `CcbVtoLin`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `carteraefectos` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `CefId` int NOT NULL,
  `CliCod` mediumint NOT NULL,
  `CefVto` date NOT NULL,
  `CefRisCod` char(3) NOT NULL DEFAULT '',
  `CefImp` decimal(11,2) NOT NULL,
  `CefCobFec` date NOT NULL,
  `CefRecNum` int DEFAULT NULL,
  `CefBanCtaTit` char(4) DEFAULT NULL,
  `CefBanCtaCod` char(6) DEFAULT NULL,
  `CefBanFec` date DEFAULT NULL,
  `CefUsu` char(10) NOT NULL,
  `CefMod` datetime NOT NULL,
  `CefBanIban` char(34) DEFAULT NULL,
  `CefBanAsi` int DEFAULT NULL,
  `CefBanEjer` char(8) DEFAULT NULL,
  `CefCobAsi` int DEFAULT NULL,
  `CefCobEjer` char(8) DEFAULT NULL,
  `CefDev` char(1) DEFAULT NULL,
  `CefFecLib` date DEFAULT NULL,
  `CefDomCta` char(10) DEFAULT NULL,
  `CefDomDC` char(2) DEFAULT NULL,
  `CefDomOfi` char(4) DEFAULT NULL,
  `CefDomEnt` char(6) DEFAULT NULL,
  `CefGastos` char(1) DEFAULT NULL,
  `CefDevMovid` int DEFAULT NULL,
  `CefDevEjer` char(8) DEFAULT NULL,
  `CefDevNum` int DEFAULT NULL,
  `CefDevFec` date DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CefId`),
  KEY `ICARTERAEFECTOS2` (`EmpCod`,`CliCod`),
  KEY `UCARTERAEFECTOS` (`EmpCod`,`CefBanEjer`,`CefBanAsi`),
  CONSTRAINT `ICARTERAEFECTOS2` FOREIGN KEY (`EmpCod`, `CliCod`) REFERENCES `clientes` (`EmpCod`, `CliCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `carterapagos` (
  `EmpCod` smallint NOT NULL,
  `CpgId` int NOT NULL,
  `CpgMovObs` char(40) NOT NULL,
  `CtaTit` char(4) NOT NULL,
  `CtaCod` char(6) NOT NULL,
  `CpgImp` decimal(11,2) NOT NULL,
  `CpgDivCod` char(3) DEFAULT NULL,
  `CpgDivCam` decimal(11,4) DEFAULT NULL,
  `CpgDivImp` decimal(11,2) DEFAULT NULL,
  `CpgTipo` char(1) NOT NULL,
  `CpgEjerCod` char(8) DEFAULT NULL,
  `CpgMovId` int DEFAULT NULL,
  `CpgForPag` char(3) DEFAULT NULL,
  `CpgUsu` char(10) NOT NULL,
  `CpgMod` datetime NOT NULL,
  `CpgUltLin` smallint NOT NULL,
  `CpgBancod` int DEFAULT NULL,
  `CpgFecha` date NOT NULL,
  `CpgTransNif` char(15) DEFAULT NULL,
  `CpgTransBenef` char(50) DEFAULT NULL,
  `CpgTransGtos` char(1) DEFAULT NULL,
  `CpgTransOrden` char(1) DEFAULT NULL,
  `CpgBancSwift` char(11) DEFAULT NULL,
  `CpgBancBban` char(30) DEFAULT NULL,
  `CpgBancIban` char(4) DEFAULT NULL,
  `CpgBancCta` char(10) DEFAULT NULL,
  `CpgBancDc` char(2) DEFAULT NULL,
  `CpgBancOfi` char(4) DEFAULT NULL,
  `CpgBancEnt` char(6) DEFAULT NULL,
  `CpgBancCtaCod` char(6) DEFAULT NULL,
  `CpgBancCtaTit` char(4) DEFAULT NULL,
  `CpgCtaCod` mediumint DEFAULT NULL,
  `Cpgctareftpo` char(1) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CpgId`),
  KEY `ICARTERAPAGOS2` (`EmpCod`,`CtaTit`,`CtaCod`),
  KEY `UCARTERAPAGOS1` (`EmpCod`,`CpgEjerCod`,`CpgMovId`),
  CONSTRAINT `ICARTERAPAGOS2` FOREIGN KEY (`EmpCod`, `CtaTit`, `CtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `carterapagoscpgvto` (
  `EmpCod` smallint NOT NULL,
  `CpgId` int NOT NULL,
  `CpgVtoLin` smallint NOT NULL,
  `CpgVto` date NOT NULL,
  `CpgVtoImp` decimal(11,2) NOT NULL,
  `CpgVtoRemFec` date DEFAULT NULL,
  `CpgVtoRemNum` int DEFAULT NULL,
  `CpgVtoCom` char(40) DEFAULT NULL,
  `CpgVtoUlt` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CpgId`,`CpgVtoLin`),
  CONSTRAINT `ICARTERAPAGOSCPGVTO1` FOREIGN KEY (`EmpCod`, `CpgId`) REFERENCES `carterapagos` (`EmpCod`, `CpgId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `carterapagoscpgvtopag` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `CpgId` int NOT NULL,
  `CpgVtoLin` smallint NOT NULL,
  `CpgVtoLinPag` smallint NOT NULL,
  `CpgVtoPagImp` decimal(11,2) DEFAULT NULL,
  `CpgVtoPagFec` date DEFAULT NULL,
  `CpgVtoPagNum` int DEFAULT NULL,
  `CpgVtoPag` char(3) DEFAULT NULL,
  `CpgVtoCtaTit` char(4) DEFAULT NULL,
  `CpgVtoCtaCod` char(6) DEFAULT NULL,
  `CpgVtoMovid` int DEFAULT NULL,
  `CpgVtoEjercod` char(8) DEFAULT NULL,
  `CpgVtoEfeCtaTit` char(4) DEFAULT NULL,
  `CpgVtoEfeCtaCod` char(6) DEFAULT NULL,
  `CpgVtoMovid2` int DEFAULT NULL,
  `CpgVtoEjercod2` char(8) DEFAULT NULL,
  `CpgVtoEfeFec` date DEFAULT NULL,
  `CpgVtoPagUsu` char(10) DEFAULT NULL,
  `CpgVtoPagMod` datetime DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CpgId`,`CpgVtoLin`,`CpgVtoLinPag`),
  KEY `UCARTERAPAGOSCPGVTOMOVID` (`EmpCod`,`CpgVtoEjercod`,`CpgVtoMovid`),
  CONSTRAINT `ICARTERAPAGOSCPGVTOPAG1` FOREIGN KEY (`EmpCod`, `CpgId`, `CpgVtoLin`) REFERENCES `carterapagoscpgvto` (`EmpCod`, `CpgId`, `CpgVtoLin`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `cenae` (
  `CenCod` char(10) NOT NULL DEFAULT '',
  `CenDes` char(130) NOT NULL,
  `CenUsuCod` char(10) NOT NULL DEFAULT '',
  `CenUltMod` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`CenCod`),
  KEY `UCENAE1` (`CenDes`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `claacr` (
  `EmpCod` smallint NOT NULL,
  `ClaAcrCod` char(2) NOT NULL,
  `ClaAcrDes` char(40) NOT NULL,
  `ClaAcrGto` decimal(5,2) NOT NULL,
  `ClaAcrUsu` char(10) NOT NULL,
  `ClaAcrUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`ClaAcrCod`),
  KEY `UCLAACR2` (`EmpCod`,`ClaAcrDes`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `clacli` (
  `EmpCod` smallint NOT NULL,
  `ClaCliCod` char(2) NOT NULL,
  `ClaCliDes` char(40) NOT NULL,
  `ClaCliGto` decimal(5,2) NOT NULL,
  `ClaUsuCod` char(10) NOT NULL,
  `ClaUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`ClaCliCod`),
  KEY `UCLACLI1` (`EmpCod`,`ClaCliDes`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `clainmo` (
  `EmpCod` smallint NOT NULL,
  `ClaInmCod` char(2) NOT NULL,
  `ClaInmDes` char(40) NOT NULL,
  `ClaInmUsuCod` char(10) NOT NULL,
  `ClaInmUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`ClaInmCod`),
  CONSTRAINT `ITCLAINMO1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `clapro` (
  `EmpCod` smallint NOT NULL,
  `ClaProCod` char(2) NOT NULL,
  `ClaProDes` char(40) NOT NULL,
  `ClaProGto` decimal(5,2) NOT NULL,
  `ClaProUsu` char(10) NOT NULL,
  `ClaProUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`ClaProCod`),
  KEY `UCLAPRO2` (`EmpCod`,`ClaProDes`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `cliarticulostarifa` (
  `EmpCod` smallint NOT NULL,
  `CliCod` mediumint NOT NULL,
  `CliDirCod` mediumint NOT NULL,
  `ArtCod` char(13) NOT NULL,
  `CliArtTarVigIni` date NOT NULL,
  `CliArtTarVigFin` date NOT NULL,
  `ArtTarCod` smallint DEFAULT NULL,
  `CliArttarVigImp` decimal(11,2) NOT NULL,
  PRIMARY KEY (`EmpCod`,`CliCod`,`CliDirCod`,`ArtCod`,`CliArtTarVigIni`),
  KEY `ICliArticulosTarifa2` (`EmpCod`,`ArtCod`,`ArtTarCod`),
  CONSTRAINT `GX_008900ZL0001` FOREIGN KEY (`EmpCod`, `ArtCod`) REFERENCES `articulos` (`EmpCod`, `ArtCod`),
  CONSTRAINT `ICliArticulosTarifa1` FOREIGN KEY (`EmpCod`, `CliCod`, `CliDirCod`) REFERENCES `clidir` (`EmpCod`, `CliCod`, `CliDirCod`),
  CONSTRAINT `ICliArticulosTarifa2` FOREIGN KEY (`EmpCod`, `ArtCod`, `ArtTarCod`) REFERENCES `artitarifas` (`EmpCod`, `ArtCod`, `ArtTarCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `clicob` (
  `EmpCod` smallint NOT NULL,
  `CliCod` mediumint NOT NULL,
  `CliCobDir` smallint NOT NULL,
  `CliCobPlaz` char(2) NOT NULL,
  `CliCobDiaVen` smallint NOT NULL,
  `CliCobEntVen` smallint NOT NULL,
  `CliCobPriDia` char(2) NOT NULL,
  `CliCobSegDia` char(2) NOT NULL,
  `CliCobPorGto` decimal(5,2) NOT NULL,
  `CliCobResFac` char(1) NOT NULL,
  `CliCobDiaRes` char(2) NOT NULL,
  `EntBancCOd` char(4) NOT NULL,
  `CliCobIban` char(4) NOT NULL,
  `CliCobBic` char(40) NOT NULL,
  `CliCobOfiBan` smallint NOT NULL,
  `CliCobDigCon` smallint NOT NULL,
  `CliCobCuenta` bigint NOT NULL,
  `CliCobAgencia` char(40) NOT NULL,
  `CliCobDirAge` char(40) NOT NULL,
  `CliCobPaiCod` char(3) NOT NULL,
  `CliCobPrvCod` char(10) NOT NULL,
  `CliCobLocCodPos` char(10) NOT NULL,
  `CliCobLocCnt` smallint NOT NULL,
  `CliCobPP` decimal(5,2) NOT NULL,
  `CliCobUsuCod` char(10) NOT NULL,
  `CliCobUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`CliCod`,`CliCobDir`),
  KEY `ICLICOB1` (`EmpCod`,`EntBancCOd`),
  CONSTRAINT `ICLICOB1` FOREIGN KEY (`EmpCod`, `EntBancCOd`) REFERENCES `entbanc` (`EmpCod`, `EntBancCOd`),
  CONSTRAINT `ICLICOB3` FOREIGN KEY (`EmpCod`, `CliCod`) REFERENCES `clientes` (`EmpCod`, `CliCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `clidir` (
  `EmpCod` smallint NOT NULL,
  `CliCod` mediumint NOT NULL,
  `CliDirCod` mediumint NOT NULL,
  `CliDirNom` char(50) NOT NULL,
  `CliDirDir` char(50) NOT NULL,
  `CliDirPaiCod` char(3) NOT NULL,
  `CliDirPrvCod` char(10) NOT NULL,
  `CliDirLocCodPos` char(10) NOT NULL,
  `CliDirLocCnt` int NOT NULL,
  `CliCobDir` smallint DEFAULT NULL,
  `CliDirTel` char(65) NOT NULL,
  `CliDirFax` char(30) NOT NULL,
  `CliDirPerCon` char(40) NOT NULL,
  `CliDirCar` char(15) NOT NULL,
  `CliDirExeIva` char(1) NOT NULL,
  `CliDirMail` char(50) NOT NULL,
  `CliDirWEB` char(50) NOT NULL,
  `CliDirDirIp` char(15) NOT NULL,
  `CliDirChoDNI` char(9) NOT NULL,
  `MozCod` char(8) NOT NULL,
  `CliDirRutCod` char(2) NOT NULL,
  `CliDirTipTra` smallint NOT NULL,
  `CliDirEntDes` char(5) NOT NULL,
  `CliDirEntHas` char(5) NOT NULL,
  `CliDirAcrCod` char(8) NOT NULL,
  `CliDirFran` char(1) NOT NULL,
  `CliDirHost` char(30) NOT NULL,
  `CliDirUsuFtp` char(15) NOT NULL,
  `CliDirPass` char(15) NOT NULL,
  `CliDirCarp` char(15) NOT NULL,
  `CliDirOfe` char(1) NOT NULL,
  `CliDirUsuCod` char(10) NOT NULL,
  `CliDirUltMod` datetime NOT NULL,
  `CliDirForCobDef` char(1) DEFAULT NULL,
  `CliDirForCobCod` char(3) DEFAULT NULL,
  `CliDirPorP` decimal(5,2) DEFAULT NULL,
  `CliDirAgeDir` char(40) DEFAULT NULL,
  `CliDirAgencia` char(40) DEFAULT NULL,
  `CliDirBic` char(11) DEFAULT NULL,
  `CliDirBanBban` char(30) DEFAULT NULL,
  `CliDirIban` varchar(50) DEFAULT NULL,
  `CliDirDiaRes` smallint DEFAULT NULL,
  `CliDirResFac` char(1) DEFAULT NULL,
  `CliDirPorGto` decimal(5,2) DEFAULT NULL,
  `CliDirSegDia` smallint DEFAULT NULL,
  `CliDirPriDia` smallint DEFAULT NULL,
  `CliDirEntVen` smallint DEFAULT NULL,
  `CliDirDiaVen` smallint DEFAULT NULL,
  `CliDirPlaz` smallint DEFAULT NULL,
  `CliDirTarCod` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CliCod`,`CliDirCod`),
  KEY `ICLIDIR2` (`EmpCod`,`CliDirForCobCod`),
  CONSTRAINT `ICLIDIR1` FOREIGN KEY (`EmpCod`, `CliCod`) REFERENCES `clientes` (`EmpCod`, `CliCod`),
  CONSTRAINT `ICLIDIR2` FOREIGN KEY (`EmpCod`, `CliDirForCobCod`) REFERENCES `forcob` (`EmpCod`, `ForCobCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `clientes` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `CliCod` mediumint NOT NULL,
  `CliRazSoc` char(40) DEFAULT NULL,
  `CliNomCom` char(40) DEFAULT NULL,
  `CliNemo` char(8) DEFAULT NULL,
  `CliDomFis` char(50) DEFAULT NULL,
  `CliDomCor` char(80) DEFAULT NULL,
  `CliNIF` char(15) DEFAULT NULL,
  `TerClaId` char(2) DEFAULT NULL,
  `CliEnvSN` char(1) DEFAULT NULL,
  `CliTel` char(65) DEFAULT NULL,
  `CliFax` char(30) DEFAULT NULL,
  `CliCon1` char(40) DEFAULT NULL,
  `CliCar1` char(15) DEFAULT NULL,
  `CliCon2` char(40) DEFAULT NULL,
  `CliCar2` char(15) DEFAULT NULL,
  `CliMail` char(50) DEFAULT NULL,
  `CliWeb` char(50) DEFAULT NULL,
  `CliActivo` char(1) DEFAULT NULL,
  `CliNomGer` char(40) DEFAULT NULL,
  `CliObs` text,
  `CliEstCod` char(3) DEFAULT NULL,
  `CliEmpFac` smallint DEFAULT NULL,
  `CliExeIva` char(1) DEFAULT NULL,
  `CliRecEqSN` char(1) DEFAULT NULL,
  `CliDtoPie` decimal(5,2) DEFAULT NULL,
  `ChoTipo` smallint DEFAULT NULL,
  `ChoPreUni` decimal(6,2) DEFAULT NULL,
  `CliPortes` smallint DEFAULT NULL,
  `CliOferta` char(1) DEFAULT NULL,
  `CliLimCre` decimal(11,2) DEFAULT NULL,
  `CLiDiaPedPen` smallint DEFAULT NULL,
  `CliPerFac` char(1) DEFAULT NULL,
  `CliAgrAlb` char(1) DEFAULT NULL,
  `CliNroCopFac` smallint DEFAULT NULL,
  `CliRapSN` char(1) DEFAULT NULL,
  `CliPorRap` decimal(5,2) DEFAULT NULL,
  `CliPorComi` decimal(5,2) DEFAULT NULL,
  `CliTipRapp` char(1) DEFAULT NULL,
  `ClaCliCod` char(2) DEFAULT NULL,
  `ChoDNI` char(9) DEFAULT NULL,
  `CliSec` char(3) DEFAULT NULL,
  `CliUltVta` date DEFAULT NULL,
  `CliInfCom` char(60) DEFAULT NULL,
  `CliAlbPenFac` decimal(11,2) DEFAULT NULL,
  `CliSalFacPen` decimal(11,2) DEFAULT NULL,
  `CliSalEfePen` decimal(11,2) DEFAULT NULL,
  `CliEfePenIng` decimal(11,2) DEFAULT NULL,
  `CliSalImp` decimal(11,2) DEFAULT NULL,
  `CliNroImp` smallint DEFAULT NULL,
  `CliTotImp` decimal(11,2) DEFAULT NULL,
  `CliUltImp` date DEFAULT NULL,
  `CliBloVtaSN` char(1) DEFAULT NULL,
  `CliTraDat` char(1) DEFAULT NULL,
  `CliDirIp` char(15) DEFAULT NULL,
  `CliMarVta` decimal(5,2) DEFAULT NULL,
  `RutCod` char(2) DEFAULT NULL,
  `RutDes` char(40) DEFAULT NULL,
  `CliAlbFac` char(1) DEFAULT NULL,
  `CliRapFac` char(1) DEFAULT NULL,
  `CliRapRes` char(1) DEFAULT NULL,
  `CliResFac` char(1) DEFAULT NULL,
  `CliIncHoja` char(1) DEFAULT NULL,
  `CliAlbVal` char(1) DEFAULT NULL,
  `CliTipo` char(1) DEFAULT NULL,
  `IdiCod` char(3) DEFAULT NULL,
  `CliDetFac` char(1) DEFAULT NULL,
  `CliFacCenSN` char(1) DEFAULT NULL,
  `CliTipFac` char(1) DEFAULT NULL,
  `CliTotClaCiaAse` decimal(11,2) DEFAULT NULL,
  `CliFecAlt` date DEFAULT NULL,
  `CliAutEmp` char(40) DEFAULT NULL,
  `CenCod` char(10) DEFAULT NULL,
  `PaiCod` char(3) DEFAULT NULL,
  `PrvCod` char(2) DEFAULT NULL,
  `LocCodPos` char(10) DEFAULT NULL,
  `LocCnt` int DEFAULT NULL,
  `CliUsuCod` char(10) DEFAULT NULL,
  `CliUltMod` datetime DEFAULT NULL,
  `CliCtaTit` char(4) NOT NULL,
  `ForCobCod` char(3) DEFAULT NULL,
  `CliPlazos` smallint DEFAULT NULL,
  `CliGtosCobro` decimal(3,2) DEFAULT NULL,
  `CliDiaHastaVto` smallint DEFAULT NULL,
  `CliDiaEntreVto` smallint DEFAULT NULL,
  `CliDiaCob1` smallint DEFAULT NULL,
  `CliDiaCob2` smallint DEFAULT NULL,
  `CliBanEnt` char(6) DEFAULT NULL,
  `CliBanOf` char(4) DEFAULT NULL,
  `CliBanDC` char(2) DEFAULT NULL,
  `CliBanCta` char(10) DEFAULT NULL,
  `CLiFacRes` char(1) DEFAULT NULL,
  `CliRiesgoAse` int DEFAULT NULL,
  `CliRiesgoEmp` int DEFAULT NULL,
  `CliRE` char(1) DEFAULT NULL,
  `CliPF` char(1) DEFAULT NULL,
  `CliCtaIngCod` char(6) DEFAULT NULL,
  `CLiCtaIngTit` char(4) DEFAULT NULL,
  `CliIvaTpoCod` char(5) DEFAULT NULL,
  `CliIgicTpoCod` char(5) DEFAULT NULL,
  `CliBanSwift` char(11) DEFAULT NULL,
  `CliBanBban` char(30) DEFAULT NULL,
  `CliBanIban` char(4) DEFAULT NULL,
  `CliFecBaja` date DEFAULT NULL,
  `CliConIdUlt` smallint DEFAULT NULL,
  `TarCod` smallint DEFAULT NULL,
  `CliCodRaz` char(100) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CliCod`),
  KEY `ICLIENTES1` (`PaiCod`,`PrvCod`,`LocCodPos`,`LocCnt`),
  KEY `ICLIENTES2` (`CenCod`),
  KEY `ICLIENT4` (`IdiCod`),
  KEY `ICLIENTES3` (`EmpCod`,`ClaCliCod`),
  KEY `ICLIENT7` (`EmpCod`,`CliEstCod`),
  KEY `UCLI01` (`EmpCod`,`CliRazSoc`),
  KEY `UCLI02` (`EmpCod`,`CliNomCom`),
  KEY `UCLI03` (`EmpCod`,`CliNIF`),
  KEY `UCLI04` (`EmpCod`,`CliNemo`),
  KEY `ICLIENTES5` (`EmpCod`,`ForCobCod`),
  KEY `ICLIENTES4` (`EmpCod`,`TerClaId`),
  KEY `ICLIENTES6` (`EmpCod`,`TarCod`),
  CONSTRAINT `ICLIENT4` FOREIGN KEY (`IdiCod`) REFERENCES `idiomas` (`IdiCod`),
  CONSTRAINT `ICLIENT7` FOREIGN KEY (`EmpCod`, `CliEstCod`) REFERENCES `cliest` (`EmpCod`, `CliEstCod`),
  CONSTRAINT `ICLIENTES4` FOREIGN KEY (`EmpCod`, `TerClaId`) REFERENCES `tercercladoc` (`EmpCod`, `TerClaId`),
  CONSTRAINT `ICLIENTES6` FOREIGN KEY (`EmpCod`, `TarCod`) REFERENCES `ttarifas` (`EmpCod`, `TarCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `clienteslevel1` (
  `EmpCod` smallint NOT NULL,
  `CliCod` mediumint NOT NULL,
  `CliCtaTer` char(4) NOT NULL,
  `CliCtaCod` char(6) NOT NULL,
  PRIMARY KEY (`EmpCod`,`CliCod`,`CliCtaTer`),
  CONSTRAINT `ICLIENTESLEVEL11` FOREIGN KEY (`EmpCod`, `CliCod`) REFERENCES `clientes` (`EmpCod`, `CliCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `cliest` (
  `EmpCod` smallint NOT NULL,
  `CliEstCod` char(3) NOT NULL,
  `CliEstDes` char(30) NOT NULL,
  `CliEstVtaSN` char(1) NOT NULL,
  `CliEstUsu` char(10) NOT NULL,
  `CliEstMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`CliEstCod`),
  KEY `UCLIEST1` (`EmpCod`,`CliEstDes`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `climandatos` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `CliCod` mediumint NOT NULL,
  `CliManCod` char(35) NOT NULL,
  `CliManTpo` char(1) NOT NULL,
  `CliManTpoPago` char(1) NOT NULL,
  `CliManEstado` char(1) NOT NULL,
  `CliManFecVigor` date NOT NULL,
  `CliManFecBaja` date NOT NULL DEFAULT '0000-00-00',
  `CliManFecFirma` date NOT NULL DEFAULT '0000-00-00',
  `CliManFile` longblob,
  PRIMARY KEY (`EmpCod`,`CliCod`,`CliManCod`),
  CONSTRAINT `ICLIMANDATOS1` FOREIGN KEY (`EmpCod`, `CliCod`) REFERENCES `clientes` (`EmpCod`, `CliCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `climandatoslevel1` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `CliCod` mediumint NOT NULL,
  `CliManCod` char(35) NOT NULL,
  `CliManBic` char(11) NOT NULL,
  `CliManIban` char(34) NOT NULL,
  `CliManCobros` bigint NOT NULL,
  `CliManFecUltCob` date NOT NULL DEFAULT '0000-00-00',
  `CliManFecUpd` date NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY (`EmpCod`,`CliCod`,`CliManCod`,`CliManFecUpd`),
  CONSTRAINT `ICLIMANDATOSLEVEL11` FOREIGN KEY (`EmpCod`, `CliCod`, `CliManCod`) REFERENCES `climandatos` (`EmpCod`, `CliCod`, `CliManCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `comgas` (
  `EmpCod` smallint NOT NULL,
  `ComGasCod` smallint NOT NULL,
  `ComGasDes` char(30) NOT NULL,
  PRIMARY KEY (`EmpCod`,`ComGasCod`),
  CONSTRAINT `ICOMGAS1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `conbanco` (
  `ConBanEmp` smallint NOT NULL DEFAULT '0',
  `ConBanEnt` char(4) NOT NULL,
  `ConBanOfi` char(4) NOT NULL,
  `ConBanCta` char(10) NOT NULL,
  `ConBanLinR` smallint NOT NULL,
  `ConBanCB` char(1) NOT NULL,
  `ConBanFecCon` date NOT NULL,
  `ConBanFecVal` date NOT NULL,
  `ConBanCuaDes` char(38) NOT NULL,
  `ConBanNDOC` char(10) NOT NULL,
  `ConBanImpD` decimal(11,2) NOT NULL,
  `ConBanImpH` decimal(11,2) NOT NULL,
  `ConBanVinc` char(1) NOT NULL,
  `ConBanMovId` int NOT NULL,
  `ConBanContra` char(10) NOT NULL,
  `ConBanEje` char(8) NOT NULL,
  `ConBanChk` char(1) NOT NULL DEFAULT '',
  PRIMARY KEY (`ConBanEmp`,`ConBanEje`,`ConBanEnt`,`ConBanOfi`,`ConBanCta`,`ConBanLinR`,`ConBanCB`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `conceptospp` (
  `PrevPCon` smallint NOT NULL,
  `EmpCod` smallint NOT NULL,
  `PrevPConNom` char(80) NOT NULL,
  PRIMARY KEY (`PrevPCon`,`EmpCod`),
  KEY `ICONCEPTOSPP1` (`EmpCod`),
  CONSTRAINT `ICONCEPTOSPP1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ctacorriente` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `MCtaTit` char(4) NOT NULL,
  `MCtaCod` char(6) NOT NULL,
  `MFechaMov` date NOT NULL,
  `EjerCod` char(8) NOT NULL DEFAULT '',
  `MovId` int NOT NULL DEFAULT '0',
  `MovLin` smallint NOT NULL DEFAULT '0',
  `MNotUPD` char(1) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`MCtaTit`,`MCtaCod`,`MFechaMov`,`EjerCod`,`MovId`,`MovLin`),
  KEY `ICTACORRIENTE1` (`EmpCod`,`EjerCod`),
  KEY `UCTACORRIENTE` (`MFechaMov`),
  KEY `UCTACORRIENTE2` (`EmpCod`,`EjerCod`,`MovId`,`MovLin`),
  CONSTRAINT `ICTACORRIENTE1` FOREIGN KEY (`EmpCod`, `EjerCod`) REFERENCES `paramejer` (`EmpCod`, `EjerCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ctater` (
  `EmpCod` smallint NOT NULL,
  `TerNro` mediumint NOT NULL,
  `TerTpo` char(1) NOT NULL,
  `TerCtaTit` char(4) NOT NULL,
  `TerCtaCod` char(6) NOT NULL,
  `TerNomFis` char(30) NOT NULL,
  `TerNomCom` char(30) NOT NULL,
  `TerDir` char(30) NOT NULL,
  `TerCP` mediumint NOT NULL,
  `TerLocalidad` char(40) NOT NULL,
  `TerPaiCod` char(3) NOT NULL,
  `TerPrvcod` char(2) NOT NULL,
  `TerNIF` char(15) NOT NULL,
  `TerCon` char(30) NOT NULL,
  `TerCar1` char(15) NOT NULL,
  `TerMov1` char(15) NOT NULL,
  `TerCon2` char(30) NOT NULL,
  `TerCar2` char(15) NOT NULL,
  `TerMov2` char(15) NOT NULL,
  `TerWeb` char(30) NOT NULL,
  `TerEmail` char(30) NOT NULL,
  `TerEstBaj` char(1) NOT NULL,
  `TerTel` char(30) NOT NULL,
  `TerFax` char(15) NOT NULL,
  `TerObs` text NOT NULL,
  `TerFchTra` date NOT NULL,
  `TerRecIvSN` char(1) NOT NULL,
  `TerIRPF` smallint NOT NULL,
  `TerUsuAM` char(10) NOT NULL,
  `TerFecAlMod` date NOT NULL,
  `TerTieCta` char(1) NOT NULL,
  PRIMARY KEY (`EmpCod`,`TerNro`,`TerTpo`),
  KEY `UCTATER` (`EmpCod`,`TerNomFis`),
  KEY `UCTATER1` (`EmpCod`,`TerTpo`,`TerNomFis`),
  KEY `UCTATER2` (`EmpCod`,`TerTpo`,`TerNIF`),
  CONSTRAINT `ICTATER1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `cuadreban` (
  `EmpCod` smallint NOT NULL,
  `EjerCod` char(8) NOT NULL,
  `CuaAny` smallint NOT NULL,
  `CuaId` int NOT NULL,
  `CuaLin` smallint NOT NULL,
  `CtaTit` char(4) NOT NULL,
  `CtaCod` char(6) NOT NULL,
  `CuaFecCon` date NOT NULL,
  `CuaImp` decimal(11,2) NOT NULL,
  `CuaDH` char(1) NOT NULL,
  `CuaDesc` char(40) NOT NULL,
  `CuaNroDoc` int NOT NULL,
  `CuaContra` char(10) NOT NULL,
  `CuaFecEx` date NOT NULL,
  `CuaVinc` char(1) NOT NULL,
  PRIMARY KEY (`EmpCod`,`EjerCod`,`CuaAny`,`CuaId`,`CuaLin`),
  KEY `ICUADREBAN1` (`EmpCod`,`CtaTit`,`CtaCod`),
  KEY `UCUADREBAN1` (`EmpCod`,`EjerCod`,`CuaAny`,`CtaTit`,`CtaCod`,`CuaFecCon`),
  CONSTRAINT `ICUADREBAN1` FOREIGN KEY (`EmpCod`, `CtaTit`, `CtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `ICUADREBAN2` FOREIGN KEY (`EmpCod`, `EjerCod`) REFERENCES `paramejer` (`EmpCod`, `EjerCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `cuotas` (
  `EmpCod` smallint NOT NULL,
  `CliCod` mediumint NOT NULL,
  `ArtCod` char(13) NOT NULL,
  `CuoFecAlta` date NOT NULL,
  `CuoPer` char(1) NOT NULL,
  `CuoArtDes` char(50) DEFAULT NULL,
  `CuoArtDesLar` varchar(2048) DEFAULT NULL,
  `CuoOrden` smallint DEFAULT NULL,
  `CuoFacInf` char(1) DEFAULT NULL,
  `CuoFecBaja` date DEFAULT NULL,
  `CuoFacSig` date DEFAULT NULL,
  `CuoFac` date DEFAULT NULL,
  `CuoMod` datetime DEFAULT NULL,
  `CuoUsu` char(10) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CliCod`,`ArtCod`,`CuoFecAlta`) USING BTREE,
  KEY `ICUOTAS1` (`EmpCod`,`ArtCod`),
  CONSTRAINT `ICUOTAS1` FOREIGN KEY (`EmpCod`, `ArtCod`) REFERENCES `articulos` (`EmpCod`, `ArtCod`),
  CONSTRAINT `ICUOTAS2` FOREIGN KEY (`EmpCod`, `CliCod`) REFERENCES `clientes` (`EmpCod`, `CliCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `cuotaslevel1` (
  `EmpCod` smallint NOT NULL,
  `CliCod` mediumint NOT NULL,
  `ArtCod` char(13) NOT NULL,
  `Cuovig` date NOT NULL,
  `CuoPre` decimal(8,2) NOT NULL,
  `CuovigF` date DEFAULT NULL,
  `CuoFecAlta` date NOT NULL,
  PRIMARY KEY (`EmpCod`,`CliCod`,`ArtCod`,`CuoFecAlta`,`Cuovig`) USING BTREE,
  CONSTRAINT `ICUOTASLEVEL11` FOREIGN KEY (`EmpCod`, `CliCod`, `ArtCod`, `CuoFecAlta`) REFERENCES `cuotas` (`EmpCod`, `CliCod`, `ArtCod`, `CuoFecAlta`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `cyppdtes` (
  `EmpCod` smallint NOT NULL,
  `CyPEjercod` char(8) NOT NULL,
  `CyPMovid` int NOT NULL,
  `CyPOrigen` char(1) DEFAULT NULL,
  `CyPcCtaTit` char(4) DEFAULT NULL,
  `CyPcCtacod` char(6) DEFAULT NULL,
  `CyPpCtatit` char(4) DEFAULT NULL,
  `CyPpCtacod` char(6) DEFAULT NULL,
  `CyPImporte` decimal(11,2) DEFAULT NULL,
  `CyPFeccon` date DEFAULT NULL,
  `CyPConcod` smallint DEFAULT NULL,
  `CyPModo` char(3) DEFAULT NULL,
  `CyPPrgid` char(8) DEFAULT NULL,
  `CyPCefid` int DEFAULT NULL,
  `CyPMovnrodoc` int DEFAULT NULL,
  `CyPMovserie` char(3) DEFAULT NULL,
  `CyPCtanom` char(80) DEFAULT NULL,
  `CyPMovobs` char(40) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CyPEjercod`,`CyPMovid`),
  CONSTRAINT `ICYPPDTES1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `defctactable` (
  `DefCtaCtbleId` char(2) NOT NULL,
  `DefCtaCtbleTitulo` char(30) NOT NULL,
  PRIMARY KEY (`DefCtaCtbleId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `defctactablelevel1` (
  `DefCtaCtbleId` char(2) NOT NULL,
  `DefCtaTit` char(4) NOT NULL,
  `DefCtaCod` char(6) NOT NULL,
  `DefCtaNom` char(80) NOT NULL,
  PRIMARY KEY (`DefCtaCtbleId`,`DefCtaTit`,`DefCtaCod`),
  CONSTRAINT `IDEFCTACTABLELEVEL11` FOREIGN KEY (`DefCtaCtbleId`) REFERENCES `defctactable` (`DefCtaCtbleId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `defexplo` (
  `EmpCod` smallint NOT NULL,
  `DefExCod` smallint NOT NULL,
  `DefExNom` char(30) NOT NULL,
  `DefExUsuCod` char(10) NOT NULL,
  `DefExUltFec` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`DefExCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `defexplolevel1` (
  `EmpCod` smallint NOT NULL,
  `DefExCod` smallint NOT NULL,
  `DefExCab` char(2) NOT NULL,
  `DefExCabNom` char(30) NOT NULL,
  `DefExSum` char(30) NOT NULL,
  `DefPorCab` char(2) NOT NULL,
  PRIMARY KEY (`EmpCod`,`DefExCod`,`DefExCab`),
  CONSTRAINT `IDEFEXPLOLEVEL11` FOREIGN KEY (`EmpCod`, `DefExCod`) REFERENCES `defexplo` (`EmpCod`, `DefExCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `definfcon` (
  `DefInfEmpCod` smallint NOT NULL DEFAULT '0',
  `DefInfId` smallint NOT NULL,
  `DefInfNom` char(60) NOT NULL,
  `DefInfCab` char(60) NOT NULL,
  `DefInfUltLin` smallint NOT NULL,
  `DefInfAgrup` char(1) NOT NULL,
  `DefInfSaldos` char(1) DEFAULT NULL,
  `DefInfMenu` smallint DEFAULT NULL,
  `DefInfEst` char(1) DEFAULT NULL,
  `DefInfExcel` blob,
  `DefInfFila` smallint unsigned DEFAULT NULL,
  `DefinfCol` smallint unsigned DEFAULT NULL,
  PRIMARY KEY (`DefInfEmpCod`,`DefInfId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `definfconallconceptosidiomacon` (
  `DefInfEmpCod` smallint NOT NULL,
  `DefInfId` smallint NOT NULL,
  `InfLin` char(4) NOT NULL,
  `DefInfLinIdiCod` char(3) NOT NULL,
  `DefInfLinIdiCon` char(80) NOT NULL,
  PRIMARY KEY (`DefInfEmpCod`,`DefInfId`,`InfLin`,`DefInfLinIdiCod`),
  CONSTRAINT `IDEFINFCONALLCONCEPTOSIDIOMAC1` FOREIGN KEY (`DefInfEmpCod`, `DefInfId`, `InfLin`) REFERENCES `definfconconceptos` (`DefInfEmpCod`, `DefInfId`, `InfLin`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `definfconallidi` (
  `DefInfEmpCod` smallint NOT NULL,
  `DefInfId` smallint NOT NULL,
  `DefInfIdiCod` char(3) NOT NULL,
  `DefInfIdiInfNom` char(40) NOT NULL,
  `DEfInfIdiInfCab` char(40) NOT NULL,
  PRIMARY KEY (`DefInfEmpCod`,`DefInfId`,`DefInfIdiCod`),
  CONSTRAINT `IDEFINFCONALLIDI1` FOREIGN KEY (`DefInfEmpCod`, `DefInfId`) REFERENCES `definfcon` (`DefInfEmpCod`, `DefInfId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `definfconceptos` (
  `DefInfEmpCod` smallint NOT NULL,
  `DefInfId` smallint NOT NULL,
  `InfLin` char(4) NOT NULL,
  `DefInfConID` char(4) NOT NULL,
  `DefInfConOp` char(1) NOT NULL,
  PRIMARY KEY (`DefInfEmpCod`,`DefInfId`,`InfLin`,`DefInfConID`),
  CONSTRAINT `IDEFINFCONCEPTOS1` FOREIGN KEY (`DefInfEmpCod`, `DefInfId`, `InfLin`) REFERENCES `definfconconceptos` (`DefInfEmpCod`, `DefInfId`, `InfLin`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `definfconconceptos` (
  `DefInfEmpCod` smallint NOT NULL,
  `DefInfId` smallint NOT NULL,
  `InfLin` char(4) NOT NULL,
  `InfCon` char(80) NOT NULL,
  `InfAcc` char(1) NOT NULL,
  `ImpBol` char(1) NOT NULL,
  `InfTab` smallint NOT NULL,
  `InfOrdImp` smallint NOT NULL,
  `InfConDetCta` char(1) DEFAULT NULL,
  `InfConMostrar` char(1) DEFAULT NULL,
  `InfConLineas` char(1) NOT NULL,
  `InfConDuplicado` char(4) DEFAULT NULL,
  `InfConPor` char(4) NOT NULL,
  `InfNroImp` int DEFAULT NULL,
  `InfConPer` char(2) DEFAULT NULL,
  PRIMARY KEY (`DefInfEmpCod`,`DefInfId`,`InfLin`),
  KEY `UDEFINFCONCONCEPTOS` (`DefInfEmpCod`,`DefInfId`,`InfAcc`),
  CONSTRAINT `IDEFINFCONCONCEPTOS1` FOREIGN KEY (`DefInfEmpCod`, `DefInfId`) REFERENCES `definfcon` (`DefInfEmpCod`, `DefInfId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `definfconconceptoscta` (
  `DefInfEmpCod` smallint NOT NULL,
  `DefInfId` smallint NOT NULL,
  `InfLin` char(4) NOT NULL,
  `CtaTit` char(4) NOT NULL,
  `CtaCod` char(6) NOT NULL,
  `CtaOp` char(1) NOT NULL,
  `CtaTpo` char(2) DEFAULT NULL,
  PRIMARY KEY (`DefInfEmpCod`,`DefInfId`,`InfLin`,`CtaTit`,`CtaCod`),
  CONSTRAINT `IDEFINFCONCONCEPTOSCTA1` FOREIGN KEY (`DefInfEmpCod`, `DefInfId`, `InfLin`) REFERENCES `definfconconceptos` (`DefInfEmpCod`, `DefInfId`, `InfLin`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `definformes` (
  `EmpCod` smallint NOT NULL,
  `DefCod` smallint NOT NULL,
  `DefTitulo` char(40) NOT NULL,
  `DefUltDef` int NOT NULL,
  `DefTpo` char(1) NOT NULL,
  `DefNombre` char(40) NOT NULL,
  PRIMARY KEY (`EmpCod`,`DefCod`),
  CONSTRAINT `IDEFINFORMES1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `departamento` (
  `EmpCod` smallint NOT NULL,
  `DepCod` smallint NOT NULL,
  `DepDes` char(30) NOT NULL,
  `DepUsuCod` char(10) NOT NULL,
  `DepUltMod` date NOT NULL,
  PRIMARY KEY (`EmpCod`,`DepCod`),
  KEY `UDEPARTAMENTO1` (`EmpCod`,`DepDes`),
  CONSTRAINT `IDEPARTAMENTO1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `diadetori` (
  `EmpCod` smallint NOT NULL,
  `DiaMesAnio` char(6) NOT NULL,
  `DiaNroLin` smallint NOT NULL,
  `DiaDetDia` smallint NOT NULL,
  `DiaDetTit` char(4) NOT NULL,
  `DiaDetCta` char(6) NOT NULL,
  `DiaCtaCont` char(10) NOT NULL,
  `DiaTipOc` smallint NOT NULL,
  `DiaTipOd` char(30) NOT NULL,
  `DiaDetObs` char(20) NOT NULL,
  `DiaDetNro` int NOT NULL,
  `DiaDetSerie` char(1) NOT NULL,
  `DiaImpIng` decimal(11,2) NOT NULL,
  `DiaImpPag` decimal(11,2) NOT NULL,
  `DiaDetSdo` decimal(11,2) NOT NULL,
  `DiaDetComp` bigint NOT NULL,
  `DiaDetCCC` char(3) NOT NULL,
  `DiaDetCCD` char(30) NOT NULL,
  `DiaCtaCCSN` char(1) NOT NULL,
  `DiaHabTit` char(4) NOT NULL,
  `DiaHabSub` char(1) NOT NULL,
  `DiaHabCt2` char(6) NOT NULL,
  `DiaHabCta` char(10) NOT NULL,
  `DiaTipIva` char(1) NOT NULL,
  `DiaPor1` decimal(5,2) NOT NULL,
  `DiaPor2` decimal(5,2) NOT NULL,
  `DiaPor3` decimal(5,2) NOT NULL,
  `DiaIva1` decimal(11,2) NOT NULL,
  `DiaIva2` decimal(11,2) NOT NULL,
  `DiaIva3` decimal(11,2) NOT NULL,
  `DiaBaseIv1` decimal(11,2) NOT NULL,
  `DiaBaseIv2` decimal(11,2) NOT NULL,
  `DiaBaseIv3` decimal(11,2) NOT NULL,
  `DiaTipDiaTip` char(1) NOT NULL,
  `diadetfch` date NOT NULL,
  `DiaTipdiaSerie` char(1) NOT NULL,
  `DiaFchDoc` date NOT NULL,
  `DiaRecIV1` decimal(11,2) NOT NULL,
  `DiaRecIv2` decimal(11,2) NOT NULL,
  `DiaRecIv3` decimal(11,2) NOT NULL,
  `DiaBaseRe1` decimal(11,2) NOT NULL,
  `DiaBaseRe2` decimal(11,2) NOT NULL,
  `DiaBaseRe3` decimal(11,2) NOT NULL,
  `DiaIvaDedSn` char(1) NOT NULL,
  PRIMARY KEY (`EmpCod`,`DiaMesAnio`,`DiaNroLin`),
  CONSTRAINT `IDIADET3` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `divisas2` (
  `EmpCod` smallint NOT NULL,
  `DivCod` char(3) NOT NULL,
  `DivNom` char(20) NOT NULL,
  `DivSmb` char(3) NOT NULL,
  PRIMARY KEY (`EmpCod`,`DivCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `divisasvigencia` (
  `EmpCod` smallint NOT NULL,
  `DivCod` char(3) NOT NULL,
  `DivFec` datetime NOT NULL,
  `DivTipCam` decimal(11,4) NOT NULL,
  `DivUsuCod` char(10) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`DivCod`,`DivFec`),
  CONSTRAINT `IDIVISASVIGENCIA1` FOREIGN KEY (`EmpCod`, `DivCod`) REFERENCES `divisas2` (`EmpCod`, `DivCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `docscartera` (
  `EmpCod` smallint NOT NULL,
  `DocCod` char(3) NOT NULL,
  `DocDes` char(15) NOT NULL,
  PRIMARY KEY (`EmpCod`,`DocCod`),
  CONSTRAINT `IDOCSCARTERA1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `dtocarfac` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `DtoCod` char(3) NOT NULL,
  `DtoCon` char(25) NOT NULL DEFAULT '',
  `DtoPor` decimal(5,2) NOT NULL,
  `DtoTipo` char(1) NOT NULL,
  `DtoCtaTit` char(4) DEFAULT NULL,
  `DtoCtaCod` char(6) DEFAULT NULL,
  `DtoIvaTpoCod` char(5) DEFAULT NULL,
  `DtoCtaTitI` char(4) DEFAULT NULL,
  `DtoCtaCodI` char(6) DEFAULT NULL,
  `DtoCtaTitE` char(4) DEFAULT NULL,
  `DtoCtaCodE` char(6) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`DtoCod`),
  KEY `IDTOCARFAC` (`EmpCod`,`DtoCtaTit`,`DtoCtaCod`),
  KEY `IDTOCARFAC1` (`EmpCod`,`DtoIvaTpoCod`),
  KEY `IDTOCARFAC2` (`EmpCod`,`DtoCtaTitI`,`DtoCtaCodI`),
  KEY `IDTOCARFAC3` (`EmpCod`,`DtoCtaTitE`,`DtoCtaCodE`),
  CONSTRAINT `IDTOCARFAC` FOREIGN KEY (`EmpCod`, `DtoCtaTit`, `DtoCtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `IDTOCARFAC1` FOREIGN KEY (`EmpCod`, `DtoIvaTpoCod`) REFERENCES `ivatipos1` (`EmpCod`, `IvaTpoCod`),
  CONSTRAINT `IDTOCARFAC2` FOREIGN KEY (`EmpCod`, `DtoCtaTitI`, `DtoCtaCodI`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `IDTOCARFAC3` FOREIGN KEY (`EmpCod`, `DtoCtaTitE`, `DtoCtaCodE`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `empcen` (
  `EmpCod` smallint NOT NULL,
  `CentCod` smallint NOT NULL,
  `CentNom` char(30) NOT NULL,
  `CentUsuCod` char(10) NOT NULL,
  `CentUltMod` datetime NOT NULL,
  `Centemail` char(30) NOT NULL,
  `CentTel` char(30) NOT NULL,
  `CentPob` char(40) NOT NULL,
  `CentDom` char(40) NOT NULL,
  `PaiCod` char(3) DEFAULT NULL,
  `PrvCod` char(2) DEFAULT NULL,
  `LocCnt` int DEFAULT NULL,
  `LocCodPos` char(10) DEFAULT NULL,
  `CentMoneda` char(3) DEFAULT 'EUR',
  `CentState` char(1) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CentCod`),
  KEY `IEMPCEN2` (`PaiCod`,`PrvCod`,`LocCodPos`,`LocCnt`),
  CONSTRAINT `GX_001F000R` FOREIGN KEY (`PaiCod`) REFERENCES `pais` (`PaiCod`),
  CONSTRAINT `GX_001F000S000R` FOREIGN KEY (`PaiCod`, `PrvCod`) REFERENCES `provincia` (`PaiCod`, `PrvCod`),
  CONSTRAINT `IEMPCEN1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `empcenlevel1` (
  `EmpCod` smallint NOT NULL,
  `CentCod` smallint NOT NULL,
  `DvsCod` smallint NOT NULL,
  `Dvsemail` char(30) NOT NULL,
  `DvsTel` char(30) NOT NULL,
  `DvsState` char(1) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CentCod`,`DvsCod`),
  KEY `IEMPCENLEVEL12` (`EmpCod`,`DvsCod`),
  CONSTRAINT `IEMPCENLEVEL11` FOREIGN KEY (`EmpCod`, `CentCod`) REFERENCES `empcen` (`EmpCod`, `CentCod`),
  CONSTRAINT `IEMPCENLEVEL12` FOREIGN KEY (`EmpCod`, `DvsCod`) REFERENCES `empdiv` (`EmpCod`, `DvsCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `empdiv` (
  `EmpCod` smallint NOT NULL,
  `DvsCod` smallint NOT NULL,
  `DvsNom` char(30) NOT NULL,
  PRIMARY KEY (`EmpCod`,`DvsCod`),
  CONSTRAINT `IEMPDIV1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `empleados` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `EplCod` mediumint NOT NULL,
  `EplNom` char(40) NOT NULL,
  `EplAli` char(40) DEFAULT NULL,
  `EplNemo` char(8) DEFAULT NULL,
  `EplDir` char(50) DEFAULT NULL,
  `EplCif` char(15) DEFAULT NULL,
  `EplDni` char(15) NOT NULL,
  `EplSegSoc` char(20) DEFAULT NULL,
  `EplMat` char(5) DEFAULT NULL,
  `EplTel` char(30) DEFAULT NULL,
  `EplTelMov` char(30) DEFAULT NULL,
  `EplEstCiv` char(1) DEFAULT NULL,
  `EplNomCon` char(40) DEFAULT NULL,
  `EplNroHjo` smallint DEFAULT NULL,
  `EplFecNac` date DEFAULT NULL,
  `EplLugNac` char(40) DEFAULT NULL,
  `EplLugTra` char(40) DEFAULT NULL,
  `EplCatLab` char(40) DEFAULT NULL,
  `EplFecAlt` date DEFAULT NULL,
  `EplConTra` char(40) DEFAULT NULL,
  `EplSalBru` decimal(11,2) DEFAULT NULL,
  `EplRetIrpf` decimal(5,2) DEFAULT NULL,
  `EplSalNet` decimal(11,2) DEFAULT NULL,
  `EplComTxt` char(40) DEFAULT NULL,
  `EplComIm` decimal(11,2) DEFAULT NULL,
  `EplOtrTrat` char(40) DEFAULT NULL,
  `EplOtrTraI` decimal(11,2) DEFAULT NULL,
  `EplPorCom` decimal(5,2) DEFAULT NULL,
  `EplTotVta` decimal(11,2) DEFAULT NULL,
  `EplObs` text,
  `EplInf` text,
  `EplEst` char(1) DEFAULT NULL,
  `EplVenSN` char(1) DEFAULT NULL,
  `EplUsuCod` char(10) DEFAULT NULL,
  `EplUltMod` datetime DEFAULT NULL,
  `LocCnt` int DEFAULT NULL,
  `LocCodPos` char(10) DEFAULT NULL,
  `PrvCod` char(2) DEFAULT NULL,
  `PaiCod` char(3) DEFAULT NULL,
  `EplBanCta` char(10) DEFAULT NULL,
  `EplBanDC` char(2) DEFAULT NULL,
  `EplBanOf` char(4) DEFAULT NULL,
  `EplBanEnt` char(6) DEFAULT NULL,
  `EplBanIban` char(4) DEFAULT NULL,
  `EplBanSwift` char(11) DEFAULT NULL,
  `EplBanBban` char(30) DEFAULT NULL,
  `EplFecBaja` date DEFAULT NULL,
  `EplCodRaz` char(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`EmpCod`,`EplCod`),
  KEY `UEMPL01` (`EmpCod`,`EplNom`),
  KEY `UEMPL02` (`EmpCod`,`EplDni`),
  KEY `UEMPL03` (`EmpCod`,`EplNemo`),
  KEY `IEMPLEADOS2` (`PaiCod`,`PrvCod`,`LocCodPos`,`LocCnt`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `empleadoslevel1` (
  `EmpCod` smallint NOT NULL,
  `EplCod` mediumint NOT NULL,
  `EplCtaTer` char(4) NOT NULL,
  `EplCtaCod` char(6) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`EplCod`,`EplCtaTer`),
  CONSTRAINT `IEMPLEADOSLEVEL11` FOREIGN KEY (`EmpCod`, `EplCod`) REFERENCES `empleados` (`EmpCod`, `EplCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `empmesanio` (
  `EmpCod` smallint NOT NULL,
  `EmpMesAnio` char(6) NOT NULL,
  `EmpPerEstado` char(1) NOT NULL,
  PRIMARY KEY (`EmpCod`,`EmpMesAnio`),
  CONSTRAINT `IEMPMESANIO1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `empresa_contacto` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `EmpConId` smallint NOT NULL,
  `CarCod` smallint NOT NULL,
  `EmpConNom` char(40) NOT NULL,
  `EmpConNif` char(15) NOT NULL DEFAULT '',
  `EmpConMov` char(65) DEFAULT NULL,
  `EmpConTel` char(65) DEFAULT NULL,
  `EmpConObs` char(30) DEFAULT NULL,
  `EmpConMail` char(50) DEFAULT NULL,
  `ViaTpoCod` char(2) DEFAULT NULL,
  `EmpConDirNom` char(30) DEFAULT NULL,
  `EmpConDirNum` char(5) DEFAULT NULL,
  `EmpConDirEsc` char(2) DEFAULT NULL,
  `EmpConDirPiso` char(2) DEFAULT NULL,
  `EmpConDirPrta` char(2) DEFAULT NULL,
  `EmpConDirCodPos` char(5) DEFAULT NULL,
  `EmpConFchPoder` date DEFAULT NULL,
  `EmpConNotaria` char(15) DEFAULT NULL,
  `EMpConFirContacto` char(1) DEFAULT NULL,
  `EmpConFirLegal` char(1) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`EmpConId`),
  KEY `IEmpresa_Contacto` (`EmpCod`,`CarCod`),
  KEY `IEmpresa_Contacto2` (`ViaTpoCod`),
  CONSTRAINT `IEmpresa_Contacto` FOREIGN KEY (`EmpCod`, `CarCod`) REFERENCES `tcargos` (`EmpCod`, `CarCod`),
  CONSTRAINT `IEmpresa_Contacto2` FOREIGN KEY (`ViaTpoCod`) REFERENCES `viatpo` (`ViaTpoCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `empresas` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `EmpRazSoc` char(50) DEFAULT NULL,
  `EmpApe1` char(15) DEFAULT NULL,
  `EmpApe2` char(15) DEFAULT NULL,
  `EmpNIF` char(15) DEFAULT NULL,
  `EmpDir` char(50) DEFAULT NULL,
  `EmpPais` char(3) DEFAULT NULL,
  `EmpProv` char(30) DEFAULT NULL,
  `EmpCP` mediumint DEFAULT NULL,
  `EmpPob` char(30) DEFAULT NULL,
  `EmpMail` char(50) DEFAULT NULL,
  `EmpWEB` char(50) DEFAULT NULL,
  `EmpTel` char(40) DEFAULT NULL,
  `EmpMovil` char(40) DEFAULT NULL,
  `EmpRegMer` char(100) DEFAULT NULL,
  `EmpSuc` char(1) DEFAULT NULL,
  `EmpGrpo` char(1) DEFAULT NULL,
  `EmpCenCod` char(10) DEFAULT NULL,
  `EmpLiqIva` char(1) DEFAULT NULL,
  `EmpRegIva` smallint DEFAULT NULL,
  `EmpDelHac` char(20) DEFAULT NULL,
  `EmpAdmHac` char(20) DEFAULT NULL,
  `EmpCodAdm` char(5) DEFAULT NULL,
  `EmpCCCPagos` char(20) DEFAULT NULL,
  `EmpCCCDev` char(20) DEFAULT NULL,
  `empsrvpop` char(40) DEFAULT NULL,
  `empsrvsmtp` char(40) DEFAULT NULL,
  `empmaiusu` char(20) DEFAULT NULL,
  `empmaipass` char(20) DEFAULT NULL,
  `EmpMaiAud` char(30) DEFAULT NULL,
  `EmpMaiAse` char(30) DEFAULT NULL,
  `EmpSucSN` char(1) DEFAULT NULL,
  `EmpCenSN` char(1) DEFAULT NULL,
  `EmpUsuCod` char(10) DEFAULT NULL,
  `EmpUltMod` datetime DEFAULT NULL,
  `DefCtaCtbleId` char(2) NOT NULL,
  `EmpLogo` longblob NOT NULL,
  `EmpPrePag` char(1) NOT NULL,
  `EmpPreCod` char(1) NOT NULL,
  `EmpBalance` smallint NOT NULL,
  `EmpPerGan` smallint NOT NULL,
  `EmpMemo` smallint NOT NULL,
  `EmpAudit` smallint NOT NULL,
  `EmpTama` smallint NOT NULL,
  `EmpDivCod` char(3) DEFAULT NULL,
  `EmpInmAudit` date NOT NULL,
  `EmpInmAltas` date NOT NULL,
  `EmpInmConta` date NOT NULL,
  `EmpLogCarta` longblob,
  `EmpPie1` char(100) DEFAULT NULL,
  `EmpPie2` char(100) DEFAULT NULL,
  `EmpPie3` char(100) DEFAULT NULL,
  `EmpIvaMens` smallint DEFAULT NULL,
  `EmpRepLegal` char(15) DEFAULT NULL,
  `EmpDec349` char(1) DEFAULT NULL,
  `EmpImpFac` char(1) DEFAULT NULL,
  `EmpCon1` char(30) DEFAULT NULL,
  `EmpCon1Tel` char(20) DEFAULT NULL,
  `EmpCon1Mov` char(20) DEFAULT NULL,
  `EmpCon1Mail` char(30) DEFAULT NULL,
  `EmpCon2` char(30) DEFAULT NULL,
  `EmpCon2Tel` char(20) DEFAULT NULL,
  `EmpCon2Mov` char(20) DEFAULT NULL,
  `EmpCon2Mail` char(30) DEFAULT NULL,
  `EmpCon3` char(30) DEFAULT NULL,
  `EmpCon3Tel` char(20) DEFAULT NULL,
  `EmpCon3Mov` char(20) DEFAULT NULL,
  `EmpCon3Mail` char(20) DEFAULT NULL,
  `EmpCon1Tip` char(2) DEFAULT NULL,
  `EmpCon2Tip` char(2) DEFAULT NULL,
  `EmpCon3Tip` char(2) DEFAULT NULL,
  `AudNom` char(40) DEFAULT NULL,
  `AudDir` char(30) DEFAULT NULL,
  `AudNif` char(15) DEFAULT NULL,
  `AudROAC` decimal(7,0) DEFAULT NULL,
  `AudTel` char(65) DEFAULT NULL,
  `AudFax` char(30) DEFAULT NULL,
  `AudMail` char(50) DEFAULT NULL,
  `AudFecnac` date DEFAULT NULL,
  `EmpNumAutTer` char(1) NOT NULL,
  `AudEjeIni` smallint DEFAULT NULL,
  `EmpFacRE` char(1) DEFAULT NULL,
  `EmpLogPie` blob,
  `AudEjeFin` smallint DEFAULT NULL,
  `EmpIvaDif` char(1) DEFAULT NULL,
  `EmpUltCon` smallint unsigned DEFAULT NULL,
  PRIMARY KEY (`EmpCod`),
  KEY `UEMPRESA11` (`EmpRazSoc`,`EmpCod`),
  KEY `IEMPRESAS1` (`DefCtaCtbleId`),
  KEY `IEMPRESAS2` (`EmpCod`,`EmpDivCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `empresasiae` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `EmpIAETpo` char(1) NOT NULL,
  `IAECod` smallint NOT NULL,
  PRIMARY KEY (`EmpCod`,`EmpIAETpo`,`IAECod`),
  KEY `IEMPRESASIAE` (`IAECod`),
  CONSTRAINT `IEMPRESASIAE` FOREIGN KEY (`IAECod`) REFERENCES `iae` (`IAECod`),
  CONSTRAINT `IEMPRESASIAE1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `empresaslevel2` (
  `EmpCod` smallint NOT NULL,
  `EmpModId` char(2) NOT NULL,
  `EmpModDes` char(30) NOT NULL,
  PRIMARY KEY (`EmpCod`,`EmpModId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `empsepa` (
  `EmpCod` smallint NOT NULL,
  `EmpDeuFecUpd` date NOT NULL,
  `EmpDeuCod` char(35) NOT NULL,
  `EmpDeuCif` char(15) NOT NULL,
  `EmpDeuNom` char(50) NOT NULL,
  PRIMARY KEY (`EmpCod`,`EmpDeuFecUpd`),
  CONSTRAINT `IEMPSEPA1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `empsuc` (
  `EmpCod` smallint NOT NULL,
  `SucCod` smallint NOT NULL,
  `SucNom` char(30) NOT NULL,
  `SucUsuCod` char(10) NOT NULL,
  `SucUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`SucCod`),
  CONSTRAINT `IEMPSUC1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `entbanc` (
  `EmpCod` smallint NOT NULL,
  `EntBancCOd` char(4) NOT NULL,
  `EntBancNom` char(40) NOT NULL,
  `EntBancUsu` char(10) NOT NULL,
  `EntBancUlt` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`EntBancCOd`),
  KEY `UENTBAN1` (`EmpCod`,`EntBancNom`),
  CONSTRAINT `IENTBAN1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `exctpo` (
  `EmpCod` smallint NOT NULL,
  `ExcCod` char(3) NOT NULL,
  `ExcNom` char(40) NOT NULL,
  `ExcMod` char(1) NOT NULL,
  PRIMARY KEY (`EmpCod`,`ExcCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `faclinlote` (
  `EmpCod` smallint NOT NULL,
  `FacCod` int NOT NULL,
  `FacLinLin` smallint NOT NULL,
  `FacLinLoteCod` char(20) NOT NULL,
  `FacLinLoteArtLin` smallint NOT NULL,
  `FacLinLoteOrd` smallint NOT NULL,
  `FacLinLoteCnt` decimal(9,3) NOT NULL,
  `FacLinLoteArt` char(13) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`FacCod`,`FacLinLin`,`FacLinLoteCod`,`FacLinLoteArtLin`),
  CONSTRAINT `IFACLOTE1` FOREIGN KEY (`EmpCod`, `FacCod`, `FacLinLin`) REFERENCES `facturasfaclin` (`EmpCod`, `FacCod`, `FacLinLin`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `facmod` (
  `EmpCod` smallint NOT NULL,
  `FacModId` smallint NOT NULL,
  `FacModMod` longblob NOT NULL,
  `FacModLin` smallint NOT NULL,
  `FacModLin2` smallint NOT NULL,
  `FacModChr` smallint NOT NULL,
  `FacModImg` longblob NOT NULL,
  `FacModDesc` char(200) NOT NULL,
  `FacModEstS` char(1) NOT NULL,
  `FacModEstN` char(1) NOT NULL,
  `FacModQRY` smallint DEFAULT NULL,
  `FacModQRX` smallint DEFAULT NULL,
  `FacModQRScale` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`FacModId`),
  CONSTRAINT `IFACMOD1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `facturas` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `FacCod` int NOT NULL,
  `FacNom` char(40) NOT NULL,
  `FacCom` char(40) DEFAULT NULL,
  `FacDir` char(50) NOT NULL DEFAULT '',
  `FacDir2` char(80) DEFAULT NULL,
  `FacPostal` char(10) NOT NULL,
  `FacPob` char(40) NOT NULL DEFAULT '',
  `FacProv` char(2) NOT NULL,
  `FacPais` char(3) NOT NULL,
  `FacNif` char(15) NOT NULL,
  `FacFec` date NOT NULL,
  `FacSer` char(3) DEFAULT NULL,
  `FacNum` int DEFAULT NULL,
  `FacFecRec` date DEFAULT NULL,
  `FacSerRec` char(3) DEFAULT NULL,
  `FacNumRec` int DEFAULT NULL,
  `FacExe` char(1) NOT NULL,
  `FacRec` char(1) NOT NULL,
  `FacDivCod` char(3) NOT NULL,
  `FacDivCam` decimal(11,4) NOT NULL,
  `FacIrpfCod` char(3) DEFAULT NULL,
  `FacIrpfPor` decimal(5,2) DEFAULT NULL,
  `FacIrpfBas` decimal(11,2) DEFAULT NULL,
  `FacIrpfImp` decimal(11,2) DEFAULT NULL,
  `FacIrpfCtaTit` char(4) DEFAULT NULL,
  `FacIrpfCtaCod` char(6) DEFAULT NULL,
  `FacEjer` char(8) DEFAULT NULL,
  `FacAsi` int DEFAULT NULL,
  `FacUltLin` smallint NOT NULL,
  `FacUltDes` smallint NOT NULL,
  `FacUsu` char(10) NOT NULL,
  `FacMod` datetime NOT NULL,
  `FacCtaTit` char(4) NOT NULL,
  `FacCtaCod` mediumint NOT NULL,
  `FacCodDes` char(1) NOT NULL,
  `FacPaisCee` char(3) NOT NULL,
  `FacEnvDir` char(40) DEFAULT NULL,
  `FacEnvPostal` char(10) DEFAULT NULL,
  `FacEnvProv` char(2) DEFAULT NULL,
  `FacPlazos` smallint NOT NULL,
  `FacDiaHastaVto` smallint NOT NULL,
  `FacDiaEntreVto` smallint NOT NULL,
  `FacDiaCob1` smallint NOT NULL,
  `FacDiaCob2` smallint NOT NULL,
  `FacEnvCod` mediumint DEFAULT NULL,
  `FacEnvCom` char(40) DEFAULT NULL,
  `FacEnvPob` char(40) DEFAULT NULL,
  `FacCobCod` char(3) NOT NULL,
  `FacSupDes` char(50) DEFAULT NULL,
  `FacSupImp` decimal(11,2) DEFAULT NULL,
  `FacTotal` decimal(11,2) DEFAULT NULL,
  `FacUltVto` smallint NOT NULL,
  `FacVto1` date DEFAULT NULL,
  `FacVtoImp1` decimal(11,2) DEFAULT NULL,
  `FacVto2` date DEFAULT NULL,
  `FacVtoImp2` decimal(11,2) DEFAULT NULL,
  `FacVto3` date DEFAULT NULL,
  `FacVtoImp3` decimal(11,2) DEFAULT NULL,
  `FacTip` char(1) NOT NULL,
  `FacPreser` char(1) NOT NULL,
  `FacTriang` char(1) NOT NULL,
  `Fac349` char(1) NOT NULL,
  `DvsCod` smallint DEFAULT NULL,
  `CentCod` smallint DEFAULT NULL,
  `FacIngCtaCod` char(6) DEFAULT NULL,
  `FacIngCtaTit` char(4) DEFAULT NULL,
  `FacTuraE` char(1) DEFAULT NULL,
  `FacEst` char(1) DEFAULT NULL,
  `FacFecEnvEmail` date DEFAULT NULL,
  `FacMail` char(50) DEFAULT NULL,
  `FacTel` char(65) DEFAULT NULL,
  `FacAlb` char(1) DEFAULT NULL,
  `FacIntraTipo` char(1) DEFAULT NULL,
  `FacAmbito` char(1) DEFAULT NULL,
  `FacHashData` varchar(1000) DEFAULT NULL,
  `FacHashCode` varchar(1000) DEFAULT NULL,
  `FacIdSIF` char(40) DEFAULT NULL,
  `FacQR` longblob,
  `FacVeriCSV` char(32) DEFAULT NULL,
  `FacVeriEst` char(20) DEFAULT NULL,
  `FacVeriErrCod` int DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`FacCod`),
  KEY `IFACTURAS1` (`EmpCod`,`CentCod`,`DvsCod`),
  KEY `UFACTURAS1` (`EmpCod`,`FacEjer`,`FacAsi`),
  KEY `UFACFEC` (`EmpCod`,`FacFec`),
  KEY `UFECDESC` (`EmpCod`,`FacFec`,`FacNum`),
  KEY `UFACESTCLI` (`EmpCod`,`FacEst`,`FacCtaCod`),
  CONSTRAINT `IFACTURAS1` FOREIGN KEY (`EmpCod`, `CentCod`, `DvsCod`) REFERENCES `empcenlevel1` (`EmpCod`, `CentCod`, `DvsCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `facturasadjuntos` (
  `EmpCod` smallint NOT NULL,
  `FacCod` int NOT NULL,
  `FacAdjId` smallint NOT NULL,
  `FacAdjBlob` longblob NOT NULL,
  `FacAdjFormato` char(4) NOT NULL,
  `FacAdjTpo` char(8) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`FacCod`,`FacAdjId`),
  CONSTRAINT `IFACVTAPROADJUNTOS1` FOREIGN KEY (`EmpCod`, `FacCod`) REFERENCES `facturas` (`EmpCod`, `FacCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `facturasfacdes` (
  `EmpCod` smallint NOT NULL,
  `FacCod` int NOT NULL,
  `FacDesTip` char(1) NOT NULL,
  `FacDesCtaTit` char(4) NOT NULL,
  `FacDesCtaCod` char(6) NOT NULL,
  `FacDesImp` decimal(11,2) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`FacCod`,`FacDesTip`,`FacDesCtaTit`,`FacDesCtaCod`),
  CONSTRAINT `IFACTURASFACDES1` FOREIGN KEY (`EmpCod`, `FacCod`) REFERENCES `facturas` (`EmpCod`, `FacCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `facturasfacdto` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `FacCod` int NOT NULL,
  `FacDtoLin` smallint NOT NULL,
  `FacDtoCod` char(3) NOT NULL,
  `FacDtoCon` char(25) NOT NULL,
  `FacDtoPor` decimal(5,2) NOT NULL,
  `FacDtoTip` char(1) NOT NULL,
  `FacDtoSec` smallint DEFAULT NULL,
  `FacDtoImp` decimal(11,2) DEFAULT NULL,
  `FacDtoCtaTit` char(4) DEFAULT NULL,
  `FacDtoCtaCod` char(6) DEFAULT NULL,
  `FacDtoIvaPor` decimal(5,2) DEFAULT NULL,
  `FacDtoIvaCod` char(5) NOT NULL,
  `FacDtoIvaRec` decimal(5,2) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`FacCod`,`FacDtoLin`),
  KEY `IFACTURASFACDTO4` (`EmpCod`,`FacDtoCod`),
  CONSTRAINT `IFACTURASFACDTO1` FOREIGN KEY (`EmpCod`, `FacCod`) REFERENCES `facturas` (`EmpCod`, `FacCod`),
  CONSTRAINT `IFACTURASFACDTO4` FOREIGN KEY (`EmpCod`, `FacDtoCod`) REFERENCES `dtocarfac` (`EmpCod`, `DtoCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `facturasfacimp` (
  `EmpCod` smallint NOT NULL,
  `FacCod` int NOT NULL,
  `FacImpCod` char(1) NOT NULL,
  `FacImpIvaCod` char(5) NOT NULL,
  `FacImpBase` decimal(11,2) DEFAULT NULL,
  `FacImpPor` decimal(5,2) DEFAULT NULL,
  `FacImpImp` decimal(11,2) DEFAULT NULL,
  `FacImpRec` decimal(5,2) DEFAULT NULL,
  `FacImpImpRec` decimal(11,2) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`FacCod`,`FacImpCod`,`FacImpIvaCod`),
  CONSTRAINT `IFACTURASFACIMP1` FOREIGN KEY (`EmpCod`, `FacCod`) REFERENCES `facturas` (`EmpCod`, `FacCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `facturasfaclin` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `FacCod` int NOT NULL,
  `FacLinLin` smallint NOT NULL,
  `FacLinArt` char(13) NOT NULL,
  `FacLinCon` char(50) NOT NULL,
  `FacLinConL` varchar(2048) NOT NULL,
  `FacLinUni` decimal(10,3) DEFAULT NULL,
  `FacLinPre` decimal(10,3) DEFAULT NULL,
  `FacLinMed` char(3) NOT NULL,
  `FacLinDtoPor` decimal(5,2) DEFAULT NULL,
  `FacLinDtoImp` decimal(11,2) DEFAULT NULL,
  `FacLinIvaCod` char(5) NOT NULL,
  `FacLinIvaPor` decimal(5,2) NOT NULL,
  `FacLinCtaTit` char(4) DEFAULT NULL,
  `FacLinCtaCod` char(6) DEFAULT NULL,
  `FacLinImp` decimal(10,3) DEFAULT NULL,
  `FacLinIvaRec` decimal(5,2) NOT NULL,
  `FacLinBarras` char(13) DEFAULT NULL,
  `FacLinIrpfCod` char(3) DEFAULT NULL,
  `FacLinElimina` char(1) DEFAULT NULL,
  `FacLinAuxCon` char(50) DEFAULT NULL,
  `FacLinImpAux` decimal(10,3) DEFAULT NULL,
  `FacLinAuxUni` decimal(9,3) DEFAULT NULL,
  `FacLinFecExp` date DEFAULT NULL,
  `FacLinRefExp` char(20) DEFAULT NULL,
  `FacLinFecOpeRec` date DEFAULT NULL,
  `FacLinRefOpeRec` char(20) DEFAULT NULL,
  `FacLinFecConRec` date DEFAULT NULL,
  `FacLinRefConRec` char(20) DEFAULT NULL,
  `FacLinFecOpeEmi` date DEFAULT NULL,
  `FacLinRefOpeEmi` char(20) DEFAULT NULL,
  `FacLinFecConEmi` date DEFAULT NULL,
  `FacLinRefConEmi` char(20) DEFAULT NULL,
  `FacLinAlbaran` int DEFAULT NULL,
  `FacLinLote` char(20) DEFAULT NULL,
  `FacLinUniAnt` decimal(9,3) DEFAULT NULL,
  `FacLinLotMan` char(20) DEFAULT NULL,
  `FacLinCaj` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`FacCod`,`FacLinLin`),
  KEY `IFACTURASFACLIN2` (`EmpCod`,`FacLinArt`),
  CONSTRAINT `IFACTURASFACLIN1` FOREIGN KEY (`EmpCod`, `FacCod`) REFERENCES `facturas` (`EmpCod`, `FacCod`),
  CONSTRAINT `IFACTURASFACLIN2` FOREIGN KEY (`EmpCod`, `FacLinArt`) REFERENCES `articulos` (`EmpCod`, `ArtCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `facturasfacven` (
  `EmpCod` smallint NOT NULL,
  `FacCod` int NOT NULL,
  `FacVenCod` char(1) NOT NULL,
  `FacVenCtaTit` char(4) NOT NULL,
  `FacVenCtaCod` char(6) NOT NULL,
  `FacVenImp` decimal(11,2) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`FacCod`,`FacVenCod`,`FacVenCtaTit`,`FacVenCtaCod`),
  CONSTRAINT `IFACTURASFACVEN1` FOREIGN KEY (`EmpCod`, `FacCod`) REFERENCES `facturas` (`EmpCod`, `FacCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `facvtaproemail` (
  `EmpCod` smallint NOT NULL,
  `FacCod` int NOT NULL,
  `FacFecId` int NOT NULL,
  `FacFecEnv` datetime DEFAULT NULL,
  `FacFecTo` char(100) DEFAULT NULL,
  `FacFecOCD` char(1) DEFAULT NULL,
  `FacFecUsr` char(30) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`FacCod`,`FacFecId`),
  CONSTRAINT `IFACVTAPROEMAIL1` FOREIGN KEY (`EmpCod`, `FacCod`) REFERENCES `facturas` (`EmpCod`, `FacCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `famgru` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `FamGruCod` smallint NOT NULL,
  `FamGruDes` char(40) NOT NULL DEFAULT '',
  PRIMARY KEY (`EmpCod`,`FamGruCod`),
  CONSTRAINT `IFAMGRU1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `familias` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `FamCod` char(8) NOT NULL,
  `FamDes` char(30) NOT NULL,
  `FamImp` char(1) NOT NULL,
  `FamIvaTpoCod` char(5) DEFAULT NULL,
  `FamCtaCodE` char(6) DEFAULT NULL,
  `FamCtaTitE` char(4) DEFAULT NULL,
  `FamCtaCodI` char(6) DEFAULT NULL,
  `FamCtaTitI` char(4) DEFAULT NULL,
  `FamCtaCod` char(6) DEFAULT NULL,
  `FamCtaTit` char(4) DEFAULT NULL,
  `FamIrpfCod` char(3) DEFAULT NULL,
  `FamClase` char(1) DEFAULT NULL,
  `FamComLin` decimal(4,0) DEFAULT NULL,
  `FamIgicTpoCod` char(5) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`FamCod`),
  KEY `IFAMILIAS2` (`EmpCod`,`FamCtaTit`,`FamCtaCod`),
  KEY `IFAMILIAS3` (`EmpCod`,`FamCtaTitI`,`FamCtaCodI`),
  KEY `IFAMILIAS4` (`EmpCod`,`FamCtaTitE`,`FamCtaCodE`),
  KEY `IFAMILIAS5` (`EmpCod`,`FamIgicTpoCod`),
  CONSTRAINT `IFAMILAS3` FOREIGN KEY (`EmpCod`, `FamCtaTitI`, `FamCtaCodI`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `IFAMILIAS2` FOREIGN KEY (`EmpCod`, `FamCtaTit`, `FamCtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `IFAMILIAS4` FOREIGN KEY (`EmpCod`, `FamCtaTitE`, `FamCtaCodE`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `IFAMILIAS5` FOREIGN KEY (`EmpCod`, `FamIgicTpoCod`) REFERENCES `igictipos` (`EmpCod`, `IgicTpoCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `familiasfamgru` (
  `EmpCod` smallint NOT NULL,
  `FamCod` char(8) NOT NULL,
  `FamGruCod` smallint NOT NULL,
  PRIMARY KEY (`EmpCod`,`FamCod`,`FamGruCod`),
  KEY `IFAMILIASFAMGRU1` (`EmpCod`,`FamGruCod`),
  CONSTRAINT `IFAMILIASFAMGRU1` FOREIGN KEY (`EmpCod`, `FamGruCod`) REFERENCES `famgru` (`EmpCod`, `FamGruCod`),
  CONSTRAINT `IFAMILIASFAMGRU2` FOREIGN KEY (`EmpCod`, `FamCod`) REFERENCES `familias` (`EmpCod`, `FamCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `forcob` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `ForCobCod` char(3) NOT NULL,
  `ForCobDes` char(40) NOT NULL,
  `ForCobDtoPP` decimal(5,2) NOT NULL,
  `ForCobGtoFin` decimal(5,2) NOT NULL,
  `ForCobUsuCod` char(10) NOT NULL,
  `ForCobUltFec` datetime NOT NULL,
  `ForCobRis` smallint DEFAULT NULL,
  `ForCobSN` char(1) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`ForCobCod`),
  KEY `UFORCOB` (`EmpCod`,`ForCobDes`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `forpag` (
  `EmpCod` smallint NOT NULL,
  `ForPagCod` char(3) NOT NULL,
  `ForPagDes` char(40) NOT NULL,
  `ForPagUsuCod` char(10) NOT NULL,
  `ForPagUltFec` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`ForPagCod`),
  KEY `UFORPAG` (`EmpCod`,`ForPagDes`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `grupoinmov` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `GruIdCtaTit` char(4) NOT NULL,
  `GruIdCtaCod` char(6) NOT NULL,
  `GruActivo` char(4) DEFAULT NULL,
  `GruCurso` char(1) DEFAULT NULL,
  `GruNsa` char(1) DEFAULT NULL,
  `GruDetP` char(4) DEFAULT NULL,
  `Grudet` char(4) DEFAULT NULL,
  `GruBfo` char(4) DEFAULT NULL,
  `GruPerd` char(4) DEFAULT NULL,
  `GruDot` char(4) DEFAULT NULL,
  `GruAmo` char(4) DEFAULT NULL,
  `GruEnaj` char(4) DEFAULT NULL,
  `GruCtaCod` char(6) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`GruIdCtaTit`,`GruIdCtaCod`),
  CONSTRAINT `IGRUPOINMOV` FOREIGN KEY (`EmpCod`, `GruIdCtaTit`, `GruIdCtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `gvconceptos` (
  `EmpCod` smallint NOT NULL,
  `GVConcepId` char(3) NOT NULL,
  `GVConcepDes` char(40) NOT NULL,
  PRIMARY KEY (`EmpCod`,`GVConcepId`),
  CONSTRAINT `IGVCONCEPTOS1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `gvconceptoslevel1` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `GVConcepId` char(3) NOT NULL,
  `GVConcepFec` date NOT NULL,
  `GVConcepLim` decimal(9,2) NOT NULL,
  `GVCtaTit` char(4) NOT NULL DEFAULT '',
  `GVCtaCod` char(6) NOT NULL DEFAULT '',
  PRIMARY KEY (`EmpCod`,`GVConcepId`,`GVConcepFec`),
  CONSTRAINT `IGVCONCEPTOSGVCONCEP1` FOREIGN KEY (`EmpCod`, `GVConcepId`) REFERENCES `gvconceptos` (`EmpCod`, `GVConcepId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `gvdesplazamiento` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `EplCod` mediumint NOT NULL,
  `GVDesFec` date NOT NULL,
  `GVDesNum` int NOT NULL,
  `GVDesEplIrpf` decimal(5,2) NOT NULL,
  `GVDesLug` char(20) NOT NULL,
  `GVDesCon` char(60) NOT NULL,
  `GVDesKms` decimal(6,2) NOT NULL,
  `GVDesKmsPre` decimal(9,2) NOT NULL,
  `GVDesKmsImp` decimal(9,2) NOT NULL,
  `GVDesKmsLim` decimal(9,2) NOT NULL,
  `GVDesKmsSuj` decimal(9,2) NOT NULL,
  `GVDesLiq` int NOT NULL,
  `GVDesAlq` decimal(9,2) NOT NULL,
  `GVDesAvi` decimal(9,2) NOT NULL,
  `GVDesCar` decimal(9,2) NOT NULL,
  `GVDesDce` decimal(9,2) NOT NULL,
  `GVDesDcn` decimal(9,2) NOT NULL,
  `GVDesHot` decimal(9,2) NOT NULL,
  `GVDesMan` decimal(9,2) NOT NULL,
  `GVDesMde` decimal(9,2) NOT NULL,
  `GVDesMdn` decimal(9,2) NOT NULL,
  `GVDesConcepId` char(3) NOT NULL,
  `GVDesDieta` decimal(9,2) NOT NULL,
  `GVDesDietaLim` decimal(9,2) NOT NULL,
  `GVDesDietaSuj` decimal(9,2) NOT NULL,
  `GVDesPar` decimal(9,2) NOT NULL,
  `GVDesPea` decimal(9,2) NOT NULL,
  `GVDesRep` decimal(9,2) NOT NULL,
  `GVDesTax` decimal(9,2) NOT NULL,
  `GVDesTre` decimal(9,2) NOT NULL,
  `GVDesBus` decimal(9,2) NOT NULL,
  `GVDesCon1` char(20) NOT NULL,
  `GVDesImp1` decimal(9,2) NOT NULL,
  `GVDesCon2` char(20) NOT NULL,
  `GVDesImp2` decimal(9,2) NOT NULL,
  `GVDesCon3` char(20) NOT NULL,
  `GVDesImp3` decimal(9,2) NOT NULL,
  `GVDesCon4` char(20) NOT NULL,
  `GVDesImp4` decimal(9,2) NOT NULL,
  `GVDesConAdjUltid` smallint DEFAULT NULL,
  `GVDesNumDW` int NOT NULL,
  `gvDesConConUltId` smallint NOT NULL,
  `GVDesPdtLiq` char(1) NOT NULL DEFAULT '',
  PRIMARY KEY (`EmpCod`,`EplCod`,`GVDesFec`,`GVDesNum`),
  CONSTRAINT `IGVDESPLAZAMIENTO1` FOREIGN KEY (`EmpCod`, `EplCod`) REFERENCES `empleados` (`EmpCod`, `EplCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `gvliquidacion` (
  `EmpCod` smallint NOT NULL,
  `EplCod` mediumint NOT NULL,
  `GVLiqDes` int NOT NULL,
  `GVLiqSuj` decimal(9,2) NOT NULL,
  `GVLiqNosuj` decimal(9,2) NOT NULL,
  `GVLiqReten` decimal(9,2) NOT NULL,
  `GVLiqNeto` decimal(9,2) NOT NULL,
  `GVLiqTjta` decimal(9,2) NOT NULL,
  `GVLiqCheq` decimal(9,2) NOT NULL,
  `GVLiqEfec` decimal(9,2) NOT NULL,
  `GVLiqAbon` decimal(9,2) NOT NULL,
  `GVLiqFact` decimal(9,2) NOT NULL,
  `GVLiqOtro` decimal(9,2) NOT NULL,
  `GVLiqTotal` decimal(9,2) NOT NULL,
  `GVLiqDfec` date NOT NULL,
  `GVLiqAfec` date NOT NULL,
  `GVLiqNota1` char(80) NOT NULL,
  `GVLiqNota2` char(80) NOT NULL,
  `GVLiqNota3` char(80) NOT NULL,
  PRIMARY KEY (`EmpCod`,`EplCod`,`GVLiqDes`),
  CONSTRAINT `IGVLIQUIDACION1` FOREIGN KEY (`EmpCod`, `EplCod`) REFERENCES `empleados` (`EmpCod`, `EplCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `gvnotadiariadetalleconcepto` (
  `EmpCod` smallint NOT NULL,
  `EplCod` mediumint NOT NULL,
  `GVDesFec` date NOT NULL,
  `GVDesNum` int NOT NULL,
  `GVDesConId` smallint NOT NULL,
  `GVDesConLin` smallint NOT NULL,
  `GVDesConFraSN` char(1) DEFAULT NULL,
  `GVDesConImp` decimal(11,2) DEFAULT NULL,
  `GVDesConFraFPag` smallint DEFAULT NULL,
  `GVDesDivCod` char(3) NOT NULL,
  `GVDesConImpME` decimal(11,2) NOT NULL,
  `GVDesConAdj` longblob,
  `GVDesConAdjNom` char(200) DEFAULT NULL,
  `GVDesConAdjType` char(4) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`EplCod`,`GVDesFec`,`GVDesNum`,`GVDesConId`,`GVDesConLin`),
  CONSTRAINT `IGVNOTADIARIADETALLECONCEPTO1` FOREIGN KEY (`EmpCod`, `EplCod`, `GVDesFec`, `GVDesNum`) REFERENCES `gvdesplazamiento` (`EmpCod`, `EplCod`, `GVDesFec`, `GVDesNum`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `iae` (
  `IAECod` smallint NOT NULL,
  `IAESeccion` smallint NOT NULL,
  `IAEDivision` char(1) NOT NULL,
  `IAEAgrupacion` char(2) NOT NULL,
  `IAEGrupo` char(3) NOT NULL,
  `IAEEpigrafe` char(5) NOT NULL,
  `IAEDenominacion` char(40) NOT NULL,
  `IAEBusqueda` char(100) DEFAULT NULL,
  PRIMARY KEY (`IAECod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `idiomas` (
  `IdiCod` char(3) NOT NULL,
  `IdiDes` char(30) NOT NULL,
  `IdiUsuCod` char(10) NOT NULL,
  `IdiUltMod` datetime NOT NULL,
  PRIMARY KEY (`IdiCod`),
  KEY `UIDIOMAS1` (`IdiDes`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `igictipos` (
  `EmpCod` smallint NOT NULL,
  `IgicTpoCod` char(5) NOT NULL,
  `IgicTpoNom` char(80) NOT NULL,
  PRIMARY KEY (`EmpCod`,`IgicTpoCod`),
  CONSTRAINT `IIGICTIPOS1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `igictiposctas` (
  `EmpCod` smallint NOT NULL,
  `IgicTpoCod` char(5) NOT NULL,
  `IgicTpoTpoCod` char(5) NOT NULL,
  `IgicTpoCtaTit` char(4) NOT NULL,
  `IgicTpoCtaCod` char(6) NOT NULL,
  PRIMARY KEY (`EmpCod`,`IgicTpoCod`,`IgicTpoTpoCod`),
  KEY `IIGICTIPOSCTAS1` (`EmpCod`,`IgicTpoTpoCod`),
  CONSTRAINT `IIGICTIPOSCTAS1` FOREIGN KEY (`EmpCod`, `IgicTpoTpoCod`) REFERENCES `tipigictip` (`EmpCod`, `IgicTpoTpoCod`),
  CONSTRAINT `IIGICTIPOSCTAS2` FOREIGN KEY (`EmpCod`, `IgicTpoCod`) REFERENCES `igictipos` (`EmpCod`, `IgicTpoCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `igictiposvigencia` (
  `EmpCod` smallint NOT NULL,
  `IgicTpoCod` char(5) NOT NULL,
  `IgicTpoVig` date NOT NULL,
  `IgicTpoPor` decimal(5,2) NOT NULL,
  `IgicTpoPorRe` decimal(5,2) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`IgicTpoCod`,`IgicTpoVig`),
  CONSTRAINT `IIGICTIPOSVIGENCIA1` FOREIGN KEY (`EmpCod`, `IgicTpoCod`) REFERENCES `igictipos` (`EmpCod`, `IgicTpoCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `infcalculo` (
  `CalcEmpcod` smallint NOT NULL,
  `CalcCon` smallint NOT NULL,
  `CalcSess` char(100) NOT NULL,
  `CalcDate` date NOT NULL,
  `CalcTotal` decimal(11,2) NOT NULL,
  `CalcTotAnt` decimal(11,2) NOT NULL,
  `CalcInf` smallint DEFAULT NULL,
  `CalcInfOrd` smallint DEFAULT NULL,
  `CalcImpA` decimal(11,2) DEFAULT NULL,
  `CalcImpC` decimal(11,2) DEFAULT NULL,
  `CalcImp1` decimal(11,2) DEFAULT NULL,
  `CalcImp2` decimal(11,2) DEFAULT NULL,
  `CalcImp3` decimal(11,2) DEFAULT NULL,
  `CalcImp4` decimal(11,2) DEFAULT NULL,
  `CalcImp5` decimal(11,2) DEFAULT NULL,
  `CalcImp6` decimal(11,2) DEFAULT NULL,
  `CalcImp7` decimal(11,2) DEFAULT NULL,
  `CalcImp8` decimal(11,2) DEFAULT NULL,
  `CalcImp9` decimal(11,2) DEFAULT NULL,
  `CalcImp10` decimal(11,2) DEFAULT NULL,
  `CalcImp11` decimal(11,2) DEFAULT NULL,
  `CalcImp12` decimal(11,2) DEFAULT NULL,
  PRIMARY KEY (`CalcEmpcod`,`CalcCon`,`CalcSess`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ivasujecion` (
  `EmpCod` smallint NOT NULL,
  `IvaSujCod` char(2) NOT NULL,
  `IvaSujNom` char(20) NOT NULL,
  `IvaSujApPor` char(1) NOT NULL,
  `IvaSujAsi` char(5) NOT NULL,
  PRIMARY KEY (`EmpCod`,`IvaSujCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ivatipos1` (
  `EmpCod` smallint NOT NULL,
  `IvaTpoCod` char(5) NOT NULL,
  `IvaTpoNom` char(80) NOT NULL,
  PRIMARY KEY (`EmpCod`,`IvaTpoCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ivatipos` (
  `EmpCod` smallint NOT NULL,
  `IvaTpoTpoCod` char(5) NOT NULL,
  `IvaTpoTpoNom` char(30) NOT NULL,
  PRIMARY KEY (`EmpCod`,`IvaTpoTpoCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ivatiposctas` (
  `EmpCod` smallint NOT NULL,
  `IvaTpoCod` char(5) NOT NULL,
  `IvaTpoTpoCod` char(5) NOT NULL,
  `IvaTpoCtaTit` char(4) NOT NULL,
  `IvaTpoCtaCod` char(6) NOT NULL,
  PRIMARY KEY (`EmpCod`,`IvaTpoCod`,`IvaTpoTpoCod`),
  KEY `IIVATIPOSTPOTPO12` (`EmpCod`,`IvaTpoTpoCod`),
  KEY `IIVATIPOSCTAS1` (`EmpCod`,`IvaTpoTpoCod`),
  CONSTRAINT `IIVATIPOSCTAS1` FOREIGN KEY (`EmpCod`, `IvaTpoTpoCod`) REFERENCES `ivatipos` (`EmpCod`, `IvaTpoTpoCod`),
  CONSTRAINT `IIVATIPOSCTAS2` FOREIGN KEY (`EmpCod`, `IvaTpoCod`) REFERENCES `ivatipos1` (`EmpCod`, `IvaTpoCod`),
  CONSTRAINT `IIVATIPOSTPOTPO12` FOREIGN KEY (`EmpCod`, `IvaTpoTpoCod`) REFERENCES `ivatipos` (`EmpCod`, `IvaTpoTpoCod`),
  CONSTRAINT `IIVATIPOSTPOTPO13` FOREIGN KEY (`EmpCod`, `IvaTpoCod`) REFERENCES `ivatipos1` (`EmpCod`, `IvaTpoCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ivatiposextranjero` (
  `IvaExTpo` char(6) NOT NULL,
  `PaiCod` char(3) NOT NULL,
  `IvaExDes` char(80) NOT NULL,
  PRIMARY KEY (`IvaExTpo`,`PaiCod`),
  KEY `IIVAEXTRANJERO1` (`PaiCod`),
  CONSTRAINT `IIVAEXTRANJERO1` FOREIGN KEY (`PaiCod`) REFERENCES `pais` (`PaiCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ivatiposextranjeroctas` (
  `IvaExTpo` char(6) NOT NULL,
  `PaiCod` char(3) NOT NULL,
  `IvaExTpoTpoCod` char(5) NOT NULL,
  `EmpCod` smallint NOT NULL,
  `CtaTit` char(4) NOT NULL,
  `CtaCod` char(6) NOT NULL,
  PRIMARY KEY (`IvaExTpo`,`PaiCod`,`IvaExTpoTpoCod`),
  KEY `IIVAEXTRANJEROLEVEL11` (`EmpCod`,`CtaTit`,`CtaCod`),
  CONSTRAINT `IIVAEXTRANJEROLEVEL11` FOREIGN KEY (`EmpCod`, `CtaTit`, `CtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `IIVAEXTRANJEROLEVEL12` FOREIGN KEY (`IvaExTpo`, `PaiCod`) REFERENCES `ivatiposextranjero` (`IvaExTpo`, `PaiCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ivatiposextranjerovig` (
  `IvaExTpo` char(6) NOT NULL,
  `PaiCod` char(3) NOT NULL,
  `IvaExVigencia` date NOT NULL,
  `IvaExPor` decimal(5,2) NOT NULL,
  PRIMARY KEY (`IvaExTpo`,`PaiCod`,`IvaExVigencia`),
  CONSTRAINT `IIVAEXTRANJEROVIGENCIAS1` FOREIGN KEY (`IvaExTpo`, `PaiCod`) REFERENCES `ivatiposextranjero` (`IvaExTpo`, `PaiCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ivavigencia` (
  `EmpCod` smallint NOT NULL,
  `IvaTpoCod` char(5) NOT NULL,
  `IvaTpoVig` date NOT NULL,
  `IvaTpoPor` decimal(5,2) NOT NULL,
  `IvaTpoPorRE` decimal(5,2) NOT NULL,
  PRIMARY KEY (`EmpCod`,`IvaTpoCod`,`IvaTpoVig`),
  KEY `UIVAVIGENCIA` (`EmpCod`,`IvaTpoPor`,`IvaTpoVig`),
  CONSTRAINT `IIVAVIGENCIA1` FOREIGN KEY (`EmpCod`, `IvaTpoCod`) REFERENCES `ivatipos1` (`EmpCod`, `IvaTpoCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `limdeclara` (
  `LimCod` char(6) NOT NULL,
  `LimImp` decimal(11,2) NOT NULL,
  `LimDes` char(20) DEFAULT NULL,
  PRIMARY KEY (`LimCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `liqiva` (
  `LiqIvaEmpCod` smallint NOT NULL,
  `LiqIvaSession` char(100) NOT NULL,
  `LiqIvaCtaTit` char(4) NOT NULL,
  `LiqIvaCtaCod` char(6) NOT NULL,
  `LiqIvaDiario` smallint NOT NULL,
  `LiqIvaEjerCod` char(8) DEFAULT NULL,
  `LiqIvaMovId` int DEFAULT NULL,
  `LiqIvaLinId` smallint DEFAULT NULL,
  `LiqIvaCuota` decimal(11,2) DEFAULT NULL,
  `LiqIvaBase` decimal(11,2) DEFAULT NULL,
  `LiqIvaPor` decimal(5,2) DEFAULT NULL,
  `LiqIvaTpo` smallint DEFAULT NULL,
  `LiqIvaFecAlta` date DEFAULT NULL,
  `LiqUsuCod` char(10) DEFAULT NULL,
  `LiqUltMod` datetime DEFAULT NULL,
  PRIMARY KEY (`LiqIvaEmpCod`,`LiqIvaSession`,`LiqIvaCtaTit`,`LiqIvaCtaCod`,`LiqIvaDiario`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `localidad` (
  `PaiCod` char(3) NOT NULL DEFAULT '',
  `PrvCod` char(10) NOT NULL DEFAULT '',
  `LocCnt` smallint NOT NULL DEFAULT '0',
  `LocDes` char(40) DEFAULT NULL,
  `LocCodPos` char(10) NOT NULL DEFAULT '',
  `LocUsuCod` char(10) DEFAULT NULL,
  `LocUltMod` datetime DEFAULT NULL,
  `LocDesCP` char(60) DEFAULT NULL,
  PRIMARY KEY (`PaiCod`,`PrvCod`,`LocCodPos`,`LocCnt`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `localidades` (
  `PaiCod` char(3) NOT NULL,
  `PrvCod` char(2) NOT NULL,
  `LocCodPos` char(10) NOT NULL,
  `LocCnt` int NOT NULL,
  `LocDes` char(40) NOT NULL,
  `LocUsuCod` char(10) NOT NULL,
  `LocUltMod` datetime NOT NULL,
  PRIMARY KEY (`PaiCod`,`PrvCod`,`LocCodPos`,`LocCnt`),
  CONSTRAINT `ILOCALIDADES1` FOREIGN KEY (`PaiCod`, `PrvCod`) REFERENCES `provincia` (`PaiCod`, `PrvCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `lote` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `LotCod` char(20) NOT NULL,
  `LotFecEnt` date NOT NULL,
  `ProCod` mediumint NOT NULL,
  `LotUsuCod` char(10) NOT NULL,
  `LotUltMod` datetime NOT NULL,
  `LotDes` char(40) NOT NULL,
  `LotCerSN` char(1) NOT NULL,
  `LotFecINS` datetime NOT NULL,
  `LotUsuCodINS` char(10) NOT NULL,
  `LotFraPro` char(40) DEFAULT NULL,
  `LotEst` smallint NOT NULL,
  `LotNroOC` char(40) DEFAULT NULL,
  `LotUltLin` smallint NOT NULL,
  `LotEntCon` char(1) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`LotCod`),
  KEY `ILOTE1` (`EmpCod`,`ProCod`),
  CONSTRAINT `ILOTE1` FOREIGN KEY (`EmpCod`, `ProCod`) REFERENCES `proveedor` (`EmpCod`, `ProCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `lotearticulo` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `LotCod` char(20) NOT NULL,
  `ArtCod` char(13) NOT NULL,
  `CentCod` smallint NOT NULL,
  `LotArtLin` smallint NOT NULL,
  `LotNroPro` char(20) NOT NULL,
  `LotCanEnt` decimal(9,3) DEFAULT NULL,
  `LotCanSal` decimal(9,3) NOT NULL,
  `LotFecCad` date NOT NULL,
  `LotArtCerSN` char(1) NOT NULL,
  `LotArtImpCompra` decimal(11,2) NOT NULL,
  `LotArtImpRecomen` decimal(11,2) NOT NULL,
  `LotCanAnt` decimal(9,3) NOT NULL,
  `LotArtLocCB` char(13) NOT NULL,
  `LotArtLoc` char(50) NOT NULL,
  `LotCanBulPale` smallint unsigned NOT NULL DEFAULT '0',
  `LotCanPale` smallint NOT NULL,
  `LotCanTara` decimal(11,2) NOT NULL,
  `LotCanUniBul` decimal(9,3) NOT NULL,
  `LotArtLinUltReg` smallint NOT NULL DEFAULT '0',
  PRIMARY KEY (`EmpCod`,`LotCod`,`ArtCod`,`CentCod`,`LotArtLin`),
  KEY `ILOTEARTICULO` (`EmpCod`,`CentCod`),
  KEY `ILOTEARTICULO1` (`EmpCod`,`ArtCod`),
  KEY `ULOTEARTICULO` (`EmpCod`,`CentCod`,`ArtCod`,`LotArtCerSN`),
  CONSTRAINT `ITLOTELOTEARTICULO2` FOREIGN KEY (`EmpCod`, `LotCod`) REFERENCES `lote` (`EmpCod`, `LotCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `lotelotearticulo` (
  `EmpCod` smallint NOT NULL,
  `LotCod` char(20) NOT NULL,
  `ArtCod` char(13) NOT NULL,
  `LotCanEnt` decimal(9,3) NOT NULL,
  `LotCanSal` decimal(9,3) NOT NULL,
  `LotFecCad` date NOT NULL,
  PRIMARY KEY (`EmpCod`,`LotCod`,`ArtCod`),
  KEY `ILOTELOTEARTICULO1` (`EmpCod`,`ArtCod`),
  CONSTRAINT `ILOTELOTEARTICULO1` FOREIGN KEY (`EmpCod`, `ArtCod`) REFERENCES `articulos` (`EmpCod`, `ArtCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `lotgastos` (
  `EmpCod` smallint NOT NULL,
  `LotCod` char(20) NOT NULL,
  `ComGasCod` smallint NOT NULL,
  `LotComGasImp` decimal(11,2) NOT NULL,
  PRIMARY KEY (`EmpCod`,`LotCod`,`ComGasCod`),
  KEY `ILOTGASTOS1` (`EmpCod`,`ComGasCod`),
  CONSTRAINT `ILOTGASTOS1` FOREIGN KEY (`EmpCod`, `ComGasCod`) REFERENCES `comgas` (`EmpCod`, `ComGasCod`),
  CONSTRAINT `ILOTGASTOS2` FOREIGN KEY (`EmpCod`, `LotCod`) REFERENCES `lote` (`EmpCod`, `LotCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `mayores347` (
  `EmpCod` smallint NOT NULL,
  `MayCod` char(4) NOT NULL,
  PRIMARY KEY (`EmpCod`,`MayCod`),
  CONSTRAINT `IMAYORES3471` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `metodoamort` (
  `MetId` char(3) NOT NULL,
  `MetCon` char(20) NOT NULL,
  PRIMARY KEY (`MetId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `modlistados` (
  `EmpCod` smallint NOT NULL,
  `ModId` char(15) NOT NULL,
  `ModDesc` char(80) NOT NULL,
  `ModAdj` longblob NOT NULL,
  PRIMARY KEY (`EmpCod`,`ModId`),
  CONSTRAINT `IMODLISTADOS1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `monedas` (
  `EmpCod` smallint NOT NULL,
  `MonCod` char(3) NOT NULL,
  `MonDes` char(40) NOT NULL,
  `MonUsuCod` char(10) NOT NULL,
  `MonUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`MonCod`),
  KEY `UMON1` (`EmpCod`,`MonDes`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `movctas` (
  `MovEmpCod` smallint NOT NULL DEFAULT '0',
  `EjerCod` char(8) NOT NULL,
  `MovId` int NOT NULL,
  `MovLin` smallint NOT NULL,
  `MovFecha` date NOT NULL,
  `MovDiario` smallint NOT NULL DEFAULT '0',
  `ConCod` smallint DEFAULT NULL,
  `MovDCtaTit` char(4) NOT NULL,
  `MovDCtaCod` char(6) NOT NULL,
  `MovImpDebe` decimal(11,2) NOT NULL,
  `MovHCtaTit` char(4) NOT NULL,
  `MovHCtaCod` char(6) NOT NULL,
  `MovImpHaber` decimal(11,2) NOT NULL,
  `MovObs` char(40) NOT NULL,
  `MovNroDoc` int NOT NULL,
  `MovSerie` char(3) NOT NULL DEFAULT '',
  `MovDocFch` date NOT NULL DEFAULT '1000-01-01',
  `SucCod` smallint DEFAULT NULL,
  `MovFecExt` date NOT NULL,
  `Mov349` char(1) NOT NULL,
  `MovTriang` char(1) NOT NULL,
  `MovNumExp` char(20) NOT NULL,
  `MovTipo` char(1) NOT NULL,
  `MovCab` char(1) NOT NULL,
  `MovMonCod` char(3) NOT NULL,
  `MovMonTipCam` decimal(11,4) NOT NULL,
  `MovImpDiv` decimal(11,2) NOT NULL,
  `MovClaIva` char(3) NOT NULL,
  `MovImgDoc` longblob,
  `MovUsuCod` char(10) NOT NULL,
  `MovUltMod` datetime NOT NULL,
  `MovImgDocType` char(4) DEFAULT NULL,
  `MovImgDocName` char(200) DEFAULT NULL,
  `MovFraFec` date NOT NULL,
  `MovFraNro` char(40) NOT NULL,
  `MovMonFecCam` date NOT NULL,
  `MovClaTipLibIva` char(1) NOT NULL,
  `MovPreSer` char(1) NOT NULL,
  `MovImpNomAux2` decimal(11,2) DEFAULT NULL,
  `MovImpNomAux` decimal(11,2) DEFAULT NULL,
  `MovNotUPD` char(1) DEFAULT NULL,
  PRIMARY KEY (`MovEmpCod`,`EjerCod`,`MovId`,`MovLin`),
  KEY `IMOVCTAS1` (`MovEmpCod`,`MovHCtaTit`,`MovHCtaCod`),
  KEY `IMOVCTAS2` (`MovEmpCod`,`MovDCtaTit`,`MovDCtaCod`),
  KEY `IMOVCTAS3` (`MovEmpCod`,`SucCod`),
  KEY `UMOVCTAS1` (`MovEmpCod`,`EjerCod`,`MovFecha`,`MovId`,`MovLin`),
  KEY `UMOVCTAS2` (`MovEmpCod`,`EjerCod`,`MovFecha`,`MovId`,`MovTipo`,`MovLin`),
  KEY `IMOVCTAS5` (`MovEmpCod`,`ConCod`),
  KEY `UMOVCTAS3` (`EjerCod`,`MovId`),
  KEY `UMOVCTAS4` (`MovEmpCod`,`MovFecha`,`MovDiario`,`MovTipo`,`MovId`,`MovDCtaTit`,`MovDCtaCod`),
  KEY `UMOVCTAS5` (`MovEmpCod`,`MovFecha`,`MovDiario`,`MovTipo`,`MovId`,`MovHCtaTit`,`MovHCtaCod`),
  KEY `UMOVCTAS6` (`MovEmpCod`,`MovFecha`,`MovId`,`MovLin`),
  KEY `UMOVCTAS7` (`MovEmpCod`,`MovFecha`,`MovId`,`MovTipo`,`MovLin`),
  KEY `UMOVCTAS8` (`MovEmpCod`,`MovFecha`,`MovDiario`,`MovId`,`MovLin`),
  CONSTRAINT `IMOVCTAS1` FOREIGN KEY (`MovEmpCod`, `MovHCtaTit`, `MovHCtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `IMOVCTAS2` FOREIGN KEY (`MovEmpCod`, `MovDCtaTit`, `MovDCtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `IMOVCTAS4` FOREIGN KEY (`MovEmpCod`, `EjerCod`) REFERENCES `paramejer` (`EmpCod`, `EjerCod`),
  CONSTRAINT `IMOVCTAS5` FOREIGN KEY (`MovEmpCod`, `ConCod`) REFERENCES `tconceptos` (`EmpCod`, `ConCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `movctaslevel1` (
  `MovEmpCod` smallint NOT NULL,
  `EjerCod` char(8) NOT NULL,
  `MovId` int NOT NULL,
  `MovLin` smallint NOT NULL,
  `MovIvaId` int NOT NULL,
  `MovIvaTip` char(1) NOT NULL,
  `MovIvaClas` char(1) NOT NULL,
  `MovIvaBase` decimal(11,2) NOT NULL,
  `MovIvaPor` decimal(5,2) NOT NULL,
  `MovIvaCuota` decimal(9,2) NOT NULL,
  `MovIvaDed` char(2) NOT NULL,
  `MovIvaPorDP` decimal(5,2) DEFAULT NULL,
  `MovClaOp` char(3) NOT NULL,
  `MovCodPaiExt` char(3) NOT NULL,
  `MovCodProExt` mediumint NOT NULL,
  PRIMARY KEY (`MovEmpCod`,`EjerCod`,`MovId`,`MovLin`,`MovIvaId`),
  KEY `UMOVCTASLEVEL1` (`MovEmpCod`,`EjerCod`,`MovIvaTip`,`MovIvaClas`,`MovIvaId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `movctaslevel2` (
  `MovEmpCod` smallint NOT NULL,
  `EjerCod` char(8) NOT NULL,
  `MovId` int NOT NULL,
  `MovLin` smallint NOT NULL,
  `MovIRPFId` int NOT NULL,
  `MovIRPFBase` decimal(11,2) NOT NULL,
  `MovIRPFPor` decimal(5,2) NOT NULL,
  `MovIRPFCuota` decimal(11,2) NOT NULL,
  `MovIrpfClas` char(1) NOT NULL,
  `MovIrpfCod` char(3) DEFAULT NULL,
  PRIMARY KEY (`MovEmpCod`,`EjerCod`,`MovId`,`MovLin`,`MovIRPFId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `movctasupd` (
  `MUEmpCod` smallint NOT NULL,
  `MUEjerCod` char(8) NOT NULL,
  `MUMovId` int NOT NULL,
  `MUMovLin` smallint NOT NULL,
  `MUFecUPD` datetime NOT NULL,
  `MUMovFecha` date NOT NULL,
  `MUMovDiario` smallint NOT NULL,
  `MUConCod` smallint DEFAULT NULL,
  `MUMovDCTaTit` char(4) NOT NULL,
  `MUMovDCtaCod` char(6) NOT NULL,
  `MUMovHCTaTit` char(4) NOT NULL,
  `MUMovHCTaCod` char(6) NOT NULL,
  `MUMovImpDebe` decimal(11,2) NOT NULL,
  `MUMovImpHaber` decimal(11,2) NOT NULL,
  `MUMovObs` char(80) NOT NULL,
  `MUMovNroDoc` int NOT NULL,
  `MUMovSerie` char(15) NOT NULL,
  `MUMovDocFch` date NOT NULL,
  `MUSucCod` smallint DEFAULT NULL,
  `MUMovFecExt` date NOT NULL,
  `MUMov349` char(1) NOT NULL,
  `MUMovTriangu` char(1) NOT NULL,
  `MUMovNumExp` char(20) NOT NULL,
  `MUMovPreSer` char(1) NOT NULL,
  `MUMovTipo` char(1) NOT NULL,
  `MUMovCab` char(1) NOT NULL,
  `MUMonCod` char(3) NOT NULL,
  `MUMovMonFecCam` date NOT NULL,
  `MUMonTipCam` decimal(11,4) NOT NULL,
  `MUMovImpDiv` decimal(11,2) NOT NULL,
  `MUMovClaIva` char(3) NOT NULL,
  `MUMovFraFec` date NOT NULL,
  `MUMovFraNro` char(40) NOT NULL,
  `MUMovClaTipLibIva` char(1) NOT NULL,
  `MUMovImpNomAux` decimal(11,2) NOT NULL,
  `MUMovImpNomAux2` decimal(11,2) NOT NULL,
  `MUUsuCod` char(10) NOT NULL,
  PRIMARY KEY (`MUEmpCod`,`MUEjerCod`,`MUMovId`,`MUMovLin`,`MUFecUPD`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `movctasupdlevel1` (
  `MUEmpCod` smallint NOT NULL,
  `MUEjerCod` char(8) NOT NULL,
  `MUMovId` int NOT NULL,
  `MUMovLin` smallint NOT NULL,
  `MUFecUPD` datetime NOT NULL,
  `MUMovIvaId` int NOT NULL,
  `MUMovIVaTip` char(1) NOT NULL,
  `MUMovIvaClas` char(1) NOT NULL,
  `MUMovIvaBase` decimal(11,2) NOT NULL,
  `MUMovIvaPor` decimal(5,2) NOT NULL,
  `MUMovIvaCuota` decimal(11,2) NOT NULL,
  `MUMovIvaDed` char(2) NOT NULL,
  `MUMovIvaPorDP` decimal(5,2) NOT NULL,
  `MUMovClaOp` char(3) NOT NULL,
  `MUMovCodProExt` mediumint NOT NULL,
  `MUMovCodPaiExt` char(3) NOT NULL,
  PRIMARY KEY (`MUEmpCod`,`MUEjerCod`,`MUMovId`,`MUMovLin`,`MUFecUPD`,`MUMovIvaId`),
  CONSTRAINT `ITMOVCTASUPDLEVEL2` FOREIGN KEY (`MUEmpCod`, `MUEjerCod`, `MUMovId`, `MUMovLin`, `MUFecUPD`) REFERENCES `movctasupd` (`MUEmpCod`, `MUEjerCod`, `MUMovId`, `MUMovLin`, `MUFecUPD`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `movctasupdlevel2` (
  `MUEmpCod` smallint NOT NULL,
  `MUEjerCod` char(8) NOT NULL,
  `MUMovId` int NOT NULL,
  `MUMovLin` smallint NOT NULL,
  `MUFecUPD` datetime NOT NULL,
  `MUMovIRPFId` int NOT NULL,
  `MUMovIrpfClas` char(1) NOT NULL,
  `MUMovIrpfBase` decimal(11,2) NOT NULL,
  `MUMovIrpfPor` decimal(5,2) NOT NULL,
  `MUMovIrpfCuota` decimal(11,2) NOT NULL,
  `MUMovIrpfCod` char(3) NOT NULL,
  PRIMARY KEY (`MUEmpCod`,`MUEjerCod`,`MUMovId`,`MUMovLin`,`MUFecUPD`,`MUMovIRPFId`),
  CONSTRAINT `ITMOVCTASUPDLEVEL4` FOREIGN KEY (`MUEmpCod`, `MUEjerCod`, `MUMovId`, `MUMovLin`, `MUFecUPD`) REFERENCES `movctasupd` (`MUEmpCod`, `MUEjerCod`, `MUMovId`, `MUMovLin`, `MUFecUPD`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `numbasicos` (
  `EmpCod` smallint NOT NULL,
  `NumBasCod` char(4) NOT NULL,
  `NumBasUlt` int NOT NULL,
  PRIMARY KEY (`EmpCod`,`NumBasCod`),
  CONSTRAINT `INUMBASICOS1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `numeradores` (
  `EmpCod` smallint NOT NULL,
  `NumCod` char(4) NOT NULL,
  `NumEjer` char(8) NOT NULL,
  `NumUltNum` int NOT NULL,
  `NumSerie` char(1) NOT NULL,
  `NumUsuCod` char(10) NOT NULL,
  `NumUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`NumCod`,`NumEjer`),
  CONSTRAINT `INUMERADORES1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `numfratmp` (
  `NumFraTyp` char(3) NOT NULL,
  `NumFraId` char(200) NOT NULL,
  `NumFraUlt` smallint NOT NULL,
  PRIMARY KEY (`NumFraTyp`,`NumFraId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `numserie` (
  `EmpCod` smallint NOT NULL,
  `EjerCod` char(8) NOT NULL,
  `NumSerTip` char(1) NOT NULL,
  `NumSerPre` char(3) NOT NULL,
  `NumSerNum` int NOT NULL,
  `NumSerUsuCod` char(10) NOT NULL,
  `NumSerUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`EjerCod`,`NumSerTip`,`NumSerPre`),
  CONSTRAINT `INUMSERIE1` FOREIGN KEY (`EmpCod`, `EjerCod`) REFERENCES `paramejer` (`EmpCod`, `EjerCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `objetos` (
  `ObjId` char(20) NOT NULL,
  `ObjTip` char(1) NOT NULL,
  `ObjDes` char(30) NOT NULL,
  PRIMARY KEY (`ObjId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `otros` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `OtrCod` mediumint NOT NULL,
  `OtrNom` char(40) NOT NULL,
  `OtrCom` char(40) NOT NULL,
  `OtrNemo` char(8) DEFAULT NULL,
  `OtrDir` char(50) DEFAULT NULL,
  `OtrCif` char(15) NOT NULL,
  `OtrTel` char(65) DEFAULT NULL,
  `OtrFax` char(30) DEFAULT NULL,
  `OtrCon1` char(40) DEFAULT NULL,
  `OtrCon2` char(40) DEFAULT NULL,
  `OtrCon1Car` char(15) DEFAULT NULL,
  `OtrCon2Car` char(15) DEFAULT NULL,
  `OtrMail` char(50) DEFAULT NULL,
  `OtrWeb` char(50) DEFAULT NULL,
  `OtrObs` text,
  `OtrEst` char(1) DEFAULT NULL,
  `OtrIRPF` decimal(5,2) DEFAULT NULL,
  `TipIrpfCod` char(3) DEFAULT NULL,
  `OtrComi` decimal(5,2) DEFAULT NULL,
  `OtrUltFac` date DEFAULT NULL,
  `OtrUltUsu` char(10) DEFAULT NULL,
  `OtrUltFec` date DEFAULT NULL,
  `CenCod` char(10) DEFAULT NULL,
  `PaiCod` char(3) DEFAULT NULL,
  `PrvCod` char(2) DEFAULT NULL,
  `LocCodPos` char(10) DEFAULT NULL,
  `LocCnt` int DEFAULT NULL,
  `ClaOtrCod` char(2) DEFAULT NULL,
  `OtrCodRaz` char(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`EmpCod`,`OtrCod`),
  KEY `IOTROS1` (`PaiCod`,`PrvCod`,`LocCodPos`,`LocCnt`),
  KEY `IOTROS2` (`CenCod`),
  KEY `IOTROS3` (`EmpCod`,`TipIrpfCod`),
  KEY `IOTROS4` (`EmpCod`,`ClaOtrCod`),
  CONSTRAINT `IOTROS4` FOREIGN KEY (`EmpCod`, `ClaOtrCod`) REFERENCES `tclaotr` (`EmpCod`, `ClaOtrCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `otroslevel1` (
  `EmpCod` smallint NOT NULL,
  `OtrCod` mediumint NOT NULL,
  `OtrCtaTer` char(4) NOT NULL,
  `OtrCtaCod` char(6) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`OtrCod`,`OtrCtaTer`),
  CONSTRAINT `IOTROSLEVEL11` FOREIGN KEY (`EmpCod`, `OtrCod`) REFERENCES `otros` (`EmpCod`, `OtrCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `pais` (
  `PaiCod` char(3) NOT NULL DEFAULT '',
  `PaiNom` char(40) DEFAULT NULL,
  `PaiCEE` char(3) DEFAULT NULL,
  `PaiUsuCod` char(10) DEFAULT NULL,
  `PaiUltMod` datetime DEFAULT NULL,
  `PaiPrvVer` char(1) DEFAULT NULL,
  `PaiIsoNum` smallint NOT NULL,
  `PaiIso2` char(2) NOT NULL,
  `PaiSEPA` char(1) DEFAULT NULL,
  PRIMARY KEY (`PaiCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `paramejer` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `EjerCod` char(8) NOT NULL,
  `EjerIni` date NOT NULL,
  `EjerFin` date NOT NULL,
  `EjerCerr` char(1) NOT NULL,
  `EjerAper` char(1) DEFAULT NULL,
  `EjerAsto` mediumint NOT NULL,
  `PlaCodTip` smallint NOT NULL,
  `EjerDebe` decimal(11,2) NOT NULL,
  `EjerHaber` decimal(11,2) NOT NULL,
  `EjerUltMod` datetime NOT NULL,
  `EjerUsuCod` char(10) NOT NULL,
  `EjerDesc` char(50) NOT NULL DEFAULT '',
  `EjerAsiAper` decimal(8,0) DEFAULT NULL,
  `EjerAsiCier` decimal(8,0) DEFAULT NULL,
  `EjerAsiPyG` decimal(8,0) NOT NULL DEFAULT '0',
  PRIMARY KEY (`EmpCod`,`EjerCod`),
  KEY `IPARAMEJER` (`EmpCod`,`PlaCodTip`),
  KEY `UPARAMEJER1` (`EmpCod`,`EjerIni`,`EjerCod`),
  CONSTRAINT `IPARAMEJER` FOREIGN KEY (`EmpCod`, `PlaCodTip`) REFERENCES `platip` (`EmpCod`, `PlaCodTip`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `paramejerlevel1` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `EjerCod` char(8) NOT NULL,
  `EjerMes` smallint NOT NULL,
  `EjerMesCer` char(1) NOT NULL,
  `EjerMesCerIva` char(1) NOT NULL DEFAULT '',
  `EjerMesUltPag` int DEFAULT NULL,
  `EjerMesUltAsi` int DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`EjerCod`,`EjerMes`),
  CONSTRAINT `IPARAMEJERLEVEL11` FOREIGN KEY (`EmpCod`, `EjerCod`) REFERENCES `paramejer` (`EmpCod`, `EjerCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `pdefecto` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `PdeCod` char(8) NOT NULL,
  `PdeCon` char(40) NOT NULL,
  `PdePar` char(60) NOT NULL,
  `PdeBlob` longblob,
  PRIMARY KEY (`EmpCod`,`PdeCod`),
  CONSTRAINT `IPDEFECTO1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `pdefectomsg` (
  `EmpCod` smallint NOT NULL,
  `PdeCodM` char(15) NOT NULL,
  `PdeConMMsg` mediumtext NOT NULL,
  PRIMARY KEY (`EmpCod`,`PdeCodM`),
  CONSTRAINT `IPDEFECTOMSG1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `pdefectopag` (
  `EmpCod` smallint NOT NULL,
  `PdeCodP` char(15) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL,
  `PdeConP` char(80) CHARACTER SET latin1 COLLATE latin1_bin DEFAULT NULL,
  `PdeParP` char(15) CHARACTER SET latin1 COLLATE latin1_bin DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`PdeCodP`),
  CONSTRAINT `IPDEFECTOPAG1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `platip` (
  `EmpCod` smallint NOT NULL,
  `PlaCodTip` smallint NOT NULL,
  `PlaDes` char(30) NOT NULL,
  `PlaDef` char(1) NOT NULL,
  `PlaEst` char(1) NOT NULL,
  `PlaUsuCod` char(10) NOT NULL,
  `PlaUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`PlaCodTip`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `pressii` (
  `PresSIIEmpCod` smallint NOT NULL DEFAULT '0',
  `PresSIIEjerCod` char(8) NOT NULL DEFAULT '',
  `PresSIIMovId` int NOT NULL,
  `PresSIITpoCom` char(2) NOT NULL,
  `PresSIITpoFac` char(2) NOT NULL DEFAULT '',
  `PresSIIFecha` date NOT NULL DEFAULT '1000-01-01',
  `PresSIIFechaEnv` date NOT NULL DEFAULT '1000-01-01',
  `PresSIIErrCod` char(5) NOT NULL,
  `PresSIIErrDes` mediumtext NOT NULL,
  `PresSIIEst` char(40) NOT NULL,
  `PresSIICSV` char(16) NOT NULL DEFAULT '',
  `PresSiiTimeStamp` char(255) DEFAULT NULL,
  `PresSIIErrCodOld` char(5) NOT NULL DEFAULT '',
  `PresSIIErrFechaOld` date NOT NULL,
  `PresSIIErrCount` smallint NOT NULL,
  `PresSIIFacNro` char(40) NOT NULL DEFAULT '',
  `PresSIIFechaFra` date NOT NULL DEFAULT '1000-01-01',
  `PresSIINif` char(15) NOT NULL DEFAULT '',
  `PresSIIFechaCtr` date NOT NULL DEFAULT '1000-01-01',
  PRIMARY KEY (`PresSIIEmpCod`,`PresSIIEjerCod`,`PresSIIMovId`,`PresSIITpoCom`),
  KEY `Useridx_2` (`PresSIIEmpCod`,`PresSIIEjerCod`,`PresSIIFacNro`,`PresSIIFechaFra`,`PresSIINif`,`PresSIITpoFac`,`PresSIICSV`),
  KEY `Useridx_1` (`PresSIIEmpCod`,`PresSIIEjerCod`,`PresSIIFacNro`,`PresSIIFechaFra`,`PresSIITpoFac`,`PresSIICSV`),
  KEY `UPRESSII` (`PresSIIEmpCod`,`PresSIIFechaEnv`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `prestamos` (
  `EmpCod` smallint NOT NULL,
  `PresId` int NOT NULL,
  `PresNum` char(25) DEFAULT NULL,
  `PresCon` char(25) DEFAULT NULL,
  `PresCap` decimal(11,2) DEFAULT NULL,
  `PresInt` decimal(7,4) DEFAULT NULL,
  `PresTer` decimal(4,2) DEFAULT NULL,
  `PresPer` smallint DEFAULT NULL,
  `PresCar` smallint DEFAULT NULL,
  `PresPagos` smallint DEFAULT NULL,
  `PresCuota` decimal(11,2) DEFAULT NULL,
  `PresFecini` date DEFAULT NULL,
  `PresPctatit` char(4) DEFAULT NULL,
  `PresPctacod` char(6) DEFAULT NULL,
  `PresDctatit` char(4) DEFAULT NULL,
  `PresDctacod` char(6) DEFAULT NULL,
  `PresActatit` char(4) DEFAULT NULL,
  `PresActacod` char(6) DEFAULT NULL,
  `PresIctatit` char(4) DEFAULT NULL,
  `PresIctacod` char(6) DEFAULT NULL,
  `PresFeccon` date DEFAULT NULL,
  `PresCarCuota` decimal(11,2) DEFAULT NULL,
  `PresCarTip` char(1) DEFAULT NULL,
  `PresFec` date DEFAULT NULL,
  `PresMesCon` smallint DEFAULT NULL,
  `PresAnyCon` smallint DEFAULT NULL,
  `DvsCod` smallint DEFAULT NULL,
  `CentCod` smallint DEFAULT NULL,
  `PresCctacod` char(6) DEFAULT NULL,
  `PresCctatit` char(4) DEFAULT NULL,
  `PresComMes` decimal(11,2) DEFAULT NULL,
  `PresCapFin` decimal(11,2) DEFAULT NULL,
  `Prestipo` char(4) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`PresId`),
  KEY `IPRESTAMOS1` (`EmpCod`,`CentCod`,`DvsCod`),
  KEY `GX_005400FZ0001` (`EmpCod`,`DvsCod`),
  CONSTRAINT `GX_005400FZ0001` FOREIGN KEY (`EmpCod`, `DvsCod`) REFERENCES `empdiv` (`EmpCod`, `DvsCod`),
  CONSTRAINT `GX_005400G00001` FOREIGN KEY (`EmpCod`, `CentCod`) REFERENCES `empcen` (`EmpCod`, `CentCod`),
  CONSTRAINT `IPRESTAMOS1` FOREIGN KEY (`EmpCod`, `CentCod`, `DvsCod`) REFERENCES `empcenlevel1` (`EmpCod`, `CentCod`, `DvsCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `prestamosprescon` (
  `EmpCod` smallint NOT NULL,
  `PresId` int NOT NULL,
  `PresConLin` smallint NOT NULL,
  `PresConAny` char(4) NOT NULL,
  `PresConMes` char(2) NOT NULL,
  `PresConImp` decimal(13,6) DEFAULT NULL,
  `PresConCon` char(1) DEFAULT NULL,
  `PresConMovid` char(23) DEFAULT NULL,
  `PresConCom` decimal(11,2) DEFAULT NULL,
  `PresConCap` decimal(13,6) DEFAULT NULL,
  `PresConCapEjer` decimal(13,6) DEFAULT NULL,
  `PresConAcumInt` decimal(13,6) DEFAULT NULL,
  `PresConCapVivo` decimal(13,6) DEFAULT NULL,
  `PresConCuota` decimal(13,6) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`PresId`,`PresConLin`),
  CONSTRAINT `IPRESTAMOSPRESCON1` FOREIGN KEY (`EmpCod`, `PresId`) REFERENCES `prestamos` (`EmpCod`, `PresId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `prestamospresint` (
  `EmpCod` smallint NOT NULL,
  `PresId` int NOT NULL,
  `PresConLin` smallint NOT NULL,
  `PresIntAny` char(4) NOT NULL,
  `PresIntMes` char(2) NOT NULL,
  `PresIntCuota` decimal(11,2) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`PresId`,`PresConLin`,`PresIntAny`,`PresIntMes`),
  CONSTRAINT `IPRESTAMOSPRESINT1` FOREIGN KEY (`EmpCod`, `PresId`, `PresConLin`) REFERENCES `prestamosprescon` (`EmpCod`, `PresId`, `PresConLin`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `prestamospresrev` (
  `EmpCod` smallint NOT NULL,
  `PresId` int NOT NULL,
  `PresRevLin` smallint NOT NULL,
  `PresRevAny` smallint DEFAULT NULL,
  `PresRevMes` smallint DEFAULT NULL,
  `PresRevInt` decimal(7,4) DEFAULT NULL,
  `PresRevCuota` decimal(11,2) DEFAULT NULL,
  `PresRevCarCuota` decimal(11,2) DEFAULT NULL,
  `PresRevCalc` char(1) DEFAULT NULL,
  `PresRevAmort` decimal(11,2) DEFAULT NULL,
  `PresRevCom` decimal(11,2) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`PresId`,`PresRevLin`),
  CONSTRAINT `IPRESTAMOSPRESREV1` FOREIGN KEY (`EmpCod`, `PresId`) REFERENCES `prestamos` (`EmpCod`, `PresId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `prgama` (
  `EmpCod` smallint NOT NULL,
  `PrgId` char(15) NOT NULL,
  `PrgDes` char(40) NOT NULL,
  `PrgCabTot` char(1) NOT NULL,
  `PrgLinTot` char(1) NOT NULL,
  `PrgSerie` char(3) NOT NULL,
  `PrgUsuCod` char(10) NOT NULL,
  `PrgUltMod` datetime NOT NULL,
  `PrgNumLin` smallint NOT NULL,
  `PrgNumCab` smallint NOT NULL,
  `PrgNumAuto` char(1) NOT NULL,
  `PrgDiario` char(1) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`PrgId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `prgcontrapartidas` (
  `EmpCod` smallint NOT NULL,
  `PrgId` char(15) NOT NULL,
  `PrgLinId` smallint NOT NULL,
  `PrgLinCtaTit` char(4) NOT NULL,
  `PrgLinHasCtaTit` char(4) NOT NULL,
  `PrgLinCtaCod` char(6) NOT NULL,
  `PrgLinAcepta` char(1) NOT NULL,
  PRIMARY KEY (`EmpCod`,`PrgId`,`PrgLinId`),
  CONSTRAINT `IPROG12` FOREIGN KEY (`EmpCod`, `PrgId`) REFERENCES `prgama` (`EmpCod`, `PrgId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `prgctascab` (
  `EmpCod` smallint NOT NULL,
  `PrgId` char(15) NOT NULL,
  `PrgCabId` smallint NOT NULL,
  `PrgCabCtaTit` char(4) NOT NULL,
  `PrgCabHasCtaTit` char(4) NOT NULL,
  `PrgCabCtaCod` char(6) NOT NULL,
  `PrgCabAcepta` char(1) NOT NULL,
  PRIMARY KEY (`EmpCod`,`PrgId`,`PrgCabId`),
  CONSTRAINT `IPROG21` FOREIGN KEY (`EmpCod`, `PrgId`) REFERENCES `prgama` (`EmpCod`, `PrgId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `prodir` (
  `EmpCod` smallint NOT NULL,
  `ProCod` mediumint NOT NULL,
  `ProCodDir` smallint NOT NULL,
  `ProDirNom` char(40) NOT NULL,
  `ProDirDir` char(40) NOT NULL,
  `ProDirPaiCod` char(3) NOT NULL,
  `ProDirPrvCod` char(10) NOT NULL,
  `ProDirLocCnt` smallint NOT NULL,
  `ProDirLocCodPos` char(10) NOT NULL,
  `ProDirTel` char(65) NOT NULL,
  `ProDirFax` char(15) NOT NULL,
  `ProDirCon` char(25) NOT NULL,
  `ProDirCar` char(15) NOT NULL,
  `ProDirMail` char(30) NOT NULL,
  `ProDirWeb` char(30) NOT NULL,
  `ProDirHor` char(30) NOT NULL,
  `ProDirUsuCod` char(10) NOT NULL,
  `ProDirUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`ProCod`,`ProCodDir`),
  CONSTRAINT `IPRODIR1` FOREIGN KEY (`EmpCod`, `ProCod`) REFERENCES `proveedor` (`EmpCod`, `ProCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `prorrata` (
  `EmpCod` smallint NOT NULL,
  `ProrrataAnio` smallint NOT NULL,
  `ProrrataPor` decimal(5,2) NOT NULL,
  `ProrrataPorDef` decimal(5,2) NOT NULL,
  PRIMARY KEY (`EmpCod`,`ProrrataAnio`),
  CONSTRAINT `ITPRORRATAPRORRATA1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `proveedor` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `ProCod` mediumint NOT NULL,
  `ProTit` char(40) NOT NULL,
  `ProCom` char(40) DEFAULT NULL,
  `ProNemo` char(8) DEFAULT NULL,
  `ProDire` char(50) DEFAULT NULL,
  `ProCif` char(15) DEFAULT NULL,
  `TerClaId` char(2) DEFAULT NULL,
  `ProTel` char(65) DEFAULT NULL,
  `ProFax` char(30) DEFAULT NULL,
  `ProFecAlt` date DEFAULT NULL,
  `ProPerCon1` char(40) DEFAULT NULL,
  `ProCarCon1` char(15) DEFAULT NULL,
  `ProPerCon2` char(40) DEFAULT NULL,
  `ProCarCon2` char(15) DEFAULT NULL,
  `ProEmail` char(50) DEFAULT NULL,
  `ProWeb` char(50) DEFAULT NULL,
  `ProObs` text,
  `ProVisita` text,
  `ProActivo` char(1) DEFAULT NULL,
  `ProDirCor` text,
  `ClaProCod` char(2) DEFAULT NULL,
  `ProLiqRap` char(1) DEFAULT NULL,
  `ProPorRap` decimal(5,2) DEFAULT NULL,
  `ProUltCom` date DEFAULT NULL,
  `ProRegMerc` char(80) DEFAULT NULL,
  `ProCarComPag` char(1) DEFAULT NULL,
  `ProCodCli` mediumint DEFAULT NULL,
  `ProPorComHab` decimal(5,2) DEFAULT NULL,
  `ProEanPro` char(13) DEFAULT NULL,
  `ProEanDis` char(13) DEFAULT NULL,
  `ProDesHab` decimal(5,2) DEFAULT NULL,
  `ProRegEsp` char(1) DEFAULT NULL,
  `ProCtaIva` char(10) DEFAULT NULL,
  `ProAutVen` char(1) DEFAULT NULL,
  `ProRegSan` char(15) DEFAULT NULL,
  `CenCod` char(10) DEFAULT NULL,
  `ProSocio` char(4) DEFAULT NULL,
  `ProSat` mediumint DEFAULT NULL,
  `PaiCod` char(3) DEFAULT NULL,
  `PrvCod` char(2) DEFAULT NULL,
  `LocCodPos` char(10) DEFAULT NULL,
  `LocCnt` int DEFAULT NULL,
  `ProIrpf` decimal(5,2) DEFAULT NULL,
  `TipIrpfCod` char(3) DEFAULT NULL,
  `ProUsuCod` char(10) DEFAULT NULL,
  `ProUltMod` datetime DEFAULT NULL,
  `IdiCod` char(3) DEFAULT NULL,
  `ProCtaTit` char(4) NOT NULL,
  `ForPagCod` char(3) DEFAULT NULL,
  `ProPlazos` smallint DEFAULT NULL,
  `ProGtosCobro` decimal(3,2) DEFAULT NULL,
  `ProDiaHastaVto` smallint DEFAULT NULL,
  `ProdiaentreVto` smallint DEFAULT NULL,
  `ProDiaCob1` smallint DEFAULT NULL,
  `ProDiaCob2` smallint DEFAULT NULL,
  `ProBanEnt` char(6) DEFAULT NULL,
  `ProBanOf` char(4) DEFAULT NULL,
  `ProBanDC` char(2) DEFAULT NULL,
  `ProBanCta` char(10) DEFAULT NULL,
  `ProRiesgoAse` int DEFAULT NULL,
  `ProRiesgoEmp` int DEFAULT NULL,
  `ProCtaCodGasto` char(6) DEFAULT NULL,
  `ProCtaTitGasto` char(4) DEFAULT NULL,
  `ProIvaTpoCod` char(5) DEFAULT NULL,
  `ProBancCod` int DEFAULT NULL,
  `ProBanSwift` char(11) DEFAULT NULL,
  `ProBanBban` char(30) DEFAULT NULL,
  `ProBanIban` char(4) DEFAULT NULL,
  `ProIgicTpoCod` char(5) DEFAULT NULL,
  `ProBancCtaCod` char(6) DEFAULT NULL,
  `ProBancCtaTit` char(4) DEFAULT NULL,
  `ProFecBaja` date DEFAULT NULL,
  `ProConIdUlt` smallint DEFAULT NULL,
  `ProCodRaz` char(100) NOT NULL DEFAULT '',
  `ProRE` char(1) DEFAULT 'N',
  PRIMARY KEY (`EmpCod`,`ProCod`),
  KEY `IPROVEEDOR1` (`PaiCod`,`PrvCod`,`LocCodPos`,`LocCnt`),
  KEY `IPROVEEDOR3` (`CenCod`),
  KEY `IPROVEEDOR4` (`EmpCod`,`TipIrpfCod`),
  KEY `IPROVEEDOR5` (`EmpCod`,`ClaProCod`),
  KEY `UPRO01` (`EmpCod`,`ProTit`),
  KEY `UPRO02` (`EmpCod`,`ProCom`),
  KEY `UPRO03` (`EmpCod`,`ProCif`),
  KEY `UPRO04` (`EmpCod`,`ProCod`,`ClaProCod`),
  KEY `UPRO05` (`EmpCod`,`ProNemo`),
  KEY `IPROVEEDOR2` (`IdiCod`),
  KEY `IPROVEEDOR6` (`EmpCod`,`ForPagCod`),
  KEY `IPROVEEDOR7` (`EmpCod`,`TerClaId`),
  CONSTRAINT `IPROVEEDOR7` FOREIGN KEY (`EmpCod`, `TerClaId`) REFERENCES `tercercladoc` (`EmpCod`, `TerClaId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `proveedorlevel1` (
  `EmpCod` smallint NOT NULL,
  `ProCod` mediumint NOT NULL,
  `ProCtaTer` char(4) NOT NULL,
  PRIMARY KEY (`EmpCod`,`ProCod`,`ProCtaTer`),
  CONSTRAINT `IPROVEEDORLEVEL11` FOREIGN KEY (`EmpCod`, `ProCod`) REFERENCES `proveedor` (`EmpCod`, `ProCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `provincia` (
  `PaiCod` char(3) NOT NULL DEFAULT '',
  `PrvCod` char(10) NOT NULL DEFAULT '',
  `PrvNom` char(30) DEFAULT NULL,
  `PrvPreTel` smallint DEFAULT NULL,
  `PrvUsuCod` char(10) DEFAULT NULL,
  `PrvUltMod` datetime DEFAULT NULL,
  PRIMARY KEY (`PaiCod`,`PrvCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `remesacobro` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `RemId` int NOT NULL,
  `RemFec` date NOT NULL,
  `RemImp` decimal(11,2) NOT NULL,
  `RemSufijo` smallint DEFAULT NULL,
  `RemOfiPre` char(4) DEFAULT NULL,
  `RemPresen` char(1) DEFAULT NULL,
  `RemMovIdRis` int DEFAULT NULL,
  `RemMovIdBan` int DEFAULT NULL,
  `RemMovIdRem` int DEFAULT NULL,
  `RemEjercod` char(8) DEFAULT NULL,
  `RemNorma` char(2) DEFAULT NULL,
  `RemContab` char(1) DEFAULT NULL,
  `BancCod` decimal(8,0) DEFAULT NULL,
  `BancEnt` char(6) DEFAULT NULL,
  `BancOf` char(4) DEFAULT NULL,
  `BancDC` char(2) DEFAULT NULL,
  `BancCta` char(10) DEFAULT NULL,
  `RemFecCar` date DEFAULT NULL,
  `RemMod` datetime DEFAULT NULL,
  `RemUsu` char(10) DEFAULT NULL,
  `RemMovIdGas` decimal(8,0) DEFAULT NULL,
  `RemMovIdCgo` int DEFAULT NULL,
  `RemNomEmpOri` char(70) DEFAULT NULL,
  `RemIdEmpOri` char(35) DEFAULT NULL,
  `RemNomEmpre` char(70) DEFAULT NULL,
  `RemIdEmpre` char(35) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`RemId`),
  KEY `IREMESACOBRO1` (`EmpCod`,`BancCod`,`BancEnt`,`BancOf`,`BancDC`,`BancCta`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `remesacobrolevel1` (
  `EmpCod` smallint NOT NULL,
  `RemId` int NOT NULL,
  `Remlin` smallint NOT NULL,
  `CcbId` int NOT NULL,
  `CcbVtoLin` smallint NOT NULL,
  `CcbVtoCobLin` smallint NOT NULL,
  `RemLinRisg` char(1) DEFAULT NULL,
  `RemLinDev` char(1) DEFAULT NULL,
  `RemDevMovid` int DEFAULT NULL,
  `RemDevEjer` char(8) DEFAULT NULL,
  `RemDevNum` int DEFAULT NULL,
  `RemDevFec` date DEFAULT NULL,
  `RemBicOri` char(11) DEFAULT NULL,
  `RemIbanOri` char(34) DEFAULT NULL,
  `RemManOri` char(35) DEFAULT NULL,
  `RemManFec` date DEFAULT NULL,
  `RemMandato` char(35) DEFAULT NULL,
  `RemSeqTp` char(4) DEFAULT NULL,
  `RemManFecUpd` date DEFAULT NULL,
  `RemBic` char(11) DEFAULT NULL,
  `RemIban` char(34) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`RemId`,`Remlin`),
  KEY `IREMESACOBROLEVEL11` (`EmpCod`,`CcbId`,`CcbVtoLin`,`CcbVtoCobLin`),
  CONSTRAINT `IREMESACOBROLEVEL11` FOREIGN KEY (`EmpCod`, `CcbId`, `CcbVtoLin`, `CcbVtoCobLin`) REFERENCES `carteradecobrosccbvtocob` (`EmpCod`, `CcbId`, `CcbVtoLin`, `CcbVtoCobLin`),
  CONSTRAINT `IREMESACOBROLEVEL12` FOREIGN KEY (`EmpCod`, `RemId`) REFERENCES `remesacobro` (`EmpCod`, `RemId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `remesapago` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `RpagId` int NOT NULL,
  `RpagFec` date NOT NULL,
  `RpagEmis` date NOT NULL,
  `RpagDetCar` char(1) NOT NULL,
  `RpagImp` decimal(11,2) NOT NULL,
  `RpagOfiPre` char(4) DEFAULT NULL,
  `RpagSufijo` smallint DEFAULT NULL,
  `RpagPresen` char(1) DEFAULT NULL,
  `RpagContab` char(1) DEFAULT NULL,
  `RpagEjercod` char(8) DEFAULT NULL,
  `BancCod` int NOT NULL DEFAULT '0',
  `BancEnt` char(6) NOT NULL DEFAULT '',
  `BancOf` char(4) NOT NULL DEFAULT '',
  `BancDC` char(2) NOT NULL DEFAULT '',
  `BancCta` char(10) NOT NULL DEFAULT '',
  `RpagUsu` char(10) DEFAULT NULL,
  `RpagMod` datetime DEFAULT NULL,
  `RpagNorma` char(5) DEFAULT NULL,
  `RpagTipRem` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`RpagId`),
  KEY `IREMESAPAGO1` (`EmpCod`,`BancCod`,`BancEnt`,`BancOf`,`BancDC`,`BancCta`),
  CONSTRAINT `IREMESAPAGO1` FOREIGN KEY (`EmpCod`, `BancCod`, `BancEnt`, `BancOf`, `BancDC`, `BancCta`) REFERENCES `bancosbcta` (`EmpCod`, `BancCod`, `BancEnt`, `BancOf`, `BancDC`, `BancCta`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `remesapagorpag` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `RpagId` int NOT NULL DEFAULT '0',
  `RpagLin` smallint NOT NULL,
  `RpagLinEjer` char(8) DEFAULT NULL,
  `RpagLinMovid` int NOT NULL,
  `CpgId` int NOT NULL DEFAULT '0',
  `CpgVtoLin` smallint NOT NULL DEFAULT '0',
  `RpagLinBloq` char(1) DEFAULT NULL,
  `CpgVtoLinPag` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`RpagId`,`RpagLin`),
  KEY `IREMESAPAGORPAG2` (`EmpCod`,`RpagId`),
  KEY `IREMESAPAGORPAG1` (`EmpCod`,`CpgId`,`CpgVtoLin`,`CpgVtoLinPag`),
  CONSTRAINT `IREM ESAPAGORPAG1` FOREIGN KEY (`EmpCod`, `CpgId`, `CpgVtoLin`, `CpgVtoLinPag`) REFERENCES `carterapagoscpgvtopag` (`EmpCod`, `CpgId`, `CpgVtoLin`, `CpgVtoLinPag`),
  CONSTRAINT `IREMESAPAGORPAG2` FOREIGN KEY (`EmpCod`, `RpagId`) REFERENCES `remesapago` (`EmpCod`, `RpagId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ricoherp` (
  `EmpCod` smallint NOT NULL,
  `EjerCod` char(8) NOT NULL,
  `RICERP_NRO_MOVIM` int NOT NULL,
  `RICERP_ID_FACT` char(20) NOT NULL,
  `RICERP_NIF_EMPRESA` char(15) NOT NULL,
  `RICERP_NOMBRE_EMPRESA` char(50) NOT NULL,
  `RICERP_NIF_PROVEEDOR` char(15) NOT NULL,
  `RICERP_NOMBRE_PROVEEDOR` char(50) NOT NULL,
  `RICERP_NUMERO_FACTURA` char(40) NOT NULL,
  `RICERP_FECHA_FACTURA` date NOT NULL,
  `RICERP_IMPORTE` decimal(11,2) NOT NULL,
  `RICERP_BASE_IMPONIBLE_1` decimal(11,2) NOT NULL,
  `RICERP_PORCENTAJE_IVA_1` decimal(5,2) NOT NULL,
  `RICERP_IMPORTE_IVA_1` decimal(11,2) NOT NULL,
  `RICERP_BASE_IMPONIBLE_2` decimal(11,2) NOT NULL,
  `RICERP_PORCENTAJE_2` decimal(5,2) NOT NULL,
  `RICERP_IMPORTE_IVA_2` decimal(11,2) NOT NULL,
  `RICERP_BASE_IMPONIBLE_3` decimal(11,2) NOT NULL,
  `RICERP_PORCENTAJE_3` decimal(5,2) NOT NULL,
  `RICERP_IMPORTE_IVA_3` decimal(11,2) NOT NULL,
  `RICERP_BASE_IMPONIBLE_4` decimal(11,2) NOT NULL,
  `RICERP_PORCENTAJE_4` decimal(5,2) NOT NULL,
  `RICERP_IMPORTE_IVA_4` decimal(11,2) NOT NULL,
  `RICERP_BASE_IMPONIBLE_IRPF` decimal(11,2) DEFAULT NULL,
  `RICERP_PORCENTAJE_IRPF` decimal(5,2) DEFAULT NULL,
  `RICERP_IMPORTE_IRPF` decimal(11,2) DEFAULT NULL,
  `RICERP_FECHA_ENVIO` date DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`EjerCod`,`RICERP_NRO_MOVIM`),
  CONSTRAINT `IRICOHERP1` FOREIGN KEY (`EmpCod`, `EjerCod`) REFERENCES `paramejer` (`EmpCod`, `EjerCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `riesgoefectos` (
  `EmpCod` smallint NOT NULL,
  `RisCod` char(3) NOT NULL,
  `RisDes` char(15) NOT NULL,
  `RisDias` decimal(3,0) NOT NULL,
  PRIMARY KEY (`EmpCod`,`RisCod`),
  CONSTRAINT `IRIESGOEFECTOS1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `saldos` (
  `EmpCod` smallint NOT NULL,
  `AcCtaPer` char(8) NOT NULL,
  `AcCtaAny` char(4) NOT NULL,
  `CtaTit` char(4) NOT NULL,
  `CtaCod` char(6) NOT NULL,
  `AcCtaApD` decimal(11,2) NOT NULL,
  `AcCtaApH` decimal(11,2) NOT NULL,
  `AcCtaCiD` decimal(11,2) NOT NULL,
  `AcCtaCiH` decimal(11,2) NOT NULL,
  `AcCtaUsuCod` char(10) NOT NULL,
  `AcCtaUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`AcCtaPer`,`AcCtaAny`,`CtaTit`,`CtaCod`),
  KEY `ISALDOS1` (`EmpCod`,`CtaTit`,`CtaCod`),
  CONSTRAINT `ISALDOS1` FOREIGN KEY (`EmpCod`, `CtaTit`, `CtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `saldoslevel1` (
  `EmpCod` smallint NOT NULL,
  `AcCtaPer` char(8) NOT NULL,
  `AcCtaAny` char(4) NOT NULL,
  `CtaTit` char(4) NOT NULL,
  `CtaCod` char(6) NOT NULL,
  `AcCtaMes` smallint NOT NULL,
  `AcCtaMesD` decimal(14,2) NOT NULL,
  `AcCtaMesH` decimal(14,2) NOT NULL,
  PRIMARY KEY (`EmpCod`,`AcCtaPer`,`AcCtaAny`,`CtaTit`,`CtaCod`,`AcCtaMes`),
  KEY `CUENTAS` (`EmpCod`,`AcCtaPer`,`CtaTit`,`CtaCod`,`AcCtaMes`),
  CONSTRAINT `ISALDOSLEVEL11` FOREIGN KEY (`EmpCod`, `AcCtaPer`, `AcCtaAny`, `CtaTit`, `CtaCod`) REFERENCES `saldos` (`EmpCod`, `AcCtaPer`, `AcCtaAny`, `CtaTit`, `CtaCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sdocentros` (
  `EmpCod` smallint NOT NULL,
  `SdoEjerCod` char(8) NOT NULL,
  `SdoCen` smallint NOT NULL,
  `SdoDiv` smallint NOT NULL,
  `SdoCtaTit` char(4) NOT NULL,
  `SdoCtaCod` char(6) NOT NULL,
  `SdoMes` smallint NOT NULL,
  `SdoImpD` decimal(11,2) NOT NULL,
  `SdoImpH` decimal(11,2) NOT NULL,
  PRIMARY KEY (`EmpCod`,`SdoEjerCod`,`SdoCen`,`SdoDiv`,`SdoCtaTit`,`SdoCtaCod`,`SdoMes`),
  CONSTRAINT `ISDOCENTROS1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `seg_perfil` (
  `SegPerfid` smallint NOT NULL,
  `EmpCod` smallint NOT NULL,
  `SegPerfNom` char(20) NOT NULL,
  `SegPerfTitulo` char(40) NOT NULL,
  PRIMARY KEY (`SegPerfid`,`EmpCod`),
  KEY `ISEG_PERFIL1` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `seg_perfilobjeto` (
  `EmpCod` smallint NOT NULL,
  `SegPerfid` smallint NOT NULL,
  `SegPrgId` smallint NOT NULL,
  `SegPrgClass` smallint NOT NULL,
  PRIMARY KEY (`EmpCod`,`SegPerfid`,`SegPrgId`,`SegPrgClass`),
  KEY `ISEG_PERFILPERMISO12` (`SegPrgId`,`SegPrgClass`,`EmpCod`),
  KEY `ISEG_PERFILPERMISO13` (`SegPerfid`,`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `seg_perfilpermiso` (
  `SegPerfid` smallint NOT NULL DEFAULT '0',
  `SegPrgId` smallint NOT NULL,
  `SegPrgClass` smallint NOT NULL,
  `SegPrgAccion` char(10) NOT NULL,
  `SegPrgAccEst` char(1) NOT NULL,
  `EmpCod` smallint NOT NULL DEFAULT '1',
  PRIMARY KEY (`SegPerfid`,`SegPrgId`,`SegPrgClass`,`SegPrgAccion`,`EmpCod`),
  KEY `ISEG_PERFILPERMISO1` (`SegPrgId`,`SegPrgClass`,`SegPrgAccion`),
  KEY `ISEG_PERFILPERMISO2` (`EmpCod`,`SegPerfid`,`SegPrgId`,`SegPrgClass`),
  CONSTRAINT `ISEG_PERFILPERMISO2` FOREIGN KEY (`EmpCod`, `SegPerfid`, `SegPrgId`, `SegPrgClass`) REFERENCES `seg_perfilobjeto` (`EmpCod`, `SegPerfid`, `SegPrgId`, `SegPrgClass`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `segprg` (
  `SegPrgId` smallint NOT NULL,
  `SegPrgClass` smallint NOT NULL,
  `EmpCod` smallint NOT NULL,
  `SegPrgNom` char(40) DEFAULT NULL,
  `SegPrgTitulo` char(100) DEFAULT NULL,
  `SegPrgAgrup` char(1) DEFAULT NULL,
  PRIMARY KEY (`SegPrgId`,`SegPrgClass`,`EmpCod`),
  KEY `ISEGPRG1` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `segprgaccion` (
  `SegPrgId` smallint NOT NULL DEFAULT '0',
  `SegPrgClass` smallint NOT NULL,
  `SegPrgAccion` char(10) NOT NULL,
  `SegPrgAccNom` char(100) DEFAULT NULL,
  `EmpCod` smallint NOT NULL DEFAULT '0',
  PRIMARY KEY (`SegPrgId`,`SegPrgClass`,`SegPrgAccion`,`EmpCod`),
  KEY `ISegPrgAccion1` (`SegPrgId`,`SegPrgClass`,`EmpCod`),
  CONSTRAINT `ISegPrgAccion1` FOREIGN KEY (`SegPrgId`, `SegPrgClass`, `EmpCod`) REFERENCES `segprg` (`SegPrgId`, `SegPrgClass`, `EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tacreedores__contactos` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `AcrCod` mediumint NOT NULL,
  `AcrConId` smallint NOT NULL,
  `AcrConTip` char(30) DEFAULT NULL,
  `AcrConNom` char(40) DEFAULT NULL,
  `AcrConTel` char(65) DEFAULT NULL,
  `AcrConMov` char(65) DEFAULT NULL,
  `AcrConMail` char(50) DEFAULT NULL,
  `CarCod` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`AcrCod`,`AcrConId`),
  KEY `ITACREEDORES__CONTACTOS` (`EmpCod`,`CarCod`),
  CONSTRAINT `ITACREEDORES__CONTACTOS` FOREIGN KEY (`EmpCod`, `CarCod`) REFERENCES `tcargos` (`EmpCod`, `CarCod`),
  CONSTRAINT `ITACREEDORESCONTACTOS2` FOREIGN KEY (`EmpCod`, `AcrCod`) REFERENCES `acreedores` (`EmpCod`, `AcrCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tacreedorescontactos` (
  `EmpCod` smallint NOT NULL,
  `AcrCod` mediumint NOT NULL,
  `AcrConTip` char(30) NOT NULL DEFAULT '',
  `AcrConNom` char(40) NOT NULL,
  `AcrConTel` char(65) NOT NULL,
  `AcrConMov` char(65) NOT NULL,
  `AcrConMail` char(50) NOT NULL,
  PRIMARY KEY (`EmpCod`,`AcrCod`,`AcrConTip`),
  CONSTRAINT `ITACREEDORESCONTACTOS1` FOREIGN KEY (`EmpCod`, `AcrCod`) REFERENCES `acreedores` (`EmpCod`, `AcrCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tasiimpcen` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `AsiImpEje` char(8) NOT NULL DEFAULT '',
  `AsiImpMov` int NOT NULL,
  `AsiImpLin` smallint NOT NULL,
  `AsiImpCen` smallint NOT NULL,
  `AsiImpDiv` smallint NOT NULL,
  `AsiImpCenNom` char(30) NOT NULL,
  `AsiImpDivNom` char(30) NOT NULL,
  `AsiImpTit` char(4) NOT NULL,
  `AsiImpCta` char(6) NOT NULL,
  `AsiImpFecha` date NOT NULL,
  `AsiImpImp` decimal(11,2) NOT NULL,
  `AsiImpDH` char(1) NOT NULL,
  `AsiImpTemp` char(1) NOT NULL,
  `AsiImpRedist` char(1) DEFAULT 'N',
  PRIMARY KEY (`EmpCod`,`AsiImpEje`,`AsiImpMov`,`AsiImpLin`,`AsiImpCen`,`AsiImpDiv`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tbandejaemail` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `BanEntId` smallint NOT NULL,
  `BanEntSubj` char(30) NOT NULL,
  `BanEntText` mediumtext NOT NULL,
  `BanEntFrom` char(50) NOT NULL,
  `BanEntFec` date NOT NULL,
  `BanEntLeido` char(1) NOT NULL,
  `BanEntBlobFile` longblob NOT NULL,
  `BanEntBlobName` char(200) NOT NULL,
  `BanEntBlobType` char(4) NOT NULL,
  `BanEntAbrir` char(1) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`BanEntId`),
  CONSTRAINT `ITBANDEJAEMAIL1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tcargos` (
  `EmpCod` smallint NOT NULL,
  `CarCod` smallint NOT NULL,
  `CarDes` char(30) NOT NULL,
  PRIMARY KEY (`EmpCod`,`CarCod`),
  CONSTRAINT `ITCARGOS1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tclaotr` (
  `EmpCod` smallint NOT NULL,
  `ClaOtrCod` char(2) NOT NULL,
  `ClaOtrDes` char(40) NOT NULL,
  `ClaOtrGto` decimal(5,2) NOT NULL,
  `ClaOtrUsu` char(10) NOT NULL,
  `ClaOtrUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`ClaOtrCod`),
  CONSTRAINT `ITCLAOTR1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tcliadmcen` (
  `EmpCod` smallint NOT NULL,
  `CliCod` mediumint NOT NULL,
  `CliAdmCen` char(20) NOT NULL,
  `CliDirCod` mediumint NOT NULL,
  `CliAdmDes` char(50) NOT NULL,
  `CliAdmPLO` char(14) NOT NULL,
  `CliAdmGLN` char(14) NOT NULL,
  `CliAdmApe2` char(40) NOT NULL,
  `CliAdmApe1` char(40) NOT NULL,
  `CliAdmNom` char(40) NOT NULL,
  `CliAdmLocCnt` int NOT NULL,
  `CliAdmLocCodPos` char(10) NOT NULL,
  `CliAdmPrvCod` char(2) NOT NULL,
  `CliAdmPaiCod` char(3) NOT NULL,
  `CliAdmDir` char(80) NOT NULL,
  PRIMARY KEY (`EmpCod`,`CliCod`,`CliAdmCen`,`CliDirCod`),
  KEY `ITCLIADMCEN1` (`EmpCod`,`CliCod`,`CliDirCod`),
  CONSTRAINT `ITCLIADMCEN1` FOREIGN KEY (`EmpCod`, `CliCod`, `CliDirCod`) REFERENCES `clidir` (`EmpCod`, `CliCod`, `CliDirCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tcliadmcenrol` (
  `EmpCod` smallint NOT NULL,
  `CliCod` mediumint NOT NULL,
  `CliAdmCen` char(20) NOT NULL,
  `CliDirCod` mediumint NOT NULL,
  `Rol` smallint NOT NULL,
  PRIMARY KEY (`EmpCod`,`CliCod`,`CliAdmCen`,`CliDirCod`,`Rol`),
  KEY `ITCLIADMCENROL1` (`EmpCod`,`Rol`),
  CONSTRAINT `ITCLIADMCENROL1` FOREIGN KEY (`EmpCod`, `Rol`) REFERENCES `troles` (`EmpCod`, `Rol`),
  CONSTRAINT `ITCLIADMCENROL2` FOREIGN KEY (`EmpCod`, `CliCod`, `CliAdmCen`, `CliDirCod`) REFERENCES `tcliadmcen` (`EmpCod`, `CliCod`, `CliAdmCen`, `CliDirCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tclientes_contactos` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `CliCod` mediumint NOT NULL,
  `CliConId` smallint NOT NULL,
  `CliConTel` char(65) DEFAULT NULL,
  `CliConMov` char(65) DEFAULT NULL,
  `CliConMail` char(50) DEFAULT NULL,
  `CliConMailTO` char(1) DEFAULT NULL,
  `CliConTip` char(30) DEFAULT NULL,
  `CliConNom` char(40) DEFAULT NULL,
  `CarCod` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CliCod`,`CliConId`),
  KEY `ITCLICON_CAR` (`EmpCod`,`CarCod`),
  CONSTRAINT `ITCLICON_CAR` FOREIGN KEY (`EmpCod`, `CarCod`) REFERENCES `tcargos` (`EmpCod`, `CarCod`),
  CONSTRAINT `ITCLICON_CLI` FOREIGN KEY (`EmpCod`, `CliCod`) REFERENCES `clientes` (`EmpCod`, `CliCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tclientescontactos` (
  `EmpCod` smallint NOT NULL,
  `CliCod` mediumint NOT NULL,
  `CliConTip` char(30) NOT NULL DEFAULT '',
  `CliConNom` char(40) NOT NULL,
  `CliConTel` char(65) NOT NULL,
  `CliConMov` char(65) NOT NULL,
  `CliConMail` char(50) NOT NULL,
  `CliConMailCC` char(1) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CliCod`,`CliConTip`),
  CONSTRAINT `ITCLIENTESCONTACTOS1` FOREIGN KEY (`EmpCod`, `CliCod`) REFERENCES `clientes` (`EmpCod`, `CliCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tconceptos` (
  `EmpCod` smallint NOT NULL,
  `ConCod` smallint NOT NULL,
  `ConDes` char(20) NOT NULL,
  `ConNorm43` smallint NOT NULL,
  `ConUsuCod` char(10) NOT NULL,
  `ConUltMod` datetime NOT NULL,
  `ConOperacion` char(3) DEFAULT NULL,
  `ConAsiFEN` char(1) NOT NULL,
  `ConAsiFRI` char(1) NOT NULL,
  `ConAsiFRN` char(1) NOT NULL,
  `ConAsiFRA` char(1) NOT NULL,
  PRIMARY KEY (`EmpCod`,`ConCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tctactble` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `CtaTit` char(4) NOT NULL,
  `CtaCod` char(6) NOT NULL DEFAULT '',
  `CtaNom` char(80) NOT NULL,
  `CtaUsuCod` char(10) NOT NULL,
  `CtaUltMod` datetime NOT NULL,
  `CtaTitCod` char(100) DEFAULT NULL,
  `CtaState` char(1) DEFAULT 'N',
  PRIMARY KEY (`EmpCod`,`CtaTit`,`CtaCod`),
  KEY `UCTACTBLE1` (`EmpCod`,`CtaNom`,`CtaTit`,`CtaCod`),
  KEY `UTCTACTBLE` (`EmpCod`,`CtaTitCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tctareferencia` (
  `EmpCod` smallint NOT NULL,
  `CtaRefCodTit` char(4) NOT NULL,
  `CtaRefCod` char(6) NOT NULL,
  `CtaRefTpo` char(1) NOT NULL,
  `CtaRefCompleta` char(80) NOT NULL,
  `CtaRefTpoIva` smallint NOT NULL,
  `CtaRefMe` char(1) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`CtaRefCodTit`,`CtaRefCod`),
  KEY `UTCTAREFERENCIA` (`EmpCod`,`CtaRefTpo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tctaterceros` (
  `EmpCod` smallint NOT NULL,
  `CtaTerTitCod` char(4) NOT NULL,
  `CtaTerCod` char(6) NOT NULL,
  `CtaTerNif` char(15) NOT NULL,
  PRIMARY KEY (`EmpCod`,`CtaTerTitCod`,`CtaTerCod`),
  KEY `UTCTATERCEROS` (`EmpCod`,`CtaTerTitCod`,`CtaTerNif`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tdefexploctalevel1` (
  `EmpCod` smallint NOT NULL,
  `DefExCod` smallint NOT NULL,
  `DefExCab` char(2) NOT NULL,
  `CtaTit` char(4) NOT NULL,
  `CtaCod` char(6) NOT NULL,
  `DefExAgr` char(1) NOT NULL,
  PRIMARY KEY (`EmpCod`,`DefExCod`,`DefExCab`,`CtaTit`,`CtaCod`),
  KEY `IDEFEXPLOLEVEL1LEVEL21` (`EmpCod`,`CtaTit`,`CtaCod`),
  KEY `ITDEFEXPLOCTALEVEL11` (`EmpCod`,`CtaTit`,`CtaCod`),
  CONSTRAINT `IDEFEXPLOLEVEL1LEVEL21` FOREIGN KEY (`EmpCod`, `CtaTit`, `CtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `IDEFEXPLOLEVEL1LEVEL22` FOREIGN KEY (`EmpCod`, `DefExCod`, `DefExCab`) REFERENCES `defexplolevel1` (`EmpCod`, `DefExCod`, `DefExCab`),
  CONSTRAINT `ITDEFEXPLOCTALEVEL11` FOREIGN KEY (`EmpCod`, `CtaTit`, `CtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`),
  CONSTRAINT `ITDEFEXPLOCTALEVEL12` FOREIGN KEY (`EmpCod`, `DefExCod`, `DefExCab`) REFERENCES `defexplolevel1` (`EmpCod`, `DefExCod`, `DefExCab`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tempcenparcentros` (
  `EmpCod` smallint NOT NULL,
  `CentCod` smallint NOT NULL,
  `CentParCod` char(8) NOT NULL,
  `CentParCon` char(40) NOT NULL,
  `CentParPar` char(60) NOT NULL,
  PRIMARY KEY (`EmpCod`,`CentCod`,`CentParCod`),
  CONSTRAINT `ITEMPCENPARCENTROS1` FOREIGN KEY (`EmpCod`, `CentCod`) REFERENCES `empcen` (`EmpCod`, `CentCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tercercladoc` (
  `EmpCod` smallint NOT NULL,
  `TerClaId` char(2) NOT NULL,
  `TerClaDesc` char(100) NOT NULL,
  PRIMARY KEY (`EmpCod`,`TerClaId`),
  CONSTRAINT `ITERCERCLADOC1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tipigic` (
  `EmpCod` smallint NOT NULL,
  `TipIgicTip` char(5) NOT NULL,
  `TipIgicFec` date NOT NULL,
  `TipIgicTitRep` char(4) NOT NULL,
  `TipIgicCtaRep` char(6) NOT NULL,
  `TipIgicTitIslas` char(4) NOT NULL,
  `TipIgicCtaIslas` char(6) NOT NULL,
  `TipIgicTitImp` char(4) NOT NULL,
  `TipIgicCtaImp` char(6) NOT NULL,
  `TipIgicPor` decimal(5,2) NOT NULL,
  PRIMARY KEY (`EmpCod`,`TipIgicTip`,`TipIgicFec`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tipigictip` (
  `EmpCod` smallint NOT NULL,
  `IgicTpoTpoCod` char(5) NOT NULL,
  `IgicTpoTpoNom` char(30) NOT NULL,
  PRIMARY KEY (`EmpCod`,`IgicTpoTpoCod`),
  CONSTRAINT `ITIPIGICTIP1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tipirpf1` (
  `EmpCod` smallint NOT NULL,
  `TipIrpfCod` char(3) NOT NULL,
  `TipIRPFFEc` date NOT NULL,
  `TipIRPFFecFin` date NOT NULL,
  `TipIRPFPor` decimal(5,2) NOT NULL,
  `TipIrpfCtaCodSop` char(6) DEFAULT NULL,
  `TipIrpfCtaTitSop` char(4) DEFAULT NULL,
  `TipIRPfCtaCodPra` char(6) NOT NULL,
  `TipIRPfCtaTitPra` char(4) NOT NULL,
  PRIMARY KEY (`EmpCod`,`TipIrpfCod`,`TipIRPFFEc`),
  CONSTRAINT `ITIPIRPF12` FOREIGN KEY (`EmpCod`, `TipIrpfCod`) REFERENCES `tipirpf` (`EmpCod`, `TipIrpfCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tipirpf` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `TipIrpfCod` char(3) NOT NULL,
  `TipIRPFDes` char(30) NOT NULL,
  `TipIRPFUsuCod` char(10) NOT NULL,
  `TipIRPFUltMod` datetime NOT NULL,
  `TipIrpfModT` decimal(3,0) DEFAULT NULL,
  `TipIrpfModA` decimal(3,0) DEFAULT NULL,
  `TipIrpfClave` char(4) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`TipIrpfCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tipivaplano` (
  `EmpCod` smallint NOT NULL,
  `TipIvaTip` char(5) NOT NULL,
  `TipIvaFec` date NOT NULL,
  `TipReTit` char(4) NOT NULL,
  `TipReCod` char(6) NOT NULL,
  `TipIvaCtaRep` char(6) NOT NULL,
  `TipIvaTitRep` char(4) NOT NULL,
  `TipIvaAutCodD` char(6) NOT NULL,
  `TipIvaAutTitD` char(4) NOT NULL,
  `TipIvaCtaInt` char(6) NOT NULL,
  `TipIvaTitInt` char(4) NOT NULL,
  `TipIvaCtaImp` char(6) NOT NULL,
  `TipIvaTitImp` char(4) NOT NULL,
  `TipIvaCod` char(6) NOT NULL,
  `TipIvaTit` char(4) NOT NULL,
  `TipIvaRec` decimal(5,2) NOT NULL,
  `TipIvaPor` decimal(5,2) NOT NULL,
  PRIMARY KEY (`EmpCod`,`TipIvaTip`,`TipIvaFec`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tivaextra` (
  `IvaEXEmpCod` smallint NOT NULL,
  `IvaEXEjerCod` char(8) NOT NULL,
  `IvaEXMovId` int NOT NULL,
  `IvaEXMovLin` smallint NOT NULL,
  `IvaEXIvaTip` char(1) NOT NULL,
  `IvaEXIvaTipLin` char(1) NOT NULL,
  `PaiCod` char(3) NOT NULL,
  `IvaEXMovFecha` date NOT NULL,
  `IvaEXSerie` char(20) NOT NULL,
  `IvaEXNum` int NOT NULL,
  `IvaEXCtaTit` char(4) NOT NULL,
  `IvaEXCtaCod` char(6) NOT NULL,
  `IvaEXBase` decimal(11,2) NOT NULL,
  `IvaEXCuota` decimal(11,2) NOT NULL,
  `IvaExExPor` decimal(5,2) NOT NULL,
  `IvaEXIvaDed` char(3) NOT NULL,
  `IvaEXIvaClase` char(3) NOT NULL,
  `IvaEXIvaPorDedu` decimal(5,2) NOT NULL,
  `IvaEXUsuCodINS` char(10) NOT NULL,
  `IvaEXFecINS` datetime NOT NULL,
  `IvaEXUsuCodMod` char(10) NOT NULL,
  `IvaEXUltMod` datetime NOT NULL,
  PRIMARY KEY (`IvaEXEmpCod`,`IvaEXEjerCod`,`IvaEXMovId`,`IvaEXMovLin`,`IvaEXIvaTip`,`IvaEXIvaTipLin`),
  KEY `ITIVAEXTRA1` (`PaiCod`),
  CONSTRAINT `ITIVAEXTRA1` FOREIGN KEY (`PaiCod`) REFERENCES `pais` (`PaiCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tivaintra` (
  `IntraEmpCod` smallint NOT NULL DEFAULT '0',
  `IntraEjerCod` char(8) NOT NULL,
  `IntraNOI` char(15) NOT NULL,
  `IntraReg` int NOT NULL,
  `IntraLin` smallint NOT NULL,
  `IntraId` int NOT NULL,
  `IntraTipo` char(1) DEFAULT NULL,
  `IntraFec` date DEFAULT NULL,
  `IntraCodigo` char(8) DEFAULT NULL,
  `IntraDCtaTit` char(4) NOT NULL,
  `IntraDCtaCod` char(6) NOT NULL,
  `IntraImporte` decimal(11,2) DEFAULT NULL,
  `IntraSerie` char(3) DEFAULT NULL,
  `IntraNumIva` int DEFAULT NULL,
  `IntraBase` decimal(11,2) DEFAULT NULL,
  `IntraPorIva` decimal(5,2) DEFAULT NULL,
  `IntraCuota` decimal(11,2) DEFAULT NULL,
  `IntraEst` char(1) DEFAULT NULL,
  `IntraNumExp` char(20) DEFAULT NULL,
  `IntraUsuCod` char(10) DEFAULT NULL,
  `IntraUltMod` datetime DEFAULT NULL,
  PRIMARY KEY (`IntraEmpCod`,`IntraEjerCod`,`IntraNOI`,`IntraReg`,`IntraLin`,`IntraId`),
  KEY `ITIVAINTRA1` (`IntraEmpCod`,`IntraDCtaTit`,`IntraDCtaCod`),
  CONSTRAINT `ITIVAINTRA1` FOREIGN KEY (`IntraEmpCod`, `IntraDCtaTit`, `IntraDCtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tlotartreglevel1` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `LotCod` char(20) NOT NULL,
  `ArtCod` char(13) NOT NULL,
  `CentCod` smallint NOT NULL,
  `LotArtLin` smallint NOT NULL,
  `LotArtRegLin` smallint NOT NULL,
  `LotArtRegFec` date NOT NULL,
  `LotArtRegMer` decimal(9,3) NOT NULL,
  `LotArtRegUniDev` decimal(9,3) NOT NULL,
  `LotArtRegEnt` decimal(9,3) NOT NULL,
  `LotArtRegUsu` char(10) NOT NULL,
  `LotArtRefMod` datetime NOT NULL,
  `LotArtRegObs` char(38) NOT NULL DEFAULT '',
  `LotArtRegEntC` smallint NOT NULL DEFAULT '0',
  `LotArtRegUDC` smallint NOT NULL DEFAULT '0',
  `LotArtRegMerC` smallint NOT NULL DEFAULT '0',
  `LotArtFacCod` int DEFAULT '0',
  PRIMARY KEY (`EmpCod`,`LotCod`,`ArtCod`,`CentCod`,`LotArtLin`,`LotArtRegLin`),
  CONSTRAINT `ITLOTARTREGLEVEL11` FOREIGN KEY (`EmpCod`, `LotCod`, `ArtCod`, `CentCod`, `LotArtLin`) REFERENCES `lotearticulo` (`EmpCod`, `LotCod`, `ArtCod`, `CentCod`, `LotArtLin`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tmp347` (
  `Tmp347EmpCod` smallint NOT NULL DEFAULT '0',
  `Tmp347Anio` char(4) NOT NULL,
  `Tmp347Hoja` char(1) NOT NULL,
  `Tmp347ClaOp` char(1) NOT NULL,
  `Tmp347Nif` char(15) NOT NULL,
  `Tmp347ImpOpe` decimal(11,2) NOT NULL,
  `Tmp347ImpMet` decimal(11,2) NOT NULL,
  `Tmp347ImpTrans` decimal(11,2) NOT NULL,
  `Tmp347Tercero` char(1) NOT NULL,
  `Tmp347CtaTit` char(4) NOT NULL,
  `Tmp347CtaCod` char(6) NOT NULL,
  `Tmp347InmCod` int DEFAULT NULL,
  `Tmp347ImpTransT4` decimal(11,2) DEFAULT NULL,
  `Tmp347ImpTransT3` decimal(11,2) DEFAULT NULL,
  `Tmp347ImpTransT2` decimal(11,2) DEFAULT NULL,
  `Tmp347ImpTransT1` decimal(11,2) DEFAULT NULL,
  `Tmp347ImpOpeT4` decimal(11,2) DEFAULT NULL,
  `Tmp347ImpOpeT3` decimal(11,2) DEFAULT NULL,
  `Tmp347ImpOpeT2` decimal(11,2) DEFAULT NULL,
  `Tmp347ImpOpeT1` decimal(11,2) DEFAULT NULL,
  `Tmp347PrvCod` char(2) DEFAULT NULL,
  `Tmp347PaisIso2` char(2) DEFAULT NULL,
  `Tmp347CtaNom` char(80) DEFAULT NULL,
  `Tmp347FecEnv` date DEFAULT NULL,
  `Tmp347Email` varchar(100) DEFAULT NULL,
  `Tmp347Mod` char(3) NOT NULL DEFAULT '347',
  `Tmp347anioMet2` char(4) DEFAULT NULL,
  `Tmp347ImpMet2` decimal(11,2) DEFAULT NULL,
  `Tmp347anioMet` char(4) DEFAULT NULL,
  `Tmp347ClaEsp` char(1) NOT NULL DEFAULT '',
  PRIMARY KEY (`Tmp347EmpCod`,`Tmp347Mod`,`Tmp347Anio`,`Tmp347Hoja`,`Tmp347Nif`,`Tmp347ClaOp`,`Tmp347ClaEsp`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tmpexcel` (
  `TmpEmpCod` smallint NOT NULL,
  `TmpSession` char(100) NOT NULL,
  `TmpLine` smallint NOT NULL,
  `TmpCtaTitD` char(4) DEFAULT NULL,
  `TmpCtaCodD` char(6) DEFAULT NULL,
  `TmpCtaTitH` char(4) DEFAULT NULL,
  `TmpCtaCodH` char(6) DEFAULT NULL,
  `TmpFecMov` date DEFAULT NULL,
  `TmpConcepto` smallint DEFAULT NULL,
  `TmpObs` char(40) DEFAULT NULL,
  `TmpIngreso` decimal(11,2) DEFAULT NULL,
  `TmpPago` decimal(11,2) DEFAULT NULL,
  `TmpNroDoc` int DEFAULT NULL,
  `TmpME` decimal(11,2) DEFAULT NULL,
  `TmpDivisa` char(3) DEFAULT NULL,
  `TmpVencimiento` date DEFAULT NULL,
  `TmpForCob` char(3) DEFAULT NULL,
  `TmpCuoIRPF` decimal(11,2) DEFAULT NULL,
  `TmpPorIRPF` decimal(5,2) DEFAULT NULL,
  `TmpBasIRPF` decimal(11,2) DEFAULT NULL,
  `TmpClaIRPF` char(3) DEFAULT NULL,
  `TmpSujIva` char(2) DEFAULT NULL,
  `TmpPorRE3` decimal(5,2) DEFAULT NULL,
  `TmpPorRE2` decimal(5,2) DEFAULT NULL,
  `TmpPorRE1` decimal(5,2) DEFAULT NULL,
  `TmpCuoRE3` decimal(11,2) DEFAULT NULL,
  `TmpCuoRE2` decimal(11,2) DEFAULT NULL,
  `TmpCuoRE1` decimal(11,2) DEFAULT NULL,
  `TmpPor1Iva` decimal(5,2) DEFAULT NULL,
  `TmpBas1Iva` decimal(11,2) DEFAULT NULL,
  `TmpCuo1Iva` decimal(9,2) DEFAULT NULL,
  `TmpPor2Iva` decimal(5,2) DEFAULT NULL,
  `TmpBas2Iva` decimal(11,2) DEFAULT NULL,
  `TmpCuo2Iva` decimal(9,2) DEFAULT NULL,
  `TmpPor3Iva` decimal(5,2) DEFAULT NULL,
  `TmpBas3Iva` decimal(11,2) DEFAULT NULL,
  `TmpPor4Iva` decimal(5,2) DEFAULT NULL,
  `TmpBas4Iva` decimal(11,2) DEFAULT NULL,
  `TmpCuo4Iva` decimal(9,2) DEFAULT NULL,
  `TmpPor5Iva` decimal(5,2) DEFAULT NULL,
  `TmpBas5Iva` decimal(11,2) DEFAULT NULL,
  `TmpCuo5Iva` decimal(9,2) DEFAULT NULL,
  `TmpPor6Iva` decimal(5,2) DEFAULT NULL,
  `TmpBas6Iva` decimal(11,2) DEFAULT NULL,
  `TmpCuo6Iva` decimal(9,2) DEFAULT NULL,
  `TmpCuo3Iva` decimal(9,2) DEFAULT NULL,
  `TmpSerie` char(3) DEFAULT NULL,
  `TmpTipFac` char(3) DEFAULT NULL,
  `TmpRazSoc` char(40) DEFAULT NULL,
  `TmpNif` char(15) DEFAULT NULL,
  `TmpFecFac` date DEFAULT NULL,
  `TmpNroDua` char(20) DEFAULT NULL,
  `TmpDiv` smallint DEFAULT NULL,
  `TmpSuc` smallint DEFAULT NULL,
  `TmpBlobFile` longblob,
  `TmpBlobName` char(200) DEFAULT NULL,
  `TmpBlobType` char(4) DEFAULT NULL,
  `TmpIban` char(34) DEFAULT NULL,
  `TmpClades` char(40) DEFAULT NULL,
  `TmpClacli` char(2) DEFAULT NULL,
  `TmpRec` char(1) DEFAULT NULL,
  `TmpPais` char(3) DEFAULT NULL,
  `TmpPob` char(40) DEFAULT NULL,
  `TmpCP` char(10) DEFAULT NULL,
  `TmpDir` char(50) DEFAULT NULL,
  `TmpNomcom` char(40) DEFAULT NULL,
  `TmpDiacob2` smallint DEFAULT NULL,
  `TmpDiacob1` smallint DEFAULT NULL,
  `TmpDiaentre` smallint DEFAULT NULL,
  `TmpDia1` smallint DEFAULT NULL,
  `TmpPlazos` smallint DEFAULT NULL,
  `TmpSerieNumRec` char(20) DEFAULT NULL,
  `TmpFecFacRec` date DEFAULT NULL,
  `TmpCliDirCod` mediumint DEFAULT NULL,
  `TmpAux1` char(100) DEFAULT NULL,
  `TmpAux2` char(100) DEFAULT NULL,
  PRIMARY KEY (`TmpEmpCod`,`TmpSession`,`TmpLine`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tmpficban1` (
  `TmpFicBanEmp` smallint NOT NULL,
  `TmpFicBanEnt` char(4) NOT NULL,
  `TmpFicBanOfi` char(4) NOT NULL,
  `TmpFicBanCta` char(10) NOT NULL,
  `TmpFicBanFecIni` date NOT NULL,
  `TmpFicBanFecFin` date NOT NULL,
  `TmpFicBanImpSalIni` decimal(11,2) NOT NULL,
  PRIMARY KEY (`TmpFicBanEmp`,`TmpFicBanEnt`,`TmpFicBanOfi`,`TmpFicBanCta`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tmpficban` (
  `TmpFicBanEmp` smallint NOT NULL DEFAULT '0',
  `TmpFicBanEnt` char(4) NOT NULL,
  `TmpFicBanOfi` char(4) NOT NULL,
  `TmpFicBanCta` char(10) NOT NULL,
  `TmpFicBanLinR` smallint NOT NULL,
  `TmpFicBanFecOP` date NOT NULL,
  `TmpFicBanFecVal` date NOT NULL,
  `TmpFicBanDH` char(1) NOT NULL,
  `TmpFicBanImporte` decimal(11,2) NOT NULL,
  `TmpFicBanNDoc` char(38) NOT NULL DEFAULT '',
  `TmpFicBanConcepto` char(38) NOT NULL,
  `TmpFicBanVinc` char(1) NOT NULL,
  PRIMARY KEY (`TmpFicBanEmp`,`TmpFicBanEnt`,`TmpFicBanOfi`,`TmpFicBanCta`,`TmpFicBanLinR`),
  CONSTRAINT `ITMPFICBAN1` FOREIGN KEY (`TmpFicBanEmp`, `TmpFicBanEnt`, `TmpFicBanOfi`, `TmpFicBanCta`) REFERENCES `tmpficban1` (`TmpFicBanEmp`, `TmpFicBanEnt`, `TmpFicBanOfi`, `TmpFicBanCta`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tmpficbanconceptos` (
  `TmpFicBanEmp` smallint NOT NULL,
  `TmpFicBanEnt` char(4) NOT NULL,
  `TmpFicBanOfi` char(4) NOT NULL,
  `TmpFicBanCta` char(10) NOT NULL,
  `TmpFicBanConCod` smallint NOT NULL,
  `TmpFicBanConDes` char(38) NOT NULL,
  PRIMARY KEY (`TmpFicBanEmp`,`TmpFicBanEnt`,`TmpFicBanOfi`,`TmpFicBanCta`,`TmpFicBanConCod`),
  CONSTRAINT `ITMPFICBANCONCEPTOS1` FOREIGN KEY (`TmpFicBanEmp`, `TmpFicBanEnt`, `TmpFicBanOfi`, `TmpFicBanCta`) REFERENCES `tmpficban1` (`TmpFicBanEmp`, `TmpFicBanEnt`, `TmpFicBanOfi`, `TmpFicBanCta`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tmpficbanoperacion` (
  `TmpFicBanEmp` smallint NOT NULL,
  `TmpFicBanEnt` char(4) NOT NULL,
  `TmpFicBanOfi` char(4) NOT NULL,
  `TmpFicBanCta` char(10) NOT NULL,
  `TmpFicBanOpCod` smallint NOT NULL,
  `TmpFicBanOpDes` char(38) NOT NULL,
  PRIMARY KEY (`TmpFicBanEmp`,`TmpFicBanEnt`,`TmpFicBanOfi`,`TmpFicBanCta`,`TmpFicBanOpCod`),
  CONSTRAINT `ITMPFICBANOPERACION1` FOREIGN KEY (`TmpFicBanEmp`, `TmpFicBanEnt`, `TmpFicBanOfi`, `TmpFicBanCta`) REFERENCES `tmpficban1` (`TmpFicBanEmp`, `TmpFicBanEnt`, `TmpFicBanOfi`, `TmpFicBanCta`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tmpinm` (
  `TmpInmEmp` smallint NOT NULL DEFAULT '0',
  `TmpInmId` mediumint NOT NULL,
  `TmpInmNom` char(80) DEFAULT NULL,
  `TmpInmCtaTit` char(4) DEFAULT NULL,
  `TmpInmCtaCod` char(6) DEFAULT NULL,
  `TmpInmAmoCtaTit` char(4) DEFAULT NULL,
  `TmpInmAmoCtaCod` char(6) DEFAULT NULL,
  `TmpInmDotCtaTit` char(4) DEFAULT NULL,
  `TmpInmDotCtaCod` char(6) DEFAULT NULL,
  `TmpInmCosFec` date DEFAULT NULL,
  `TmpInmCosPro` char(40) DEFAULT NULL,
  `TmpInmCosImp` decimal(11,2) DEFAULT NULL,
  `TmpInmValRes` decimal(11,2) DEFAULT NULL,
  `TmpInmFec` date DEFAULT NULL,
  `TmpInmPor` decimal(7,4) DEFAULT NULL,
  `TmpInmAny` decimal(5,2) DEFAULT NULL,
  `TmpInmCri` char(3) DEFAULT NULL,
  `TmpInmPorFis` decimal(7,4) DEFAULT NULL,
  `TmpInmAnyFis` decimal(5,2) DEFAULT NULL,
  `TmpInmCentCod` smallint DEFAULT NULL,
  `TmpInmDvsCod` smallint DEFAULT NULL,
  `TmpInmMesUac` smallint DEFAULT NULL,
  `TmpInmAnyUac` smallint DEFAULT NULL,
  `TmpInmImpUac` decimal(11,2) DEFAULT NULL,
  `TmpInmDifUac` decimal(11,2) DEFAULT NULL,
  `TmpInmAccion` char(1) DEFAULT NULL,
  `TmpInmFila` smallint DEFAULT NULL,
  PRIMARY KEY (`TmpInmEmp`,`TmpInmId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tmpiva` (
  `TmpIvaEmpCod` smallint NOT NULL,
  `TmpIvaSession` char(100) NOT NULL,
  `TmpIvaCtaTit` char(4) NOT NULL,
  `TmpIvaCtaCod` char(6) NOT NULL,
  `TmpIvaEjerCod` char(8) NOT NULL,
  `TmpIvaMovId` int NOT NULL,
  `TmpIvaLinId` smallint NOT NULL,
  `TmpIvaPor` decimal(5,2) NOT NULL,
  `TmpIvaBase` decimal(11,2) NOT NULL,
  `TmpIvaCuota` decimal(11,2) NOT NULL,
  `TmpIvaTpo` smallint NOT NULL,
  `TmpIvaFecAlta` date DEFAULT NULL,
  `TmpIvaDiario` smallint NOT NULL,
  PRIMARY KEY (`TmpIvaEmpCod`,`TmpIvaSession`,`TmpIvaCtaTit`,`TmpIvaCtaCod`,`TmpIvaDiario`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tmporides` (
  `TmpOriEmp` smallint NOT NULL,
  `TmpOriId` char(6) NOT NULL,
  `TmpOriAny` smallint DEFAULT NULL,
  `TmpOriMes` smallint DEFAULT NULL,
  `TmpOriFecApe` date DEFAULT NULL,
  `TmpOriFecAcum` date DEFAULT NULL,
  `TmpOriFecCli` date DEFAULT NULL,
  `TmpOriFecAcr` date DEFAULT NULL,
  `TmpOriFecPro` date DEFAULT NULL,
  `TmpOriFecBan` date DEFAULT NULL,
  `TmpOriFecInm` date DEFAULT NULL,
  `TmpOriFecFam` date DEFAULT NULL,
  `TmpOriFecArt` date DEFAULT NULL,
  `TmpOriFecDia` date DEFAULT NULL,
  PRIMARY KEY (`TmpOriEmp`,`TmpOriId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tmporidesdiv` (
  `TmpOriEmp` smallint NOT NULL,
  `TmpOriId` char(6) NOT NULL,
  `TmpOriDivLin` smallint NOT NULL,
  `TmpOriDiv` char(10) DEFAULT NULL,
  `TmpOriDivDes` smallint DEFAULT NULL,
  PRIMARY KEY (`TmpOriEmp`,`TmpOriId`,`TmpOriDivLin`),
  CONSTRAINT `ITMPORIDESDIV1` FOREIGN KEY (`TmpOriEmp`, `TmpOriId`) REFERENCES `tmporides` (`TmpOriEmp`, `TmpOriId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tmporideslevel1` (
  `TmpOriEmp` smallint NOT NULL,
  `TmpOriId` char(6) NOT NULL,
  `TmpOriLin` smallint NOT NULL,
  `TmpOriCta` char(12) DEFAULT NULL,
  `TmpOriCtaDes` char(4) DEFAULT NULL,
  `TmpOriCodDes` char(6) DEFAULT NULL,
  PRIMARY KEY (`TmpOriEmp`,`TmpOriId`,`TmpOriLin`),
  CONSTRAINT `ITMPORIDESLEVEL11` FOREIGN KEY (`TmpOriEmp`, `TmpOriId`) REFERENCES `tmporides` (`TmpOriEmp`, `TmpOriId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tmporideslevel2` (
  `TmpOriEmp` smallint NOT NULL,
  `TmpOriId` char(6) NOT NULL,
  `TmpOriCenLin` smallint NOT NULL,
  `TmpOriCen` char(10) DEFAULT NULL,
  `TmpOriCenDes` smallint DEFAULT NULL,
  PRIMARY KEY (`TmpOriEmp`,`TmpOriId`,`TmpOriCenLin`),
  CONSTRAINT `ITMPORIDESLEVEL21` FOREIGN KEY (`TmpOriEmp`, `TmpOriId`) REFERENCES `tmporides` (`TmpOriEmp`, `TmpOriId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tpaisestpo` (
  `PaiCod` char(3) NOT NULL,
  `TpoCaracteres` char(1) NOT NULL,
  `PaiCara1` smallint DEFAULT NULL,
  `PaiCara2` smallint DEFAULT NULL,
  `PaiCara3` smallint DEFAULT NULL,
  `PaiCaraOp` char(4) DEFAULT NULL,
  PRIMARY KEY (`PaiCod`,`TpoCaracteres`),
  CONSTRAINT `ITPAISESTPO1` FOREIGN KEY (`PaiCod`) REFERENCES `pais` (`PaiCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tplann43` (
  `TmpFicBanEmp` smallint NOT NULL DEFAULT '0',
  `TmpFicBanEnt` char(4) NOT NULL,
  `TmpFicBanOfi` char(4) NOT NULL,
  `TmpFicBanCta` char(10) NOT NULL,
  `TmpFicBanOpCod` smallint NOT NULL,
  `TmpFicBanConCod` smallint NOT NULL,
  `TmpFicBanGrupoP` char(4) NOT NULL,
  `TmpFicBanCtaP` char(6) NOT NULL,
  `TmpFicBanClP` smallint NOT NULL,
  `TmpFicBanCen` smallint DEFAULT NULL,
  `TmpFicBanEx` char(1) NOT NULL DEFAULT '',
  `TmpFicBanSelCon` smallint unsigned DEFAULT NULL,
  PRIMARY KEY (`TmpFicBanEmp`,`TmpFicBanEnt`,`TmpFicBanOfi`,`TmpFicBanCta`,`TmpFicBanOpCod`,`TmpFicBanConCod`),
  KEY `ITPLANN431` (`TmpFicBanEmp`,`TmpFicBanEnt`,`TmpFicBanOfi`,`TmpFicBanCta`,`TmpFicBanConCod`),
  CONSTRAINT `ITPLANN431` FOREIGN KEY (`TmpFicBanEmp`, `TmpFicBanEnt`, `TmpFicBanOfi`, `TmpFicBanCta`, `TmpFicBanConCod`) REFERENCES `tmpficbanconceptos` (`TmpFicBanEmp`, `TmpFicBanEnt`, `TmpFicBanOfi`, `TmpFicBanCta`, `TmpFicBanConCod`),
  CONSTRAINT `ITPLANN432` FOREIGN KEY (`TmpFicBanEmp`, `TmpFicBanEnt`, `TmpFicBanOfi`, `TmpFicBanCta`, `TmpFicBanOpCod`) REFERENCES `tmpficbanoperacion` (`TmpFicBanEmp`, `TmpFicBanEnt`, `TmpFicBanOfi`, `TmpFicBanCta`, `TmpFicBanOpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tplaredcen` (
  `EmpCod` smallint NOT NULL,
  `PlaRedId` smallint NOT NULL,
  `PlaRedTitOri` char(4) NOT NULL,
  `PlaRedCodOri` char(6) NOT NULL,
  `PlaRedCenOri` smallint NOT NULL,
  `PlaRedDvsOri` smallint NOT NULL,
  `PlaRedPor` decimal(5,2) NOT NULL,
  `PlaRedCenDes` smallint NOT NULL,
  `PlaRedDvsDes` smallint NOT NULL,
  `PlaRedTitDes` char(4) NOT NULL,
  `PlaRedFecha` date NOT NULL,
  PRIMARY KEY (`EmpCod`,`PlaRedId`),
  KEY `UTPLAREDCEN` (`EmpCod`,`PlaRedTitOri`,`PlaRedCodOri`,`PlaRedCenOri`,`PlaRedDvsOri`),
  CONSTRAINT `ITPLAREDCEN1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tproveedor_contactos` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `ProCod` mediumint NOT NULL,
  `ProConId` smallint NOT NULL,
  `ProConTip` char(30) DEFAULT NULL,
  `ProConNom` char(40) DEFAULT NULL,
  `ProConTel` char(65) DEFAULT NULL,
  `ProConMov` char(65) DEFAULT NULL,
  `ProConMail` char(50) DEFAULT NULL,
  `CarCod` smallint DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`ProCod`,`ProConId`),
  KEY `ITPROVEEDOR_CONTACTOS` (`EmpCod`,`CarCod`),
  CONSTRAINT `ITPROVEEDOR_CONTACTOS` FOREIGN KEY (`EmpCod`, `CarCod`) REFERENCES `tcargos` (`EmpCod`, `CarCod`),
  CONSTRAINT `ITPROVEEDORCONTACTOS` FOREIGN KEY (`EmpCod`, `ProCod`) REFERENCES `proveedor` (`EmpCod`, `ProCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tproveedorcontactos` (
  `EmpCod` smallint NOT NULL,
  `ProCod` mediumint NOT NULL,
  `ProConTip` char(30) NOT NULL DEFAULT '',
  `ProConNom` char(40) NOT NULL,
  `ProConTel` char(65) NOT NULL,
  `ProConMov` char(65) NOT NULL,
  `ProConMail` char(50) NOT NULL,
  PRIMARY KEY (`EmpCod`,`ProCod`,`ProConTip`),
  CONSTRAINT `ITPROVEEDORCONTACTOS1` FOREIGN KEY (`EmpCod`, `ProCod`) REFERENCES `proveedor` (`EmpCod`, `ProCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `troles` (
  `EmpCod` smallint NOT NULL,
  `Rol` smallint NOT NULL,
  `RolDesc` char(30) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`Rol`),
  CONSTRAINT `ITROLES1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tsaldosme` (
  `EmpCod` smallint NOT NULL,
  `AcMEDivCod` char(3) NOT NULL,
  `AcMECtaPer` char(8) NOT NULL,
  `AcMECtaAny` char(4) NOT NULL,
  `CtaTit` char(4) NOT NULL,
  `CtaCod` char(6) NOT NULL,
  `AcMECtaApD` decimal(11,2) NOT NULL,
  `AcMECtaApH` decimal(11,2) NOT NULL,
  `AcMECtaCiD` decimal(11,2) NOT NULL,
  `AcMECtaCiH` decimal(11,2) NOT NULL,
  `AcMECtaUsuCod` char(10) NOT NULL,
  `AcMECtaUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`AcMEDivCod`,`AcMECtaPer`,`AcMECtaAny`,`CtaTit`,`CtaCod`),
  KEY `ITSALDOSME1` (`EmpCod`,`CtaTit`,`CtaCod`),
  CONSTRAINT `ITSALDOSME1` FOREIGN KEY (`EmpCod`, `CtaTit`, `CtaCod`) REFERENCES `tctactble` (`EmpCod`, `CtaTit`, `CtaCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tsaldosmelevel1` (
  `EmpCod` smallint NOT NULL,
  `AcMECtaPer` char(8) NOT NULL,
  `AcMECtaAny` char(4) NOT NULL,
  `CtaTit` char(4) NOT NULL,
  `CtaCod` char(6) NOT NULL,
  `AcMECtaMes` smallint NOT NULL,
  `AcMECtaMesD` decimal(14,2) NOT NULL,
  `AcMECtaMesH` decimal(14,2) NOT NULL,
  `AcMEDivCod` char(3) NOT NULL,
  PRIMARY KEY (`EmpCod`,`AcMEDivCod`,`AcMECtaPer`,`AcMECtaAny`,`CtaTit`,`CtaCod`,`AcMECtaMes`),
  CONSTRAINT `ITSALDOSMELEVEL11` FOREIGN KEY (`EmpCod`, `AcMEDivCod`, `AcMECtaPer`, `AcMECtaAny`, `CtaTit`, `CtaCod`) REFERENCES `tsaldosme` (`EmpCod`, `AcMEDivCod`, `AcMECtaPer`, `AcMECtaAny`, `CtaTit`, `CtaCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ttarifas` (
  `EmpCod` smallint NOT NULL,
  `TarCod` smallint NOT NULL,
  `TarDes` char(30) NOT NULL,
  PRIMARY KEY (`EmpCod`,`TarCod`),
  CONSTRAINT `ITTARIFAS1` FOREIGN KEY (`EmpCod`) REFERENCES `empresas` (`EmpCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `tusuariosseg` (
  `EmpCod` smallint NOT NULL,
  `UsuCod` char(10) NOT NULL,
  `SegPerfid` smallint NOT NULL,
  PRIMARY KEY (`EmpCod`,`UsuCod`,`SegPerfid`),
  KEY `ITUSUARIOSSEG1` (`SegPerfid`,`EmpCod`),
  CONSTRAINT `ITUSUARIOSSEG1` FOREIGN KEY (`SegPerfid`, `EmpCod`) REFERENCES `seg_perfil` (`SegPerfid`, `EmpCod`),
  CONSTRAINT `ITUSUARIOSSEG2` FOREIGN KEY (`EmpCod`, `UsuCod`) REFERENCES `usuarios` (`EmpCod`, `UsuCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `uniconsumo` (
  `EmpCod` smallint NOT NULL,
  `UniCod` char(3) NOT NULL,
  `UniDes` char(15) NOT NULL,
  `UniDec` smallint NOT NULL,
  PRIMARY KEY (`EmpCod`,`UniCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `uploadfile` (
  `WebSession` char(200) NOT NULL,
  `File` longblob NOT NULL,
  `FileName` char(200) NOT NULL,
  `FileType` char(4) NOT NULL,
  PRIMARY KEY (`WebSession`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `usuarios1` (
  `EmpCod` smallint NOT NULL,
  `UsuCod` char(10) NOT NULL,
  `ObjId` char(20) NOT NULL,
  `UsuPrgAlt` char(1) NOT NULL,
  `UsuPrgBaj` char(1) NOT NULL,
  `UsuPrgMod` char(1) NOT NULL,
  `UsuPrgVis` char(1) NOT NULL,
  `UsuPrgImp` char(1) NOT NULL,
  PRIMARY KEY (`EmpCod`,`UsuCod`,`ObjId`),
  KEY `IUSUARIOS12` (`ObjId`),
  CONSTRAINT `IUSUARIOS12` FOREIGN KEY (`ObjId`) REFERENCES `objetos` (`ObjId`),
  CONSTRAINT `IUSUARIOS13` FOREIGN KEY (`EmpCod`, `UsuCod`) REFERENCES `usuarios` (`EmpCod`, `UsuCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `usuarios` (
  `EmpCod` smallint NOT NULL DEFAULT '0',
  `UsuCod` char(10) NOT NULL,
  `UsuNom` char(30) NOT NULL,
  `UsuPss` char(40) NOT NULL DEFAULT '',
  `UsuBaj` char(1) NOT NULL,
  `IdiCod` char(3) NOT NULL,
  `DepCod` smallint DEFAULT NULL,
  `UsuMen` char(20) NOT NULL,
  `UsuMail` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`EmpCod`,`UsuCod`),
  KEY `IUSUARIOS1` (`EmpCod`,`DepCod`),
  KEY `IUSUARI3` (`IdiCod`),
  KEY `UUSU01` (`EmpCod`,`UsuNom`),
  CONSTRAINT `IUSUARIOS1` FOREIGN KEY (`EmpCod`, `DepCod`) REFERENCES `departamento` (`EmpCod`, `DepCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `usuprg1` (
  `EmpCod` smallint NOT NULL,
  `UsuCod` char(10) NOT NULL,
  `SegPrgId` smallint NOT NULL,
  `SegPrgClass` smallint NOT NULL,
  `SegPrgAccion` char(10) NOT NULL,
  `UsuSegAccEst` char(1) NOT NULL,
  PRIMARY KEY (`EmpCod`,`UsuCod`,`SegPrgId`,`SegPrgClass`,`SegPrgAccion`),
  KEY `IUSUPRG12` (`EmpCod`,`SegPrgId`,`SegPrgClass`,`SegPrgAccion`),
  CONSTRAINT `IUSUPRG13` FOREIGN KEY (`EmpCod`, `UsuCod`) REFERENCES `usuarios` (`EmpCod`, `UsuCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `usuprg` (
  `EmpCod` smallint NOT NULL,
  `UsuCod` char(10) NOT NULL,
  `UsuPrgCod` char(15) NOT NULL,
  `UsuPrgHab` char(1) NOT NULL,
  `UsuPrgNivel` smallint NOT NULL,
  `UsuPrgUsuCod` char(10) NOT NULL,
  `UsuPrgUltMod` datetime NOT NULL,
  PRIMARY KEY (`EmpCod`,`UsuCod`,`UsuPrgCod`),
  CONSTRAINT `IUSUPRG1` FOREIGN KEY (`EmpCod`, `UsuCod`) REFERENCES `usuarios` (`EmpCod`, `UsuCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `viatpo` (
  `ViaTpoCod` char(2) NOT NULL DEFAULT '',
  `ViaTpoDes` char(20) NOT NULL DEFAULT '',
  PRIMARY KEY (`ViaTpoCod`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Procedimientos almacenados

CREATE PROCEDURE `cambia_usupss`(in bd char(20), in usu char(10) ,in pass char(40))
BEGIN
  set @query := CONCAT("UPDATE ", bd, ".usuarios ", "SET usupss= ", "'", pass, "'", " WHERE usucod = ", "'", usu, "'", ";");
  PREPARE s from @query;
  EXECUTE s;
  DEALLOCATE PREPARE s;
END ;;

CREATE PROCEDURE `select_emp_usu`(in usu char(20), out bases char(255))
BEGIN
    
    select group_concat(EmpBase SEPARATOR '-' ) INTO bases from prueba_db.empbase where empbase.EmpCod in
    (select EmpCod from prueba_db.usuariosemp where EBUsuCod = usu); 
END ;;
