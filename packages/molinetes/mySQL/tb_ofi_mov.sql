delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

CREATE TABLE IF NOT EXISTS `ofi_mov` (
  `idofi_mov` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `fecha` timestamp NULL DEFAULT NULL,
  `tipo` varchar(16) COLLATE utf8_spanish_ci DEFAULT NULL,
  `idoficina` int(10) unsigned DEFAULT NULL,
  `idpersona` int(10) unsigned DEFAULT NULL,
  `idoperador` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`idofi_mov`),
  KEY `PerFch_IDX` (`idpersona`,`fecha`),
  KEY `OfiFch_IDX` (`idoficina`,`fecha`),
  KEY `OfiId_IDX` (`idoficina`,`idofi_mov`),
  KEY `PerId_IDX` (`idpersona`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci$$

