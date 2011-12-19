delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

CREATE TABLE IF NOT EXISTS `trj_mov` (
  `idtrj_mov` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `fecha` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `tarjeta` int(10) unsigned DEFAULT NULL,
  `tipo` varchar(10) COLLATE utf8_spanish_ci DEFAULT NULL COMMENT 'ENTREGA de OM/OCG a OM/OCG\nASIGNA de OM a Persona\nDEVUELVE de Persona a OM\nBUZON de Persona a Controlador\nRETIRA de Controlador a OM/OCG\nALMACENA de OM/OCG a Controlador',
  `de` int(10) unsigned DEFAULT NULL,
  `a` int(10) unsigned DEFAULT NULL,
  `funciones` char(1) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`idtrj_mov`),
  KEY `Trj_IDX` (`tarjeta`),
  KEY `TrjFch_IDX` (`tarjeta`,`fecha`),
  KEY `idTrj_IDX` (`idtrj_mov`,`tarjeta`),
  KEY `Fch_IDX` (`fecha`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci$$

