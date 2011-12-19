delimiter $$
CREATE DATABASE IF NOT EXISTS molinetes$$
USE molinetes$$

CREATE TABLE IF NOT EXISTS `tarjetas` (
  `idtarjeta` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `hex` char(8) COLLATE utf8_spanish_ci DEFAULT NULL,
  `pack` char(4) COLLATE utf8_spanish_ci DEFAULT NULL,
  `lecturas` int(10) unsigned DEFAULT '0',
  `created` datetime DEFAULT NULL,
  `last` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `funciones` char(1) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`idtarjeta`),
  KEY `Hex_IDX` (`hex`),
  KEY `Pack_IDX` (`pack`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci$$

